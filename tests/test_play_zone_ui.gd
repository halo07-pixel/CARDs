extends "res://tests/test_case.gd"


func test_hidden_until_shown_and_never_blocks_the_mouse() -> void:
	var zone := PlayZoneUI.new()
	assert_false(zone.visible)
	assert_eq(zone.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(zone.label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	zone.free()


func test_show_and_hide() -> void:
	var zone := PlayZoneUI.new()
	zone.show_zone()
	assert_true(zone.visible)
	assert_false(zone.active)
	zone.set_active(true)
	assert_true(zone.active)
	zone.hide_zone()
	assert_false(zone.visible)
	assert_false(zone.active, "ẩn đi thì không còn sáng")
	zone.show_zone()
	assert_false(zone.active, "hiện lại thì bắt đầu ở trạng thái thường")
	zone.free()


func test_zone_uses_the_same_rectangle_as_the_drop_decision() -> void:
	var zone := PlayZoneUI.new()
	assert_eq(zone.zone_rect(), DropIntent.play_zone(DropIntent.DESIGN_SCREEN))
	assert_true(zone.zone_rect().encloses(Rect2(zone.label.position, zone.label.size)), "nhãn nằm trọn trong vùng thả")
	assert_true(zone.label.position.y > zone.zone_rect().size.y / 2.0, "và nằm ở nửa dưới (không bị quái che)")
	assert_eq(zone.label.text, PlayZoneUI.LABEL_TEXT)
	zone.free()
