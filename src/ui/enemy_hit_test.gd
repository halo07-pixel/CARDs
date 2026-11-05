class_name EnemyHitTest
extends RefCounted
## Tìm quái SỐNG nằm dưới một điểm trên màn hình (toạ độ toàn cục). Quái chết không bao giờ trúng.


static func unit_at(point: Vector2, enemy_uis: Array[EnemyUI]) -> EnemyUnit:
	for enemy_ui in enemy_uis:
		if enemy_ui.unit != null and enemy_ui.unit.is_alive() and enemy_ui.get_global_rect().has_point(point):
			return enemy_ui.unit
	return null
