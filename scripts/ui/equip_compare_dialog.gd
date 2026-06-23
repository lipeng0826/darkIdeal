extends Control
class_name EquipCompareDialog
## 装备对比弹窗 - 双击背包装备时展示

signal equip_confirmed(item: Dictionary)
signal closed

var _new_item: Dictionary = {}
var _old_item: Dictionary = {}

var _overlay: ColorRect
var _panel: PanelContainer
var _title: Label
var _compare_body: RichTextLabel
var _equip_btn: Button
var _cancel_btn: Button

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if _equip_btn:
		_equip_btn.pressed.connect(_on_equip)
	if _cancel_btn:
		_cancel_btn.pressed.connect(_on_cancel)

func open(new_item: Dictionary, old_item: Dictionary = {}) -> void:
	_new_item = DataManager.normalize_item(new_item)
	_old_item = DataManager.normalize_item(old_item) if old_item != null else {}
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _title:
		_title.text = "装备对比"
	if _compare_body:
		_compare_body.text = _build_compare_bbcode(_new_item, _old_item)
	if _equip_btn:
		var delta: int = _item_power(_new_item) - _item_power(_old_item)
		if _old_item.is_empty():
			_equip_btn.text = "装备"
		elif delta > 0:
			_equip_btn.text = "替换 (+%d)" % delta
			_equip_btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
		elif delta < 0:
			_equip_btn.text = "仍要替换 (%d)" % delta
			_equip_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.75))
		else:
			_equip_btn.text = "替换 (持平)"
			_equip_btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)

func _on_equip() -> void:
	if not _new_item.is_empty():
		equip_confirmed.emit(_new_item)
	_close()

func _on_cancel() -> void:
	_close()

func dismiss() -> void:
	_close()

func _close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()

func _build_compare_bbcode(new_item: Dictionary, old_item: Dictionary) -> String:
	var lines: PackedStringArray = []
	var new_r: Dictionary = DataManager.RARITY_INFO[int(new_item["rarity"]) as DataManager.Rarity]
	lines.append("[b][color=#%s]%s[/color][/b]  [color=#888896]vs[/color]  %s" % [
		new_r["color"].to_html(false),
		new_item["name"],
		"[color=#666670]空[/color]" if old_item.is_empty() else old_item["name"],
	])
	if not old_item.is_empty():
		var old_r: Dictionary = DataManager.RARITY_INFO[int(old_item["rarity"]) as DataManager.Rarity]
		lines.append("[color=#888896]%s[/color]  vs  [color=#%s]%s[/color]" % [
			new_r["name"], old_r["color"].to_html(false), old_r["name"],
		])
	lines.append("")
	var all_stats: Dictionary = {}
	for sk in new_item.get("stats", {}):
		all_stats[int(sk)] = true
	for sk2 in old_item.get("stats", {}):
		all_stats[int(sk2)] = true
	var stat_keys: Array = all_stats.keys()
	stat_keys.sort()
	for stat_i in stat_keys:
		var info: Dictionary = DataManager.STAT_INFO.get(int(stat_i), {})
		var new_stats: Dictionary = new_item.get("stats", {})
		var old_stats: Dictionary = old_item.get("stats", {}) if not old_item.is_empty() else {}
		var new_v: int = DataManager.get_item_stat(new_stats, int(stat_i))
		var old_v: int = DataManager.get_item_stat(old_stats, int(stat_i))
		var delta: int = new_v - old_v
		var suffix := "%" if stat_i in [DataManager.StatType.CRIT, DataManager.StatType.CRIT_DMG, DataManager.StatType.LIFESTEAL] else ""
		var delta_str := ""
		if old_item.is_empty():
			if new_v > 0:
				delta_str = " [color=#7dcea0](新)[/color]"
		elif delta > 0:
			delta_str = " [color=#7dcea0](+%d%s)[/color]" % [delta, suffix]
		elif delta < 0:
			delta_str = " [color=#e57373](%d%s)[/color]" % [delta, suffix]
		if new_v > 0 or old_v > 0:
			var old_txt := str(old_v) if not old_item.is_empty() else "-"
			lines.append("%s %s: [color=#ddd]%d%s[/color] → [color=#fff]%d%s[/color]%s" % [
				info.get("icon", ""), info.get("short", ""), old_v, suffix, new_v, suffix, delta_str,
			])
	var p_new: int = _item_power(new_item)
	var p_old: int = _item_power(old_item) if not old_item.is_empty() else 0
	var p_delta: int = p_new - p_old
	var p_color := "#7dcea0" if p_delta > 0 else ("#e57373" if p_delta < 0 else "#aaaaaa")
	lines.append("")
	lines.append("战力: %d → [color=%s]%d[/color] (%s%d)" % [
		p_old, p_color, p_new, "+" if p_delta >= 0 else "", p_delta,
	])
	return "\n".join(lines)

func _item_power(item: Dictionary) -> int:
	return DataManager.item_power(DataManager.normalize_item(item))

func _build_ui() -> void:
	if _panel != null:
		return
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.45)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			dismiss())
	add_child(_overlay)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(300, 0)
	center.add_child(_panel)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.13, 0.98)
	ps.corner_radius_top_left = 14
	ps.corner_radius_top_right = 14
	ps.corner_radius_bottom_left = 14
	ps.corner_radius_bottom_right = 14
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.55, 0.45, 0.65, 0.8)
	ps.content_margin_left = 16.0
	ps.content_margin_right = 16.0
	ps.content_margin_top = 14.0
	ps.content_margin_bottom = 14.0
	_panel.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72))
	vbox.add_child(_title)
	_compare_body = RichTextLabel.new()
	_compare_body.bbcode_enabled = true
	_compare_body.fit_content = true
	_compare_body.scroll_active = false
	_compare_body.custom_minimum_size = Vector2(268, 0)
	_compare_body.add_theme_font_size_override("normal_font_size", 11)
	_compare_body.add_theme_color_override("default_color", Color(0.85, 0.83, 0.90))
	vbox.add_child(_compare_body)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)
	_cancel_btn = Button.new()
	_cancel_btn.text = "取消"
	_cancel_btn.custom_minimum_size = Vector2(100, 32)
	_style_btn_outline(_cancel_btn)
	footer.add_child(_cancel_btn)
	_equip_btn = Button.new()
	_equip_btn.text = "装备"
	_equip_btn.custom_minimum_size = Vector2(120, 32)
	_style_btn_primary(_equip_btn)
	footer.add_child(_equip_btn)

func _style_btn_primary(btn: Button) -> void:
	var n := ThemeConfig.make_btn_primary()
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)

func _style_btn_outline(btn: Button) -> void:
	var n := ThemeConfig.make_btn_outline(ThemeConfig.TXT_SECONDARY)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
