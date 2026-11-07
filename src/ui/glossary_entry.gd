class_name GlossaryEntry
extends RefCounted
## Một mục chú giải từ khóa (vd. "Exhaust" + lời giải thích) hiện trong tooltip. Chỉ là dữ liệu hiển thị.

var title: String = ""
var text: String = ""


static func create(p_title: String, p_text: String) -> GlossaryEntry:
	var entry := GlossaryEntry.new()
	entry.title = p_title
	entry.text = p_text
	return entry
