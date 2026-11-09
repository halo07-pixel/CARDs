class_name EffectCue
extends RefCounted
## Một "tín hiệu hiệu ứng" cần trình diễn (số nổi...), suy ra từ EffectResult. Chỉ là dữ liệu hiển thị.

enum Kind { DAMAGE, BLOCKED, BLOCK_GAIN, HEAL, LOSE_HP, STATUS, DRAW, ENERGY }

var kind: Kind = Kind.DAMAGE
var target: Combatant = null  ## nơi chữ xuất hiện (DRAW / ENERGY thuộc về người chơi)
var text: String = ""


static func create(p_kind: Kind, p_target: Combatant, p_text: String) -> EffectCue:
	var cue := EffectCue.new()
	cue.kind = p_kind
	cue.target = p_target
	cue.text = p_text
	return cue
