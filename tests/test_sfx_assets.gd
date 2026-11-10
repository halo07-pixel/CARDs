extends "res://tests/test_case.gd"
## Tài sản âm thanh: mỗi tên trong SfxMap có tệp thật nạp được, độ dài hợp lý, và nguồn gốc/giấy phép được ghi lại.

const SFX_DIR := "res://assets/audio/sfx/"
const CREDITS_PATH := "res://assets/CREDITS.md"
const LICENSE_DIR := "res://assets/audio/licenses/"
const PACKS: Array[String] = ["casinoaudio", "impactsounds", "rpgaudio", "interfacesounds"]
const MIN_LENGTH := 0.05
const MAX_LENGTH := 3.0


func test_every_sound_in_the_map_has_a_loadable_file_of_sensible_length() -> void:
	for sfx in SfxMap.ALL:
		var path := "%s%s.ogg" % [SFX_DIR, sfx]
		assert_true(ResourceLoader.exists(path), "thiếu tệp %s" % path)
		var stream := load(path) as AudioStream
		assert_true(stream != null, "không nạp được %s" % path)
		if stream != null:
			assert_true(stream.get_length() >= MIN_LENGTH and stream.get_length() <= MAX_LENGTH,
					"%s dài %.2f giây (ngoài [%.2f, %.2f])" % [sfx, stream.get_length(), MIN_LENGTH, MAX_LENGTH])


func test_no_stray_sound_files_without_a_map_entry() -> void:
	var dir := DirAccess.open(SFX_DIR)
	assert_true(dir != null)
	for file in dir.get_files():
		if file.ends_with(".ogg"):
			assert_true(SfxMap.ALL.has(StringName(file.get_basename())), "tệp %s không có trong SfxMap.ALL" % file)


func test_every_pack_has_its_license_file_and_it_says_cc0() -> void:
	for pack in PACKS:
		var path := "%skenney-%s-License.txt" % [LICENSE_DIR, pack]
		assert_true(FileAccess.file_exists(path), "thiếu giấy phép: %s" % path)
		assert_true(FileAccess.get_file_as_string(path).contains("Creative Commons Zero"), "%s phải là CC0" % pack)


func test_credits_list_every_source_pack_and_every_sound_file() -> void:
	var credits := FileAccess.get_file_as_string(CREDITS_PATH)
	for pack in PACKS:
		assert_true(credits.contains("kenney_%s" % pack), "CREDITS thiếu gói kenney_%s" % pack)
	for sfx in SfxMap.ALL:
		assert_true(credits.contains("%s.ogg" % sfx), "CREDITS thiếu tệp %s.ogg" % sfx)
