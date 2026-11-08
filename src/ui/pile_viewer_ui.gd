class_name PileViewerUI
extends Control
## Lớp phủ xem nội dung một pile (rút/bỏ/exhaust) dưới dạng lưới thẻ cuộn được. Chặn chuột phía sau khi mở.
## Chỉ vẽ danh sách CardView do nơi gọi đưa vào (PileView lo thứ tự); thẻ trong lưới chỉ để xem.

signal closed

const DIM_COLOR := Color(0, 0, 0, 0.9)
const COLUMNS := 6
const GRID_GAP := 16
const SCROLL_HEIGHT := 760.0
const TITLE_FONT_SIZE := 52
const BUTTON_FONT_SIZE := 40
const BUTTON_SIZE := Vector2(260, 76)
const EMPTY_TEXT := "This pile is empty."
const EMPTY_FONT_SIZE := 40
const SEPARATION := 16

var title_label: Label
var empty_label: Label
var scroll: ScrollContainer
var grid: GridContainer
var close_button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", SEPARATION)
	center.add_child(column)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * (CardUI.CARD_SIZE.x + GRID_GAP), SCROLL_HEIGHT)
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	var holder := CenterContainer.new()  # lưới ít thẻ vẫn nằm giữa, thẳng với tiêu đề
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(grid)
	scroll.add_child(holder)
	column.add_child(scroll)
	empty_label = Label.new()
	empty_label.text = EMPTY_TEXT
	empty_label.add_theme_font_size_override("font_size", EMPTY_FONT_SIZE)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(empty_label)
	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = BUTTON_SIZE
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	close_button.pressed.connect(close)
	column.add_child(close_button)


func is_open() -> bool:
	return visible


## Mở lớp phủ với tiêu đề và danh sách thẻ (đã sắp xếp sẵn). Mở khi đang mở thì thay nội dung.
func show_pile(title: String, views: Array[CardView]) -> void:
	_clear_cards()
	title_label.text = title
	for view in views:
		var card_ui := CardUI.new()
		card_ui.show_view(view)
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE  # để bánh xe chuột cuộn được ScrollContainer
		grid.add_child(card_ui)
	empty_label.visible = views.is_empty()
	scroll.visible = not views.is_empty()
	scroll.scroll_vertical = 0
	visible = true


## Đóng và dọn lưới. Trả true nếu đang mở (khi đó phát `closed`).
func close() -> bool:
	var was_open := visible
	visible = false
	_clear_cards()
	if was_open:
		closed.emit()
	return was_open


func _clear_cards() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
