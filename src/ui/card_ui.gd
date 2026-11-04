class_name CardUI
extends PanelContainer
## Hiển thị MỘT thẻ từ CardView. Không chứa luật chơi: chỉ đọc view và vẽ (màu theo loại/độ hiếm).
## Hình thẻ là placeholder (chữ cái đầu) cho tới khi có asset; dựng control ngay trong _init nên
## dùng được cả khi chưa nằm trong cây scene (test headless).

const CARD_SIZE := Vector2(220, 300)
const ART_HEIGHT := 96.0
const CORNER_RADIUS := 10
const BORDER_WIDTH := 3
const UNPLAYABLE_ALPHA := 0.55
const TEXT_COLOR := Color("f2f2f2")
const COST_UP_COLOR := Color("ff7070")
const COST_DOWN_COLOR := Color("7ee06a")
const TYPE_COLORS := {
	CardData.CardType.ATTACK: Color("5b2a2a"),
	CardData.CardType.SKILL: Color("2a3f5b"),
	CardData.CardType.POWER: Color("45295b"),
}
const RARITY_COLORS := {
	CardData.Rarity.STARTER: Color("8a8f98"),
	CardData.Rarity.COMMON: Color("b8bcc4"),
	CardData.Rarity.UNCOMMON: Color("5aa9ff"),
	CardData.Rarity.RARE: Color("ffc94a"),
}
const TYPE_NAMES := {
	CardData.CardType.ATTACK: "Attack",
	CardData.CardType.SKILL: "Skill",
	CardData.CardType.POWER: "Power",
}

var view: CardView = null
var cost_label: Label
var name_label: Label
var art_label: Label
var type_label: Label
var description_label: RichTextLabel


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	var header := HBoxContainer.new()
	cost_label = _make_label(24)
	cost_label.custom_minimum_size = Vector2(36, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label = _make_label(18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(cost_label)
	header.add_child(name_label)
	column.add_child(header)

	var art := ColorRect.new()
	art.color = Color(0, 0, 0, 0.3)
	art.custom_minimum_size = Vector2(0, ART_HEIGHT)
	art_label = _make_label(40)
	art_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art.add_child(art_label)
	column.add_child(art)

	type_label = _make_label(13)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(type_label)

	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.scroll_active = false
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_label.add_theme_font_size_override("normal_font_size", 16)
	description_label.add_theme_color_override("default_color", TEXT_COLOR)
	column.add_child(description_label)


## Hiển thị một thẻ. view null -> không đổi gì (kèm log).
func show_view(new_view: CardView) -> void:
	if new_view == null:
		push_error("CardUI.show_view: view null")
		return
	view = new_view
	cost_label.text = view.cost_text
	cost_label.add_theme_color_override("font_color", _cost_color(view.cost_shift))
	name_label.text = view.title
	art_label.text = String(view.card_id).substr(0, 1).to_upper()
	type_label.text = TYPE_NAMES.get(view.card_type, "")
	description_label.text = "[center]%s[/center]" % view.description
	add_theme_stylebox_override("panel", _make_style(view))
	modulate.a = 1.0 if view.is_playable else UNPLAYABLE_ALPHA


func _cost_color(shift: int) -> Color:
	if shift > 0:
		return COST_UP_COLOR
	return COST_DOWN_COLOR if shift < 0 else TEXT_COLOR


func _make_style(card_view: CardView) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(card_view.card_type, Color.DIM_GRAY)
	style.border_color = RARITY_COLORS.get(card_view.rarity, Color.WHITE)
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(8)
	return style


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label
