extends PanelContainer
class_name QuestCard
## 主线任务卡片 — 时间线节点 + 进度条 + 奖励预览

signal claim_pressed(quest: Dictionary)

var quest: Dictionary = {}
var quest_index: int = 0

var _timeline_dot: ColorRect
var _timeline_line: ColorRect
var _icon_badge: PanelContainer
var _index_l: Label
var _title_l: Label
var _type_l: Label
var _desc_l: Label
var _status_l: Label
var _prog_l: Label
var _track: ColorRect
var _fill: ColorRect
var _reward_row: HBoxContainer
var _claim_btn: Button

func _ready() -> void:
	custom_minimum_size = Vector2(0, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_nodes()

func setup(
	p_quest: Dictionary,
	p_index: int,
	progress: int,
	claimed: bool,
	is_focus: bool,
	show_timeline_line: bool,
) -> void:
	quest = p_quest
	quest_index = p_index
	_ensure_nodes()
	var target: int = int(p_quest.get("target", 1))
	var prog_clamped: int = mini(progress, target)
	var done: bool = progress >= target
	var status: QuestUtils.QuestStatus = QuestUtils.resolve_status(claimed, done, is_focus)
	var ratio: float = QuestUtils.progress_ratio(prog_clamped, target)
	var chapter: Dictionary = QuestUtils.chapter_info(p_index)
	var accent: Color = QuestUtils.card_accent(status)
	_apply_card_style(accent, status == QuestUtils.QuestStatus.FOCUS)
	_timeline_dot.color = _dot_color(status)
	_timeline_line.visible = show_timeline_line
	_timeline_line.color = Color(chapter["color"].r, chapter["color"].g, chapter["color"].b, 0.35 if claimed else 0.2)
	_setup_icon_badge(p_quest, accent, claimed)
	_index_l.text = "Q%02d" % (p_index + 1)
	_title_l.text = str(p_quest.get("name", ""))
	_title_l.add_theme_color_override("font_color", accent if not claimed else ThemeConfig.ACCENT_GREEN)
	_type_l.text = "%s · %s" % [QuestUtils.type_icon(str(p_quest.get("type", ""))), QuestUtils.type_label(str(p_quest.get("type", "")))]
	_desc_l.text = str(p_quest.get("desc", ""))
	_status_l.text = QuestUtils.status_text(status)
	_status_l.add_theme_color_override("font_color", QuestUtils.status_color(status))
	_prog_l.text = "%s / %s" % [_fmt_prog(prog_clamped, target), _fmt_prog(target, target)]
	_fill.custom_minimum_size = Vector2(0, 6)
	_fill.anchor_right = ratio
	_fill.offset_right = 0
	var fill_col := ThemeConfig.ACCENT_GREEN if done else (ThemeConfig.SECONDARY if is_focus else ThemeConfig.TXT_DISABLED)
	_fill.color = fill_col
	_track.custom_minimum_size = Vector2(0, 6)
	_populate_rewards(p_quest.get("reward", {}))
	_claim_btn.visible = status == QuestUtils.QuestStatus.CLAIMABLE
	modulate = Color(1, 1, 1, 0.55 if claimed else 1.0)

func _setup_icon_badge(p_quest: Dictionary, accent: Color, claimed: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.10, 0.92)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(accent.r, accent.g, accent.b, 0.35 if claimed else 0.85)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	_icon_badge.add_theme_stylebox_override("panel", s)
	for c in _icon_badge.get_children():
		c.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon_badge.add_child(center)
	var icon := Label.new()
	icon.text = QuestUtils.type_icon(str(p_quest.get("type", "")))
	icon.add_theme_font_size_override("font_size", 22)
	icon.modulate = Color(1, 1, 1, 0.45 if claimed else 1.0)
	center.add_child(icon)

func _populate_rewards(reward: Dictionary) -> void:
	for c in _reward_row.get_children():
		c.queue_free()
	for part in QuestUtils.format_rewards(reward):
		var chip := Label.new()
		chip.text = part
		chip.add_theme_font_size_override("font_size", 9)
		chip.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
		_reward_row.add_child(chip)

func _dot_color(status: QuestUtils.QuestStatus) -> Color:
	match status:
		QuestUtils.QuestStatus.CLAIMED: return ThemeConfig.ACCENT_GREEN
		QuestUtils.QuestStatus.CLAIMABLE: return ThemeConfig.ACCENT_GOLD
		QuestUtils.QuestStatus.FOCUS: return ThemeConfig.SECONDARY_LIGHT
		_: return ThemeConfig.TXT_DISABLED

func _apply_card_style(accent: Color, glow: bool) -> void:
	var s := ThemeConfig.make_card(accent)
	if glow:
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.25)
		s.shadow_size = 6
	add_theme_stylebox_override("panel", s)

func _fmt_prog(val: int, _target: int) -> String:
	if val >= 10000:
		return "%.1f万" % (float(val) / 10000.0)
	return str(val)

func _on_claim() -> void:
	if not quest.is_empty():
		claim_pressed.emit(quest)

func _build_nodes() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _title_l != null:
		return
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)
	var timeline := Control.new()
	timeline.custom_minimum_size = Vector2(18, 0)
	timeline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(timeline)
	_timeline_dot = ColorRect.new()
	_timeline_dot.custom_minimum_size = Vector2(10, 10)
	_timeline_dot.position = Vector2(4, 18)
	_timeline_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timeline.add_child(_timeline_dot)
	_timeline_line = ColorRect.new()
	_timeline_line.position = Vector2(8, 30)
	_timeline_line.custom_minimum_size = Vector2(2, 80)
	_timeline_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timeline.add_child(_timeline_line)
	var body_margin := MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 4)
	body_margin.add_theme_constant_override("margin_right", 0)
	body_margin.add_theme_constant_override("margin_top", 0)
	body_margin.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(body_margin)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body_margin.add_child(body)
	_icon_badge = PanelContainer.new()
	_icon_badge.custom_minimum_size = Vector2(48, 48)
	body.add_child(_icon_badge)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	body.add_child(info)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	info.add_child(title_row)
	_index_l = Label.new()
	_index_l.add_theme_font_size_override("font_size", 9)
	_index_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	title_row.add_child(_index_l)
	_title_l = Label.new()
	_title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_l.add_theme_font_size_override("font_size", 13)
	title_row.add_child(_title_l)
	_status_l = Label.new()
	_status_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_l.add_theme_font_size_override("font_size", 9)
	title_row.add_child(_status_l)
	_type_l = Label.new()
	_type_l.add_theme_font_size_override("font_size", 8)
	_type_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(_type_l)
	_desc_l = Label.new()
	_desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_l.add_theme_font_size_override("font_size", 10)
	_desc_l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	info.add_child(_desc_l)
	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 8)
	info.add_child(prog_row)
	_track = ColorRect.new()
	_track.color = Color(0.12, 0.11, 0.16)
	_track.custom_minimum_size = Vector2(0, 6)
	_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_row.add_child(_track)
	_fill = ColorRect.new()
	_fill.color = ThemeConfig.SECONDARY
	_track.add_child(_fill)
	_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_fill.anchor_right = 0.0
	_prog_l = Label.new()
	_prog_l.add_theme_font_size_override("font_size", 8)
	_prog_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	prog_row.add_child(_prog_l)
	_reward_row = HBoxContainer.new()
	_reward_row.add_theme_constant_override("separation", 10)
	info.add_child(_reward_row)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(right)
	_claim_btn = Button.new()
	_claim_btn.text = "领取"
	_claim_btn.custom_minimum_size = Vector2(64, 34)
	_claim_btn.add_theme_font_size_override("font_size", 11)
	var bn := ThemeConfig.make_btn_primary()
	_claim_btn.add_theme_stylebox_override("normal", bn)
	_claim_btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
	_claim_btn.pressed.connect(_on_claim)
	right.add_child(_claim_btn)
