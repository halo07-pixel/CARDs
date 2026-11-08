class_name RelicIconUI
extends BadgeUI
## Icon một relic trên thanh relic. Chỉ để xem: hover -> tooltip (báo lên), không bấm được gì.

signal tooltip_requested(tooltip: TooltipView, anchor: Rect2)
signal tooltip_cleared

const RARITY_COLORS := {
	RelicData.Rarity.STARTER: Color("8a8f98"),
	RelicData.Rarity.COMMON: Color("b8bcc4"),
	RelicData.Rarity.UNCOMMON: Color("5aa9ff"),
	RelicData.Rarity.RARE: Color("ffc94a"),
	RelicData.Rarity.BOSS: Color("ff6a6a"),
	RelicData.Rarity.SHOP: Color("7ee06a"),
}

var view: RelicView = null


func _init() -> void:
	super()
	hover_started.connect(_emit_tooltip)
	hover_ended.connect(tooltip_cleared.emit)


func show_view(new_view: RelicView) -> void:
	if new_view == null:
		push_error("RelicIconUI.show_view: view null")
		return
	view = new_view
	show_badge(view.icon_id, view.title, RARITY_COLORS.get(view.rarity, Color.WHITE))


func _emit_tooltip() -> void:
	if view != null:
		tooltip_requested.emit(TooltipBuilder.for_relic(view), get_global_rect())
