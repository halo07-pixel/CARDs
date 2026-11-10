extends SceneTree
## In ra bảng GOLDEN (dán vào tests/test_enemy_turn_equivalence.gd). CHỈ chạy lại khi cố ý đổi dữ liệu/luật chơi
## làm các trận mô phỏng đổi kết quả (thẻ, quái, relic...), vì golden gắn với dữ liệu thật.
##   godot --headless --path . -s res://tools/record_enemy_turn_golden.gd

func _initialize() -> void:
	var data := GameData.load_default()
	var fp := load("res://tests/enemy_turn_fingerprint.gd")
	print("GOLDEN_BEGIN")
	for scenario in fp.scenarios():
		var r: Dictionary = fp.run(scenario, data)
		print("\t%d: \"%s\",  # %s lượt %d, %d lần quái đi" % [scenario["seed"], r["hash"], r["reason"], r["turn"], r["acted"]])
	print("GOLDEN_END")
	quit()
