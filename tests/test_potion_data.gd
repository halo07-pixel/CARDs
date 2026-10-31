extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const POTION_DIR := "res://data/potions"
const T := EffectData.Type
const G := EffectData.Target
const M := CardData.TargetMode


func _potion(id: StringName, mode: CardData.TargetMode, effects: Array[EffectData], props: Dictionary = {}) -> PotionData:
	var data := PotionData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.target_mode = mode
	data.effects = effects
	for key: String in props:
		data.set(key, props[key])
	return data


func _heal_potion(id: StringName = &"p") -> PotionData:
	var effects: Array[EffectData] = [EffectData.create(T.HEAL, 10, G.SELF)]
	return _potion(id, M.SELF, effects)


func test_valid_potions_for_every_target_mode() -> void:
	assert_eq(_heal_potion().validate(), [] as Array[String])
	var single: Array[EffectData] = [EffectData.create(T.DAMAGE, 20, G.TARGET_ENEMY)]
	assert_eq(_potion(&"fire", M.SINGLE_ENEMY, single).validate(), [] as Array[String])
	var everyone: Array[EffectData] = [EffectData.create(T.DAMAGE, 10, G.ALL_ENEMIES)]
	assert_eq(_potion(&"boom", M.ALL_ENEMIES, everyone).validate(), [] as Array[String])


func test_basic_field_rules() -> void:
	assert_false(_potion(&"", M.SELF, _heal_potion().effects).validate().is_empty(), "id trống")
	var nameless := _heal_potion()
	nameless.display_name = "  "
	assert_false(nameless.validate().is_empty())
	var none: Array[EffectData] = []
	assert_false(_potion(&"empty", M.SELF, none).validate().is_empty(), "không có effect")


func test_target_mode_must_match_the_effects() -> void:
	var single: Array[EffectData] = [EffectData.create(T.DAMAGE, 20, G.TARGET_ENEMY)]
	assert_false(_potion(&"bad", M.SELF, single).validate().is_empty())
	assert_false(_potion(&"bad2", M.ALL_ENEMIES, single).validate().is_empty())


func test_effect_errors_are_prefixed_with_index() -> void:
	var broken: Array[EffectData] = [EffectData.create(T.BLOCK, 0, G.SELF)]
	var errors := _potion(&"x", M.SELF, broken).validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("effects[0]"))


func test_potions_cannot_use_x_scaling_or_event_source() -> void:
	var scaling := EffectData.create(T.BLOCK, 5, G.SELF)
	scaling.scales_with_x = true
	var effects: Array[EffectData] = [scaling]
	assert_false(_potion(&"x", M.SELF, effects).validate().is_empty())
	var source: Array[EffectData] = [EffectData.create(T.DAMAGE, 5, G.EVENT_SOURCE)]
	assert_false(_potion(&"y", M.NONE, source).validate().is_empty(), "EVENT_SOURCE chỉ dùng trong trigger")


func test_enum_numbers_are_stable() -> void:
	assert_eq([PotionData.Rarity.COMMON, PotionData.Rarity.UNCOMMON, PotionData.Rarity.RARE], [0, 1, 2])


## --- Dữ liệu thật ---

func test_starter_potions_are_valid_and_have_designed_values() -> void:
	var registry := PotionRegistry.load_from_dir(POTION_DIR)
	assert_eq(registry.size(), 8, "8 potion mẫu (file lỗi/trùng id sẽ bị loại)")
	for id in registry.all_ids():
		assert_eq(registry.get_potion(id).validate(), [] as Array[String], String(id))
	var fire := registry.get_potion(&"fire_potion")
	assert_eq([fire.target_mode, fire.effects[0].type, fire.effects[0].amount], [M.SINGLE_ENEMY, T.DAMAGE, 20])
	var boom := registry.get_potion(&"explosive_potion")
	assert_eq([boom.target_mode, boom.effects[0].target, boom.effects[0].amount], [M.ALL_ENEMIES, G.ALL_ENEMIES, 10])
	assert_eq(registry.get_potion(&"block_potion").effects[0].amount, 12)
	assert_eq(registry.get_potion(&"strength_potion").effects[0].status_id, &"strength")
	assert_eq(registry.get_potion(&"energy_potion").effects[0].type, T.GAIN_ENERGY)
	assert_eq(registry.get_potion(&"swift_potion").effects[0].amount, 3)
	var weak := registry.get_potion(&"weak_potion")
	assert_eq([weak.target_mode, weak.effects[0].status_id, weak.effects[0].amount], [M.SINGLE_ENEMY, &"weak", 3])
	var blood := registry.get_potion(&"blood_potion")
	assert_eq([blood.effects[0].type, blood.effects[0].amount, blood.rarity], [T.HEAL, 12, PotionData.Rarity.UNCOMMON])


## --- Registry ---

func test_registry_rejects_wrong_type_duplicate_invalid_and_null() -> void:
	var registry := PotionRegistry.new()
	assert_true(registry.register(_heal_potion(&"a")))
	assert_false(registry.register(_heal_potion(&"a")), "trùng id")
	assert_false(registry.register(PotionData.new()), "không hợp lệ")
	assert_false(registry.register(Factory.weak()), "sai kiểu (StatusData)")
	assert_false(registry.register(null))
	assert_eq(registry.size(), 1)
	assert_true(registry.get_potion(&"nope") == null)
	assert_true(registry.has_potion(&"a"))


func test_resolve_keeps_order_and_returns_nothing_for_unknown_ids() -> void:
	var registry := PotionRegistry.load_from_dir(POTION_DIR)
	var ids: Array[StringName] = [&"swift_potion", &"fire_potion"]
	assert_eq(registry.resolve(ids).map(func(p: PotionData) -> StringName: return p.id), [&"swift_potion", &"fire_potion"])
	var bad: Array[StringName] = [&"fire_potion", &"ghost"]
	assert_eq(registry.resolve(bad).size(), 0, "không trả nửa chừng")
	var dupes: Array[StringName] = [&"ghost", &"phantom", &"ghost"]
	assert_eq(registry.missing_ids(dupes), [&"ghost", &"phantom"] as Array[StringName])
