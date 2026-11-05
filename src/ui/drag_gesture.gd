class_name DragGesture
extends RefCounted
## Phân biệt CLICK và KÉO cho một lần bấm chuột. Thuần logic, không node: nơi gọi báo vị trí con trỏ
## (press/move/release/cancel) và nhận lại sự kiện. Di chuyển không quá DRAG_THRESHOLD px kể từ lúc bấm
## thì nhả ra vẫn là click; vượt quá thì là kéo (và đã vào chế độ kéo thì không quay lại thành click).

enum Phase { IDLE, PRESSED, DRAGGING }
enum Event { NONE, DRAG_STARTED, DRAG_MOVED, CLICK, DROP, CANCELLED }

const DRAG_THRESHOLD := 12.0

var phase: Phase = Phase.IDLE
var press_position := Vector2.ZERO
var pointer := Vector2.ZERO


func is_dragging() -> bool:
	return phase == Phase.DRAGGING


## Bắt đầu một lần bấm (bấm lần nữa khi đang bấm thì làm lại từ đầu).
func press(at: Vector2) -> void:
	phase = Phase.PRESSED
	press_position = at
	pointer = at


func move(to: Vector2) -> Event:
	if phase == Phase.IDLE:
		return Event.NONE
	pointer = to
	if phase == Phase.DRAGGING:
		return Event.DRAG_MOVED
	if to.distance_to(press_position) > DRAG_THRESHOLD:
		phase = Phase.DRAGGING
		return Event.DRAG_STARTED
	return Event.NONE


func release(at: Vector2) -> Event:
	var was := phase
	phase = Phase.IDLE
	pointer = at
	match was:
		Phase.PRESSED:
			return Event.CLICK
		Phase.DRAGGING:
			return Event.DROP
	return Event.NONE


## Huỷ giữa chừng (Esc, chuột phải). Trả CANCELLED nếu đang bấm/kéo.
func cancel() -> Event:
	if phase == Phase.IDLE:
		return Event.NONE
	phase = Phase.IDLE
	return Event.CANCELLED
