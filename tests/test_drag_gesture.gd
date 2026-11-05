extends "res://tests/test_case.gd"

const Event := DragGesture.Event

var _gesture: DragGesture


func before_each() -> void:
	_gesture = DragGesture.new()


func test_idle_gesture_ignores_everything() -> void:
	assert_eq(_gesture.move(Vector2(50, 50)), Event.NONE)
	assert_eq(_gesture.release(Vector2(50, 50)), Event.NONE)
	assert_eq(_gesture.cancel(), Event.NONE)
	assert_false(_gesture.is_dragging())


func test_press_and_release_in_place_is_a_click() -> void:
	_gesture.press(Vector2(100, 100))
	assert_eq(_gesture.release(Vector2(100, 100)), Event.CLICK)


func test_small_movement_still_counts_as_a_click() -> void:
	_gesture.press(Vector2(100, 100))
	assert_eq(_gesture.move(Vector2(105, 103)), Event.NONE)
	assert_false(_gesture.is_dragging())
	assert_eq(_gesture.release(Vector2(105, 103)), Event.CLICK)


func test_threshold_is_exclusive_and_measured_as_distance() -> void:
	_gesture.press(Vector2.ZERO)
	assert_eq(_gesture.move(Vector2(DragGesture.DRAG_THRESHOLD, 0)), Event.NONE, "đúng bằng ngưỡng vẫn là click")
	assert_eq(_gesture.move(Vector2(DragGesture.DRAG_THRESHOLD + 0.01, 0)), Event.DRAG_STARTED)
	_gesture.cancel()
	_gesture.press(Vector2.ZERO)
	assert_eq(_gesture.move(Vector2(8, 8)), Event.NONE, "đường chéo 11.3 px < 12")
	assert_eq(_gesture.move(Vector2(9, 9)), Event.DRAG_STARTED, "đường chéo 12.7 px > 12")


func test_dragging_reports_moves_and_ends_with_a_drop() -> void:
	_gesture.press(Vector2.ZERO)
	assert_eq(_gesture.move(Vector2(40, 0)), Event.DRAG_STARTED)
	assert_true(_gesture.is_dragging())
	assert_eq(_gesture.move(Vector2(80, 10)), Event.DRAG_MOVED)
	assert_eq(_gesture.pointer, Vector2(80, 10))
	assert_eq(_gesture.release(Vector2(90, 20)), Event.DROP)
	assert_false(_gesture.is_dragging())


func test_returning_near_the_start_does_not_turn_a_drag_back_into_a_click() -> void:
	_gesture.press(Vector2.ZERO)
	_gesture.move(Vector2(60, 0))
	assert_eq(_gesture.move(Vector2(1, 0)), Event.DRAG_MOVED)
	assert_eq(_gesture.release(Vector2(1, 0)), Event.DROP)


func test_release_ends_the_gesture() -> void:
	_gesture.press(Vector2.ZERO)
	_gesture.release(Vector2.ZERO)
	assert_eq(_gesture.release(Vector2.ZERO), Event.NONE)
	assert_eq(_gesture.move(Vector2(99, 99)), Event.NONE)


func test_cancel_while_pressed_or_dragging() -> void:
	_gesture.press(Vector2.ZERO)
	assert_eq(_gesture.cancel(), Event.CANCELLED)
	assert_eq(_gesture.release(Vector2.ZERO), Event.NONE, "đã huỷ thì nhả chuột không còn là click")
	_gesture.press(Vector2.ZERO)
	_gesture.move(Vector2(50, 0))
	assert_eq(_gesture.cancel(), Event.CANCELLED)
	assert_eq(_gesture.release(Vector2(50, 0)), Event.NONE, "đã huỷ thì nhả chuột không còn là thả")
	assert_false(_gesture.is_dragging())


func test_pressing_again_restarts_the_gesture() -> void:
	_gesture.press(Vector2.ZERO)
	_gesture.move(Vector2(50, 0))
	_gesture.press(Vector2(200, 200))
	assert_false(_gesture.is_dragging())
	assert_eq(_gesture.move(Vector2(203, 200)), Event.NONE, "đo lại từ vị trí bấm mới")
	assert_eq(_gesture.release(Vector2(203, 200)), Event.CLICK)
