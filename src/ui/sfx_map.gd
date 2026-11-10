class_name SfxMap
extends RefCounted
## Bảng "cái gì xảy ra -> tên âm thanh" của màn chiến đấu (hàm thuần: không phát gì, không biết AudioManager).
## Tên khớp tệp assets/audio/sfx/<tên>.ogg; BattleScene phát qua EventBus.sfx_requested.

const CARD_PLAY := &"card_play"
const HIT := &"hit"
const BLOCKED := &"blocked"
const BLOCK_GAIN := &"block_gain"
const HEAL := &"heal"
const STATUS := &"status"
const POTION := &"potion"
const END_TURN := &"end_turn"
const REJECT := &"reject"
const VICTORY := &"victory"
const DEFEAT := &"defeat"

## Mọi tên âm thanh mà màn chiến đấu có thể phát (test kiểm: mỗi tên phải có tệp âm thanh).
const ALL: Array[StringName] = [CARD_PLAY, HIT, BLOCKED, BLOCK_GAIN, HEAL, STATUS, POTION, END_TURN, REJECT, VICTORY, DEFEAT]

## Loại cue -> âm thanh. Loại KHÔNG có trong bảng này là im lặng có chủ ý (DRAW, ENERGY).
const BY_CUE_KIND := {
	EffectCue.Kind.DAMAGE: HIT,
	EffectCue.Kind.LOSE_HP: HIT,
	EffectCue.Kind.BLOCKED: BLOCKED,
	EffectCue.Kind.BLOCK_GAIN: BLOCK_GAIN,
	EffectCue.Kind.HEAL: HEAL,
	EffectCue.Kind.STATUS: STATUS,
}


## Âm thanh của một loại cue; &"" nếu im lặng.
static func for_cue_kind(kind: EffectCue.Kind) -> StringName:
	return BY_CUE_KIND.get(kind, &"")


## Âm thanh cho một lô cue: mỗi âm chỉ một lần trong lô (đòn nhiều hit không phát chồng), theo thứ tự xuất hiện
## đầu tiên; cue im lặng bị bỏ qua.
static func for_cues(cues: Array[EffectCue]) -> Array[StringName]:
	var names: Array[StringName] = []
	for cue in cues:
		var sfx := for_cue_kind(cue.kind)
		if sfx != &"" and not names.has(sfx):
			names.append(sfx)
	return names


static func for_battle_end(victory: bool) -> StringName:
	return VICTORY if victory else DEFEAT
