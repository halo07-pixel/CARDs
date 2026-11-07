class_name TooltipView
extends RefCounted
## Nội dung MỘT tooltip (view-model): tiêu đề, đoạn chữ chính và các mục chú giải từ khóa bên dưới.
## Không có gì để hiện -> has_content() = false (nơi gọi không bật tooltip).

var title: String = ""
var body: String = ""
var entries: Array[GlossaryEntry] = []


func has_content() -> bool:
	return not title.is_empty() or not body.is_empty() or not entries.is_empty()
