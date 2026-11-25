extends "res://tests/test_case.gd"
## RunMap: cấu trúc, truy vấn, kiểm tra hợp lệ, serialize (kể cả vòng JSON).


## Bản đồ nhỏ hợp lệ: 3 cột x 3 tầng + boss. Tầng 0: cột 0 và 2; nối thẳng/chéo lên đến boss.
func _small() -> RunMap:
	var map := RunMap.new(3, 3)
	var a := map.add_node(0, 0)
	var b := map.add_node(0, 2)
	var c := map.add_node(1, 1)
	var d := map.add_node(2, 1)
	var boss := map.add_node(3, 1, RoomType.Kind.BOSS)
	map.connect_nodes(a.id, c.id)
	map.connect_nodes(b.id, c.id)
	map.connect_nodes(c.id, d.id)
	map.connect_nodes(d.id, boss.id)
	return map


func test_a_small_map_is_valid_and_answers_queries() -> void:
	var map := _small()
	assert_eq(map.validate(), [] as Array[String])
	assert_eq(map.node_count(), 5)
	assert_eq(map.boss_id(), RunMap.id_for(3, 1, 3))
	assert_eq(map.start_nodes().map(func(n: MapNode) -> int: return n.column), [0, 2])
	var c := map.get_node_by_id(RunMap.id_for(1, 1, 3))
	assert_eq(map.parents_of(c.id).map(func(n: MapNode) -> int: return n.column), [0, 2])
	assert_eq(map.next_nodes(map.start_nodes()[0].id).size(), 1)
	assert_eq(map.next_nodes(map.boss_id()).size(), 0, "boss không có đường đi tiếp")
	assert_true(map.get_node_by_id(999) == null)
	assert_eq(map.next_nodes(999).size(), 0)


func test_add_node_returns_the_existing_node_and_rejects_positions_outside_the_grid() -> void:
	var map := RunMap.new(3, 3)
	var first := map.add_node(1, 1)
	assert_true(map.add_node(1, 1) == first, "cùng vị trí cùng nút")
	assert_eq(map.node_count(), 1)
	assert_true(map.add_node(-1, 0) == null)
	assert_true(map.add_node(0, 3) == null)
	assert_true(map.add_node(4, 0) == null)
	assert_eq(map.node_count(), 1)


func test_connect_nodes_rejects_bad_edges_but_allows_any_column_into_the_boss() -> void:
	var map := RunMap.new(5, 3)
	var low := map.add_node(0, 0)
	var up_far := map.add_node(1, 3)
	var up_near := map.add_node(1, 1)
	var top := map.add_node(2, 4)
	var boss := map.add_node(3, 2, RoomType.Kind.BOSS)
	assert_false(map.connect_nodes(low.id, up_far.id), "lệch hai cột trở lên")
	assert_true(map.connect_nodes(low.id, up_near.id))
	assert_false(map.connect_nodes(low.id, top.id), "nhảy hai tầng")
	assert_false(map.connect_nodes(up_near.id, low.id), "đi xuống")
	assert_false(map.connect_nodes(low.id, 12345), "nút không tồn tại")
	assert_true(map.connect_nodes(top.id, boss.id), "boss nối từ cột bất kỳ")
	assert_false(map.connect_nodes(up_near.id, boss.id), "nhưng vẫn phải đúng tầng")


func test_duplicate_edges_are_ignored() -> void:
	var map := _small()
	var a := map.start_nodes()[0]
	var target := map.next_nodes(a.id)[0]
	assert_true(map.connect_nodes(a.id, target.id), "nối lại không lỗi")
	assert_eq(a.edges.size(), 1)


func test_edge_would_cross_detects_inversions_only() -> void:
	var map := RunMap.new(5, 4)
	var left := map.add_node(0, 1)
	var right := map.add_node(0, 3)
	var left_up := map.add_node(1, 2)
	map.add_node(1, 3)
	map.connect_nodes(left.id, left_up.id)  # cạnh 1 -> 2
	assert_true(map.edge_would_cross(0, 3, 1), "3 -> 1 cắt 1 -> 2")
	assert_false(map.edge_would_cross(0, 3, 3), "đi thẳng không cắt")
	assert_false(map.edge_would_cross(0, 3, 2), "cùng đích không cắt")
	assert_false(map.edge_would_cross(0, 1, 1), "chính cạnh của nó")
	assert_false(RunMap.new(5, 4).edge_would_cross(0, 2, 2), "bản đồ trống")
	assert_true(right != null)


## --- validate ---

func _has_problem(map: RunMap, fragment: String) -> bool:
	for problem in map.validate():
		if problem.contains(fragment):
			return true
	return false


## Mỗi luật cấu trúc phải tự báo ĐÚNG thông điệp của nó (không để lỗi khác che mất).
func test_validate_reports_each_structural_problem_with_its_own_message() -> void:
	var no_boss := _small()
	no_boss.get_node_by_id(no_boss.boss_id()).kind = RoomType.Kind.MONSTER
	assert_true(_has_problem(no_boss, "đúng một boss"), "không còn boss")
	assert_true(_has_problem(no_boss, "tầng boss nhưng không phải boss"))

	var boss_too_low := _small()
	boss_too_low.get_node_by_id(RunMap.id_for(2, 1, 3)).kind = RoomType.Kind.BOSS
	assert_true(_has_problem(boss_too_low, "ngoài tầng cuối"), "boss không ở tầng cuối")
	assert_true(_has_problem(boss_too_low, "đúng một boss"), "và có hai boss")

	var two_bosses := _small()
	var second := two_bosses.add_node(3, 0, RoomType.Kind.BOSS)
	two_bosses.connect_nodes(RunMap.id_for(2, 1, 3), second.id)  # nối hợp lệ: chỉ riêng số lượng boss sai
	assert_eq(two_bosses.validate().size(), 1, "chỉ đúng một lỗi: %s" % [two_bosses.validate()])
	assert_true(_has_problem(two_bosses, "đúng một boss"))

	var dead_end := _small()
	dead_end.get_node_by_id(RunMap.id_for(1, 1, 3)).edges.clear()
	assert_true(_has_problem(dead_end, "không có đường đi tiếp"))

	var orphan := _small()
	orphan.add_node(1, 0)
	assert_true(_has_problem(orphan, "không có đường dẫn tới"))

	var bad_target := _small()
	bad_target.get_node_by_id(RunMap.id_for(0, 0, 3)).edges.append(12345)
	assert_true(_has_problem(bad_target, "không tồn tại"))

	var wrong_kind := _small()
	wrong_kind.get_node_by_id(RunMap.id_for(1, 1, 3)).kind = 99 as RoomType.Kind
	assert_true(_has_problem(wrong_kind, "loại phòng không hợp lệ"))

	var no_start := RunMap.new(3, 3)
	no_start.add_node(3, 1, RoomType.Kind.BOSS)
	assert_true(_has_problem(no_start, "không có nút xuất phát"))

	assert_true(_has_problem(RunMap.new(1, 1), "kích thước"))

	var boss_climbs := _small()
	var extra := boss_climbs.add_node(3, 0)  # nút thường ở tầng boss, bị báo riêng; thêm cạnh đi lên từ boss
	boss_climbs.get_node_by_id(boss_climbs.boss_id()).edges.append(extra.id)
	assert_true(_has_problem(boss_climbs, "không được có cạnh đi lên"))

	var mismatched := _small()
	mismatched.get_node_by_id(RunMap.id_for(1, 1, 3)).column = 0  # id không còn khớp vị trí
	assert_true(_has_problem(mismatched, "không khớp"))

	var lateral := _small()
	lateral.get_node_by_id(RunMap.id_for(0, 0, 3)).edges.append(RunMap.id_for(1, 2, 3))
	lateral.add_node(1, 2)
	assert_true(_has_problem(lateral, "lệch quá một cột"))

	var duplicate_edge := _small()
	var start := duplicate_edge.get_node_by_id(RunMap.id_for(0, 0, 3))
	start.edges.append(start.edges[0])
	assert_true(_has_problem(duplicate_edge, "cạnh trùng"))


func test_validate_reports_crossing_edges_even_when_every_edge_is_otherwise_legal() -> void:
	# 4 cột: nút (0,1) -> (1,2) và nút (0,2) -> (1,1): mỗi cạnh lệch một cột (hợp lệ) nhưng hai cạnh cắt nhau.
	var map := RunMap.new(4, 3)
	var left := map.add_node(0, 1)
	var right := map.add_node(0, 2)
	var up_left := map.add_node(1, 1)
	var up_right := map.add_node(1, 2)
	var top := map.add_node(2, 1)
	var boss := map.add_node(3, 2, RoomType.Kind.BOSS)
	map.connect_nodes(left.id, up_left.id)
	map.connect_nodes(right.id, up_right.id)
	map.connect_nodes(up_left.id, top.id)
	map.connect_nodes(up_right.id, top.id)
	map.connect_nodes(top.id, boss.id)
	assert_eq(map.validate(), [] as Array[String], "chưa cắt nhau")
	map.connect_nodes(left.id, up_right.id)  # (0,1) -> (1,2)
	map.connect_nodes(right.id, up_left.id)  # (0,2) -> (1,1): cắt với (0,1) -> (1,2)
	assert_eq(map.validate().size(), 1, "chỉ đúng một lỗi: %s" % [map.validate()])
	assert_true(_has_problem(map, "cắt nhau"))


## --- serialize ---

func test_dict_round_trip_is_identical() -> void:
	var map := _small()
	var restored := RunMap.from_dict(map.to_dict())
	assert_true(restored != null)
	assert_eq(restored.to_dict(), map.to_dict())
	assert_eq(restored.validate(), [] as Array[String])


func test_round_trip_through_json_text_where_ints_become_floats() -> void:
	var map := MapGenerator.generate(4242)
	var json := JSON.stringify(map.to_dict())
	var parsed: Variant = JSON.parse_string(json)
	var restored := RunMap.from_dict(parsed)
	assert_true(restored != null, "số thực nguyên sau JSON vẫn nạp được")
	assert_eq(restored.to_dict(), map.to_dict())


func test_from_dict_rejects_broken_data() -> void:
	var good := _small().to_dict()
	var variants: Array = [null, 5, "x", [], {}, {"columns": 3},
		{"columns": 3, "floors": 3, "nodes": "no"},
		{"columns": 3.5, "floors": 3, "nodes": []},
		{"columns": 3, "floors": 3, "nodes": [5]},
		{"columns": 3, "floors": 3, "nodes": [{"id": 0}]},
		{"columns": 3, "floors": 3, "nodes": [{"id": 0, "floor": 0, "column": 0, "kind": 99, "edges": []}]},
		{"columns": 3, "floors": 3, "nodes": [{"id": 0, "floor": 0, "column": 0, "kind": 0, "edges": ["a"]}]},
	]
	for bad in variants:
		assert_true(RunMap.from_dict(bad) == null, "phải từ chối: %s" % [bad])
	var duplicate: Dictionary = good.duplicate(true)
	duplicate["nodes"].append(duplicate["nodes"][0])
	assert_true(RunMap.from_dict(duplicate) == null, "trùng id")
	var broken_edge: Dictionary = good.duplicate(true)
	broken_edge["nodes"][0]["edges"] = [999]
	assert_true(RunMap.from_dict(broken_edge) == null, "cạnh tới nút không có (validate bắt)")
	var no_boss: Dictionary = good.duplicate(true)
	for node in no_boss["nodes"]:
		if node["kind"] == RoomType.Kind.BOSS:
			node["kind"] = RoomType.Kind.MONSTER
	assert_true(RunMap.from_dict(no_boss) == null, "thiếu boss")


func test_to_dict_is_sorted_by_id_so_it_is_stable() -> void:
	var map := MapGenerator.generate(11)
	var ids: Array = map.to_dict()["nodes"].map(func(n: Dictionary) -> int: return n["id"])
	var sorted := ids.duplicate()
	sorted.sort()
	assert_eq(ids, sorted)
