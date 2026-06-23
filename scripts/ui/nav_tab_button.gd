extends VBoxContainer
class_name NavTabButton
## 底部导航图片按钮 - 普通 / 选中双态

signal tab_pressed()

var _glow: Panel
var _icon: TextureRect
var _label: Label
var _tex_normal: Texture2D
var _tex_active: Texture2D
var _selected := false
var _label_text := ""
var _pulse_t := 0.0

func setup(label_text: String, icon_normal: Texture2D, icon_active: Texture2D) -> void:
	_label_text = label_text
	_tex_normal = icon_normal
	_tex_active = icon_active
	if _label:
		_label.text = _label_text
	if is_node_ready():
		_apply_visual()

func set_selected(active: bool) -> void:
	if _selected == active:
		return
	_selected = active
	_apply_visual()

func is_selected() -> bool:
	return _selected

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 64)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = ALIGNMENT_CENTER
	add_theme_constant_override("separation", 0)
	focus_mode = Control.FOCUS_NONE
	set_process(true)

	var icon_wrap := CenterContainer.new()
	icon_wrap.name = "IconWrap"
	icon_wrap.custom_minimum_size = Vector2(50, 50)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_wrap)

	var box := Control.new()
	box.name = "IconBox"
	box.custom_minimum_size = Vector2(46, 46)
	box.size = Vector2(46, 46)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(box)

	_glow = Panel.new()
	_glow.name = "Glow"
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.72, 0.55, 0.22, 0.0)
	glow_style.border_color = Color(0.92, 0.78, 0.38, 0.0)
	glow_style.set_border_width_all(2)
	glow_style.set_corner_radius_all(14)
	glow_style.shadow_color = Color(0.85, 0.65, 0.25, 0.0)
	glow_style.shadow_size = 6
	_glow.add_theme_stylebox_override("panel", glow_style)
	box.add_child(_glow)

	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 3
	_icon.offset_top = 3
	_icon.offset_right = -3
	_icon.offset_bottom = -3
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_icon)

	_label = Label.new()
	_label.name = "Text"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 10)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	if _label_text:
		_label.text = _label_text
	_apply_visual()

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func _process(delta: float) -> void:
	if not _selected or not _glow:
		return
	_pulse_t += delta * 4.2
	var gs := _glow.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var pulse := 0.32 + sin(_pulse_t) * 0.13
	gs.shadow_size = 7 + int((sin(_pulse_t * 0.9) + 1.0) * 2.0)
	gs.bg_color = Color(0.55, 0.38, 0.72, pulse)
	_glow.add_theme_stylebox_override("panel", gs)

func _on_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		tab_pressed.emit()

func _on_hover(inside: bool) -> void:
	if _selected or not _icon:
		return
	_icon.modulate = Color(0.92, 0.90, 0.96, 1.0) if inside else Color(0.62, 0.60, 0.68, 0.82)

func _apply_visual() -> void:
	if not is_node_ready() or not _icon:
		return
	if _tex_normal and _tex_active:
		_icon.texture = _tex_active if _selected else _tex_normal
	var box := _icon.get_parent() as Control
	if _selected:
		_pulse_t = 0.0
		_icon.offset_left = 2
		_icon.offset_top = 2
		_icon.offset_right = -2
		_icon.offset_bottom = -2
		_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		_label.add_theme_font_size_override("font_size", 11)
		if box:
			box.custom_minimum_size = Vector2(48, 48)
			box.size = Vector2(48, 48)
		var gs := _glow.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		gs.bg_color = Color(0.55, 0.38, 0.72, 0.28)
		gs.border_color = Color(0.92, 0.78, 0.38, 0.95)
		gs.shadow_color = Color(0.85, 0.65, 0.25, 0.45)
		_glow.add_theme_stylebox_override("panel", gs)
	else:
		_icon.offset_left = 4
		_icon.offset_top = 4
		_icon.offset_right = -4
		_icon.offset_bottom = -4
		_icon.modulate = Color(0.62, 0.60, 0.68, 0.82)
		_label.add_theme_color_override("font_color", Color(0.48, 0.46, 0.54))
		_label.add_theme_font_size_override("font_size", 10)
		if box:
			box.custom_minimum_size = Vector2(44, 44)
			box.size = Vector2(44, 44)
		var gs2 := _glow.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		gs2.bg_color = Color(0.72, 0.55, 0.22, 0.0)
		gs2.border_color = Color(0.92, 0.78, 0.38, 0.0)
		gs2.shadow_color = Color(0.85, 0.65, 0.25, 0.0)
		_glow.add_theme_stylebox_override("panel", gs2)
