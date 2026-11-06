extends "res://tests/test_case.gd"


func test_hidden_until_shown() -> void:
	var arrow := TargetArrowUI.new()
	assert_false(arrow.visible)
	assert_true(arrow.shape == null)
	arrow.free()


func test_show_arrow_builds_the_geometry_and_colors_by_validity() -> void:
	var arrow := TargetArrowUI.new()
	arrow.show_arrow(Vector2(400, 700), Vector2(900, 200), false)
	assert_true(arrow.visible)
	var expected := ArrowGeometry.build(Vector2(400, 700), Vector2(900, 200))
	assert_eq(arrow.shape.head, expected.head)
	assert_eq(arrow.shape.shaft, expected.shaft)
	assert_eq(arrow.current_color(), TargetArrowUI.NEUTRAL_COLOR)
	arrow.show_arrow(Vector2(400, 700), Vector2(900, 200), true)
	assert_eq(arrow.current_color(), TargetArrowUI.VALID_COLOR)
	arrow.free()


func test_hide_arrow_clears_everything() -> void:
	var arrow := TargetArrowUI.new()
	arrow.show_arrow(Vector2(400, 700), Vector2(900, 200), true)
	arrow.hide_arrow()
	assert_false(arrow.visible)
	assert_true(arrow.shape == null)
	assert_false(arrow.on_valid_target)
	arrow.free()


func test_arrow_never_blocks_the_mouse() -> void:
	var arrow := TargetArrowUI.new()
	assert_eq(arrow.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	arrow.free()
