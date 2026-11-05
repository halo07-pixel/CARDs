extends RefCounted
## Sự kiện chuột giả để test control ở chế độ headless.


static func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event
