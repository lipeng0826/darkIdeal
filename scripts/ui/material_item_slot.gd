extends PanelContainer
class_name MaterialItemSlot
## 材料格 — 简洁样式，左侧色条标识

const SLOT_SIZE := Vector2(76, 88)

var material_id := ""
var count := 0

var _accent: ColorRect
var _icon_l: Label
var _name_l: Label
var _count_l: Label

func setup(mat_id: String, amount: int, mat_info: Dictionary) -> void:
	material_id = mat_id
	count = amount
	_ensure_nodes()
	var col: Color = mat_info.get("color", Color(0.6, 0.6, 0.65))
	var name: String = str(mat_info.get("name", mat_id))
	_accent.color = Color(col.r, col.g, col.b, 0.82)
	_icon_l.text = InventoryUtils.material_icon(mat_id)
	_icon_l.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.25))
	var short_name: String = name
	if short_name.length() > 6:
		short_name = short_name.substr(0, 5) + "…"
	_name_l.text = short_name
	_count_l.text = "×%s" % _fmt_count(amount)
	_apply_panel_style()

func _fmt_count(n: int) -> String:
	if n >= 10000:
		return "%.1f万" % (n / 10000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)

func _apply_panel_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.08, 0.11, 0.96)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.26, 0.24, 0.30, 0.85)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", s)

func _ensure_nodes() -> void:
	if _accent != null:
		return
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_accent = ColorRect.new()
	_accent.name = "Accent"
	_accent.anchor_top = 0.0
	_accent.anchor_bottom = 1.0
	_accent.offset_left = 0
	_accent.offset_top = 5
	_accent.offset_right = 3
	_accent.offset_bottom = -5
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_accent)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 4
	center.offset_top = 2
	center.offset_right = -2
	center.offset_bottom = -18
	add_child(center)
	_icon_l = Label.new()
	_icon_l.add_theme_font_size_override("font_size", 22)
	_icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_icon_l)
	_name_l = Label.new()
	_name_l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_name_l.offset_top = -14
	_name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_l.add_theme_font_size_override("font_size", 8)
	_name_l.add_theme_color_override("font_color", Color(0.78, 0.76, 0.84))
	_name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_l)
	_count_l = Label.new()
	_count_l.anchor_left = 1.0
	_count_l.anchor_top = 0.0
	_count_l.offset_left = -34
	_count_l.offset_top = 3
	_count_l.offset_right = -4
	_count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_l.add_theme_font_size_override("font_size", 9)
	_count_l.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	_count_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_l)
