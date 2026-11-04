extends "res://tests/test_case.gd"
## Mọi icon mà dữ liệu/UI nhắc tới đều phải có file thật (tránh icon chết khi thêm status/quái mới).

const Factory := preload("res://tests/combat_factory.gd")


func test_every_status_icon_exists() -> void:
	var statuses := StatusRegistry.load_from_dir("res://data/statuses")
	for id in statuses.all_ids():
		var icon_id := statuses.get_status(id).icon_id
		assert_true(IconLibrary.get_icon(icon_id) != null, "status %s thiếu icon '%s'" % [id, icon_id])


func test_fixed_ui_icons_exist() -> void:
	for icon_id: StringName in [IconLibrary.HEART, IconLibrary.BLOCK, IntentView.ICON_ATTACK, IntentView.ICON_DEFEND,
			IntentView.ICON_BUFF, IntentView.ICON_DEBUFF, IntentView.ICON_UNKNOWN]:
		assert_true(IconLibrary.get_icon(icon_id) != null, "thiếu icon '%s'" % icon_id)


func test_every_real_enemy_move_gets_icons_that_exist() -> void:
	var enemies := EnemyRegistry.load_from_dir("res://data/enemies")
	for id in enemies.all_ids():
		for move in enemies.get_enemy(id).moves:
			var view := IntentView.build(IntentInfo.build(move, Factory.combatant(&"e", 30), Factory.combatant(&"p", 50)))
			assert_false(view.icon_ids.is_empty(), "quái %s chiêu %s không có icon" % [id, move.id])
			for icon_id in view.icon_ids:
				assert_true(IconLibrary.get_icon(icon_id) != null, "thiếu icon '%s'" % icon_id)


func test_unknown_or_empty_icon_id_gives_null() -> void:
	assert_true(IconLibrary.get_icon(&"khong_co_icon_nay") == null)
	assert_true(IconLibrary.get_icon(&"") == null)
