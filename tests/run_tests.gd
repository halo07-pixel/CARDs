extends SceneTree
## Chạy: godot --headless --path . -s res://tests/run_tests.gd [-- --only=chuoi1,chuoi2]
## Quét đệ quy res://tests/ tìm test_*.gd. Thoát mã 1 nếu có lỗi hoặc không có test nào.
## --only: chỉ chạy các file test có tên chứa một trong các chuỗi (nhanh khi đang sửa một phần).

const TEST_ROOT := "res://tests"
const TEST_FILE_PREFIX := "test_"
const TEST_METHOD_PREFIX := "test_"
const BASE_NAME := "test_case.gd"


func _initialize() -> void:
	# Autoload chỉ chạy _ready sau _initialize -> chờ 1 frame cho môi trường giống game thật.
	await process_frame
	var exit_code := await _run_all()
	quit(exit_code)


func _run_all() -> int:
	var files := _filter_files(_collect_test_files(TEST_ROOT), _only_filters())
	files.sort()
	var passed := 0
	var failed := 0
	for path in files:
		var result := await _run_file(path)
		passed += result[0]
		failed += result[1]
	print("\n==== %d passed, %d failed (%d files) ====" % [passed, failed, files.size()])
	if passed + failed == 0:
		push_error("Không tìm thấy test nào")
		return 1
	return 1 if failed > 0 else 0


func _run_file(path: String) -> Array[int]:
	var script := load(path) as GDScript
	if script == null or not script.can_instantiate():
		printerr("FAIL  %s  (không load được script)" % path)
		return [0, 1]
	var instance: RefCounted = script.new()
	var methods: Array[String] = []
	for info: Dictionary in script.get_script_method_list():
		if String(info["name"]).begins_with(TEST_METHOD_PREFIX):
			methods.append(info["name"])
	methods.sort()
	var passed := 0
	var failed := 0
	for method in methods:
		instance.failures.clear()
		instance.assertions = 0
		if instance.has_method("before_each"):
			await instance.call("before_each")
		await instance.call(method)
		if instance.has_method("after_each"):
			await instance.call("after_each")
		if instance.assertions == 0:
			instance.failures.append("không có assertion nào chạy (test có thể đã chết vì lỗi script)")
		if instance.failures.is_empty():
			passed += 1
			print("ok    %s :: %s" % [path.get_file(), method])
		else:
			failed += 1
			printerr("FAIL  %s :: %s" % [path.get_file(), method])
			for message: String in instance.failures:
				printerr("        - " + message)
	return [passed, failed]


func _collect_test_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub in dir.get_directories():
		result.append_array(_collect_test_files(dir_path.path_join(sub)))
	for file_name in dir.get_files():
		if file_name.begins_with(TEST_FILE_PREFIX) and file_name.ends_with(".gd") and file_name != BASE_NAME:
			result.append(dir_path.path_join(file_name))
	return result


## Các chuỗi lọc từ tham số --only=a,b (rỗng = chạy tất cả).
func _only_filters() -> PackedStringArray:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			return arg.trim_prefix("--only=").split(",", false)
	return PackedStringArray()


func _filter_files(files: Array[String], filters: PackedStringArray) -> Array[String]:
	if filters.is_empty():
		return files
	var kept: Array[String] = []
	for path in files:
		for filter in filters:
			if path.get_file().contains(filter):
				kept.append(path)
				break
	return kept
