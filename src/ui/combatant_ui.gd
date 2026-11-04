class_name CombatantUI
extends VBoxContainer
## Tên + máu/giáp + hàng status của MỘT Combatant (người chơi hay quái). Tự cập nhật bằng Signal
## của chính Combatant đó (signal up): không gọi lên cha, không đổi trạng thái của lõi.

const DEFEATED_ALPHA := 0.4
const NAME_FONT_SIZE := 32

var combatant: Combatant = null
var name_label: Label
var health_bar: HealthBarUI
var status_row: HFlowContainer


func _init() -> void:
	add_theme_constant_override("separation", 6)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	health_bar = HealthBarUI.new()
	health_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(health_bar)
	status_row = HFlowContainer.new()
	status_row.alignment = FlowContainer.ALIGNMENT_CENTER
	add_child(status_row)


## Gắn vào một Combatant (bỏ gắn cái cũ nếu có). Null -> không đổi gì (kèm log).
func bind(target: Combatant) -> void:
	if target == null:
		push_error("CombatantUI.bind: combatant null")
		return
	unbind()
	combatant = target
	combatant.health_changed.connect(_on_health_changed)
	combatant.block_changed.connect(_on_block_changed)
	combatant.status_changed.connect(_on_status_changed)
	combatant.died.connect(_on_died)
	refresh()


func unbind() -> void:
	if combatant == null:
		return
	combatant.health_changed.disconnect(_on_health_changed)
	combatant.block_changed.disconnect(_on_block_changed)
	combatant.status_changed.disconnect(_on_status_changed)
	combatant.died.disconnect(_on_died)
	combatant = null


## Vẽ lại toàn bộ từ trạng thái hiện tại của Combatant.
func refresh() -> void:
	if combatant == null:
		return
	name_label.text = combatant.display_name
	health_bar.set_health(combatant.hp, combatant.max_hp)
	health_bar.set_block(combatant.block)
	_rebuild_statuses()
	modulate.a = 1.0 if combatant.is_alive() else DEFEATED_ALPHA


func _rebuild_statuses() -> void:
	for child in status_row.get_children():
		status_row.remove_child(child)
		child.free()
	for view in StatusView.build_all(combatant):
		var icon := StatusIconUI.new()
		icon.show_view(view)
		status_row.add_child(icon)


func _on_health_changed(_old_hp: int, _new_hp: int) -> void:
	health_bar.set_health(combatant.hp, combatant.max_hp)


func _on_block_changed(_old_block: int, _new_block: int) -> void:
	health_bar.set_block(combatant.block)


func _on_status_changed(_status_id: StringName, _old_amount: int, _new_amount: int) -> void:
	_rebuild_statuses()


func _on_died() -> void:
	modulate.a = DEFEATED_ALPHA
