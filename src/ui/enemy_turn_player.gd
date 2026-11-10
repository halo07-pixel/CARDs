class_name EnemyTurnPlayer
extends Node
## Diễn lượt quái TUẦN TỰ trên một BattleController đã begin_enemy_turn(): mỗi quái có một nhịp "chuẩn bị" (step_started,
## để UI nhấn mạnh quái sắp đi) rồi mới thật sự đi (run_next_enemy), rồi nghỉ một chút trước quái kế tiếp.
## Chạy bằng Timer (không dùng await) nên giải phóng giữa chừng là an toàn. Lõi vẫn là nguồn sự thật:
## ở đây chỉ định NHỊP, không tính gì và không giữ trạng thái logic.

signal step_started(unit: EnemyUnit)  ## quái sắp đi (chưa chạy gì)
signal finished  ## hết lượt quái (hoặc trận đã kết thúc)

enum Phase { IDLE, WINDUP, GAP }

const WINDUP_SECONDS := 0.3  ## từ lúc báo quái sắp đi đến lúc nó đi
const GAP_SECONDS := 0.5  ## từ lúc quái đi xong đến lúc xét quái kế tiếp
const MIN_WAIT := 0.001

var phase: Phase = Phase.IDLE
var _controller: BattleController = null
var _config: EffectsConfig = null
var _timer: Timer


func _init() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(fire_now)
	add_child(_timer)


func is_playing() -> bool:
	return phase != Phase.IDLE


## Bắt đầu diễn lượt quái. Cần controller đang có lượt quái chạy dở (đã begin_enemy_turn), hiệu ứng bật và node đã ở
## trong cây (Timer cần cây); không thì trả false và không làm gì: nơi gọi phải tự chạy nốt lượt quái. Đang diễn dở
## thì bỏ lượt diễn cũ.
func start(controller: BattleController, config: EffectsConfig) -> bool:
	stop()
	if controller == null or config == null or not config.is_enabled() or not is_inside_tree() \
			or not controller.is_enemy_turn_in_progress():
		return false
	_controller = controller
	_config = config
	_advance()
	return true


## Dừng ngay, không phát `finished` (vd. màn bị dỡ giữa chừng). Lõi giữ nguyên trạng thái hiện tại.
func stop() -> void:
	_timer.stop()
	phase = Phase.IDLE
	_controller = null
	_config = null


## Làm ngay bước đang chờ (như thể hết giờ). Test dùng để đẩy nhịp mà không phụ thuộc thời gian thật.
func fire_now() -> void:
	if phase == Phase.IDLE:
		return
	_timer.stop()
	match phase:
		Phase.WINDUP:
			_controller.run_next_enemy()
			_wait(GAP_SECONDS, Phase.GAP)
		Phase.GAP:
			_advance()


func _advance() -> void:
	if not _controller.is_enemy_turn_in_progress():
		_finish()
		return
	var unit := _controller.peek_next_enemy()
	if unit != null:
		step_started.emit(unit)
	if phase == Phase.IDLE and _controller == null:
		return  # bên nghe đã stop() trong tín hiệu
	_wait(WINDUP_SECONDS, Phase.WINDUP)


func _wait(seconds: float, next_phase: Phase) -> void:
	phase = next_phase
	_timer.start(maxf(_config.duration(seconds), MIN_WAIT))


func _finish() -> void:
	stop()
	finished.emit()
