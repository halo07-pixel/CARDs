class_name BattleInvariants
extends RefCounted
## Kiểm tra các điều kiện BẤT BIẾN của một trận đấu sau mỗi bước (dùng cho bot, simulator, test).
## Tạo TRƯỚC khi start_battle để ghi nhớ tổng số thẻ ban đầu.

var _controller: BattleController
var _expected_total: int = 0
var _ended_count: int = 0
var _last_potion_count: int = 0


func _init(controller: BattleController) -> void:
	_controller = controller
	_expected_total = controller.deck.total_count()
	_last_potion_count = controller.potions.count()
	controller.battle_ended.connect(_on_battle_ended)


func ended_count() -> int:
	return _ended_count


## Danh sách vi phạm hiện tại (rỗng = mọi thứ hợp lệ).
func check() -> Array[String]:
	var violations: Array[String] = []
	var c := _controller
	if c.deck.total_count() != _expected_total:
		violations.append("tổng số thẻ %d != %d" % [c.deck.total_count(), _expected_total])
	if c.deck.count(Deck.LIMBO) != 0:
		violations.append("limbo không rỗng khi nghỉ")
	if c.deck.count(Deck.HAND) > Deck.MAX_HAND_SIZE:
		violations.append("tay vượt giới hạn %d" % c.deck.count(Deck.HAND))
	if c.energy < 0:
		violations.append("năng lượng âm")
	if c.player.hp < 0 or c.player.hp > c.player.max_hp:
		violations.append("máu người chơi ngoài giới hạn: %d" % c.player.hp)
	if c.player.block < 0:
		violations.append("giáp người chơi âm")
	for unit in c.enemies:
		var hp := unit.combatant.hp
		if hp < 0 or hp > unit.combatant.max_hp:
			violations.append("máu quái %s ngoài giới hạn: %d" % [unit.combatant.id, hp])
		if unit.combatant.block < 0:
			violations.append("giáp quái %s âm" % unit.combatant.id)
		if unit.is_alive() and (unit.intent == null or unit.current_move == null):
			violations.append("quái sống %s không có ý định" % unit.combatant.id)
	if c.trigger_queue_size() != 0:
		violations.append("hàng đợi trigger còn %d hành động khi nghỉ" % c.trigger_queue_size())
	if c.trigger_overflowed():
		violations.append("hàng đợi trigger đã vượt giới hạn (vòng lặp?)")
	var potion_count := c.potions.count()
	if potion_count > c.potions.capacity:
		violations.append("số potion %d vượt số ô %d" % [potion_count, c.potions.capacity])
	if potion_count > _last_potion_count:
		violations.append("số potion tăng giữa trận (%d -> %d)" % [_last_potion_count, potion_count])
	_last_potion_count = potion_count
	var expected_ended := 1 if c.state.is_terminal() else 0
	if _ended_count != expected_ended:
		violations.append("battle_ended phát %d lần (cần %d)" % [_ended_count, expected_ended])
	return violations


func _on_battle_ended(_victory: bool) -> void:
	_ended_count += 1
