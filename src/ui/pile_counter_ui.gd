class_name PileCounterUI
extends PanelContainer
## Bộ đếm số thẻ của MỘT pile (rút / bỏ / exhaust). Tự cập nhật theo pile_changed của Deck.

const TITLES := {Deck.DRAW: "Draw", Deck.DISCARD: "Discard", Deck.EXHAUST: "Exhaust"}
const COUNTER_SIZE := Vector2(130, 90)
const TITLE_FONT_SIZE := 22
const COUNT_FONT_SIZE := 40
const BACKGROUND_COLOR := Color(0, 0, 0, 0.4)

var pile_name: StringName = Deck.DRAW
var deck: Deck = null
var title_label: Label
var count_label: Label


func _init(p_pile_name: StringName = Deck.DRAW) -> void:
	pile_name = p_pile_name
	custom_minimum_size = COUNTER_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND_COLOR
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	title_label = Label.new()
	title_label.text = TITLES.get(pile_name, String(pile_name).capitalize())
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	column.add_child(count_label)
	add_child(column)
	UiUtil.ignore_mouse_in_children(self)


func bind(p_deck: Deck) -> void:
	if p_deck == null:
		push_error("PileCounterUI.bind: deck null")
		return
	unbind()
	deck = p_deck
	deck.pile_changed.connect(_on_pile_changed)
	refresh()


func unbind() -> void:
	if deck == null:
		return
	deck.pile_changed.disconnect(_on_pile_changed)
	deck = null


func refresh() -> void:
	if deck != null:
		count_label.text = str(deck.count(pile_name))


func _on_pile_changed(pile: StringName) -> void:
	if pile == pile_name:
		refresh()
