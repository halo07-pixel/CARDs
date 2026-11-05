class_name EnemyUI
extends VBoxContainer
## Một quái: ý định phía trên, hình (placeholder) ở giữa, CombatantUI bên dưới.
## show_intent() do BattleScene (mốc 3.3) gọi khi controller phát intent_changed.

## Phát khi bấm chuột trái vào quái còn sống (BattleScene dùng để chọn mục tiêu).
signal clicked(unit: EnemyUnit)

const ART_SIZE := Vector2(190, 190)
const ART_COLOR := Color(0.18, 0.2, 0.3)
const ART_TARGETABLE_COLOR := Color(0.45, 0.36, 0.16)
const ART_FONT_SIZE := 96
const INTENT_ICON_SIZE := Vector2(56, 56)
const INTENT_FONT_SIZE := 48
const DEFEATED_ALPHA := 0.4

var unit: EnemyUnit = null
var intent_row: HBoxContainer
var intent_label: Label
var art_label: Label
var art_rect: ColorRect
var _targetable: bool = false
var combatant_ui: CombatantUI


func _init() -> void:
	add_theme_constant_override("separation", 8)
	intent_row = HBoxContainer.new()
	intent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_row.custom_minimum_size = Vector2(0, INTENT_ICON_SIZE.y)
	intent_label = Label.new()
	intent_label.add_theme_font_size_override("font_size", INTENT_FONT_SIZE)
	add_child(intent_row)

	art_rect = ColorRect.new()
	art_rect.color = ART_COLOR
	art_rect.custom_minimum_size = ART_SIZE
	art_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art_label = Label.new()
	art_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_font_size_override("font_size", ART_FONT_SIZE)
	art_rect.add_child(art_label)
	add_child(art_rect)

	combatant_ui = CombatantUI.new()
	add_child(combatant_ui)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UiUtil.ignore_mouse_in_children(self)  # để chính EnemyUI nhận click


## Gắn vào một quái: hiển thị máu/giáp/status và ý định hiện tại. Null -> không đổi gì (kèm log).
func bind(p_unit: EnemyUnit) -> void:
	if p_unit == null:
		push_error("EnemyUI.bind: unit null")
		return
	if unit != null:
		unit.combatant.died.disconnect(_on_died)
	unit = p_unit
	unit.combatant.died.connect(_on_died)
	art_label.text = String(unit.data.id).substr(0, 1).to_upper()
	combatant_ui.bind(unit.combatant)
	show_intent(IntentView.build(unit.intent))
	_apply_alive_state()


func show_intent(view: IntentView) -> void:
	if view == null:
		push_error("EnemyUI.show_intent: view null")
		return
	for child in intent_row.get_children():
		intent_row.remove_child(child)
		if child != intent_label:
			child.free()
	for icon_id in view.icon_ids:
		var icon := TextureRect.new()
		icon.texture = IconLibrary.get_icon(icon_id)
		icon.custom_minimum_size = INTENT_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		intent_row.add_child(icon)
	intent_label.text = view.text
	intent_row.add_child(intent_label)


## Viền/màu nổi bật khi quái là mục tiêu hợp lệ của thẻ đang chọn.
func set_targetable(on: bool) -> void:
	_targetable = on
	_refresh_art_color()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and unit != null and unit.is_alive():
		clicked.emit(unit)
		accept_event()


func _refresh_art_color() -> void:
	var targetable := _targetable and unit != null and unit.is_alive()
	art_rect.color = ART_TARGETABLE_COLOR if targetable else ART_COLOR


func _apply_alive_state() -> void:
	var alive := unit.combatant.is_alive()
	intent_row.modulate.a = 1.0 if alive else 0.0  # ẩn nhưng giữ chỗ để các quái thẳng hàng
	modulate.a = 1.0 if alive else DEFEATED_ALPHA
	_refresh_art_color()


func _on_died() -> void:
	_apply_alive_state()
