extends PanelContainer
class_name EquipItemSlot
## 装备图标槽位 — 品质边框、战力角标、单击/双击/右键

signal slot_hovered(item: Dictionary, global_pos: Vector2)
signal slot_unhovered()
signal slot_clicked(item: Dictionary)
signal slot_double_clicked(item: Dictionary)
signal slot_sell_requested(item: Dictionary)
signal slot_lock_toggled(item: Dictionary)

var item: Dictionary = {}
var slot_index: int = -1
var is_empty := true

var _icon_rect: TextureRect
var _slot_label: Label
var _name_label: Label
var _enh_label: Label
var _level_label: Label
var _delta_label: Label
var _new_label: Label
var _rarity_strip: ColorRect
var _lock_label: Label
var _upgrade_hint: Label

const SLOT_SIZE := Vector2(76, 88)

func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_nodes()

func setup_empty(slot_i: int, slot_name: String) -> void:
	_ensure_nodes()
	item = {}
	slot_index = slot_i
	is_empty = true
	_slot_label.text = slot_name
	_slot_label.visible = true
	_name_label.text = slot_name
	_name_label.visible = true
	_enh_label.visible = false
	_level_label.visible = false
	_delta_label.visible = false
	_new_label.visible = false
	if _lock_label:
		_lock_label.visible = false
	if _upgrade_hint:
		_upgrade_hint.visible = false
	if _rarity_strip:
		_rarity_strip.color = Color(0.35, 0.34, 0.38, 0.5)
	var path: String = AssetRegistry.get_slot_fallback_icon(slot_i)
	_set_icon(path, 0.35)
	_apply_border(ThemeConfig.TXT_DISABLED, false)

func setup_item(
	p_item: Dictionary,
	show_slot_label: bool = false,
	power_delta: int = 999999,
	is_new: bool = false,
	is_locked: bool = false,
	show_upgrade_hint: bool = false,
) -> void:
	_ensure_nodes()
	item = p_item
	slot_index = int(p_item.get("slot", -1))
	is_empty = false
	_slot_label.visible = show_slot_label
	if show_slot_label:
		_slot_label.text = DataManager.SLOT_NAMES.get(slot_index as DataManager.SlotType, "")
	var path: String = AssetRegistry.get_equip_icon(p_item)
	_set_icon(path, 1.0)
	var rarity: int = int(p_item.get("rarity", 0))
	var ri: Dictionary = DataManager.RARITY_INFO[rarity as DataManager.Rarity]
	var is_upgrade: bool = power_delta > 0 and power_delta != 999999
	_apply_border(ri["color"], is_upgrade)
	if _rarity_strip:
		_rarity_strip.color = Color(ri["color"].r, ri["color"].g, ri["color"].b, 0.95)
	var short_name: String = str(p_item.get("name", ""))
	if short_name.length() > 7:
		short_name = short_name.substr(0, 6) + "…"
	_name_label.text = short_name
	_name_label.visible = not show_slot_label
	_name_label.add_theme_color_override("font_color", ri["color"].lerp(Color.WHITE, 0.25))
	var enh: int = int(p_item.get("enhance_level", 0))
	if enh > 0:
		_enh_label.text = "+%d" % enh
		_enh_label.visible = true
	else:
		_enh_label.visible = false
	var lv: int = int(p_item.get("level", 1))
	_level_label.text = "Lv.%d" % lv
	_level_label.visible = true
	if power_delta == 999999:
		_delta_label.visible = false
	elif power_delta > 0:
		_delta_label.text = "▲%d" % power_delta
		_delta_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN)
		_delta_label.visible = true
	elif power_delta < 0:
		_delta_label.text = "▼%d" % abs(power_delta)
		_delta_label.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
		_delta_label.visible = true
	else:
		_delta_label.text = "="
		_delta_label.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
		_delta_label.visible = true
	_new_label.visible = is_new
	if _lock_label:
		_lock_label.visible = is_locked
	if _upgrade_hint:
		_upgrade_hint.visible = show_upgrade_hint

func _set_icon(path: String, alpha: float) -> void:
	var tex: Texture2D = AssetRegistry.load_texture(path)
	if tex:
		_icon_rect.texture = tex
	_icon_rect.modulate = Color(1, 1, 1, alpha)

func _apply_border(color: Color, glow: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.10, 0.94)
	var bw := 3 if glow else 2
	s.border_width_left = bw
	s.border_width_right = bw
	s.border_width_top = bw
	s.border_width_bottom = bw
	s.border_color = Color(color.r, color.g, color.b, 0.95 if glow else 0.75)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	if glow:
		s.shadow_color = Color(color.r, color.g, color.b, 0.35)
		s.shadow_size = 4
	add_theme_stylebox_override("panel", s)

func _gui_input(event: InputEvent) -> void:
	if is_empty and item.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.shift_pressed and not item.is_empty():
				slot_lock_toggled.emit(item)
				accept_event()
				return
			if mb.double_click:
				slot_double_clicked.emit(item)
			else:
				slot_clicked.emit(item)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			slot_sell_requested.emit(item)
			accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if not item.is_empty():
			slot_hovered.emit(item, get_global_mouse_position())
	elif what == NOTIFICATION_MOUSE_EXIT:
		slot_unhovered.emit()

func _build_nodes() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _icon_rect != null:
		return
	_rarity_strip = ColorRect.new()
	_rarity_strip.name = "RarityStrip"
	_rarity_strip.anchor_top = 0.0
	_rarity_strip.anchor_bottom = 1.0
	_rarity_strip.offset_left = 0
	_rarity_strip.offset_top = 4
	_rarity_strip.offset_right = 4
	_rarity_strip.offset_bottom = -4
	_rarity_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rarity_strip)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 6
	center.offset_top = 2
	center.offset_right = -2
	center.offset_bottom = -16
	add_child(center)
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(48, 48)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_icon_rect)
	_slot_label = Label.new()
	_slot_label.name = "SlotLabel"
	_slot_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_slot_label.offset_top = -14
	_slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_label.add_theme_font_size_override("font_size", 8)
	_slot_label.add_theme_color_override("font_color", Color(0.65, 0.62, 0.72))
	_slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slot_label)
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_name_label.offset_top = -13
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 8)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	_enh_label = Label.new()
	_enh_label.name = "EnhLabel"
	_enh_label.anchor_left = 1.0
	_enh_label.anchor_top = 0.0
	_enh_label.anchor_right = 1.0
	_enh_label.offset_left = -24
	_enh_label.offset_top = 2
	_enh_label.offset_right = -2
	_enh_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enh_label.add_theme_font_size_override("font_size", 9)
	_enh_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	_enh_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enh_label)
	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.anchor_left = 0.0
	_level_label.anchor_top = 0.0
	_level_label.offset_left = 6
	_level_label.offset_top = 2
	_level_label.add_theme_font_size_override("font_size", 7)
	_level_label.add_theme_color_override("font_color", Color(0.55, 0.53, 0.62))
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_label)
	_delta_label = Label.new()
	_delta_label.name = "DeltaLabel"
	_delta_label.anchor_left = 1.0
	_delta_label.anchor_bottom = 1.0
	_delta_label.offset_left = -28
	_delta_label.offset_top = -26
	_delta_label.offset_right = -2
	_delta_label.offset_bottom = -14
	_delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_delta_label.add_theme_font_size_override("font_size", 8)
	_delta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_delta_label)
	_new_label = Label.new()
	_new_label.name = "NewLabel"
	_new_label.text = "新"
	_new_label.anchor_left = 0.0
	_new_label.anchor_top = 0.0
	_new_label.offset_left = 5
	_new_label.offset_top = 1
	_new_label.add_theme_font_size_override("font_size", 8)
	_new_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	_new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_new_label.visible = false
	add_child(_new_label)
	_lock_label = Label.new()
	_lock_label.name = "LockLabel"
	_lock_label.text = "🔒"
	_lock_label.anchor_left = 1.0
	_lock_label.anchor_top = 0.0
	_lock_label.offset_left = -18
	_lock_label.offset_top = 12
	_lock_label.add_theme_font_size_override("font_size", 9)
	_lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_label.visible = false
	add_child(_lock_label)
	_upgrade_hint = Label.new()
	_upgrade_hint.name = "UpgradeHint"
	_upgrade_hint.text = "换"
	_upgrade_hint.anchor_left = 1.0
	_upgrade_hint.anchor_bottom = 1.0
	_upgrade_hint.offset_left = -16
	_upgrade_hint.offset_top = -28
	_upgrade_hint.offset_right = -2
	_upgrade_hint.offset_bottom = -14
	_upgrade_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_hint.add_theme_font_size_override("font_size", 8)
	_upgrade_hint.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	_upgrade_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_hint.visible = false
	add_child(_upgrade_hint)
