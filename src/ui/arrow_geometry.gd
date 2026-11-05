class_name ArrowGeometry
extends RefCounted
## Hình học mũi tên nhắm từ thẻ tới con trỏ: đường cong bậc hai nhô lên phía trên + đầu mũi tên tam giác.
## Thuần toán học, không node.

const SEGMENTS := 24
const BULGE_RATIO := 0.35
const MAX_BULGE := 160.0
const HEAD_LENGTH := 36.0
const HEAD_WIDTH := 32.0
const FALLBACK_DIRECTION := Vector2.UP  ## khi from == to (không có hướng)
const MIN_DIRECTION_LENGTH := 0.01  ## đoạn ngắn hơn (px) coi như không có hướng; bỏ qua sai số dấu phẩy động


## Các điểm của đường cong từ `from` tới `to` (segments + 1 điểm, điểm đầu = from, điểm cuối = to).
static func curve_points(from: Vector2, to: Vector2, segments: int = SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	var control := (from + to) / 2.0 + Vector2(0.0, -minf(from.distance_to(to) * BULGE_RATIO, MAX_BULGE))
	var steps := maxi(segments, 1)
	for i in steps + 1:
		var t := float(i) / steps
		var inverse := 1.0 - t
		points.append(from * inverse * inverse + control * 2.0 * inverse * t + to * t * t)
	return points


## Hướng (đơn vị) của đoạn cuối đường cong; FALLBACK_DIRECTION nếu đoạn cuối quá ngắn (xem MIN_DIRECTION_LENGTH).
static func end_direction(points: PackedVector2Array) -> Vector2:
	if points.size() < 2:
		return FALLBACK_DIRECTION
	var delta := points[points.size() - 1] - points[points.size() - 2]
	return delta.normalized() if delta.length() > MIN_DIRECTION_LENGTH else FALLBACK_DIRECTION


## Tam giác đầu mũi tên: đỉnh = tip, đáy cách đỉnh HEAD_LENGTH ngược hướng `direction`.
static func head_polygon(tip: Vector2, direction: Vector2) -> PackedVector2Array:
	var base := tip - direction * HEAD_LENGTH
	var side := Vector2(-direction.y, direction.x) * (HEAD_WIDTH / 2.0)
	return PackedVector2Array([tip, base + side, base - side])


## Mũi tên đầy đủ từ `from` tới `to`: thân kết thúc ở đáy đầu mũi tên (không chồng lên đầu).
static func build(from: Vector2, to: Vector2) -> ArrowShape:
	var shape := ArrowShape.new()
	var direction := end_direction(curve_points(from, to))
	shape.head = head_polygon(to, direction)
	if from.distance_to(to) <= HEAD_LENGTH:
		shape.shaft = PackedVector2Array([from, from])
	else:
		shape.shaft = curve_points(from, to - direction * HEAD_LENGTH)
	return shape
