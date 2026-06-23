extends Control
class_name BattleSkillBar
## 战斗区技能栏 - 图标 + CD 遮罩

var _slots: Array[Control] = []
var _flash_skill := ""
var _flash_t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_slots()
	call_deferred("_bind_skill_cast")

func _bind_skill_cast() -> void:
	if GameManager.skill_system and not GameManager.skill_system.skill_cast.is_connected(_on_skill_cast):
		GameManager.skill_system.skill_cast.connect(_on_skill_cast)

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash_skill = ""
	_refresh()

func _build_slots() -> void:
	for c in get_children():
		c.queue_free()
	_slots.clear()

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	for i in range(4):
		var slot := _make_slot()
		slot.name = "Slot_%d" % i
		row.add_child(slot)
		_slots.append(slot)

func _make_slot() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(44, 44)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.05, 0.04, 0.08, 0.82)
	bs.border_color = Color(0.35, 0.30, 0.42, 0.65)
	bs.set_border_width_all(1)
	bs.set_corner_radius_all(8)
	bg.add_theme_stylebox_override("panel", bs)
	wrap.add_child(bg)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.modulate = Color(0.35, 0.35, 0.38, 0.7)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(icon)

	var cd_mask := ColorRect.new()
	cd_mask.name = "CDMask"
	cd_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_mask.color = Color(0.02, 0.02, 0.04, 0.72)
	cd_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_mask.visible = false
	wrap.add_child(cd_mask)

	var cd_lbl := Label.new()
	cd_lbl.name = "CDLabel"
	cd_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.add_theme_font_size_override("font_size", 11)
	cd_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	cd_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_lbl.visible = false
	wrap.add_child(cd_lbl)

	var ring := Panel.new()
	ring.name = "Flash"
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.visible = false
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.92, 0.78, 0.38, 0.0)
	rs.border_color = Color(0.92, 0.78, 0.38, 0.95)
	rs.set_border_width_all(2)
	rs.set_corner_radius_all(8)
	ring.add_theme_stylebox_override("panel", rs)
	wrap.add_child(ring)

	return wrap

func _on_skill_cast(skill_id: String, _color: Color, _pos: Vector2) -> void:
	_flash_skill = skill_id
	_flash_t = 0.35
	_refresh()

func _refresh() -> void:
	if not GameManager.is_loaded or not GameManager.skill_system:
		return
	var states: Array = GameManager.skill_system.get_equipped_skill_states()
	for i in range(_slots.size()):
		var slot: Control = _slots[i]
		if i >= states.size():
			_set_slot_empty(slot)
			continue
		_set_slot_data(slot, states[i])

func _set_slot_empty(slot: Control) -> void:
	var icon := slot.get_node_or_null("Icon") as TextureRect
	var cd_mask := slot.get_node_or_null("CDMask") as ColorRect
	var cd_lbl := slot.get_node_or_null("CDLabel") as Label
	var ring := slot.get_node_or_null("Flash") as Panel
	if icon:
		icon.texture = null
		icon.modulate = Color(0.35, 0.35, 0.38, 0.5)
	if cd_mask:
		cd_mask.visible = false
	if cd_lbl:
		cd_lbl.visible = false
	if ring:
		ring.visible = false

func _set_slot_data(slot: Control, data: Dictionary) -> void:
	var skill_id: String = data.get("id", "")
	var icon := slot.get_node_or_null("Icon") as TextureRect
	var cd_mask := slot.get_node_or_null("CDMask") as ColorRect
	var cd_lbl := slot.get_node_or_null("CDLabel") as Label
	var ring := slot.get_node_or_null("Flash") as Panel
	var bg := slot.get_child(0) as Panel

	var cd_rem: float = float(data.get("cd_remaining", 0.0))
	var cd_max: float = maxf(0.01, float(data.get("cd_max", 1.0)))
	var ratio: float = clampf(cd_rem / cd_max, 0.0, 1.0)
	var on_cd: bool = cd_rem > 0.05

	if icon:
		var tex: Texture2D = AssetRegistry.load_texture(str(data.get("icon", "")))
		icon.texture = tex
		icon.modulate = Color(0.45, 0.45, 0.50, 0.65) if on_cd else Color(1, 1, 1, 1)

	if cd_mask:
		cd_mask.visible = on_cd
		if on_cd:
			cd_mask.anchor_top = 0.0
			cd_mask.anchor_bottom = ratio
			cd_mask.offset_top = 0
			cd_mask.offset_bottom = 0

	if cd_lbl:
		cd_lbl.visible = on_cd
		if on_cd:
			cd_lbl.text = "%.1f" % cd_rem if cd_rem < 10.0 else str(int(ceil(cd_rem)))

	if ring:
		ring.visible = (_flash_skill == skill_id and _flash_t > 0.0)

	if bg:
		var bs := bg.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		var accent: Color = data.get("color", Color.WHITE)
		bs.border_color = Color(accent.r, accent.g, accent.b, 0.85) if not on_cd else Color(0.35, 0.30, 0.42, 0.65)
		bg.add_theme_stylebox_override("panel", bs)
