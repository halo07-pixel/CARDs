class_name CardRegistry
extends ResourceRegistry
## Tra cứu CardData theo id và tạo CardInstance từ danh sách id (dạng RunState lưu).


static func load_from_dir(dir_path: String) -> CardRegistry:
	var registry := CardRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_card(card_id: StringName) -> CardData:
	return _find(card_id) as CardData


func has_card(card_id: StringName) -> bool:
	return has_id(card_id)


## Các id (không trùng lặp) không có trong registry.
func missing_ids(ids: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	for id in ids:
		if not has_card(id) and not missing.has(id):
			missing.append(id)
	return missing


## Mỗi id -> một CardInstance riêng. Có id lạ thì trả về mảng RỖNG (không tạo nửa chừng).
func create_instances(ids: Array[StringName]) -> Array[CardInstance]:
	var instances: Array[CardInstance] = []
	var missing := missing_ids(ids)
	if not missing.is_empty():
		push_error("CardRegistry: thiếu thẻ %s" % [missing])
		return instances
	for id in ids:
		instances.append(CardInstance.create(get_card(id)))
	return instances


## Lỗi liên kết giữa các thẻ: upgraded_id trỏ tới thẻ không tồn tại.
func link_errors() -> Array[String]:
	var errors: Array[String] = []
	for card: CardData in _by_id.values():
		if not card.upgraded_id.is_empty() and not has_card(card.upgraded_id):
			errors.append("%s -> upgraded_id '%s' không tồn tại" % [card.id, card.upgraded_id])
	return errors


## Bản nâng cấp của thẻ, hoặc null nếu thẻ không có/không tồn tại.
func upgraded(card_id: StringName) -> CardData:
	var card := get_card(card_id)
	if card == null or card.upgraded_id.is_empty():
		return null
	return get_card(card.upgraded_id)


## Kiểm tra DỮ LIỆU: bản "+" không được yếu hơn bản gốc ở bất kỳ điểm nào và phải tốt hơn ở ít nhất một điểm.
func upgrade_problems() -> Array[String]:
	var problems: Array[String] = []
	for id in all_ids():
		var base := get_card(id)
		var improved := get_card(base.upgraded_id) if not base.upgraded_id.is_empty() else null
		if improved != null:  # liên kết hỏng đã có link_errors()
			problems.append_array(_compare_upgrade(base, improved))
	return problems


static func _compare_upgrade(base: CardData, up: CardData) -> Array[String]:
	var problems: Array[String] = []
	var label := "%s -> %s" % [base.id, up.id]
	if up.card_type != base.card_type or up.character_id != base.character_id \
			or up.rarity != base.rarity or up.target_mode != base.target_mode:
		problems.append("%s: loại/nhân vật/độ hiếm/kiểu nhắm phải giữ nguyên" % label)
	if up.is_x_cost != base.is_x_cost or up.unplayable != base.unplayable:
		problems.append("%s: X-cost/unplayable phải giữ nguyên" % label)
	if up.cost > base.cost:
		problems.append("%s: cost tăng (%d -> %d)" % [label, base.cost, up.cost])
	if (up.exhaust and not base.exhaust) or (up.ethereal and not base.ethereal) \
			or (base.retain and not up.retain) or (base.innate and not up.innate):
		problems.append("%s: từ khóa bị xấu đi (thêm exhaust/ethereal hoặc mất retain/innate)" % label)
	if up.x_bonus < base.x_bonus:
		problems.append("%s: x_bonus giảm" % label)
	var better := up.cost < base.cost or up.x_bonus > base.x_bonus \
			or (base.exhaust and not up.exhaust) or (base.ethereal and not up.ethereal)
	var base_totals := _effect_totals(base)
	var up_totals := _effect_totals(up)
	for key: String in base_totals:
		var before: int = base_totals[key]
		var after: int = up_totals.get(key, 0)
		var is_self_cost := key.begins_with("LOSE_HP|SELF|")  # mất máu: ÍT hơn mới tốt
		if (after > before) if not is_self_cost else (after < before):
			better = true
		elif after != before:
			problems.append("%s: %s yếu đi (%d -> %d)" % [label, key, before, after])
	for key: String in up_totals:
		if not base_totals.has(key):
			better = true
	if not better:
		problems.append("%s: bản nâng cấp không tốt hơn bản gốc ở điểm nào" % label)
	return problems


## Tổng (amount x hits) của mọi effect, gom theo (loại, đích, status).
static func _effect_totals(card: CardData) -> Dictionary:
	var totals := {}
	for effect in card.effects:
		var key := "%s|%s|%s" % [EffectData.Type.keys()[effect.type], EffectData.Target.keys()[effect.target],
				effect.status_id]
		totals[key] = totals.get(key, 0) + effect.amount * effect.hits
	return totals


func _id_of(resource: Resource) -> StringName:
	return (resource as CardData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as CardData
	if data == null:
		var wrong_type: Array[String] = ["không phải CardData"]
		return wrong_type
	return data.validate()
