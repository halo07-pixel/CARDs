class_name EffectsConfig
extends RefCounted
## Cài đặt hiệu ứng trình diễn (chữ nổi, thanh máu mượt, rung, nảy). speed = 0 tắt hẳn: mọi hiệu ứng
## không làm gì và kết quả hiển thị đúng ngay (test và chế độ "giảm chuyển động" dùng). Lõi không biết gì ở đây.

const NORMAL_SPEED := 1.0

## 0 = tắt; 1 = bình thường; 2 = nhanh gấp đôi (thời lượng giảm một nửa)...
var speed: float = 0.0


func is_enabled() -> bool:
	return speed > 0.0


## Thời lượng thật (giây) của một hiệu ứng thiết kế dài `seconds` ở tốc độ 1. Tắt -> 0.
func duration(seconds: float) -> float:
	return seconds / speed if speed > 0.0 else 0.0
