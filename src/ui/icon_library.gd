class_name IconLibrary
extends RefCounted
## Tra icon theo icon_id (file assets/icons/<id>.svg). Thiếu file -> null: UI tự hiện chữ viết tắt.

const ICON_DIR := "res://assets/icons/"
const HEART := &"heart"
const BLOCK := &"block"


static func get_icon(icon_id: StringName) -> Texture2D:
	if icon_id.is_empty():
		return null
	var path := "%s%s.svg" % [ICON_DIR, icon_id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
