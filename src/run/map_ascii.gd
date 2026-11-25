class_name MapAscii
extends RefCounted
## Bản in ASCII của bản đồ để gỡ lỗi và để người xem bằng mắt (boss ở trên cùng, tầng đầu ở dưới cùng).

const CELL_WIDTH := 4


static func render(map: RunMap) -> String:
	var lines: PackedStringArray = []
	for floor_index in range(map.floors, -1, -1):
		lines.append(_node_line(map, floor_index))
		if floor_index > 0:
			lines.append(_edge_line(map, floor_index - 1))
	return "\n".join(lines)


static func _node_line(map: RunMap, floor_index: int) -> String:
	var cells: Array[String] = []
	for column in map.columns:
		var node := map.get_node_by_id(RunMap.id_for(floor_index, column, map.columns))
		cells.append((RoomType.symbol_of(node.kind) if node != null else ".").lpad(CELL_WIDTH / 2 + 1).rpad(CELL_WIDTH))
	return "%2d %s" % [floor_index + 1, "".join(cells).rstrip(" ")]


## Dòng nối giữa tầng `floor_index` và tầng kế tiếp: '/' sang trái, '|' thẳng, '\' sang phải (đặt ở cột nguồn).
static func _edge_line(map: RunMap, floor_index: int) -> String:
	var cells: Array[String] = []
	for column in map.columns:
		var node := map.get_node_by_id(RunMap.id_for(floor_index, column, map.columns))
		var marks := ""
		if node != null:
			for target in map.next_nodes(node.id):
				marks += "/" if target.column < column else ("\\" if target.column > column else "|")
		cells.append(marks.lpad(CELL_WIDTH / 2 + 1).rpad(CELL_WIDTH) if marks.length() <= 2 else marks.substr(0, CELL_WIDTH))
	return "   %s" % "".join(cells).rstrip(" ")
