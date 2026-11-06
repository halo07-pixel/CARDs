extends RefCounted
## Sự kiện chuột giả để test control ở chế độ headless. Toạ độ cục bộ = toàn cục (control gốc ở (0,0)).


static func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	return press(Vector2.ZERO, button)


static func press(at: Vector2 = Vector2.ZERO, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	return _button(at, button, true)


static func release(at: Vector2 = Vector2.ZERO, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	return _button(at, button, false)


static func motion(to: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	return event


static func _button(at: Vector2, button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = at
	event.global_position = at
	return event
