class_name PotionRegistry
extends ResourceRegistry
## Tra cứu PotionData theo id và đổi danh sách id (dạng RunState lưu) thành danh sách PotionData.


static func load_from_dir(dir_path: String) -> PotionRegistry:
	var registry := PotionRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_potion(potion_id: StringName) -> PotionData:
	return _find(potion_id) as PotionData


func has_potion(potion_id: StringName) -> bool:
	return has_id(potion_id)


## Các id (không trùng lặp) không có trong registry.
func missing_ids(ids: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	for id in ids:
		if not has_potion(id) and not missing.has(id):
			missing.append(id)
	return missing


## Danh sách PotionData theo đúng thứ tự id. Có id lạ thì trả về mảng RỖNG (không trả nửa chừng).
func resolve(ids: Array[StringName]) -> Array[PotionData]:
	var potions: Array[PotionData] = []
	var missing := missing_ids(ids)
	if not missing.is_empty():
		push_error("PotionRegistry: thiếu potion %s" % [missing])
		return potions
	for id in ids:
		potions.append(get_potion(id))
	return potions


func _id_of(resource: Resource) -> StringName:
	return (resource as PotionData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as PotionData
	if data == null:
		var wrong_type: Array[String] = ["không phải PotionData"]
		return wrong_type
	return data.validate()
