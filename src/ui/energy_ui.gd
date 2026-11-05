class_name EnergyUI
extends PanelContainer
## Quả cầu năng lượng "hiện tại/tối đa". Tự cập nhật theo energy_changed của controller.

const ORB_SIZE := Vector2(140, 140)
const FONT_SIZE := 56
const FILL_COLOR := Color("b8651b")
const BORDER_COLOR := Color("ffd27a")
const BORDER_WIDTH := 5

var controller: BattleController = null
var label: Label


func _init() -> void:
	custom_minimum_size = ORB_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = FILL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(int(ORB_SIZE.x / 2.0))
	add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	UiUtil.ignore_mouse_in_children(self)


func bind(p_controller: BattleController) -> void:
	if p_controller == null:
		push_error("EnergyUI.bind: controller null")
		return
	unbind()
	controller = p_controller
	controller.energy_changed.connect(_on_energy_changed)
	refresh()


func unbind() -> void:
	if controller == null:
		return
	controller.energy_changed.disconnect(_on_energy_changed)
	controller = null


func refresh() -> void:
	if controller != null:
		label.text = "%d/%d" % [controller.energy, controller.config.max_energy]


func _on_energy_changed(_old_energy: int, _new_energy: int) -> void:
	refresh()
