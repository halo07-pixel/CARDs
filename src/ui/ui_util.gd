class_name UiUtil
extends RefCounted
## Tiện ích dựng giao diện dùng chung.


## Cho MỌI control con cháu của root bỏ qua chuột, để root nhận được click (Label/ColorRect/RichTextLabel con
## mặc định có thể chặn sự kiện chuột trước khi nó lên tới root).
static func ignore_mouse_in_children(root: Node) -> void:
	for child in root.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_mouse_in_children(child)
