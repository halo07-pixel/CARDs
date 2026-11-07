class_name PileView
extends RefCounted
## Danh sách thẻ của MỘT pile để xem (view-model). Sắp xếp theo TÊN rồi theo uid, KHÔNG theo thứ tự trong pile:
## xem draw pile mà thấy thứ tự thật sẽ biết trước lá sắp rút (lộ thông tin). Chỉ pile rút/bỏ/exhaust xem được.

const VIEWABLE: Array[StringName] = [Deck.DRAW, Deck.DISCARD, Deck.EXHAUST]


## owner tùy chọn (số trên thẻ tính theo Strength...). Pile không xem được / deck null -> rỗng kèm log.
static func build(deck: Deck, pile_name: StringName, owner: Combatant = null) -> Array[CardView]:
	var views: Array[CardView] = []
	if deck == null or not VIEWABLE.has(pile_name):
		push_error("PileView.build: thiếu deck hoặc pile '%s' không xem được" % pile_name)
		return views
	var cards := deck.get_pile(pile_name)
	cards.sort_custom(_before)
	for card in cards:
		views.append(CardView.build(card, owner))
	return views


static func _before(left: CardInstance, right: CardInstance) -> bool:
	var left_name := left.data.display_name
	var right_name := right.data.display_name
	if left_name != right_name:
		return left_name < right_name
	return left.uid < right.uid
