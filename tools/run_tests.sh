#!/usr/bin/env bash
# Chạy test headless. Dùng: tools/run_tests.sh [--only=chuoi1,chuoi2]   (đặt GODOT=/đường/dẫn nếu cần)
# Thoát mã 1 nếu có test FAIL, HOẶC có dòng "SCRIPT ERROR" / "Parse Error" trong đầu ra (một lỗi script giữa chừng làm
# hàm test chết nhưng test vẫn có thể báo "đạt" nếu đã có assertion chạy trước đó), HOẶC Godot báo rò rỉ đối tượng khi thoát
# (vòng tham chiếu, node không giải phóng...). Cách tìm nguồn rò rỉ: chạy lại với --verbose rồi chia nhóm file test.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Luôn import: cập nhật cache class_name (CardData, Deck...) khi có script mới.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
set +e
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- "$@" 2>&1 | tee "$log"
code="${PIPESTATUS[0]}"
set -e
errors="$(grep -E '^(SCRIPT ERROR|Parse Error|Parser Error)' "$log" || true)"
if [ -n "$errors" ]; then
	count="$(printf '%s\n' "$errors" | wc -l | tr -d ' ')"
	echo
	echo "==== ${count} lỗi script/biên dịch (SCRIPT ERROR / Parse Error) -> FAIL ===="
	exit 1
fi
leaks="$(grep -E 'ObjectDB instances were leaked|resources still in use at exit|RID allocations .* were leaked' "$log" || true)"
if [ -n "$leaks" ]; then
	echo
	echo "==== rò rỉ đối tượng khi thoát -> FAIL ===="
	printf '%s\n' "$leaks"
	exit 1
fi
exit "$code"
