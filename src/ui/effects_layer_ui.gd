class_name EffectsLayerUI
extends Control
## Lớp phủ chứa các chữ nổi. Không nhận chuột. Chỉ biết EffectCue + hàm tra vùng neo của chủ cue, không biết luật.

const STAGGER := 0.15  ## giây (ở tốc độ 1) giữa hai chữ liên tiếp của cùng một lô
const START_HEIGHT_RATIO := 0.5  ## chữ bắt đầu ở giữa chiều cao của vùng neo rồi bay lên
const LINE_STEP := 70.0  ## chữ thứ k đang bay của cùng một chủ bắt đầu thấp hơn k dòng: không đè lên nhau khi bay
const OWNER_META := &"fx_owner"
const COLORS := {
	EffectCue.Kind.DAMAGE: Color("ff6a6a"),
	EffectCue.Kind.LOSE_HP: Color("ff6a6a"),
	EffectCue.Kind.BLOCKED: Color("9aa7bd"),
	EffectCue.Kind.BLOCK_GAIN: Color("5aa9ff"),
	EffectCue.Kind.HEAL: Color("7ee06a"),
	EffectCue.Kind.STATUS: Color("ffd27a"),
	EffectCue.Kind.DRAW: Color("f2f2f2"),
	EffectCue.Kind.ENERGY: Color("ffb347"),
}

var config: EffectsConfig = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sinh một chữ nổi cho mỗi cue (lệch thời gian theo thứ tự). anchor_of(combatant) -> Rect2 toàn cục của chủ cue.
## Tắt hiệu ứng -> không sinh gì. Trả số chữ đã sinh.
func show_cues(cues: Array[EffectCue], anchor_of: Callable) -> int:
	if config == null or not config.is_enabled():
		return 0
	var spawned := 0
	for i in cues.size():
		var cue := cues[i]
		var anchor: Rect2 = anchor_of.call(cue.target)
		var line := active_count_for(cue.target)  # tính cả chữ của lô trước còn đang bay
		var floating := FloatingTextUI.new()
		floating.set_meta(OWNER_META, cue.target)
		add_child(floating)
		var origin := Vector2(anchor.get_center().x, anchor.position.y + anchor.size.y * START_HEIGHT_RATIO + line * LINE_STEP) - global_position
		floating.play(cue.text, COLORS.get(cue.kind, Color.WHITE), origin, config.duration(STAGGER) * i, config)
		spawned += 1
	return spawned


## Số chữ đang bay (hoặc chờ bay) của một chủ.
func active_count_for(owner: Combatant) -> int:
	var count := 0
	for child in get_children():
		if not child.is_queued_for_deletion() and child.get_meta(OWNER_META, null) == owner:
			count += 1
	return count


## Xóa ngay mọi chữ đang bay.
func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
