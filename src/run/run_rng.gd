class_name RunRng
extends RefCounted
## Tách seed của run thành các luồng RNG độc lập theo lĩnh vực (bản đồ, phần thưởng, cửa hàng...). Cùng (seed, luồng, chỉ số)
## luôn cho cùng một seed con, và các luồng không ảnh hưởng nhau: làm việc này không "đổi vận" việc kia.
## Dùng SHA-256 của chuỗi để kết quả ổn định giữa các phiên bản Godot (String.hash() không được bảo đảm như vậy).


## Seed con cho luồng `stream` (vd. &"map", &"reward"), chỉ số `index` (vd. số act hoặc số phòng).
static func derive(run_seed: int, stream: StringName, index: int = 0) -> int:
	var digest := ("%d|%s|%d" % [run_seed, stream, index]).sha256_buffer()
	return digest.decode_s64(0)


## Một bộ sinh số ngẫu nhiên đã gieo sẵn cho luồng đó.
static func make(run_seed: int, stream: StringName, index: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = derive(run_seed, stream, index)
	return rng
