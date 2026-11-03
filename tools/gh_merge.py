#!/usr/bin/env python3
"""Gộp nhánh vào main dạng fast-forward bằng REST API (không tạo commit gộp, không ghi đè).

Biến môi trường: TOKEN (bắt buộc), BRANCH (bắt buộc), BASE (mặc định main), REPO (mặc định halo07-pixel/CARD).
Dừng nếu BASE có commit mà BRANCH không có (khi đó phải rebase/gộp thủ công, không được ép).
Chạy: TOKEN=... BRANCH=claude/phase-2-3-potions-xcost-upgrades python3 tools/gh_merge.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

REPO = os.environ.get("REPO", "halo07-pixel/CARD")
API = f"https://api.github.com/repos/{REPO}"


def need(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        sys.exit(f"Thiếu biến môi trường {name}")
    return value


TOKEN = need("TOKEN")


def api(method: str, path: str, body=None):
    request = urllib.request.Request(
        API + path, method=method, data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit(f"LỖI {method} {path}: {error.code} {json.load(error).get('message')}")


def main() -> None:
    branch, base = need("BRANCH"), os.environ.get("BASE", "main")
    branch_sha = api("GET", f"/git/ref/heads/{branch}")["object"]["sha"]
    base_sha = api("GET", f"/git/ref/heads/{base}")["object"]["sha"]
    cmp = api("GET", f"/compare/{base_sha}...{branch_sha}")
    print(f"{base}: {base_sha[:7]} | {branch}: {branch_sha[:7]} | {cmp['status']} "
          f"ahead_by={cmp['ahead_by']} behind_by={cmp['behind_by']}")
    if cmp["behind_by"] != 0:
        sys.exit(f"DỪNG: {base} đã có commit mới ngoài {branch}; không ghi đè.")
    api("PATCH", f"/git/refs/heads/{base}", {"sha": branch_sha, "force": False})
    after = api("GET", f"/git/ref/heads/{base}")["object"]["sha"]
    print(f"{base} sau khi gộp: {after[:7]} | khớp nhánh: {after == branch_sha}")


if __name__ == "__main__":
    main()
