class_name RejectionText
extends RefCounted
## Câu tiếng Anh hiển thị khi controller từ chối một hành động (lý do = BattleController.REASON_*).

const FALLBACK := "Can't do that"
const CHOOSE_TARGET := "Choose a target"
const TEXTS := {
	BattleController.REASON_ALREADY_STARTED: "The battle has already started",
	BattleController.REASON_BATTLE_OVER: "The battle is over",
	BattleController.REASON_NOT_PLAYER_TURN: "Not your turn",
	BattleController.REASON_CARD_NOT_IN_HAND: "That card isn't in your hand",
	BattleController.REASON_UNPLAYABLE: "This card can't be played",
	BattleController.REASON_NOT_ENOUGH_ENERGY: "Not enough energy",
	BattleController.REASON_INVALID_TARGET: "Invalid target",
	BattleController.REASON_NO_POTION: "No potion in that slot",
}


static func for_reason(reason: StringName) -> String:
	return TEXTS.get(reason, FALLBACK)
