class_name MapNode
extends RefCounted
## Một nút (phòng) trên bản đồ: vị trí, loại phòng và các nút ở tầng kế tiếp mà người chơi có thể đi tới.

var id: int = 0
var floor_index: int = 0
var column: int = 0
var kind: RoomType.Kind = RoomType.Kind.MONSTER
var edges: Array[int] = []  ## id các nút ở tầng floor + 1, luôn sắp tăng dần


static func create(p_id: int, p_floor_index: int, p_column: int, p_kind: RoomType.Kind = RoomType.Kind.MONSTER) -> MapNode:
	var node := MapNode.new()
	node.id = p_id
	node.floor_index = p_floor_index
	node.column = p_column
	node.kind = p_kind
	return node


## Thêm cạnh lên nút `target_id` (bỏ qua nếu đã có). Trả true nếu thêm mới.
func add_edge(target_id: int) -> bool:
	if edges.has(target_id):
		return false
	edges.append(target_id)
	edges.sort()
	return true


func to_dict() -> Dictionary:
	return {"id": id, "floor": floor_index, "column": column, "kind": int(kind), "edges": edges.duplicate()}
