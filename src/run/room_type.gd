class_name RoomType
extends RefCounted
## Loại phòng trên bản đồ lượt chạy. Chỉ là định danh + ký hiệu hiển thị; luật của từng phòng nằm ở nơi khác.

enum Kind { MONSTER, ELITE, CAMPFIRE, SHOP, EVENT, TREASURE, BOSS }

const NAMES := {
	Kind.MONSTER: "Monster",
	Kind.ELITE: "Elite",
	Kind.CAMPFIRE: "Campfire",
	Kind.SHOP: "Shop",
	Kind.EVENT: "Event",
	Kind.TREASURE: "Treasure",
	Kind.BOSS: "Boss",
}

## Ký hiệu một chữ cho bản in ASCII/gỡ lỗi.
const SYMBOLS := {
	Kind.MONSTER: "M",
	Kind.ELITE: "E",
	Kind.CAMPFIRE: "C",
	Kind.SHOP: "S",
	Kind.EVENT: "?",
	Kind.TREASURE: "T",
	Kind.BOSS: "B",
}

## Loại hiếm: không đứng liền nhau trên một đường và không trùng giữa các nút anh em (cùng cha).
const RESTRICTED := [Kind.ELITE, Kind.SHOP, Kind.CAMPFIRE]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < Kind.size()


static func name_of(kind: Kind) -> String:
	return NAMES[kind]


static func symbol_of(kind: Kind) -> String:
	return SYMBOLS[kind]
