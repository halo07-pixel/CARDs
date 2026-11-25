extends "res://tests/test_case.gd"
## MapAscii: bản in ASCII (boss trên cùng, tầng đầu dưới cùng).


func test_render_has_one_node_line_per_floor_plus_the_boss_and_edge_lines_between() -> void:
	var map := MapGenerator.generate(7)
	var lines := MapAscii.render(map).split("\n")
	assert_eq(lines.size(), (map.floors + 1) + map.floors, "mỗi tầng một dòng nút, giữa hai tầng một dòng cạnh")
	assert_true(lines[0].begins_with("16 "), "boss ở trên cùng")
	assert_true(lines[lines.size() - 1].begins_with(" 1 "), "tầng đầu ở dưới cùng")


func test_render_shows_each_node_with_its_symbol_exactly_once() -> void:
	for run_seed in [1, 7, 99]:
		var map := MapGenerator.generate(run_seed)
		var text := MapAscii.render(map)
		var node_lines := []
		var lines := text.split("\n")
		for i in range(0, lines.size(), 2):
			node_lines.append(lines[i])
		var symbols := 0
		for line: String in node_lines:
			var body := line.substr(3)
			for symbol in RoomType.SYMBOLS.values():
				symbols += body.count(symbol)
		assert_eq(symbols, map.node_count(), "seed %d: số ký hiệu = số nút" % run_seed)


func test_render_is_deterministic_and_has_a_boss_marker() -> void:
	var first := MapAscii.render(MapGenerator.generate(5))
	assert_eq(first, MapAscii.render(MapGenerator.generate(5)))
	assert_true(first.contains("B"))
	assert_ne(first, MapAscii.render(MapGenerator.generate(6)))
