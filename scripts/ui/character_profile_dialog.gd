extends Control
class_name CharacterProfileDialog
## 角色档案弹窗 — 查看/修改名字、性别、签名

signal profile_saved(patch: Dictionary)
signal closed

var _avatar: TextureRect
var _name_edit: LineEdit
var _gender_opt: OptionButton
var _motto_edit: LineEdit
var _error_l: Label
var _level_l: Label
var _stats_l: Label
var _subtitle_l: Label

var _overlay: ColorRect
var _panel: PanelContainer

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func open(avatar_tex: Texture2D = null) -> void:
	_build_ui()
	var player: Dictionary = GameManager.game_data.get("player", {})
	var combat: Dictionary = GameManager.game_data.get("combat", {})
	var portrait: Texture2D = avatar_tex if avatar_tex else AssetRegistry.get_hero_portrait_texture()
	if portrait:
		_avatar.texture = portrait
	_name_edit.text = PlayerProfileUtils.display_name(player)
	_motto_edit.text = str(player.get("motto", ""))
	_gender_opt.clear()
	for g in PlayerProfileUtils.GENDERS:
		_gender_opt.add_item("%s %s" % [g["icon"], g["label"]])
	_gender_opt.select(PlayerProfileUtils.gender_index(str(player.get("gender", "secret"))))
	_level_l.text = "%s · Lv.%d" % [PlayerProfileUtils.display_name(player), int(player.get("level", 1))]
	_stats_l.text = "⚔%d  🛡%d  ❤%d  ✦%d%%" % [
		int(combat.get("atk", 0)), int(combat.get("def", 0)),
		int(combat.get("max_hp", 0)), int(combat.get("crit", 0)),
	]
	_subtitle_l.text = PlayerProfileUtils.profile_subtitle(player)
	_error_l.text = ""
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_avatar_texture(tex: Texture2D) -> void:
	_build_ui()
	if _avatar and tex:
		_avatar.texture = tex

func dismiss() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()

func _on_save() -> void:
	var name: String = PlayerProfileUtils.sanitize_name(_name_edit.text)
	var err: String = PlayerProfileUtils.validate_name(name)
	if not err.is_empty():
		_error_l.text = err
		return
	var gender_id: String = str(PlayerProfileUtils.GENDERS[_gender_opt.selected]["id"])
	var patch := {
		"name": name,
		"gender": gender_id,
		"motto": PlayerProfileUtils.sanitize_motto(_motto_edit.text),
	}
	if GameManager.update_player_profile(patch):
		profile_saved.emit(patch)
		dismiss()

func _on_name_changed(_new_text: String) -> void:
	_error_l.text = ""
	var player: Dictionary = GameManager.game_data.get("player", {}) as Dictionary
	var preview: Dictionary = player.duplicate()
	preview["name"] = _name_edit.text
	preview["gender"] = str(PlayerProfileUtils.GENDERS[_gender_opt.selected]["id"])
	preview["motto"] = _motto_edit.text
	_subtitle_l.text = PlayerProfileUtils.profile_subtitle(preview)

func _build_ui() -> void:
	if _panel != null:
		return
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			dismiss())
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(300, 0)
	center.add_child(_panel)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.13, 0.98)
	ps.corner_radius_top_left = 16
	ps.corner_radius_top_right = 16
	ps.corner_radius_bottom_left = 16
	ps.corner_radius_bottom_right = 16
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.55, 0.45, 0.65, 0.85)
	ps.content_margin_left = 18.0
	ps.content_margin_right = 18.0
	ps.content_margin_top = 16.0
	ps.content_margin_bottom = 16.0
	_panel.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)
	var title := Label.new()
	title.text = "角色档案"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72))
	vbox.add_child(title)
	var avatar_wrap := CenterContainer.new()
	vbox.add_child(avatar_wrap)
	var avatar_frame := PanelContainer.new()
	var afs := StyleBoxFlat.new()
	afs.bg_color = Color(0.06, 0.05, 0.09, 0.9)
	afs.corner_radius_top_left = 12
	afs.corner_radius_top_right = 12
	afs.corner_radius_bottom_left = 12
	afs.corner_radius_bottom_right = 12
	afs.border_width_left = 2
	afs.border_width_right = 2
	afs.border_width_top = 2
	afs.border_width_bottom = 2
	afs.border_color = Color(0.45, 0.38, 0.55, 0.7)
	afs.content_margin_left = 8.0
	afs.content_margin_right = 8.0
	afs.content_margin_top = 8.0
	afs.content_margin_bottom = 8.0
	avatar_frame.add_theme_stylebox_override("panel", afs)
	avatar_wrap.add_child(avatar_frame)
	_avatar = TextureRect.new()
	_avatar.custom_minimum_size = Vector2(72, 72)
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_apply_avatar_chroma(_avatar)
	avatar_frame.add_child(_avatar)
	_level_l = Label.new()
	_level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_l.add_theme_font_size_override("font_size", 11)
	_level_l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	vbox.add_child(_level_l)
	_subtitle_l = Label.new()
	_subtitle_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_l.add_theme_font_size_override("font_size", 9)
	_subtitle_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	vbox.add_child(_subtitle_l)
	_stats_l = Label.new()
	_stats_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_l.add_theme_font_size_override("font_size", 9)
	_stats_l.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN)
	vbox.add_child(_stats_l)
	vbox.add_child(_make_field_label("角色名字"))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "2-12 个字符"
	_name_edit.max_length = PlayerProfileUtils.NAME_MAX_LEN
	_name_edit.custom_minimum_size = Vector2(0, 34)
	_style_line_edit(_name_edit)
	_name_edit.text_changed.connect(_on_name_changed)
	vbox.add_child(_name_edit)
	vbox.add_child(_make_field_label("性别"))
	_gender_opt = OptionButton.new()
	_gender_opt.custom_minimum_size = Vector2(0, 34)
	_style_option(_gender_opt)
	_gender_opt.item_selected.connect(func(_i: int): _on_name_changed(""))
	vbox.add_child(_gender_opt)
	vbox.add_child(_make_field_label("个性签名（可选）"))
	_motto_edit = LineEdit.new()
	_motto_edit.placeholder_text = "写一句冒险宣言…"
	_motto_edit.max_length = PlayerProfileUtils.MOTTO_MAX_LEN
	_motto_edit.custom_minimum_size = Vector2(0, 34)
	_style_line_edit(_motto_edit)
	_motto_edit.text_changed.connect(_on_name_changed)
	vbox.add_child(_motto_edit)
	_error_l = Label.new()
	_error_l.add_theme_font_size_override("font_size", 9)
	_error_l.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
	vbox.add_child(_error_l)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(88, 36)
	_style_outline_btn(cancel)
	cancel.pressed.connect(dismiss)
	footer.add_child(cancel)
	var save := Button.new()
	save.text = "保存"
	save.custom_minimum_size = Vector2(120, 36)
	_style_primary_btn(save)
	save.pressed.connect(_on_save)
	footer.add_child(save)

func _apply_avatar_chroma(rect: TextureRect) -> void:
	var shader: Shader = load("res://shaders/chroma_key.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("threshold", 0.40)
		mat.set_shader_parameter("smoothing", 0.15)
		rect.material = mat

func _make_field_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	return l

func _style_line_edit(edit: LineEdit) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.08, 0.07, 0.11)
	n.border_width_left = 1
	n.border_width_right = 1
	n.border_width_top = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.35, 0.32, 0.42)
	n.corner_radius_top_left = 8
	n.corner_radius_top_right = 8
	n.corner_radius_bottom_left = 8
	n.corner_radius_bottom_right = 8
	n.content_margin_left = 10.0
	n.content_margin_right = 10.0
	edit.add_theme_stylebox_override("normal", n)
	edit.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)

func _style_option(opt: OptionButton) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.08, 0.07, 0.11)
	n.border_width_left = 1
	n.border_width_right = 1
	n.border_width_top = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.35, 0.32, 0.42)
	n.corner_radius_top_left = 8
	n.corner_radius_top_right = 8
	n.corner_radius_bottom_left = 8
	n.corner_radius_bottom_right = 8
	opt.add_theme_stylebox_override("normal", n)
	opt.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)

func _style_primary_btn(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", ThemeConfig.make_btn_primary())
	btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)

func _style_outline_btn(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", ThemeConfig.make_btn_outline(ThemeConfig.TXT_SECONDARY))
	btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
