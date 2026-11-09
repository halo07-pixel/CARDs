class_name EffectCueBuilder
extends RefCounted
## Đổi kết quả hiệu ứng của lõi thành danh sách EffectCue (hàm thuần: không node, không sửa đầu vào).
## Không tính lại gì: chỉ đọc số đã có trong EffectResult/DamageResult.

const BLOCKED_TEXT := "Blocked"


## player: chủ của cue không có mục tiêu (DRAW, GAIN_ENERGY). status_lookup(status_id) -> StatusData (tùy chọn)
## để hiện tên status; thiếu thì dùng id viết hoa chữ đầu.
static func build(results: Array[EffectResult], player: Combatant, status_lookup: Callable = Callable()) -> Array[EffectCue]:
	var cues: Array[EffectCue] = []
	for result in results:
		if result == null:
			continue
		var cue := _cue_for(result, player, status_lookup)
		if cue != null:
			cues.append(cue)
	return cues


static func _cue_for(result: EffectResult, player: Combatant, status_lookup: Callable) -> EffectCue:
	var target := result.target if result.target != null else player
	match result.type:
		EffectData.Type.DAMAGE:
			var damage := result.damage
			if damage == null or not damage.accepted:
				return null
			if damage.hp_lost == 0 and damage.blocked > 0:
				return EffectCue.create(EffectCue.Kind.BLOCKED, target, BLOCKED_TEXT)
			return EffectCue.create(EffectCue.Kind.DAMAGE, target, str(damage.hp_lost))
		EffectData.Type.BLOCK:
			return EffectCue.create(EffectCue.Kind.BLOCK_GAIN, target, "+%d Block" % result.amount) if result.amount > 0 else null
		EffectData.Type.HEAL:
			return EffectCue.create(EffectCue.Kind.HEAL, target, "+%d" % result.amount) if result.amount > 0 else null
		EffectData.Type.LOSE_HP:
			return EffectCue.create(EffectCue.Kind.LOSE_HP, target, "-%d" % result.amount) if result.amount > 0 else null
		EffectData.Type.APPLY_STATUS:
			return EffectCue.create(EffectCue.Kind.STATUS, target, "%s %+d" % [_status_name(result.status_id, status_lookup), result.amount])
		EffectData.Type.DRAW:
			return EffectCue.create(EffectCue.Kind.DRAW, target, "Draw %d" % result.amount) if result.amount > 0 else null
		EffectData.Type.GAIN_ENERGY:
			return EffectCue.create(EffectCue.Kind.ENERGY, target, "+%d Energy" % result.amount) if result.amount > 0 else null
	return null


static func _status_name(status_id: StringName, status_lookup: Callable) -> String:
	if status_lookup.is_valid():
		var data := status_lookup.call(status_id) as StatusData
		if data != null and not data.display_name.is_empty():
			return data.display_name
	return String(status_id).capitalize()
