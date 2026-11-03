class_name BattleController
extends ResolverContext
## Điều phối một trận đấu: lượt người chơi, lượt quái, thắng/thua. Đây là NƠI DUY NHẤT UI gọi xuống
## (play_card, end_player_turn); mọi thay đổi được báo lên bằng Signal ("call down, signal up").
## Mọi hành động đều kiểm tra state trước; bị từ chối thì KHÔNG thay đổi gì và phát action_rejected.
## Đồng thời đóng vai ResolverContext cho EffectResolver (rút bài, năng lượng, tra status, RNG).

signal energy_changed(old_energy: int, new_energy: int)
signal turn_started(turn_number: int, is_player: bool)
signal intent_changed(unit: EnemyUnit)
signal card_played(card: CardInstance, target: EnemyUnit, results: Array[EffectResult])
signal enemy_acted(unit: EnemyUnit, move: EnemyMove, results: Array[EffectResult])
signal enemy_defeated(unit: EnemyUnit)
signal action_rejected(reason: StringName)
signal battle_ended(victory: bool)
signal triggered(owner: Combatant, source_key: StringName, results: Array[EffectResult])
signal potion_used(slot: int, potion: PotionData, target: EnemyUnit, results: Array[EffectResult])

const REASON_ALREADY_STARTED := &"already_started"
const REASON_BATTLE_OVER := &"battle_over"
const REASON_NOT_PLAYER_TURN := &"not_player_turn"
const REASON_CARD_NOT_IN_HAND := &"card_not_in_hand"
const REASON_UNPLAYABLE := &"unplayable"
const REASON_NOT_ENOUGH_ENERGY := &"not_enough_energy"
const REASON_INVALID_TARGET := &"invalid_target"
const REASON_NO_POTION := &"no_potion"
const END_VICTORY := &"victory"
const END_DEFEAT := &"defeat"
const END_TURN_CAP := &"turn_cap"

var player: Combatant = null
var deck: Deck = null
var enemies: Array[EnemyUnit] = []
var relics: Array[RelicData] = []
var potions: PotionBelt = null
var state := BattleState.new()
var config: BattleConfig = null
var energy: int = 0
var turn: int = 0
var end_reason: StringName = &""

var _status_registry: StatusRegistry = null
var _rng: RandomNumberGenerator = null
var _reported_dead: Dictionary = {}
var _triggers := TriggerRunner.new()


## Tạo trận từ các EnemyUnit dựng sẵn. Trả null nếu tham số không hợp lệ.
## Cùng seed + cùng chuỗi hành động => cùng kết quả (RNG xáo bài và RNG trận đấu tách riêng).
static func create(p_player: Combatant, cards: Array[CardInstance], units: Array[EnemyUnit],
		registry: StatusRegistry, seed_value: int = 1, p_config: BattleConfig = null,
		battle_rng: RandomNumberGenerator = null, p_relics: Array[RelicData] = [],
		p_potions: PotionBelt = null) -> BattleController:
	var cfg := p_config if p_config != null else BattleConfig.new()
	var problems := _setup_problems(p_player, cards, units, registry, cfg, p_relics)
	if not problems.is_empty():
		push_error("BattleController.create: %s" % [problems])
		return null
	var controller := BattleController.new()
	controller.player = p_player
	controller.config = cfg
	controller.enemies = units.duplicate()
	controller.relics = p_relics.duplicate()
	controller.potions = p_potions if p_potions != null else PotionBelt.new()
	controller._status_registry = registry
	controller._rng = battle_rng if battle_rng != null else _derived_rng(seed_value)
	var deck_rng := RandomNumberGenerator.new()
	deck_rng.seed = seed_value
	controller.deck = Deck.new(cards, deck_rng)
	for unit in controller.enemies:
		unit.combatant.died.connect(controller._on_enemy_died)  # không bind: tránh vòng tham chiếu
	return controller


## Tiện ích: dựng EnemyUnit từ EnemyData (id dạng "slime_0", "slime_1"...) dùng chung RNG của trận.
static func create_from_data(p_player: Combatant, cards: Array[CardInstance], datas: Array[EnemyData],
		registry: StatusRegistry, seed_value: int = 1, p_config: BattleConfig = null,
		p_relics: Array[RelicData] = [], p_potions: PotionBelt = null) -> BattleController:
	var rng := _derived_rng(seed_value)
	var units: Array[EnemyUnit] = []
	for i in datas.size():
		if datas[i] == null:
			push_error("BattleController.create_from_data: EnemyData null")
			return null
		var unit := EnemyUnit.create(datas[i], rng, StringName("%s_%d" % [datas[i].id, i]))
		if unit == null:
			return null
		units.append(unit)
	return create(p_player, cards, units, registry, seed_value, p_config, rng, p_relics, p_potions)


func start_battle() -> bool:
	if state.phase != BattleState.Phase.SETUP:
		return _reject(REASON_ALREADY_STARTED)
	deck.start_battle()
	for unit in enemies:
		unit.plan_next_move(player)
		intent_changed.emit(unit)
	_fire_and_drain(BattleEvent.create(TriggerData.Event.BATTLE_START))
	_refresh_intents()
	_begin_player_turn()
	return true


## target chỉ cần với thẻ nhắm một quái (SINGLE_ENEMY); thẻ khác bỏ qua tham số này.
func play_card(card: CardInstance, target: EnemyUnit = null) -> bool:
	var reason := _play_blocker(card)
	if reason == &"" and not _target_is_valid(card.data.target_mode, target):
		reason = REASON_INVALID_TARGET
	if reason != &"":
		return _reject(reason)
	var repeat := energy + card.data.x_bonus if card.data.is_x_cost else 1
	_set_energy(0 if card.data.is_x_cost else energy - card.get_cost())
	deck.begin_play(card)
	var results := _resolve_effects(card.data.effects, target, repeat, true)
	deck.finish_play(card)
	_triggers.fire(BattleEvent.create(TriggerData.Event.CARD_PLAYED, player, null, 0, card), self)
	card_played.emit(card, target, results)
	_triggers.drain(self)
	_refresh_intents()
	_check_end()
	return true


func end_player_turn() -> bool:
	if state.is_terminal():
		return _reject(REASON_BATTLE_OVER)
	if not state.is_player_turn():
		return _reject(REASON_NOT_PLAYER_TURN)
	_fire_and_drain(BattleEvent.create(TriggerData.Event.TURN_END, player))
	if _check_end():
		return true
	deck.end_turn_discard()
	player.end_turn()
	state.transition(BattleState.Phase.ENEMY_TURN)
	_run_enemy_turn()
	return true


## Dùng potion ở ô `slot` (không tốn năng lượng). target chỉ cần với potion nhắm một quái.
func use_potion(slot: int, target: EnemyUnit = null) -> bool:
	if state.is_terminal():
		return _reject(REASON_BATTLE_OVER)
	if not state.is_player_turn():
		return _reject(REASON_NOT_PLAYER_TURN)
	var potion := potions.get_at(slot)
	if potion == null:
		return _reject(REASON_NO_POTION)
	if not _target_is_valid(potion.target_mode, target):
		return _reject(REASON_INVALID_TARGET)
	potions.remove_at(slot)
	var results := _resolve_effects(potion.effects, target, 1, false)
	potion_used.emit(slot, potion, target, results)
	_triggers.drain(self)
	_refresh_intents()
	_check_end()
	return true


func can_play(card: CardInstance) -> bool:
	return _play_blocker(card) == &""


## Quái sống có thể chọn làm mục tiêu cho thẻ (rỗng nếu thẻ không nhắm một quái).
func valid_targets(card: CardInstance) -> Array[EnemyUnit]:
	var targets: Array[EnemyUnit] = []
	if card != null and card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY:
		targets.assign(living_enemies())
	return targets


## Số hành động trigger đang chờ (phải bằng 0 khi trận nghỉ) và cờ đã từng vượt giới hạn.
func trigger_queue_size() -> int:
	return _triggers.queue_size()


func trigger_overflowed() -> bool:
	return _triggers.overflowed


func living_enemies() -> Array[EnemyUnit]:
	var living: Array[EnemyUnit] = []
	for unit in enemies:
		if unit.is_alive():
			living.append(unit)
	return living


## --- ResolverContext ---

func draw_cards(count: int) -> int:
	return deck.draw(count).size()


func gain_energy(amount: int) -> void:
	_set_energy(energy + amount)


func get_status_data(status_id: StringName) -> StatusData:
	return _status_registry.get_status(status_id)


func get_rng() -> RandomNumberGenerator:
	return _rng


## --- Nội bộ ---

static func _derived_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5DEECE66D
	return rng


static func _setup_problems(p_player: Combatant, cards: Array[CardInstance], units: Array[EnemyUnit],
		registry: StatusRegistry, cfg: BattleConfig, p_relics: Array[RelicData]) -> Array[String]:
	var problems: Array[String] = []
	if p_player == null or not p_player.is_alive():
		problems.append("người chơi null hoặc đã chết")
	if cards.is_empty():
		problems.append("bộ bài rỗng")
	if units.is_empty():
		problems.append("không có quái")
	for unit in units:
		if unit == null:
			problems.append("có EnemyUnit null")
			break
	if registry == null:
		problems.append("thiếu StatusRegistry")
	for relic in p_relics:
		if relic == null:
			problems.append("có RelicData null")
			break
	problems.append_array(cfg.validate())
	return problems


func _begin_player_turn() -> void:
	turn += 1
	_triggers.new_turn()
	state.transition(BattleState.Phase.PLAYER_START)
	if turn > 1:
		player.start_turn()  # lượt 1 giữ nguyên giáp sinh ra từ sự kiện BATTLE_START (kiểu relic Anchor)
	_set_energy(config.max_energy)
	turn_started.emit(turn, true)
	_fire_and_drain(BattleEvent.create(TriggerData.Event.TURN_START, player))
	player.decay_after_turn_start()
	if _check_end():
		return
	deck.draw(config.draw_per_turn)
	_refresh_intents()
	state.transition(BattleState.Phase.PLAYER_TURN)


## Lý do không chơi được thẻ (&"" nếu chơi được), chưa xét mục tiêu.
func _play_blocker(card: CardInstance) -> StringName:
	if state.is_terminal():
		return REASON_BATTLE_OVER
	if not state.is_player_turn():
		return REASON_NOT_PLAYER_TURN
	if card == null or deck.find_pile(card) != Deck.HAND:
		return REASON_CARD_NOT_IN_HAND
	if card.data.unplayable:
		return REASON_UNPLAYABLE
	if not card.is_playable(energy):
		return REASON_NOT_ENOUGH_ENERGY
	return &""


func _target_is_valid(mode: CardData.TargetMode, target: EnemyUnit) -> bool:
	if mode != CardData.TargetMode.SINGLE_ENEMY:
		return true
	return target != null and target.is_alive() and enemies.has(target)


## Thực thi danh sách effect của thẻ hoặc potion. Effect scales_with_x lặp `repeat` lần.
## counts_as_attack = false (potion): sát thương không sinh sự kiện ATTACKED (không kích hoạt Thorns).
func _resolve_effects(effects: Array[EffectData], target: EnemyUnit, repeat: int,
		counts_as_attack: bool) -> Array[EffectResult]:
	var results: Array[EffectResult] = []
	var opponents := _enemy_combatants()
	var chosen: Combatant = target.combatant if target != null else null
	for effect in effects:
		for i in (repeat if effect.scales_with_x else 1):
			if not player.is_alive():
				return results  # tự làm mình chết giữa chừng (vd. Bloodletting ở 3 máu): effect sau bị bỏ
			if effect.target == EffectData.Target.TARGET_ENEMY and (chosen == null or not chosen.is_alive()):
				break  # mục tiêu đã chết giữa chừng (vd. lần lặp trước đã hạ nó)
			var effect_results := EffectResolver.resolve(effect, player, chosen, opponents, self)
			_triggers.events_from_results(effect_results, not counts_as_attack, self)
			results.append_array(effect_results)
	return results


func _run_enemy_turn() -> void:
	turn_started.emit(turn, false)
	var opponents: Array[Combatant] = [player]
	for unit in enemies:
		if state.is_terminal():
			return
		if unit.is_alive() and not _run_enemy_unit_turn(unit, opponents):
			return
	state.transition(BattleState.Phase.CHECK_END)
	if _check_end():
		return
	if config.turn_cap > 0 and turn >= config.turn_cap:
		_finish(false, END_TURN_CAP)
		return
	_refresh_intents()
	_begin_player_turn()


## Lượt của MỘT quái. Trả false nếu trận đã kết thúc giữa chừng (các quái sau không được đi nữa).
func _run_enemy_unit_turn(unit: EnemyUnit, opponents: Array[Combatant]) -> bool:
	var combatant := unit.combatant
	combatant.start_turn()
	_fire_and_drain(BattleEvent.create(TriggerData.Event.TURN_START, combatant))
	combatant.decay_after_turn_start()
	if _check_end():
		return false
	if not unit.is_alive():
		return true  # chết vì Poison đầu lượt: bỏ lượt, các quái khác vẫn đi
	var results: Array[EffectResult] = []
	for effect in unit.current_move.effects:
		if not player.is_alive():
			break
		var effect_results := EffectResolver.resolve(effect, combatant, player, opponents, self)
		_triggers.events_from_results(effect_results, false, self)
		results.append_array(effect_results)
	enemy_acted.emit(unit, unit.current_move, results)
	_triggers.drain(self)
	if _check_end():
		return false
	if unit.is_alive():
		_fire_and_drain(BattleEvent.create(TriggerData.Event.TURN_END, combatant))
		combatant.end_turn()
		if _check_end():
			return false
	if unit.is_alive():
		unit.plan_next_move(player)
		intent_changed.emit(unit)
	return true


## Người chơi chết được xét TRƯỚC (thua ưu tiên hơn thắng nếu xảy ra cùng lúc).
func _check_end() -> bool:
	if state.is_terminal():
		return true
	if not player.is_alive():
		_finish(false, END_DEFEAT)
		return true
	if living_enemies().is_empty():
		_finish(true, END_VICTORY)
		return true
	return false


func _finish(victory: bool, reason: StringName) -> void:
	end_reason = reason
	if victory:
		_fire_and_drain(BattleEvent.create(TriggerData.Event.BATTLE_VICTORY))  # trước battle_ended
	state.transition(BattleState.Phase.VICTORY if victory else BattleState.Phase.DEFEAT)
	battle_ended.emit(victory)


func _fire_and_drain(event: BattleEvent) -> void:
	_triggers.fire(event, self)
	_triggers.drain(self)


func _enemy_combatants() -> Array[Combatant]:
	var combatants: Array[Combatant] = []
	for unit in enemies:
		combatants.append(unit.combatant)
	return combatants


## Dựng lại ý định (Strength/Weak/Vulnerable đổi làm con số đổi) và chỉ báo khi thật sự khác.
func _refresh_intents() -> void:
	for unit in enemies:
		if not unit.is_alive() or unit.current_move == null:
			continue
		var before := unit.intent
		var after := unit.refresh_intent(player)
		if before == null or after.damage_per_hit != before.damage_per_hit \
				or after.hit_count != before.hit_count or after.total_damage != before.total_damage:
			intent_changed.emit(unit)


func _set_energy(new_energy: int) -> void:
	var old := energy
	energy = maxi(new_energy, 0)
	if energy != old:
		energy_changed.emit(old, energy)


## Combatant.died không bind được unit (vòng tham chiếu) -> quét tìm quái chết chưa báo.
func _on_enemy_died() -> void:
	for unit in enemies:
		if not unit.is_alive() and not _reported_dead.has(unit):
			_reported_dead[unit] = true
			enemy_defeated.emit(unit)


func _reject(reason: StringName) -> bool:
	action_rejected.emit(reason)
	return false
