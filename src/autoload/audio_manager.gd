extends Node
## Quản lý bus, SFX (pool) và nhạc. Thiếu file âm thanh thì cảnh báo 1 lần rồi bỏ qua.
## Lắng nghe EventBus; UI chỉ cần phát sfx_requested, không biết gì về AudioManager.

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const EXTENSIONS: Array[String] = [".ogg", ".wav", ".mp3"]
const SFX_POOL_SIZE := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player := AudioStreamPlayer.new()
var _missing_logged: Dictionary = {}


func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	EventBus.sfx_requested.connect(play_sfx)
	EventBus.music_requested.connect(play_music)
	EventBus.settings_changed.connect(apply_settings)
	apply_settings(SaveSystem.load_settings())


func apply_settings(settings: Dictionary) -> void:
	set_bus_volume(&"Master", float(settings.get("master_volume", 1.0)))
	set_bus_volume(BUS_MUSIC, float(settings.get("music_volume", 0.8)))
	set_bus_volume(BUS_SFX, float(settings.get("sfx_volume", 0.8)))


## linear 0..1; trả về false nếu bus không tồn tại.
func set_bus_volume(bus_name: StringName, linear: float) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		push_error("AudioManager: không có bus %s" % bus_name)
		return false
	var clamped := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(clamped))
	AudioServer.set_bus_mute(index, is_zero_approx(clamped))
	return true


func play_sfx(sfx_name: StringName) -> bool:
	var stream := _find_stream(SFX_DIR, sfx_name)
	if stream == null:
		return false
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return true
	return false  # pool đầy: bỏ qua tiếng này thay vì cắt tiếng khác


## Dừng mọi tiếng SFX đang phát (vd. khi đổi màn). Không đụng tới nhạc.
func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()


func play_music(track_name: StringName) -> bool:
	var stream := _find_stream(MUSIC_DIR, track_name)
	if stream == null:
		return false
	if _music_player.stream == stream and _music_player.playing:
		return true
	_music_player.stream = stream
	_music_player.play()
	return true


func stop_music() -> void:
	_music_player.stop()


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")


func _find_stream(dir: String, asset_name: StringName) -> AudioStream:
	for ext in EXTENSIONS:
		var path := dir + String(asset_name) + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	if not _missing_logged.has(asset_name):
		_missing_logged[asset_name] = true
		push_warning("AudioManager: thiếu âm thanh '%s' trong %s" % [asset_name, dir])
	return null
