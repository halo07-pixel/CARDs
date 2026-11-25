extends SceneTree
## Vẽ bản đồ của một seed ra ảnh PNG tĩnh để xem bằng mắt (màn bản đồ thật ở mốc 4.5). Không cần cửa sổ: chỉ dùng Image.
##   godot --headless --path . -s res://tools/capture_map.gd -- --seed=7 --out=/tmp/map_7.png
## Màu: Monster xám đỏ, Elite đỏ, Campfire cam, Shop vàng, Event xanh dương, Treasure xanh lá, Boss tím.

const COLORS := {
	RoomType.Kind.MONSTER: Color("8d6e6e"),
	RoomType.Kind.ELITE: Color("e53935"),
	RoomType.Kind.CAMPFIRE: Color("fb8c00"),
	RoomType.Kind.SHOP: Color("fdd835"),
	RoomType.Kind.EVENT: Color("1e88e5"),
	RoomType.Kind.TREASURE: Color("43a047"),
	RoomType.Kind.BOSS: Color("8e24aa"),
}
const BACKGROUND := Color("1c1f2b")
const EDGE_COLOR := Color("aab0c0")
const CELL_X := 130
const CELL_Y := 80
const MARGIN := 80
const NODE_HALF := 22


func _initialize() -> void:
	var run_seed := 1
	var path := "/tmp/map.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			run_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--out="):
			path = arg.trim_prefix("--out=")
	var map := MapGenerator.generate(run_seed)
	var width := MARGIN * 2 + CELL_X * (map.columns - 1)
	var height := MARGIN * 2 + CELL_Y * map.floors
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(BACKGROUND)
	for floor_index in map.floors:
		for node in map.nodes_on_floor(floor_index):
			for next in map.next_nodes(node.id):
				_line(image, _center(map, node, height), _center(map, next, height), EDGE_COLOR)
	for floor_index in range(0, map.floors + 1):
		for node in map.nodes_on_floor(floor_index):
			var center := _center(map, node, height)
			var half := NODE_HALF + (10 if node.kind == RoomType.Kind.BOSS else 0)
			image.fill_rect(Rect2i(center.x - half - 2, center.y - half - 2, half * 2 + 4, half * 2 + 4), BACKGROUND)
			image.fill_rect(Rect2i(center.x - half, center.y - half, half * 2, half * 2), COLORS[node.kind])
	print("seed=%d nút=%d lỗi=%s -> %s (lỗi lưu=%d)" % [run_seed, map.node_count(), map.validate(), path, image.save_png(path)])
	quit()


func _center(map: RunMap, node: MapNode, height: int) -> Vector2i:
	return Vector2i(MARGIN + node.column * CELL_X, height - MARGIN - node.floor_index * CELL_Y)


func _line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in range(steps + 1):
		var t := float(i) / maxf(steps, 1)
		var x := int(round(lerpf(from.x, to.x, t)))
		var y := int(round(lerpf(from.y, to.y, t)))
		image.fill_rect(Rect2i(x - 1, y - 1, 3, 3), color)
