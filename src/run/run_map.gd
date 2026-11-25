class_name RunMap
extends RefCounted
## Bản đồ một act: lưới `columns` cột x `floors` tầng thường (chỉ số 0..floors-1) cộng một nút boss ở tầng chỉ số `floors`
## (cột giữa). Cạnh chỉ đi lên tầng kế tiếp, lệch tối đa một cột (riêng cạnh vào boss thì từ cột nào cũng được), và không cắt nhau. Dữ liệu thuần: không biết luật phòng.
## validate() kiểm CẤU TRÚC (dùng cả khi nạp từ bản lưu); luật xếp loại phòng thuộc về MapGenerator.

const MAX_COLUMNS := 15
const MAX_FLOORS := 40

var columns: int
var floors: int
var _nodes: Dictionary = {}  ## id -> MapNode


func _init(p_columns: int = 7, p_floors: int = 15) -> void:
	columns = p_columns
	floors = p_floors


static func id_for(floor_index: int, column: int, p_columns: int) -> int:
	return floor_index * p_columns + column


func boss_column() -> int:
	return columns / 2


func boss_id() -> int:
	return id_for(floors, boss_column(), columns)


func node_count() -> int:
	return _nodes.size()


func has_node(id: int) -> bool:
	return _nodes.has(id)


## Null nếu không có nút đó.
func get_node_by_id(id: int) -> MapNode:
	return _nodes.get(id, null)


## Lấy nút tại (tầng, cột), tạo mới nếu chưa có. Null (kèm log) nếu vị trí ngoài lưới.
func add_node(floor_index: int, column: int, kind: RoomType.Kind = RoomType.Kind.MONSTER) -> MapNode:
	if floor_index < 0 or floor_index > floors or column < 0 or column >= columns:
		push_error("RunMap.add_node: vị trí (%d, %d) ngoài lưới" % [floor_index, column])
		return null
	var id := id_for(floor_index, column, columns)
	if not _nodes.has(id):
		_nodes[id] = MapNode.create(id, floor_index, column, kind)
	return _nodes[id]


## Nối from_id -> to_id (đi lên một tầng, lệch tối đa một cột; vào boss thì không giới hạn cột). Trả false (kèm log) nếu không hợp lệ.
func connect_nodes(from_id: int, to_id: int) -> bool:
	var from := get_node_by_id(from_id)
	var to := get_node_by_id(to_id)
	if from == null or to == null or to.floor_index != from.floor_index + 1 or (to.floor_index != floors and absi(to.column - from.column) > 1):
		push_error("RunMap.connect_nodes: cạnh %d -> %d không hợp lệ" % [from_id, to_id])
		return false
	from.add_edge(to_id)
	return true


## Mọi nút ở tầng `floor_index`, theo cột tăng dần.
func nodes_on_floor(floor_index: int) -> Array[MapNode]:
	var found: Array[MapNode] = []
	for column in columns:
		var node: MapNode = _nodes.get(id_for(floor_index, column, columns), null)
		if node != null:
			found.append(node)
	return found


func start_nodes() -> Array[MapNode]:
	return nodes_on_floor(0)


## Các nút người chơi có thể đi tới từ `id`, theo cột tăng dần. Rỗng nếu không có nút đó hoặc là boss.
func next_nodes(id: int) -> Array[MapNode]:
	var found: Array[MapNode] = []
	var node := get_node_by_id(id)
	if node == null:
		return found
	for target_id in node.edges:
		found.append(_nodes[target_id])
	found.sort_custom(func(a: MapNode, b: MapNode) -> bool: return a.column < b.column)
	return found


## Các nút ở tầng dưới có cạnh tới `id`.
func parents_of(id: int) -> Array[MapNode]:
	var found: Array[MapNode] = []
	var node := get_node_by_id(id)
	if node == null:
		return found
	for parent in nodes_on_floor(node.floor_index - 1):
		if parent.edges.has(id):
			found.append(parent)
	return found


## Danh sách lỗi CẤU TRÚC (rỗng = hợp lệ): kích thước, nút (id khớp vị trí, loại hợp lệ, boss duy nhất ở tầng cuối),
## cạnh (đúng tầng, lệch tối đa một cột trừ cạnh vào boss, không trùng, không cắt nhau) và khả năng đi từ tầng đầu tới boss.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if columns < 2 or columns > MAX_COLUMNS or floors < 2 or floors > MAX_FLOORS:
		problems.append("kích thước không hợp lệ: %d cột x %d tầng" % [columns, floors])
		return problems
	var boss_count := 0
	for id in _nodes:
		var node: MapNode = _nodes[id]
		if node.id != id or node.floor_index < 0 or node.floor_index > floors or node.column < 0 or node.column >= columns \
				or id_for(node.floor_index, node.column, columns) != id:
			problems.append("nút %s có id/vị trí không khớp" % [id])
			continue
		if not RoomType.is_valid(int(node.kind)):
			problems.append("nút %d có loại phòng không hợp lệ" % id)
		if node.kind == RoomType.Kind.BOSS:
			boss_count += 1
			if node.floor_index != floors:
				problems.append("boss nằm ngoài tầng cuối (nút %d)" % id)
		elif node.floor_index == floors:
			problems.append("nút %d ở tầng boss nhưng không phải boss" % id)
	if boss_count != 1:
		problems.append("phải có đúng một boss, đang có %d" % boss_count)
	if not _nodes.has(boss_id()):
		problems.append("thiếu nút boss ở cột giữa tầng cuối")
	if nodes_on_floor(0).is_empty():
		problems.append("không có nút xuất phát")
	problems.append_array(_edge_problems())
	return problems


func _edge_problems() -> Array[String]:
	var problems: Array[String] = []
	for id in _nodes:
		var node: MapNode = _nodes[id]
		var seen := {}
		for target_id in node.edges:
			if seen.has(target_id):
				problems.append("nút %d có cạnh trùng tới %d" % [id, target_id])
			seen[target_id] = true
			var target: MapNode = _nodes.get(target_id, null)
			if target == null:
				problems.append("nút %d có cạnh tới nút không tồn tại %d" % [id, target_id])
			elif target.floor_index != node.floor_index + 1 or (target.floor_index != floors and absi(target.column - node.column) > 1):
				problems.append("cạnh %d -> %d sai tầng hoặc lệch quá một cột" % [id, target_id])
		if node.floor_index == floors and not node.edges.is_empty():
			problems.append("boss %d không được có cạnh đi lên" % id)
		if node.floor_index < floors and node.edges.is_empty():
			problems.append("nút %d (tầng %d) không có đường đi tiếp" % [id, node.floor_index])
		if node.floor_index > 0 and parents_of(id).is_empty():
			problems.append("nút %d (tầng %d) không có đường dẫn tới" % [id, node.floor_index])
	for floor_index in floors:
		problems.append_array(_crossing_problems(floor_index))
	return problems


func _crossing_problems(floor_index: int) -> Array[String]:
	var problems: Array[String] = []
	var edges: Array = []  ## [cột nguồn, cột đích]
	for node in nodes_on_floor(floor_index):
		for target_id in node.edges:
			if _nodes.has(target_id):
				edges.append([node.column, (_nodes[target_id] as MapNode).column])
	for i in edges.size():
		for j in range(i + 1, edges.size()):
			var a: Array = edges[i]
			var b: Array = edges[j]
			if (a[0] < b[0] and a[1] > b[1]) or (a[0] > b[0] and a[1] < b[1]):
				problems.append("hai cạnh cắt nhau ở tầng %d: %s và %s" % [floor_index, a, b])
	return problems


## Có cạnh nào từ tầng `floor_index` mà đi từ cột `from_column` tới `to_column` sẽ cắt cạnh sẵn có không.
func edge_would_cross(floor_index: int, from_column: int, to_column: int) -> bool:
	for node in nodes_on_floor(floor_index):
		for target_id in node.edges:
			var existing_to := (_nodes[target_id] as MapNode).column
			if (node.column < from_column and existing_to > to_column) or (node.column > from_column and existing_to < to_column):
				return true
	return false


func to_dict() -> Dictionary:
	var ids: Array = _nodes.keys()
	ids.sort()
	var nodes: Array = []
	for id in ids:
		nodes.append((_nodes[id] as MapNode).to_dict())
	return {"columns": columns, "floors": floors, "nodes": nodes}


## Dựng lại từ to_dict() (kể cả sau vòng JSON, khi số nguyên thành số thực). Null (kèm log) nếu dữ liệu hỏng hoặc sai cấu trúc.
static func from_dict(data: Variant) -> RunMap:
	if typeof(data) != TYPE_DICTIONARY:
		push_error("RunMap.from_dict: dữ liệu không phải Dictionary")
		return null
	var dict: Dictionary = data
	var p_columns: Variant = _whole_number(dict.get("columns", null))
	var p_floors: Variant = _whole_number(dict.get("floors", null))
	if p_columns == null or p_floors == null or typeof(dict.get("nodes", null)) != TYPE_ARRAY:
		push_error("RunMap.from_dict: thiếu hoặc sai kiểu columns/floors/nodes")
		return null
	var map := RunMap.new(p_columns, p_floors)
	for raw in dict["nodes"]:
		var node := _node_from_dict(raw)
		if node == null:
			push_error("RunMap.from_dict: nút hỏng: %s" % [raw])
			return null
		if map._nodes.has(node.id):
			push_error("RunMap.from_dict: trùng id nút %d" % node.id)
			return null
		map._nodes[node.id] = node
	var problems := map.validate()
	if not problems.is_empty():
		push_error("RunMap.from_dict: bản đồ không hợp lệ: %s" % [problems])
		return null
	return map


static func _node_from_dict(raw: Variant) -> MapNode:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = raw
	var id: Variant = _whole_number(dict.get("id", null))
	var floor_index: Variant = _whole_number(dict.get("floor", null))
	var column: Variant = _whole_number(dict.get("column", null))
	var kind: Variant = _whole_number(dict.get("kind", null))
	if id == null or floor_index == null or column == null or kind == null or not RoomType.is_valid(kind) \
			or typeof(dict.get("edges", null)) != TYPE_ARRAY:
		return null
	var node := MapNode.create(id, floor_index, column, kind)
	for raw_edge in dict["edges"]:
		var edge: Variant = _whole_number(raw_edge)
		if edge == null:
			return null
		node.edges.append(edge)
	node.edges.sort()
	return node


## int hoặc float nguyên (JSON trả số thực) -> int; còn lại null.
static func _whole_number(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, roundf(value)):
		return int(value)
	return null
