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

func show_item(item: Dictionary, global_pos: Vector2, compare_equipped: Dictionary = {}) -> void:
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
	compare_equipped = DataManager.normalize_item(compare_equipped)
	for line in InventoryUtils.sorted_stat_lines(item, compare_equipped):
		lines.append(line)
	var enchant: String = str(item.get("enchant", ""))
	if not enchant.is_empty() and EnhanceSystem.ENCHANTS.has(enchant):
		var ed: Dictionary = EnhanceSystem.ENCHANTS[enchant]
		lines.append("[color=#d4a5ff]附魔: %s[/color]" % ed.get("name", enchant))
	var power: int = _item_power(item)
	lines.append("[color=#888896]战力 %d[/color]" % power)
	if GameManager.is_item_locked(str(item.get("uid", ""))):
		lines.append("[color=#e8b84a]🔒 已锁定（防误售）[/color]")
	if not compare_equipped.is_empty():
		var p_delta: int = power - _item_power(compare_equipped)
		var p_col := "#7dcea0" if p_delta > 0 else ("#e57373" if p_delta < 0 else "#aaaaaa")
		lines.append("对比已装备: [color=%s]%s%d[/color]" % [p_col, "+" if p_delta > 0 else "", p_delta])
	lines.append("[color=#888896]出售价: %d 金币[/color]" % InventoryUtils.sell_price(item))
	lines.append("[color=#666670]单击对比 · 双击装备 · 右键出售 · Shift+锁定[/color]")
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
