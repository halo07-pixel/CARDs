class_name TooltipPlacement
extends RefCounted
## Tính góc trên-trái của tooltip so với vùng "neo" (control đang được trỏ vào) sao cho tooltip luôn nằm
## trong màn hình. Ưu tiên bên phải neo, hết chỗ thì sang bên trái; theo chiều dọc căn đầu neo rồi kẹp vào màn hình.

const GAP := 12.0
const MARGIN := 8.0


static func place(anchor: Rect2, tooltip_size: Vector2, screen: Vector2) -> Vector2:
	var x := anchor.end.x + GAP
	if x + tooltip_size.x > screen.x - MARGIN:
		x = anchor.position.x - GAP - tooltip_size.x
	x = clampf(x, MARGIN, maxf(MARGIN, screen.x - MARGIN - tooltip_size.x))
	var y := clampf(anchor.position.y, MARGIN, maxf(MARGIN, screen.y - MARGIN - tooltip_size.y))
	return Vector2(x, y)
