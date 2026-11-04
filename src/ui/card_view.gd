class_name CardView
extends RefCounted
## Dữ liệu HIỂN THỊ của một thẻ (view-model): CardUI chỉ đọc cái này, không biết luật chơi.
## Tách khỏi CardData (luật) để UI không phụ thuộc cách tính; dựng bằng CardView.build().

var uid: int = 0
var card_id: StringName = &""
var title: String = ""
var cost_text: String = ""
var cost_shift: int = 0  ## < 0: rẻ hơn gốc, > 0: đắt hơn gốc, 0: đúng gốc
var card_type: CardData.CardType = CardData.CardType.ATTACK
var rarity: CardData.Rarity = CardData.Rarity.COMMON
var description: String = ""  ## BBCode (số bị đổi được tô màu)
var icon_id: StringName = &""
var is_upgraded: bool = false
var is_playable: bool = true

const COST_UNPLAYABLE := "-"
const COST_X := "X"


## owner/target tùy chọn (xem CardTextFormatter). Trả null (kèm log) nếu thiếu thẻ.
static func build(card: CardInstance, owner: Combatant = null, target: Combatant = null,
		playable: bool = true) -> CardView:
	if card == null or card.data == null:
		push_error("CardView.build: thiếu thẻ")
		return null
	var view := CardView.new()
	var data := card.data
	view.uid = card.uid
	view.card_id = data.id
	view.title = data.display_name
	view.card_type = data.card_type
	view.rarity = data.rarity
	view.icon_id = data.icon_id
	view.is_upgraded = data.is_upgrade()
	view.is_playable = playable and not data.unplayable
	view.description = CardTextFormatter.format(data, owner, target, true)
	if data.unplayable:
		view.cost_text = COST_UNPLAYABLE
	elif data.is_x_cost:
		view.cost_text = COST_X
	else:
		view.cost_text = str(card.get_cost())
		view.cost_shift = signi(card.get_cost() - data.cost)
	return view
