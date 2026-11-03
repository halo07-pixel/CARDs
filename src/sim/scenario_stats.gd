class_name ScenarioStats
extends RefCounted
## Số liệu thô của một kịch bản mô phỏng (một nhóm quái + một loại bot) để xem cân bằng.

var scenario: String = ""
var bot: StringName = &""
var battles: int = 0
var wins: int = 0
var defeats: int = 0
var turn_caps: int = 0
var total_turns: int = 0
var total_potions_used: int = 0
var total_hp_lost: int = 0  ## máu người chơi mất trong cả trận (cả thắng lẫn thua)
var violations: Array[String] = []


func record(end_reason: StringName, turns: int, hp_lost: int, potions_used: int = 0) -> void:
	battles += 1
	total_potions_used += potions_used
	total_turns += turns
	total_hp_lost += hp_lost
	match end_reason:
		BattleController.END_VICTORY:
			wins += 1
		BattleController.END_TURN_CAP:
			turn_caps += 1
		_:
			defeats += 1


func win_rate() -> float:
	return float(wins) / battles if battles > 0 else 0.0


func avg_turns() -> float:
	return float(total_turns) / battles if battles > 0 else 0.0


func avg_hp_lost() -> float:
	return float(total_hp_lost) / battles if battles > 0 else 0.0


func avg_potions_used() -> float:
	return float(total_potions_used) / battles if battles > 0 else 0.0


func summary_line() -> String:
	return "%-22s %-7s %5d trận | thắng %5.1f%% | %4.1f lượt | -%5.1f máu | potion %.1f | cap %d | lỗi %d" % [
		scenario, bot, battles, win_rate() * 100.0, avg_turns(), avg_hp_lost(), avg_potions_used(),
		turn_caps, violations.size()]
