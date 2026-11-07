extends "res://tests/test_case.gd"
## TooltipPlacement: tooltip luôn nằm trong màn hình, ưu tiên bên phải neo.

const SCREEN := Vector2(1920, 1080)
const SIZE := Vector2(300, 200)


func test_prefers_the_right_side_aligned_with_the_anchor_top() -> void:
	var anchor := Rect2(100, 300, 80, 80)
	assert_eq(TooltipPlacement.place(anchor, SIZE, SCREEN), Vector2(180 + TooltipPlacement.GAP, 300))


func test_flips_to_the_left_when_there_is_no_room_on_the_right() -> void:
	var anchor := Rect2(1700, 300, 100, 80)
	var pos := TooltipPlacement.place(anchor, SIZE, SCREEN)
	assert_eq(pos.x, 1700 - TooltipPlacement.GAP - SIZE.x)
	assert_true(pos.x + SIZE.x <= anchor.position.x, "không đè lên neo")


func test_vertical_position_is_clamped_to_the_screen() -> void:
	var low := TooltipPlacement.place(Rect2(100, 1000, 80, 80), SIZE, SCREEN)
	assert_eq(low.y, SCREEN.y - TooltipPlacement.MARGIN - SIZE.y)
	var high := TooltipPlacement.place(Rect2(100, -50, 80, 80), SIZE, SCREEN)
	assert_eq(high.y, TooltipPlacement.MARGIN)


func test_tooltip_bigger_than_the_screen_stays_at_the_margin() -> void:
	var pos := TooltipPlacement.place(Rect2(100, 100, 50, 50), Vector2(3000, 2000), SCREEN)
	assert_eq(pos, Vector2(TooltipPlacement.MARGIN, TooltipPlacement.MARGIN))


func test_result_is_always_inside_the_screen_for_any_anchor() -> void:
	for x in range(0, 1921, 160):
		for y in range(0, 1081, 120):
			var pos := TooltipPlacement.place(Rect2(x, y, 90, 90), SIZE, SCREEN)
			assert_true(pos.x >= TooltipPlacement.MARGIN and pos.y >= TooltipPlacement.MARGIN, "mép trên/trái (%d,%d)" % [x, y])
			assert_true(pos.x + SIZE.x <= SCREEN.x - TooltipPlacement.MARGIN, "mép phải (%d,%d)" % [x, y])
			assert_true(pos.y + SIZE.y <= SCREEN.y - TooltipPlacement.MARGIN, "mép dưới (%d,%d)" % [x, y])
