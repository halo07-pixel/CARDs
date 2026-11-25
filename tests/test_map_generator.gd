extends "res://tests/test_case.gd"
## MapGenerator: tất định, cấu trúc hợp lệ và mọi luật xếp loại phòng, kiểm bằng fuzz trên nhiều seed.

const SEEDS := 2000
const DISTRIBUTION_SEEDS := 400

var _kinds_seen := {}


func _kind_counts(map: RunMap, floors: Array) -> Dictionary:
	var counts := {}
	for floor_index in floors:
		for node in map.nodes_on_floor(floor_index):
			counts[node.kind] = counts.get(node.kind, 0) + 1
	return counts


## --- Tất định ---

func test_same_seed_gives_the_identical_map() -> void:
	for run_seed in [0, 1, 7, 12345, -99, 2147483647]:
		assert_eq(MapGenerator.generate(run_seed).to_dict(), MapGenerator.generate(run_seed).to_dict(), "seed %d" % run_seed)


func test_different_seeds_and_acts_give_different_maps() -> void:
	var seen := {}
	for run_seed in 200:
		seen[str(MapGenerator.generate(run_seed).to_dict())] = true
	assert_true(seen.size() >= 195, "200 seed phải cho (gần như) 200 bản đồ khác nhau, được %d" % seen.size())
	assert_ne(MapGenerator.generate(5, 1).to_dict(), MapGenerator.generate(5, 2).to_dict(), "act khác -> bản đồ khác")


func test_generation_does_not_touch_the_global_rng() -> void:
	seed(777)
	var before := randi()
	seed(777)
	MapGenerator.generate(123)
	assert_eq(randi(), before, "chỉ dùng luồng RNG riêng")


## --- Cấu hình ---

func test_invalid_config_gives_null() -> void:
	var cfg := MapConfig.new()
	cfg.columns = 1
	assert_true(MapGenerator.generate(1, 1, cfg) == null)


func test_small_and_unusual_configs_still_give_valid_maps() -> void:
	var shapes := [[3, 4, 2, 1, 1], [3, 6, 4, 2, 2], [5, 8, 3, 3, 2], [9, 12, 8, 6, 3], [15, 25, 12, 12, 2], [4, 20, 10, 10, 4]]
	for shape: Array in shapes:
		var cfg := MapConfig.new()
		cfg.columns = shape[0]
		cfg.floors = shape[1]
		cfg.paths = shape[2]
		cfg.treasure_floor = shape[3]
		cfg.elite_min_floor = mini(cfg.elite_min_floor, cfg.floors - 1)
		cfg.campfire_min_floor = mini(cfg.campfire_min_floor, cfg.floors - 1)
		cfg.min_start_columns = mini(shape[4], mini(cfg.columns, cfg.paths))
		assert_eq(cfg.validate(), [] as Array[String], "cấu hình %s" % [shape])
		for run_seed in 60:
			var map := MapGenerator.generate(run_seed, 1, cfg)
			assert_true(map != null)
			assert_eq(map.validate(), [] as Array[String], "hình dạng %s seed %d" % [shape, run_seed])
			assert_true(map.start_nodes().size() >= cfg.min_start_columns, "đủ cột xuất phát %s" % [shape])


## --- Cấu trúc (fuzz) ---

func test_structure_is_valid_for_every_seed() -> void:
	for run_seed in SEEDS:
		var map := MapGenerator.generate(run_seed)
		var problems := map.validate()
		assert_eq(problems, [] as Array[String], "seed %d" % run_seed)
		if not problems.is_empty():
			return  # một seed hỏng là đủ để biết; tránh tràn log


func test_every_floor_has_nodes_and_the_start_floor_has_at_least_two_distinct_columns() -> void:
	for run_seed in SEEDS:
		var map := MapGenerator.generate(run_seed)
		for floor_index in map.floors:
			var count := map.nodes_on_floor(floor_index).size()
			assert_true(count >= 1 and count <= map.columns, "seed %d tầng %d có %d nút" % [run_seed, floor_index, count])
		var starts := map.start_nodes().size()
		assert_true(starts >= 2 and starts <= 6, "seed %d có %d nút xuất phát" % [run_seed, starts])
		assert_eq(map.nodes_on_floor(map.floors).size(), 1, "đúng một boss")


func test_the_number_of_start_nodes_is_bounded_by_the_number_of_paths_and_reaches_it() -> void:
	var cfg := MapConfig.new()
	var highest := 0
	for run_seed in 600:
		var starts := MapGenerator.generate(run_seed, 1, cfg).start_nodes().size()
		assert_true(starts <= cfg.paths, "seed %d có %d nút xuất phát > %d đường" % [run_seed, starts, cfg.paths])
		highest = maxi(highest, starts)
	assert_eq(highest, cfg.paths, "với %d đường, có seed phải đủ %d nút xuất phát khác nhau" % [cfg.paths, cfg.paths])
	cfg.paths = 3
	cfg.min_start_columns = 2
	var three_max := 0
	for run_seed in 200:
		three_max = maxi(three_max, MapGenerator.generate(run_seed, 1, cfg).start_nodes().size())
	assert_eq(three_max, 3)


func test_every_node_is_reachable_from_a_start_and_leads_to_the_boss() -> void:
	for run_seed in 300:  # kiểm tra độc lập với validate(): đi thật trên đồ thị
		var map := MapGenerator.generate(run_seed)
		var reachable := {}
		var frontier: Array[int] = []
		for start in map.start_nodes():
			frontier.append(start.id)
			reachable[start.id] = true
		while not frontier.is_empty():
			var id: int = frontier.pop_back()
			for next in map.next_nodes(id):
				if not reachable.has(next.id):
					reachable[next.id] = true
					frontier.append(next.id)
		assert_eq(reachable.size(), map.node_count(), "seed %d: nút không đi tới được" % run_seed)
		assert_true(reachable.has(map.boss_id()))
		for floor_index in map.floors:
			for node in map.nodes_on_floor(floor_index):
				assert_false(map.next_nodes(node.id).is_empty(), "seed %d: nút cụt %d" % [run_seed, node.id])


func test_edges_go_up_one_floor_stay_within_one_column_and_never_cross() -> void:
	for run_seed in 500:
		var map := MapGenerator.generate(run_seed)
		for floor_index in map.floors:
			var edges: Array = []
			for node in map.nodes_on_floor(floor_index):
				for next in map.next_nodes(node.id):
					assert_eq(next.floor_index, floor_index + 1)
					if next.floor_index < map.floors:
						assert_true(absi(next.column - node.column) <= 1, "seed %d: cạnh lệch quá một cột" % run_seed)
					edges.append([node.column, next.column])
			for i in edges.size():
				for j in range(i + 1, edges.size()):
					var a: Array = edges[i]
					var b: Array = edges[j]
					assert_false((a[0] < b[0] and a[1] > b[1]) or (a[0] > b[0] and a[1] < b[1]), "seed %d: cạnh cắt nhau" % run_seed)


## --- Luật loại phòng (fuzz) ---

func test_forced_floors_have_the_forced_kind_everywhere() -> void:
	for run_seed in SEEDS:
		var map := MapGenerator.generate(run_seed)
		for node in map.nodes_on_floor(0):
			assert_eq(node.kind, RoomType.Kind.MONSTER, "seed %d tầng đầu" % run_seed)
		for node in map.nodes_on_floor(8):
			assert_eq(node.kind, RoomType.Kind.TREASURE, "seed %d tầng kho báu" % run_seed)
		for node in map.nodes_on_floor(14):
			assert_eq(node.kind, RoomType.Kind.CAMPFIRE, "seed %d tầng lửa trại cuối" % run_seed)
		assert_eq(map.get_node_by_id(map.boss_id()).kind, RoomType.Kind.BOSS)


func test_special_kinds_appear_only_where_the_rules_allow() -> void:
	for run_seed in SEEDS:
		var map := MapGenerator.generate(run_seed)
		for floor_index in range(0, map.floors):
			for node in map.nodes_on_floor(floor_index):
				match node.kind:
					RoomType.Kind.TREASURE:
						assert_eq(floor_index, 8, "seed %d: kho báu ngoài tầng 9" % run_seed)
					RoomType.Kind.BOSS:
						assert_true(false, "seed %d: boss ngoài tầng cuối" % run_seed)
					RoomType.Kind.ELITE:
						assert_true(floor_index >= 5, "seed %d: elite quá sớm (tầng %d)" % [run_seed, floor_index])
					RoomType.Kind.CAMPFIRE:
						assert_true(floor_index == 14 or (floor_index >= 5 and floor_index != 13),
								"seed %d: lửa trại sai tầng %d" % [run_seed, floor_index])


func test_restricted_kinds_never_touch_themselves_along_a_path_or_among_siblings() -> void:
	for run_seed in SEEDS:
		var map := MapGenerator.generate(run_seed)
		for floor_index in range(1, map.floors + 1):
			for node in map.nodes_on_floor(floor_index):
				if not RoomType.RESTRICTED.has(node.kind):
					continue
				for parent in map.parents_of(node.id):
					assert_ne(parent.kind, node.kind, "seed %d: %s liền nhau (tầng %d)" % [run_seed, RoomType.name_of(node.kind), floor_index])
					if floor_index == 14:
						continue  # tầng ép lửa trại: anh em đều là lửa trại theo luật ép
					for sibling_id in parent.edges:
						if sibling_id != node.id:
							assert_ne(map.get_node_by_id(sibling_id).kind, node.kind,
									"seed %d: nút anh em trùng %s (tầng %d)" % [run_seed, RoomType.name_of(node.kind), floor_index])


## --- Phân bố ---

func test_free_floors_follow_the_weights_roughly_and_every_free_kind_shows_up() -> void:
	var free_floors := [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13]
	var totals := {}
	var grand := 0
	for run_seed in DISTRIBUTION_SEEDS:
		var counts := _kind_counts(MapGenerator.generate(run_seed), free_floors)
		for kind in counts:
			totals[kind] = totals.get(kind, 0) + counts[kind]
			grand += counts[kind]
	var share := func(kind: RoomType.Kind) -> float: return float(totals.get(kind, 0)) / grand
	assert_true(share.call(RoomType.Kind.MONSTER) > share.call(RoomType.Kind.EVENT), "quái nhiều hơn sự kiện")
	assert_true(share.call(RoomType.Kind.EVENT) > share.call(RoomType.Kind.ELITE), "sự kiện nhiều hơn elite")
	assert_true(share.call(RoomType.Kind.MONSTER) > 0.38 and share.call(RoomType.Kind.MONSTER) < 0.62, "tỉ lệ quái %.3f" % share.call(RoomType.Kind.MONSTER))
	assert_true(share.call(RoomType.Kind.EVENT) > 0.15 and share.call(RoomType.Kind.EVENT) < 0.36, "tỉ lệ sự kiện %.3f" % share.call(RoomType.Kind.EVENT))
	for kind in [RoomType.Kind.ELITE, RoomType.Kind.SHOP, RoomType.Kind.CAMPFIRE]:
		assert_true(share.call(kind) > 0.01 and share.call(kind) < 0.2, "tỉ lệ %s %.3f" % [RoomType.name_of(kind), share.call(kind)])
	assert_false(totals.has(RoomType.Kind.TREASURE) or totals.has(RoomType.Kind.BOSS), "không có kho báu/boss ở tầng tự do")


func test_custom_weights_change_the_mix() -> void:
	var cfg := MapConfig.new()
	cfg.weights = {RoomType.Kind.MONSTER: 1.0, RoomType.Kind.EVENT: 100.0}
	var events := 0
	var monsters := 0
	for run_seed in 100:
		var counts := _kind_counts(MapGenerator.generate(run_seed, 1, cfg), [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13])
		events += counts.get(RoomType.Kind.EVENT, 0)
		monsters += counts.get(RoomType.Kind.MONSTER, 0)
		for forbidden in [RoomType.Kind.ELITE, RoomType.Kind.SHOP]:
			assert_false(counts.has(forbidden), "trọng số 0 thì không xuất hiện")
	assert_true(events > monsters * 10, "sự kiện áp đảo: %d vs %d" % [events, monsters])


func test_only_monster_weight_still_works_because_it_is_the_fallback() -> void:
	var cfg := MapConfig.new()
	cfg.weights = {RoomType.Kind.MONSTER: 1.0}
	var map := MapGenerator.generate(3, 1, cfg)
	assert_eq(map.validate(), [] as Array[String])
	for node in map.nodes_on_floor(5):
		assert_eq(node.kind, RoomType.Kind.MONSTER)
