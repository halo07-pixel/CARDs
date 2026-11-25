class_name MapConfig
extends RefCounted
## Tham số sinh bản đồ (mặc định kiểu Slay the Spire: 7 cột x 15 tầng, boss ở tầng 16). Có validate() để từ chối cấu hình vô lý.

var columns: int = 7
var floors: int = 15  ## số tầng thường (chỉ số 0..floors-1); boss ở tầng chỉ số `floors`
var paths: int = 6  ## số đường đi xuất phát từ tầng đầu
var min_start_columns: int = 2  ## ít nhất bấy nhiêu cột xuất phát khác nhau
var treasure_floor: int = 8  ## tầng (chỉ số) toàn kho báu
var elite_min_floor: int = 5  ## elite chỉ xuất hiện từ tầng này
var campfire_min_floor: int = 5  ## lửa trại (ngẫu nhiên) chỉ xuất hiện từ tầng này
## Trọng số loại phòng cho các nút tự do (không bị ép loại).
var weights: Dictionary = {
	RoomType.Kind.MONSTER: 45.0,
	RoomType.Kind.EVENT: 22.0,
	RoomType.Kind.CAMPFIRE: 12.0,
	RoomType.Kind.ELITE: 8.0,
	RoomType.Kind.SHOP: 5.0,
}

const FREE_KINDS := [RoomType.Kind.MONSTER, RoomType.Kind.ELITE, RoomType.Kind.CAMPFIRE, RoomType.Kind.SHOP, RoomType.Kind.EVENT]
const NOT_FORCED := -1


## Loại bị ép ở tầng `floor_index` (tầng đầu toàn quái, tầng kho báu, tầng ngay trước boss toàn lửa trại, tầng boss) hoặc NOT_FORCED.
func forced_kind(floor_index: int) -> int:
	if floor_index == floors:
		return RoomType.Kind.BOSS
	if floor_index == 0:
		return RoomType.Kind.MONSTER
	if floor_index == treasure_floor:
		return RoomType.Kind.TREASURE
	if floor_index == floors - 1:
		return RoomType.Kind.CAMPFIRE
	return NOT_FORCED


## Danh sách lỗi của cấu hình (rỗng = hợp lệ).
func validate() -> Array[String]:
	var problems: Array[String] = []
	if columns < 3 or columns > 15:
		problems.append("columns phải trong [3, 15], đang là %d" % columns)
	if floors < 4 or floors > 40:
		problems.append("floors phải trong [4, 40], đang là %d" % floors)
	if paths < 2 or paths > 20:
		problems.append("paths phải trong [2, 20], đang là %d" % paths)
	if min_start_columns < 1 or min_start_columns > mini(columns, paths):
		problems.append("min_start_columns phải trong [1, min(columns, paths)], đang là %d" % min_start_columns)
	if treasure_floor < 1 or treasure_floor > floors - 2:
		problems.append("treasure_floor phải trong [1, floors-2], đang là %d" % treasure_floor)
	if elite_min_floor < 1 or elite_min_floor > floors - 1:
		problems.append("elite_min_floor phải trong [1, floors-1], đang là %d" % elite_min_floor)
	if campfire_min_floor < 1 or campfire_min_floor > floors - 1:
		problems.append("campfire_min_floor phải trong [1, floors-1], đang là %d" % campfire_min_floor)
	if float(weights.get(RoomType.Kind.MONSTER, 0.0)) <= 0.0:
		problems.append("trọng số MONSTER phải > 0 (là loại dự phòng khi mọi loại khác bị cấm)")
	for kind in weights:
		if not FREE_KINDS.has(kind):
			problems.append("trọng số cho loại không thể tự do: %s" % [kind])
		elif float(weights[kind]) < 0.0:
			problems.append("trọng số âm cho %s" % RoomType.name_of(kind))
	return problems
