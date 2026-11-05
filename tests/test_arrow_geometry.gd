extends "res://tests/test_case.gd"

const FROM := Vector2(400, 700)
const TO := Vector2(900, 200)


func test_curve_starts_and_ends_exactly_at_the_given_points() -> void:
	var points := ArrowGeometry.curve_points(FROM, TO)
	assert_eq(points.size(), ArrowGeometry.SEGMENTS + 1)
	assert_almost_eq(points[0].x, FROM.x, 0.001)
	assert_almost_eq(points[0].y, FROM.y, 0.001)
	assert_almost_eq(points[points.size() - 1].x, TO.x, 0.001)
	assert_almost_eq(points[points.size() - 1].y, TO.y, 0.001)


func test_curve_bulges_upward_and_is_smooth() -> void:
	var points := ArrowGeometry.curve_points(Vector2(100, 500), Vector2(900, 500))
	var middle := points[points.size() / 2]
	assert_true(middle.y < 500.0, "giữa đường cong nhô lên trên đường thẳng")
	assert_almost_eq(middle.x, 500.0, 0.001)
	for i in range(1, points.size()):
		assert_true(points[i].distance_to(points[i - 1]) < 120.0, "không có bước nhảy lớn")


func test_bulge_is_capped() -> void:
	var points := ArrowGeometry.curve_points(Vector2(0, 1000), Vector2(4000, 1000))
	var peak := 1000.0
	for point in points:
		peak = minf(peak, point.y)
	# đỉnh của đường cong bậc hai nằm ở nửa độ cao của điểm điều khiển
	assert_true(1000.0 - peak <= ArrowGeometry.MAX_BULGE / 2.0 + 0.01, "đỉnh nhô tối đa nửa MAX_BULGE")


func test_zero_length_curve_is_safe() -> void:
	var points := ArrowGeometry.curve_points(FROM, FROM)
	for point in points:
		assert_true(point.distance_to(FROM) < 0.01, "mọi điểm trùng from (sai số dấu phẩy động nhỏ)")
	assert_eq(ArrowGeometry.end_direction(points), ArrowGeometry.FALLBACK_DIRECTION)


func test_end_direction_points_along_the_last_segment() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(0, 10), Vector2(10, 10)])
	assert_eq(ArrowGeometry.end_direction(points), Vector2.RIGHT)
	assert_eq(ArrowGeometry.end_direction(PackedVector2Array([Vector2(1, 1)])), ArrowGeometry.FALLBACK_DIRECTION)


func test_head_is_a_triangle_with_its_tip_on_the_target() -> void:
	var head := ArrowGeometry.head_polygon(TO, Vector2.UP)
	assert_eq(head.size(), 3)
	assert_eq(head[0], TO)
	var base_middle := (head[1] + head[2]) / 2.0
	assert_almost_eq(base_middle.distance_to(TO), ArrowGeometry.HEAD_LENGTH, 0.001)
	assert_almost_eq(head[1].distance_to(head[2]), ArrowGeometry.HEAD_WIDTH, 0.001)
	assert_almost_eq(base_middle.x, TO.x, 0.001, "đáy vuông góc với hướng mũi tên")


func test_head_follows_any_direction() -> void:
	var direction := Vector2(1, 1).normalized()
	var head := ArrowGeometry.head_polygon(Vector2(500, 500), direction)
	var base_middle := (head[1] + head[2]) / 2.0
	assert_almost_eq((Vector2(500, 500) - base_middle).normalized().dot(direction), 1.0, 0.0001)


func test_built_arrow_has_its_shaft_end_where_the_head_begins() -> void:
	var arrow := ArrowGeometry.build(FROM, TO)
	assert_eq(arrow.head[0], TO)
	var base_middle := (arrow.head[1] + arrow.head[2]) / 2.0
	var shaft_end := arrow.shaft[arrow.shaft.size() - 1]
	assert_almost_eq(shaft_end.distance_to(base_middle), 0.0, 0.5, "thân kết thúc ở đáy đầu mũi tên")
	assert_almost_eq(arrow.shaft[0].distance_to(FROM), 0.0, 0.001)


func test_very_short_arrow_has_only_a_head() -> void:
	var arrow := ArrowGeometry.build(FROM, FROM + Vector2(10, 0))
	assert_eq(arrow.shaft.size(), 2)
	assert_eq(arrow.shaft[0], arrow.shaft[1], "thân suy biến thành một điểm")
	assert_eq(arrow.head.size(), 3)


func test_zero_length_arrow_is_safe() -> void:
	var arrow := ArrowGeometry.build(FROM, FROM)
	assert_eq(arrow.head.size(), 3)
	assert_eq(arrow.head[0], FROM)
