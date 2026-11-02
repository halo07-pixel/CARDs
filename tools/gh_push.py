#!/usr/bin/env python3
"""Đẩy thay đổi local lên GitHub bằng REST API.

Vì sao có file này: trong sandbox của Claude, giao thức git (push/clone có xác thực) bị chặn (401),
nhưng api.github.com thì dùng được. Công cụ này tạo blob -> tree -> commit -> ref giống hệt `git push`.

Biến môi trường:
  TOKEN    (bắt buộc) fine-grained PAT, chỉ repo này, quyền Contents: Read and write. KHÔNG ghi vào file.
  BRANCH   (bắt buộc) nhánh đích. Chưa có -> tạo mới từ BASE. Đã có -> thêm commit lên đầu nhánh (fast-forward).
  MESSAGE  (bắt buộc) nội dung commit (theo mẫu `<type>: <mô tả>`).
  BASE     nhánh gốc để so sánh/tạo nhánh mới (mặc định main).
  REPO     mặc định halo07-pixel/CARD.
  DRY_RUN  =1 chỉ liệt kê file sẽ đẩy.
Chạy từ bất kỳ đâu: TOKEN=... BRANCH=claude/xxx MESSAGE="feat: ..." python3 tools/gh_push.py
Chỉ thêm/sửa file (không xóa file trên remote); nếu local thiếu file có trên remote thì dừng và báo.
"""
import base64
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.environ.get("REPO", "halo07-pixel/CARD")
API = f"https://api.github.com/repos/{REPO}"
SKIP_DIRS = {".git", ".godot"}


def need(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        sys.exit(f"Thiếu biến môi trường {name}")
    return value


TOKEN = need("TOKEN")


def api(method: str, path: str, body=None, allow_404: bool = False):
    request = urllib.request.Request(
        API + path, method=method, data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        if error.code == 404 and allow_404:
            return None
        message = json.load(error).get("message")
        sys.exit(f"LỖI {method} {path}: {error.code} {message}")


def head_sha(branch: str):
    ref = api("GET", f"/git/ref/heads/{branch}", allow_404=True)
    return ref["object"]["sha"] if ref else None


def tree_of(commit_sha: str):
    tree_sha = api("GET", f"/git/commits/{commit_sha}")["tree"]["sha"]
    listing = api("GET", f"/git/trees/{tree_sha}?recursive=1")["tree"]
    return tree_sha, {t["path"]: t for t in listing if t["type"] == "blob"}


def local_files() -> dict:
    files = {}
    for directory, subdirs, names in os.walk(ROOT):
        subdirs[:] = [d for d in subdirs if d not in SKIP_DIRS]
        for name in names:
            path = os.path.join(directory, name)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            data = open(path, "rb").read()
            mode = "100755" if rel.endswith(".sh") and os.access(path, os.X_OK) else "100644"
            files[rel] = (data, mode, hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest())
    return files


def main() -> None:
    branch, message, base = need("BRANCH"), need("MESSAGE"), os.environ.get("BASE", "main")
    target_head = head_sha(branch)
    parent = target_head or head_sha(base)
    if parent is None:
        sys.exit(f"Không tìm thấy nhánh gốc '{base}'")
    parent_tree, remote = tree_of(parent)
    local = local_files()
    changed = sorted(r for r, (_d, m, h) in local.items()
                     if r not in remote or remote[r]["sha"] != h or remote[r]["mode"] != m)
    missing = sorted(r for r in remote if r not in local)
    print(f"cha: {parent[:7]} ({'nhánh ' + branch if target_head else 'nhánh ' + base}) | "
          f"file đổi/mới: {len(changed)} | thiếu ở local: {len(missing)}")
    for rel in changed:
        print("  ", "M" if rel in remote else "A", rel)
    if missing:
        sys.exit(f"DỪNG: local thiếu file có trên remote (công cụ này không xóa file): {missing[:10]}")
    if not changed:
        print("Không có gì để đẩy.")
        return
    if os.environ.get("DRY_RUN") == "1":
        return
    entries = []
    for rel in changed:
        data, mode, _hash = local[rel]
        blob = api("POST", "/git/blobs", {"content": base64.b64encode(data).decode(), "encoding": "base64"})
        entries.append({"path": rel, "mode": mode, "type": "blob", "sha": blob["sha"]})
    tree = api("POST", "/git/trees", {"base_tree": parent_tree, "tree": entries})["sha"]
    commit = api("POST", "/git/commits", {"message": message, "tree": tree, "parents": [parent]})["sha"]
    if target_head:
        api("PATCH", f"/git/refs/heads/{branch}", {"sha": commit, "force": False})
    else:
        api("POST", "/git/refs", {"ref": f"refs/heads/{branch}", "sha": commit})
    after_head = head_sha(branch)
    _tree, after = tree_of(after_head)
    wrong = [r for r in local if r not in after or after[r]["sha"] != local[r][2] or after[r]["mode"] != local[r][1]]
    print(f"ĐÃ ĐẨY {branch} -> {after_head[:7]} | file trên nhánh: {len(after)} | "
          f"sai khác so với local: {wrong or 'KHÔNG CÓ'}")
    print(f"https://github.com/{REPO}/tree/{branch}")


if __name__ == "__main__":
    main()
