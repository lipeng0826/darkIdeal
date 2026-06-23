extends PanelContainer
class_name EquipTooltip
## 装备悬停提示

var _title: Label
var _body: RichTextLabel

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	custom_minimum_size = Vector2(180, 0)
	_build_nodes()
	_apply_style()

func show_item(item: Dictionary, global_pos: Vector2) -> void:
	item = DataManager.normalize_item(item)
	if item.is_empty():
		hide_tooltip()
		return
	_build_nodes()
	var rarity: int = int(item.get("rarity", 0))
	var ri: Dictionary = DataManager.RARITY_INFO[rarity as DataManager.Rarity]
	var enh: int = int(item.get("enhance_level", 0))
	var title: String = str(item["name"])
	if enh > 0:
		title += "  +%d" % enh
	_title.text = title
	_title.add_theme_color_override("font_color", ri["color"])
	var lines: PackedStringArray = []
	lines.append("[color=#888896]%s · Lv.%d[/color]" % [ri["name"], int(item.get("level", 1))])
	var slot_i: int = int(item.get("slot", 0))
	lines.append("[color=#888896]%s[/color]" % DataManager.SLOT_NAMES.get(slot_i as DataManager.SlotType, ""))
	for stat_key in item.get("stats", {}):
		var stat_i: int = int(stat_key)
		var stats: Dictionary = item.get("stats", {})
		var val: int = DataManager.get_item_stat(stats, stat_i)
		if val <= 0:
			continue
		var info: Dictionary = DataManager.STAT_INFO.get(stat_i, {})
		var suffix := "%" if stat_i in [DataManager.StatType.CRIT, DataManager.StatType.CRIT_DMG, DataManager.StatType.LIFESTEAL] else ""
		lines.append("%s %s: [color=#c8e6c9]+%d%s[/color]" % [info.get("icon", ""), info.get("short", ""), val, suffix])
	var enchant: String = str(item.get("enchant", ""))
	if not enchant.is_empty() and EnhanceSystem.ENCHANTS.has(enchant):
		var ed: Dictionary = EnhanceSystem.ENCHANTS[enchant]
		lines.append("[color=#d4a5ff]附魔: %s[/color]" % ed.get("name", enchant))
	lines.append("[color=#888896]战力 %d[/color]" % _item_power(item))
	_body.text = "\n".join(lines)
	visible = true
	var parent_ctrl: Control = get_parent() as Control
	var local_pos: Vector2 = global_pos
	if parent_ctrl:
		local_pos = parent_ctrl.get_global_transform_with_canvas().affine_inverse() * global_pos
	position = local_pos + Vector2(12, 12)
	var parent_size: Vector2 = parent_ctrl.size if parent_ctrl else get_viewport_rect().size
	if position.x + custom_minimum_size.x > parent_size.x - 8:
		position.x = local_pos.x - custom_minimum_size.x - 12
	if position.y + 120 > parent_size.y - 8:
		position.y = maxf(8, local_pos.y - 100)

func hide_tooltip() -> void:
	visible = false

func _item_power(item: Dictionary) -> int:
	return DataManager.item_power(DataManager.normalize_item(item))

func _apply_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.05, 0.09, 0.96)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.45, 0.38, 0.55, 0.7)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 10.0
	s.content_margin_right = 10.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", s)

func _build_nodes() -> void:
	if _title != null:
		return
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_title)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(160, 0)
	_body.add_theme_font_size_override("normal_font_size", 10)
	_body.add_theme_color_override("default_color", Color(0.82, 0.80, 0.88))
	vbox.add_child(_body)
