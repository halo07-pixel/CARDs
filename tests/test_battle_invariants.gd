extends "res://tests/test_case.gd"
## Kiểm tra CHÍNH bộ kiểm tra bất biến: nó phải im lặng khi ổn và phải kêu khi có sai sót thật.

const Factory := preload("res://tests/combat_factory.gd")


func _fresh() -> Array:
	var controller := Factory.battle(Factory.fillers(10), [Factory.dummy_enemy()] as Array[EnemyData])
	var invariants := BattleInvariants.new(controller)
	controller.start_battle()
	return [controller, invariants]


func _violations_contain(violations: Array[String], fragment: String) -> bool:
	for message in violations:
		if message.contains(fragment):
			return true
	return false


func test_clean_battle_has_no_violations_at_every_stage() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	var invariants: BattleInvariants = parts[1]
	assert_eq(invariants.check(), [] as Array[String])
	controller.end_player_turn()
	assert_eq(invariants.check(), [] as Array[String])
	controller.enemies[0].combatant.take_damage(999)
	controller._check_end()
	assert_eq(invariants.check(), [] as Array[String], "trận đã kết thúc đúng một lần vẫn hợp lệ")
	assert_eq(invariants.ended_count(), 1)


func test_detects_lost_or_extra_cards() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.deck.add_to_discard(Factory.strike(&"stowaway"))
	assert_true(_violations_contain(parts[1].check(), "tổng số thẻ"))


func test_detects_card_stuck_in_limbo() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.deck.begin_play(controller.deck.get_pile(Deck.HAND)[0])
	assert_true(_violations_contain(parts[1].check(), "limbo"))


func test_detects_negative_energy_and_block() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.energy = -1
	controller.player.block = -3
	var violations: Array[String] = parts[1].check()
	assert_true(_violations_contain(violations, "năng lượng âm"))
	assert_true(_violations_contain(violations, "giáp người chơi âm"))


func test_detects_hp_out_of_bounds() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.player.hp = controller.player.max_hp + 1
	controller.enemies[0].combatant.hp = -5
	var violations: Array[String] = parts[1].check()
	assert_true(_violations_contain(violations, "máu người chơi"))
	assert_true(_violations_contain(violations, "máu quái"))


func test_detects_living_enemy_without_intent() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.enemies[0].intent = null
	assert_true(_violations_contain(parts[1].check(), "không có ý định"))


func test_detects_overfull_hand() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	for i in 8:
		controller.deck._hand.append(Factory.strike(StringName("x%d" % i)))
	assert_true(_violations_contain(parts[1].check(), "tay vượt giới hạn"))


func test_detects_battle_ended_count_mismatch() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	controller.state.phase = BattleState.Phase.DEFEAT  # kết thúc nhưng KHÔNG phát battle_ended
	assert_true(_violations_contain(parts[1].check(), "battle_ended"))


func test_detects_potions_appearing_mid_battle_and_belt_overflow() -> void:
	var parts := _fresh()
	var controller: BattleController = parts[0]
	var fire := PotionRegistry.load_from_dir("res://data/potions").get_potion(&"fire_potion")
	assert_eq(parts[1].check(), [] as Array[String])
	controller.potions.add(fire)
	assert_true(_violations_contain(parts[1].check(), "potion tăng"), "potion không được tự xuất hiện giữa trận")
	var overfull := _fresh()
	var belt: PotionBelt = overfull[0].potions
	for i in belt.capacity + 1:
		belt._slots.append(fire)
	assert_true(_violations_contain(overfull[1].check(), "vượt số ô"))
