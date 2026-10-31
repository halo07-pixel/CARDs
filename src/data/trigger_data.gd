class_name TriggerData
extends Resource
## "Khi sự kiện X xảy ra với chủ sở hữu thì chạy các effect này." Dữ liệu thuần, đặt trong
## StatusData (và RelicData ở bước 2.2). Chủ sở hữu = Combatant đang mang status/relic đó.
##  - TURN_START / TURN_END: lượt của chính chủ sở hữu
##  - ATTACKED: chủ sở hữu bị đánh bằng đòn tấn công (kể cả khi giáp chặn hết)
##  - HP_LOST: chủ sở hữu mất máu
##  - CARD_PLAYED: chủ sở hữu (người chơi) vừa chơi một thẻ
##  - BATTLE_START / BATTLE_VICTORY: một lần mỗi trận
## LƯU Ý: enum lưu dạng số nguyên trong .tres -> giá trị mới luôn thêm vào CUỐI.

enum Event { BATTLE_START, BATTLE_VICTORY, TURN_START, TURN_END, CARD_PLAYED, ATTACKED, HP_LOST }

@export var event: Event = Event.TURN_START
@export var effects: Array[EffectData] = []
@export var scale_by_stacks: bool = false  ## amount của mỗi effect nhân với số stack của status
@export var every_n: int = 0               ## 0 = mọi lần; N > 0 = chỉ ở lần xảy ra thứ N, 2N, ...
@export var max_per_turn: int = 0          ## 0 = không giới hạn
@export var max_per_battle: int = 0        ## 0 = không giới hạn
@export var filter_card_type: bool = false ## chỉ với CARD_PLAYED: lọc theo card_type bên dưới
@export var card_type: CardData.CardType = CardData.CardType.ATTACK
@export var requires_zero_block: bool = false  ## chỉ nổ khi chủ sở hữu đang có 0 giáp


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if effects.is_empty():
		errors.append("trigger phải có ít nhất 1 effect")
	for i in effects.size():
		var effect := effects[i]
		if effect == null:
			errors.append("effects[%d] là null" % i)
			continue
		for message: String in effect.validate(true):
			errors.append("effects[%d]: %s" % [i, message])
		if effect.scales_with_x:
			errors.append("effects[%d]: scales_with_x chỉ dùng cho thẻ X-cost" % i)
		if effect.target == EffectData.Target.TARGET_ENEMY:
			errors.append("effects[%d]: TARGET_ENEMY không dùng trong trigger (dùng ALL_ENEMIES, RANDOM_ENEMY hoặc EVENT_SOURCE)" % i)
		if effect.target == EffectData.Target.EVENT_SOURCE \
				and event != Event.ATTACKED and event != Event.HP_LOST:
			errors.append("effects[%d]: EVENT_SOURCE chỉ có nghĩa với ATTACKED/HP_LOST" % i)
	if every_n < 0:
		errors.append("every_n không được âm (hiện %d)" % every_n)
	if max_per_turn < 0:
		errors.append("max_per_turn không được âm (hiện %d)" % max_per_turn)
	if max_per_battle < 0:
		errors.append("max_per_battle không được âm (hiện %d)" % max_per_battle)
	if filter_card_type and event != Event.CARD_PLAYED:
		errors.append("filter_card_type chỉ dùng với CARD_PLAYED")
	return errors
