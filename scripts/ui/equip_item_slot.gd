extends PanelContainer
class_name EquipItemSlot
## 装备图标槽位 - 图标展示 + hover + 双击

signal slot_hovered(item: Dictionary, global_pos: Vector2)
signal slot_unhovered()
signal slot_double_clicked(item: Dictionary)

var item: Dictionary = {}
var slot_index: int = -1
var is_empty := true

var _icon_rect: TextureRect
var _slot_label: Label
var _enh_label: Label

const SLOT_SIZE := Vector2(72, 72)

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
	_enh_label.visible = false
	var path: String = AssetRegistry.get_slot_fallback_icon(slot_i)
	_set_icon(path, 0.35)
	_apply_border(ThemeConfig.TXT_DISABLED)

func setup_item(p_item: Dictionary, show_slot_label: bool = false) -> void:
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
	_apply_border(ri["color"])
	var enh: int = int(p_item.get("enhance_level", 0))
	if enh > 0:
		_enh_label.text = "+%d" % enh
		_enh_label.visible = true
	else:
		_enh_label.visible = false

func _set_icon(path: String, alpha: float) -> void:
	var tex: Texture2D = AssetRegistry.load_texture(path)
	if tex:
		_icon_rect.texture = tex
	_icon_rect.modulate = Color(1, 1, 1, alpha)

func _apply_border(color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.10, 0.92)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(color.r, color.g, color.b, 0.85)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", s)

func _gui_input(event: InputEvent) -> void:
	if is_empty and item.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			slot_double_clicked.emit(item)
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
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(52, 52)
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
	_enh_label = Label.new()
	_enh_label.name = "EnhLabel"
	_enh_label.anchor_left = 1.0
	_enh_label.anchor_top = 0.0
	_enh_label.anchor_right = 1.0
	_enh_label.offset_left = -22
	_enh_label.offset_top = 2
	_enh_label.offset_right = -2
	_enh_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enh_label.add_theme_font_size_override("font_size", 9)
	_enh_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	_enh_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enh_label)
