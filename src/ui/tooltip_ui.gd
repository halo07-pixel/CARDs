class_name TooltipUI
extends PanelContainer
## Khung tooltip duy nhất của màn chiến đấu: tiêu đề, đoạn chữ chính, rồi các mục chú giải từ khóa.
## Không nhận chuột (không cướp hover của thứ bên dưới). Vị trí do TooltipPlacement tính theo "neo" và được
## tính lại khi kích thước đổi (chữ tự xuống dòng nên kích thước chỉ chốt sau khi bố cục chạy).

const CONTENT_WIDTH := 460.0
const TITLE_FONT_SIZE := 34
const BODY_FONT_SIZE := 28
const ENTRY_TITLE_FONT_SIZE := 28
const ENTRY_TEXT_FONT_SIZE := 24
const BACKGROUND_COLOR := Color(0.07, 0.08, 0.12, 0.96)
const BORDER_COLOR := Color("8a8f98")
const TITLE_COLOR := Color("ffd27a")
const ENTRY_TITLE_COLOR := Color("9ad1ff")
const TEXT_COLOR := Color("f2f2f2")
const SEPARATION := 6
const ENTRY_GAP := 10

var title_label: Label
var body_label: Label
var entries_box: VBoxContainer
var _anchor: Rect2 = Rect2()


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", SEPARATION)
	add_child(column)
	title_label = _make_label(TITLE_FONT_SIZE, TITLE_COLOR)
	body_label = _make_label(BODY_FONT_SIZE, TEXT_COLOR)
	entries_box = VBoxContainer.new()
	entries_box.add_theme_constant_override("separation", ENTRY_GAP)
	column.add_child(title_label)
	column.add_child(body_label)
	column.add_child(entries_box)
	UiUtil.ignore_mouse_in_children(self)
	resized.connect(_place)


## Hiện tooltip cạnh vùng neo `anchor` (toạ độ toàn cục). view null hoặc rỗng -> ẩn.
func show_tooltip(view: TooltipView, anchor: Rect2) -> void:
	if view == null or not view.has_content():
		hide_tooltip()
		return
	_anchor = anchor
	_set_text(title_label, view.title)
	_set_text(body_label, view.body)
	_rebuild_entries(view.entries)
	visible = true
	reset_size()
	_place()


func hide_tooltip() -> void:
	visible = false


func _place() -> void:
	if visible:
		position = TooltipPlacement.place(_anchor, size, DropIntent.DESIGN_SCREEN)


func _set_text(label: Label, text: String) -> void:
	label.text = text
	label.visible = not text.is_empty()


func _rebuild_entries(entries: Array[GlossaryEntry]) -> void:
	for child in entries_box.get_children():
		entries_box.remove_child(child)
		child.free()
	for entry in entries:
		var box := VBoxContainer.new()
		box.add_child(_make_label(ENTRY_TITLE_FONT_SIZE, ENTRY_TITLE_COLOR, entry.title))
		box.add_child(_make_label(ENTRY_TEXT_FONT_SIZE, TEXT_COLOR, entry.text))
		entries_box.add_child(box)
	entries_box.visible = not entries.is_empty()


func _make_label(font_size: int, color: Color, text: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
