class_name MapGenerator
extends RefCounted
## Sinh bản đồ một act theo seed (kiểu Slay the Spire): trước hết trải `paths` đường đi từ tầng đầu lên tầng cuối (mỗi bước
## sang cột kề, không cắt nhau, các đường có thể gộp), nối mọi nút tầng cuối vào boss, rồi gán loại phòng theo luật.
## Tất định: cùng (run_seed, act, config) cho cùng bản đồ. Seed con lấy từ RunRng để không phụ thuộc luồng RNG khác.

## Sinh bản đồ. config null -> mặc định. Null (kèm log) nếu cấu hình không hợp lệ.
static func generate(run_seed: int, act: int = 1, config: MapConfig = null) -> RunMap:
	var cfg := config if config != null else MapConfig.new()
	var problems := cfg.validate()
	if not problems.is_empty():
		push_error("MapGenerator.generate: cấu hình không hợp lệ: %s" % [problems])
		return null
	var rng := RunRng.make(run_seed, &"map", act)
	var map := RunMap.new(cfg.columns, cfg.floors)
	_build_paths(map, cfg, rng)
	_connect_boss(map, cfg)
	_assign_kinds(map, cfg, rng)
	return map


## --- Trải đường đi ---

static func _build_paths(map: RunMap, cfg: MapConfig, rng: RandomNumberGenerator) -> void:
	var start_columns: Array[int] = []
	for path_index in cfg.paths:
		var column := rng.randi_range(0, cfg.columns - 1)
		# Hai đường đầu bắt buộc xuất phát từ hai cột khác nhau (min_start_columns tối thiểu 2 nếu cấu hình yêu cầu).
		if path_index < cfg.min_start_columns:
			while start_columns.has(column):
				column = rng.randi_range(0, cfg.columns - 1)
		start_columns.append(column)
		var node := map.add_node(0, column)
		for floor_index in cfg.floors - 1:
			var next_column := _pick_next_column(map, floor_index, node.column, rng)
			var next := map.add_node(floor_index + 1, next_column)
			map.connect_nodes(node.id, next.id)
			node = next


## Chọn cột ở tầng kế tiếp: trái, thẳng hoặc phải, trong lưới và không cắt cạnh sẵn có. Đi thẳng luôn hợp lệ
## (cạnh sẵn có từ cột nhỏ hơn không thể sang cột lớn hơn cột này và ngược lại) nên danh sách không bao giờ rỗng.
static func _pick_next_column(map: RunMap, floor_index: int, column: int, rng: RandomNumberGenerator) -> int:
	var options: Array[int] = []
	for target in [column - 1, column, column + 1]:
		if target >= 0 and target < map.columns and not map.edge_would_cross(floor_index, column, target):
			options.append(target)
	return options[rng.randi_range(0, options.size() - 1)]


static func _connect_boss(map: RunMap, _cfg: MapConfig) -> void:
	var boss := map.add_node(map.floors, map.boss_column(), RoomType.Kind.BOSS)
	for node in map.nodes_on_floor(map.floors - 1):
		map.connect_nodes(node.id, boss.id)


## --- Gán loại phòng ---

static func _assign_kinds(map: RunMap, cfg: MapConfig, rng: RandomNumberGenerator) -> void:
	var assigned := {}  ## id -> true: nút đã có loại (để biết nút anh em nào đã xét)
	for floor_index in range(0, cfg.floors + 1):
		for node in map.nodes_on_floor(floor_index):
			var forced := cfg.forced_kind(floor_index)
			node.kind = forced if forced != MapConfig.NOT_FORCED else _pick_kind(map, cfg, node, assigned, rng)
			assigned[node.id] = true


static func _pick_kind(map: RunMap, cfg: MapConfig, node: MapNode, assigned: Dictionary, rng: RandomNumberGenerator) -> RoomType.Kind:
	var banned := _banned_kinds(map, cfg, node, assigned)
	var total := 0.0
	var candidates: Array = []
	for kind in MapConfig.FREE_KINDS:  # thứ tự cố định -> tất định
		var weight := float(cfg.weights.get(kind, 0.0))
		if weight > 0.0 and not banned.has(kind):
			candidates.append([kind, weight])
			total += weight
	var roll := rng.randf() * total
	for candidate in candidates:
		roll -= candidate[1]
		if roll < 0.0:
			return candidate[0]
	return candidates[candidates.size() - 1][0]  # sai số làm tròn: lấy loại cuối; MONSTER luôn có mặt nên không rỗng


static func _banned_kinds(map: RunMap, cfg: MapConfig, node: MapNode, assigned: Dictionary) -> Dictionary:
	var banned := {}
	if node.floor_index < cfg.elite_min_floor:
		banned[RoomType.Kind.ELITE] = true
	if node.floor_index < cfg.campfire_min_floor or node.floor_index == cfg.floors - 2:
		banned[RoomType.Kind.CAMPFIRE] = true  # tầng ngay trước tầng lửa trại bắt buộc cũng không có lửa trại
	for parent in map.parents_of(node.id):
		if RoomType.RESTRICTED.has(parent.kind):
			banned[parent.kind] = true  # loại hiếm không đứng liền nhau trên một đường
		for sibling_id in parent.edges:
			if sibling_id != node.id and assigned.has(sibling_id):
				var sibling := map.get_node_by_id(sibling_id)
				if RoomType.RESTRICTED.has(sibling.kind):
					banned[sibling.kind] = true  # nút anh em không trùng loại hiếm
	return banned
