#!/usr/bin/env bash
# Tự kiểm bộ chạy test: nó PHẢI thất bại khi một test có lỗi script (dù đã có assertion đạt trước đó), lỗi biên dịch hoặc
# rò rỉ đối tượng khi thoát, và PHẢI đạt khi không có lỗi. Tạo file test tạm rồi luôn xóa. Dùng: tools/check_runner.sh
set -uo pipefail
cd "$(dirname "$0")/.."
tmp_ok="tests/test_zz_runner_selfcheck_ok.gd"
tmp_script_error="tests/test_zz_runner_selfcheck_script_error.gd"
tmp_parse_error="tests/test_zz_runner_selfcheck_parse_error.gd"
tmp_leak="tests/test_zz_runner_selfcheck_leak.gd"
cleanup() { rm -f "$tmp_ok" "$tmp_script_error" "$tmp_parse_error" "$tmp_leak" "$tmp_ok.uid" "$tmp_script_error.uid" "$tmp_parse_error.uid" "$tmp_leak.uid"; }
trap cleanup EXIT
failed=0

cat > "$tmp_ok" <<'GD'
extends "res://tests/test_case.gd"
func test_plain_pass() -> void:
	assert_true(true)
GD
cat > "$tmp_script_error" <<'GD'
extends "res://tests/test_case.gd"
func test_script_error_after_a_passing_assertion() -> void:
	assert_true(true)  # đã có assertion đạt: bộ chạy cũ sẽ báo "đạt"
	var node: Node = null
	node.queue_free()  # SCRIPT ERROR: gọi hàm trên null
GD
cat > "$tmp_parse_error" <<'GD'
extends "res://tests/test_case.gd"
func test_parse_error() -> void:
	var x: int = "không phải số"
	assert_true(true)
GD
cat > "$tmp_leak" <<'GD'
extends "res://tests/test_case.gd"
func test_reference_cycle_that_leaks_at_exit() -> void:
	assert_true(true)  # test đạt, nhưng để lại một vòng tham chiếu: holder -> meta -> lambda -> holder
	var holder := RefCounted.new()
	var callback := func() -> int: return holder.get_reference_count()
	holder.set_meta("callback", callback)
GD

expect() {  # expect <mô tả> <mã thoát mong đợi> <--only>
	local description="$1" expected="$2" only="$3" out code
	out="$(tools/run_tests.sh --only="$only" 2>&1)"; code=$?
	if [ "$code" -eq "$expected" ]; then
		echo "ok    ${description} (mã thoát ${code})"
	else
		echo "LỖI   ${description}: mong đợi mã thoát ${expected}, thực tế ${code}"
		echo "$out" | tail -8
		failed=1
	fi
}
expect "test sạch -> đạt" 0 "test_zz_runner_selfcheck_ok.gd"
expect "SCRIPT ERROR sau assertion đạt -> FAIL" 1 "test_zz_runner_selfcheck_script_error.gd"
expect "Parse Error -> FAIL" 1 "test_zz_runner_selfcheck_parse_error.gd"
expect "rò rỉ khi thoát (vòng tham chiếu) -> FAIL" 1 "test_zz_runner_selfcheck_leak.gd"
if [ "$failed" -eq 0 ]; then echo "Bộ chạy test hoạt động đúng."; else echo "Bộ chạy test CÓ VẤN ĐỀ."; fi
exit "$failed"
