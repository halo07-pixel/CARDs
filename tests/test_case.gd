extends RefCounted
## Lớp cơ sở cho test. File test dùng: extends "res://tests/test_case.gd"
## Hàm test: bắt đầu bằng "test_" (có thể dùng await). Hook tùy chọn: before_each / after_each.

var failures: Array[String] = []
var assertions: int = 0  ## số assertion đã chạy trong test hiện tại (runner dùng để bắt test chết giữa chừng)


func assert_true(condition: bool, message: String = "") -> void:
	assertions += 1
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message: String = "") -> void:
	assertions += 1
	if condition:
		_fail("expected false", message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("expected value different from %s" % var_to_str(unexpected), message)


func assert_almost_eq(actual: float, expected: float, epsilon: float = 0.0001, message: String = "") -> void:
	assertions += 1
	if absf(actual - expected) > epsilon:
		_fail("expected ~%s, got %s" % [expected, actual], message)


func _fail(detail: String, message: String) -> void:
	failures.append(detail if message.is_empty() else "%s (%s)" % [detail, message])
