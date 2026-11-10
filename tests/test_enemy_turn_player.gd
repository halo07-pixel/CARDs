extends "res://tests/test_case.gd"
## EnemyTurnPlayer: nhịp diễn lượt quái. Đẩy nhịp bằng fire_now() để test không phụ thuộc thời gian thật.

const Hud := preload("res://tests/hud_factory.gd")

var _player: EnemyTurnPlayer = null
var _config := EffectsConfig.new()
var _log: Array = []


func before_each() -> void:
	_config.speed = EffectsConfig.NORMAL_SPEED
	_log = []
	_player = EnemyTurnPlayer.new()
	Engine.get_main_loop().root.add_child(_player)
	_player.step_started.connect(func(unit: EnemyUnit) -> void: _log.append("step:%s" % unit.combatant.id))
	_player.finished.connect(func() -> void: _log.append("finished"))


func after_each() -> void:
	if is_instance_valid(_player):
		_player.free()


func _battle(enemy_count: int = 3) -> BattleController:
	var controller := Hud.controller([], [], enemy_count)
	controller.enemy_acted.connect(func(unit: EnemyUnit, _m: EnemyMove, _r: Array[EffectResult]) -> void:
		_log.append("acted:%s" % unit.combatant.id))
	controller.begin_enemy_turn()
	return controller


func _run_to_the_end() -> void:
	for i in 40:
		if not _player.is_playing():
			return
		_player.fire_now()


## --- start ---

func test_start_refuses_when_there_is_nothing_to_play() -> void:
	var idle := Hud.controller([], [], 2)  # đang lượt người chơi: chưa begin_enemy_turn
	assert_false(_player.start(idle, _config))
	assert_false(_player.start(null, _config))
	assert_false(_player.start(_battle(), null))
	assert_false(_player.start(_battle(), EffectsConfig.new()), "hiệu ứng tắt")
	assert_false(_player.is_playing())
	assert_eq(_log, [])


func test_start_refuses_outside_the_tree() -> void:
	var loose := EnemyTurnPlayer.new()
	assert_false(loose.start(_battle(), _config))
	loose.free()


func test_start_announces_the_first_enemy_but_nobody_has_acted_yet() -> void:
	var controller := _battle()
	assert_true(_player.start(controller, _config))
	assert_true(_player.is_playing())
	assert_eq(_player.phase, EnemyTurnPlayer.Phase.WINDUP)
	assert_eq(_log, ["step:dummy_0"])
	assert_true(controller.is_enemy_turn_in_progress())


## --- nhịp ---

func test_each_enemy_is_announced_then_acts_then_the_next_one() -> void:
	var controller := _battle()
	_player.start(controller, _config)
	_run_to_the_end()
	assert_eq(_log, ["step:dummy_0", "acted:dummy_0", "step:dummy_1", "acted:dummy_1", "step:dummy_2", "acted:dummy_2", "finished"])
	assert_false(_player.is_playing())
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)
	assert_eq(controller.turn, 2)


func test_fire_now_alternates_windup_and_gap() -> void:
	var controller := _battle(2)
	_player.start(controller, _config)
	assert_eq(_player.phase, EnemyTurnPlayer.Phase.WINDUP)
	_player.fire_now()
	assert_eq(_player.phase, EnemyTurnPlayer.Phase.GAP)
	assert_eq(_log, ["step:dummy_0", "acted:dummy_0"])
	_player.fire_now()
	assert_eq(_player.phase, EnemyTurnPlayer.Phase.WINDUP)
	assert_eq(_log.back(), "step:dummy_1")


func test_finished_is_emitted_exactly_once() -> void:
	_player.start(_battle(1), _config)
	_run_to_the_end()
	_player.fire_now()  # đã xong: không làm gì
	assert_eq(_log.count("finished"), 1)


func test_dead_enemies_are_never_announced() -> void:
	var controller := Hud.controller([], [], 3)
	controller.enemies[1].combatant.take_damage(999)
	controller.begin_enemy_turn()
	_player.start(controller, _config)
	_run_to_the_end()
	assert_false(_log.has("step:dummy_1"))
	assert_eq(_log.count("step:dummy_0") + _log.count("step:dummy_2"), 2)


func test_the_player_dying_stops_the_remaining_enemies() -> void:
	var controller := Hud.controller([], [], 3)
	controller.player.lose_hp(controller.player.hp - 3)
	controller.enemy_acted.connect(func(unit: EnemyUnit, _m: EnemyMove, _r: Array[EffectResult]) -> void:
		_log.append("acted:%s" % unit.combatant.id))
	controller.begin_enemy_turn()
	_player.start(controller, _config)
	_run_to_the_end()
	assert_eq(_log, ["step:dummy_0", "acted:dummy_0", "finished"])
	assert_eq(controller.state.phase, BattleState.Phase.DEFEAT)


## --- dừng, khởi động lại, giải phóng ---

func test_stop_halts_everything_and_leaves_the_core_untouched() -> void:
	var controller := _battle()
	_player.start(controller, _config)
	_player.fire_now()
	_player.stop()
	assert_false(_player.is_playing())
	assert_true(_player._timer.is_stopped(), "không để lại timer đang chạy")
	_player.fire_now()
	assert_eq(_log, ["step:dummy_0", "acted:dummy_0"], "không có gì chạy tiếp, cũng không có finished")
	assert_true(controller.is_enemy_turn_in_progress(), "lõi giữ nguyên chỗ dừng")


func test_starting_again_replaces_the_old_run() -> void:
	var first := _battle()
	_player.start(first, _config)
	var second := _battle()
	_player.start(second, _config)
	_player.fire_now()
	assert_true(first.is_enemy_turn_in_progress() and first.peek_next_enemy() == first.enemies[0], "trận cũ không bị chạy tiếp")
	assert_false(second.peek_next_enemy() == second.enemies[0], "trận mới đã chạy quái đầu")


func test_stopping_from_inside_step_started_is_safe() -> void:
	var controller := _battle()
	var stopper := EnemyTurnPlayer.new()
	Engine.get_main_loop().root.add_child(stopper)
	stopper.step_started.connect(func(_unit: EnemyUnit) -> void: stopper.stop())
	assert_true(stopper.start(controller, _config))
	assert_false(stopper.is_playing(), "bên nghe đã dừng trong tín hiệu: không hẹn thêm nhịp")
	stopper.free()


func test_changing_speed_to_off_mid_turn_does_not_break_the_timer() -> void:
	var controller := _battle(2)
	_player.start(controller, _config)
	_config.speed = 0.0
	_player.fire_now()
	assert_true(_player.is_playing())
	_run_to_the_end()
	assert_eq(_log.back(), "finished")


func test_timer_waits_follow_the_speed() -> void:
	_config.speed = 2.0
	_player.start(_battle(), _config)
	assert_almost_eq(_player._timer.wait_time, EnemyTurnPlayer.WINDUP_SECONDS / 2.0, 0.0001)
	_player.fire_now()
	assert_almost_eq(_player._timer.wait_time, EnemyTurnPlayer.GAP_SECONDS / 2.0, 0.0001)


func test_freeing_the_node_mid_turn_is_safe() -> void:
	var controller := _battle()
	var other := EnemyTurnPlayer.new()
	Engine.get_main_loop().root.add_child(other)
	_config.speed = 500.0
	other.start(controller, _config)
	other.free()
	for i in 5:
		await Engine.get_main_loop().process_frame
	assert_true(controller.is_enemy_turn_in_progress(), "bị dỡ giữa chừng: lõi dừng đúng chỗ")


func test_runs_to_completion_on_its_own_with_the_real_timer() -> void:
	var controller := _battle()
	_config.speed = 600.0
	_player.start(controller, _config)
	for i in 600:
		if not _player.is_playing():
			break
		await Engine.get_main_loop().process_frame
	assert_eq(_log.back(), "finished")
	assert_eq(_log.count("finished"), 1)
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)
