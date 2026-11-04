class_name EnemyData
extends Resource
## Định nghĩa một loại quái (dữ liệu thuần, không giữ hình: UI tra theo icon_id).
## pattern SEQUENCE: đi theo `sequence` (cho phép lặp chiêu); WEIGHTED: bốc ngẫu nhiên theo weight.

enum PatternKind { SEQUENCE, WEIGHTED }

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 10
@export var moves: Array[EnemyMove] = []
@export var pattern: PatternKind = PatternKind.SEQUENCE
@export var sequence: Array[StringName] = []  ## chỉ dùng với SEQUENCE; rỗng = theo thứ tự `moves`
@export var opening_move_id: StringName = &""  ## chiêu đầu tiên (tùy chọn)
@export var icon_id: StringName = &""
## Status quái mang sẵn khi vào trận: id status -> số stack (> 0). Ví dụ {&"thorns": 3}.
@export var starting_statuses: Dictionary = {}


func find_move(move_id: StringName) -> EnemyMove:
	for move in moves:
		if move != null and move.id == move_id:
			return move
	return null


## Thứ tự chiêu cho pattern SEQUENCE (mặc định: theo thứ tự khai báo trong `moves`).
func get_sequence() -> Array[StringName]:
	if not sequence.is_empty():
		return sequence.duplicate()
	var ids: Array[StringName] = []
	for move in moves:
		if move != null:
			ids.append(move.id)
	return ids


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if max_hp <= 0:
		errors.append("max_hp phải > 0 (hiện %d)" % max_hp)
	if moves.is_empty():
		errors.append("quái phải có ít nhất 1 chiêu")
	var seen: Dictionary = {}
	for i in moves.size():
		var move := moves[i]
		if move == null:
			errors.append("moves[%d] là null" % i)
			continue
		for message: String in move.validate():
			errors.append("moves[%d] (%s): %s" % [i, move.id, message])
		if seen.has(move.id):
			errors.append("trùng id chiêu '%s'" % move.id)
		seen[move.id] = true
	if not opening_move_id.is_empty() and find_move(opening_move_id) == null:
		errors.append("opening_move_id '%s' không tồn tại trong moves" % opening_move_id)
	if pattern == PatternKind.WEIGHTED and not sequence.is_empty():
		errors.append("sequence chỉ dùng với pattern SEQUENCE")
	for move_id in sequence:
		if find_move(move_id) == null:
			errors.append("sequence chứa chiêu không tồn tại: '%s'" % move_id)
	errors.append_array(_validate_starting_statuses())
	return errors


func _validate_starting_statuses() -> Array[String]:
	var errors: Array[String] = []
	for key: Variant in starting_statuses:
		var amount: Variant = starting_statuses[key]
		if not (key is StringName or key is String) or String(key).is_empty():
			errors.append("starting_statuses: id status không hợp lệ (%s)" % [key])
		elif not amount is int or amount <= 0:
			errors.append("starting_statuses[%s]: số stack phải là số nguyên > 0 (hiện %s)" % [key, amount])
	return errors
