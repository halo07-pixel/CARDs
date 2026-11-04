class_name HealthBarUI
extends HBoxContainer
## Thanh máu "hp/max" và (khi có) giáp = icon khiên + số. Chỉ hiển thị, không biết luật chơi.

const BAR_SIZE := Vector2(220, 32)
const BLOCK_ICON_SIZE := Vector2(32, 32)
const FILL_COLOR := Color("c0392b")
const BACKGROUND_COLOR := Color("2a1a1a")
const BLOCK_FONT_SIZE := 32
const HP_FONT_SIZE := 24

var bar: ProgressBar
var hp_label: Label
var block_box: HBoxContainer
var block_label: Label


func _init() -> void:
	add_theme_constant_override("separation", 8)
	block_box = HBoxContainer.new()
	var shield := TextureRect.new()
	shield.texture = IconLibrary.get_icon(IconLibrary.BLOCK)
	shield.custom_minimum_size = BLOCK_ICON_SIZE
	shield.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	block_label = Label.new()
	block_label.add_theme_font_size_override("font_size", BLOCK_FONT_SIZE)
	block_box.add_child(shield)
	block_box.add_child(block_label)
	block_box.visible = false
	add_child(block_box)

	bar = ProgressBar.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.show_percentage = false
	bar.add_theme_stylebox_override("fill", _flat(FILL_COLOR))
	bar.add_theme_stylebox_override("background", _flat(BACKGROUND_COLOR))
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", HP_FONT_SIZE)
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(hp_label)
	add_child(bar)


func set_health(hp: int, max_hp: int) -> void:
	bar.max_value = maxi(max_hp, 1)
	bar.value = hp  # ProgressBar (Range) tự giới hạn trong [0, max]
	hp_label.text = "%d/%d" % [hp, max_hp]


func set_block(amount: int) -> void:
	block_box.visible = amount > 0
	block_label.text = str(amount)


func _flat(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
