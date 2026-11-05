class_name ResultOverlayUI
extends Control
## Lớp phủ kết quả trận (Victory!/Defeat) kèm nút "Play again". Chặn chuột phía sau khi đang hiện.

signal play_again_pressed

const DIM_COLOR := Color(0, 0, 0, 0.65)
const VICTORY_TEXT := "Victory!"
const DEFEAT_TEXT := "Defeat"
const VICTORY_COLOR := Color("ffd27a")
const DEFEAT_COLOR := Color("ff6a6a")
const TITLE_FONT_SIZE := 120
const BUTTON_FONT_SIZE := 48
const BUTTON_SIZE := Vector2(360, 90)
const SEPARATION := 40

var title_label: Label
var play_again_button: Button


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
	play_again_button = Button.new()
	play_again_button.text = "Play again"
	play_again_button.custom_minimum_size = BUTTON_SIZE
	play_again_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	play_again_button.pressed.connect(_on_play_again_pressed)
	column.add_child(play_again_button)


func show_result(victory: bool) -> void:
	title_label.text = VICTORY_TEXT if victory else DEFEAT_TEXT
	title_label.add_theme_color_override("font_color", VICTORY_COLOR if victory else DEFEAT_COLOR)
	visible = true


func hide_result() -> void:
	visible = false


func _on_play_again_pressed() -> void:
	play_again_pressed.emit()
