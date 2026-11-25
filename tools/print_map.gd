extends SceneTree
## In bản đồ ASCII của một seed. Dùng:  godot --headless --path . -s res://tools/print_map.gd -- --seed=123 [--act=1]
func _initialize() -> void:
	var run_seed := 1
	var act := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			run_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--act="):
			act = int(arg.trim_prefix("--act="))
	var map := MapGenerator.generate(run_seed, act)
	print("MAP seed=%d act=%d nút=%d lỗi=%s" % [run_seed, act, map.node_count(), map.validate()])
	print(MapAscii.render(map))
	quit()
