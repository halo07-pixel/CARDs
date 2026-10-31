class_name PotionBelt
extends RefCounted
## Dây đeo potion: số ô cố định (mặc định 3). Ô có thể trống. Phát `changed` mỗi khi nội dung đổi
## để UI vẽ lại; BattleController đọc/ghi qua đây, RunState lưu danh sách id (to_ids()).

signal changed

const DEFAULT_SLOTS := 3

var capacity: int = DEFAULT_SLOTS
var _slots: Array[PotionData] = []


func _init(p_capacity: int = DEFAULT_SLOTS) -> void:
	capacity = maxi(p_capacity, 1)
	_slots.resize(capacity)


## Dựng từ danh sách id (thứ tự = thứ tự ô). Trả null nếu có id lạ hoặc nhiều hơn số ô.
static func from_ids(ids: Array[StringName], registry: PotionRegistry,
		p_capacity: int = DEFAULT_SLOTS) -> PotionBelt:
	if registry == null or ids.size() > maxi(p_capacity, 1):
		push_error("PotionBelt.from_ids: thiếu registry hoặc quá số ô (%d > %d)" % [ids.size(), p_capacity])
		return null
	var potions := registry.resolve(ids)
	if potions.size() != ids.size():
		return null
	var belt := PotionBelt.new(p_capacity)
	for potion in potions:
		belt.add(potion)
	return belt


func get_at(slot: int) -> PotionData:
	return _slots[slot] if slot >= 0 and slot < capacity else null


func count() -> int:
	var total := 0
	for potion in _slots:
		if potion != null:
			total += 1
	return total


func is_full() -> bool:
	return count() >= capacity


## Chỉ số ô trống đầu tiên, -1 nếu đầy.
func first_free_slot() -> int:
	for i in capacity:
		if _slots[i] == null:
			return i
	return -1


## Trả về ô đã đặt, hoặc -1 nếu potion null hoặc dây đã đầy.
func add(potion: PotionData) -> int:
	var slot := first_free_slot()
	if potion == null or slot == -1:
		return -1
	_slots[slot] = potion
	changed.emit()
	return slot


## Lấy potion ra khỏi ô; null nếu ô trống hoặc ngoài phạm vi.
func remove_at(slot: int) -> PotionData:
	var potion := get_at(slot)
	if potion == null:
		return null
	_slots[slot] = null
	changed.emit()
	return potion


## Bản sao các ô (kể cả ô trống = null) để UI duyệt.
func get_all() -> Array[PotionData]:
	return _slots.duplicate()


## Id các potion đang có, theo thứ tự ô (bỏ ô trống) - dạng RunState lưu.
func to_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for potion in _slots:
		if potion != null:
			ids.append(potion.id)
	return ids
