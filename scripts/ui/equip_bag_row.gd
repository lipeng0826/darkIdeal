extends PanelContainer
class_name EquipBagRow
## 背包列表行 — 图标 + 名称 + 属性摘要 + 战力差

signal row_hovered(item: Dictionary, global_pos: Vector2)
signal row_unhovered()
signal row_clicked(item: Dictionary)
signal row_double_clicked(item: Dictionary)
signal row_sell_requested(item: Dictionary)
signal row_lock_toggled(item: Dictionary)

var item: Dictionary = {}

var _icon: TextureRect
var _name_l: Label
var _sub_l: Label
var _stats_l: Label
var _delta_l: Label
var _new_l: Label
var _lock_l: Label
var _rarity_bar: ColorRect

func _ready() -> void:
	custom_minimum_size = Vector2(0, 52)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_nodes()
	_apply_style()

func setup(p_item: Dictionary, power_delta: int, is_new: bool, is_locked: bool) -> void:
	item = DataManager.normalize_item(p_item)
	if item.is_empty():
		return
	var rarity: int = int(item.get("rarity", 0))
	var ri: Dictionary = DataManager.RARITY_INFO[rarity as DataManager.Rarity]
	_rarity_bar.color = Color(ri["color"].r, ri["color"].g, ri["color"].b, 0.95)
	var path: String = AssetRegistry.get_equip_icon(item)
	var tex: Texture2D = AssetRegistry.load_texture(path)
	if tex:
		_icon.texture = tex
	_name_l.text = str(item.get("name", ""))
	_name_l.add_theme_color_override("font_color", ri["color"].lerp(Color.WHITE, 0.2))
	_sub_l.text = InventoryUtils.format_item_subtitle(item)
	_stats_l.text = InventoryUtils.format_stat_summary(item, 4)
	if power_delta > 0:
		_delta_l.text = "▲ +%d" % power_delta
		_delta_l.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN)
		_delta_l.visible = true
	elif power_delta < 0:
		_delta_l.text = "▼ %d" % power_delta
		_delta_l.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
		_delta_l.visible = true
	else:
		_delta_l.text = "持平"
		_delta_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
		_delta_l.visible = true
	_new_l.visible = is_new
	_lock_l.visible = is_locked
	var glow := power_delta > 0
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.08, 0.11, 0.96)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.26, 0.24, 0.30, 0.88)
	if glow:
		s.border_color = Color(ri["color"].r, ri["color"].g, ri["color"].b, 0.38)
	add_theme_stylebox_override("panel", s)
	_rarity_bar.color = Color(ri["color"].r, ri["color"].g, ri["color"].b, 0.75 if glow else 0.55)

func _gui_input(event: InputEvent) -> void:
	if item.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.shift_pressed:
				row_lock_toggled.emit(item)
				accept_event()
				return
			if mb.double_click:
				row_double_clicked.emit(item)
			else:
				row_clicked.emit(item)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			row_sell_requested.emit(item)
			accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if not item.is_empty():
			row_hovered.emit(item, get_global_mouse_position())
	elif what == NOTIFICATION_MOUSE_EXIT:
		row_unhovered.emit()

func _apply_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.10, 0.94)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", s)

func _build_nodes() -> void:
	if _icon != null:
		return
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	_rarity_bar = ColorRect.new()
	_rarity_bar.custom_minimum_size = Vector2(4, 0)
	_rarity_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rarity_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_rarity_bar)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	row.add_child(mid)
	_name_l = Label.new()
	_name_l.add_theme_font_size_override("font_size", 12)
	_name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_name_l)
	_sub_l = Label.new()
	_sub_l.add_theme_font_size_override("font_size", 9)
	_sub_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	_sub_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_sub_l)
	_stats_l = Label.new()
	_stats_l.add_theme_font_size_override("font_size", 9)
	_stats_l.add_theme_color_override("font_color", Color(0.55, 0.75, 0.58))
	_stats_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_stats_l)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 2)
	row.add_child(right)
	_delta_l = Label.new()
	_delta_l.add_theme_font_size_override("font_size", 11)
	_delta_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_delta_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_delta_l)
	var badges := HBoxContainer.new()
	badges.alignment = BoxContainer.ALIGNMENT_END
	badges.add_theme_constant_override("separation", 4)
	right.add_child(badges)
	_new_l = Label.new()
	_new_l.text = "新"
	_new_l.add_theme_font_size_override("font_size", 8)
	_new_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	_new_l.visible = false
	_new_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badges.add_child(_new_l)
	_lock_l = Label.new()
	_lock_l.text = "🔒"
	_lock_l.add_theme_font_size_override("font_size", 10)
	_lock_l.visible = false
	_lock_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badges.add_child(_lock_l)
