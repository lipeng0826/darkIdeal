extends Control
class_name AdventureMapView
## 冒险世界地图 - 可滚动节点路线图

signal zone_selected(zone_idx: int)
signal tower_requested()

const MAP_HEIGHT := 2480.0
const NODE_SIZE := Vector2(108, 128)

const ZONE_POSITIONS: Array = [
	Vector2(0.50, 0.91),
	Vector2(0.26, 0.81),
	Vector2(0.74, 0.71),
	Vector2(0.30, 0.61),
	Vector2(0.70, 0.51),
	Vector2(0.34, 0.41),
	Vector2(0.66, 0.31),
	Vector2(0.28, 0.22),
	Vector2(0.72, 0.13),
	Vector2(0.50, 0.04),
]
const TOWER_POS := Vector2(0.86, 0.08)

var _current_zone := 0
var _unlocked_zone := 0
var _node_centers: PackedVector2Array = PackedVector2Array()
var _pulse := 0.0
var _zone_nodes: Array[Control] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_pulse += delta * 2.4
	queue_redraw()
	for node in _zone_nodes:
		if node.has_meta("is_current") and node.get_meta("is_current"):
			var glow: float = 1.0 + sin(_pulse) * 0.06
			node.scale = Vector2(glow, glow)

func setup(current_zone: int, unlocked_zone: int) -> void:
	_current_zone = current_zone
	_unlocked_zone = unlocked_zone
	custom_minimum_size = Vector2(0, MAP_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_map()

func scroll_to_zone(zone_idx: int) -> void:
	var scroll := _find_scroll_parent()
	if scroll == null or zone_idx < 0 or zone_idx >= _node_centers.size():
		return
	var target_y: float = _node_centers[zone_idx].y - scroll.size.y * 0.42
	scroll.scroll_vertical = int(clampf(target_y, 0.0, maxf(0.0, MAP_HEIGHT - scroll.size.y)))

func _build_map() -> void:
	for c in get_children():
		c.queue_free()
	_zone_nodes.clear()
	_node_centers = PackedVector2Array()

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.03, 0.06, 0.35)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	_add_map_title()
	_add_compass()
	_add_tower_landmark()

	for i in DataManager.ZONES.size():
		_add_zone_node(i)

	call_deferred("_finalize_layout")

func _finalize_layout() -> void:
	var w: float = _get_map_width()
	_node_centers = PackedVector2Array()
	for i in DataManager.ZONES.size():
		if i >= _zone_nodes.size():
			continue
		var pos_ratio: Vector2 = ZONE_POSITIONS[i]
		var center := Vector2(w * pos_ratio.x, MAP_HEIGHT * pos_ratio.y)
		_node_centers.append(center)
		var node: Control = _zone_nodes[i]
		node.position = center - NODE_SIZE * 0.5
		node.size = NODE_SIZE
		if node.get_meta("is_current"):
			node.pivot_offset = NODE_SIZE * 0.5
	queue_redraw()
	var tower := get_node_or_null("TowerLandmark")
	if tower:
		_position_tower(tower)

func _get_map_width() -> float:
	if size.x >= 100.0:
		return size.x
	var parent := get_parent()
	if parent is Control and (parent as Control).size.x >= 100.0:
		return (parent as Control).size.x
	return maxf(320.0, get_viewport_rect().size.x - 16.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_finalize_layout")

func _draw() -> void:
	if _node_centers.size() < 2:
		return
	for i in range(_node_centers.size() - 1):
		var from: Vector2 = _node_centers[i]
		var to: Vector2 = _node_centers[i + 1]
		var lit: bool = i < _unlocked_zone
		var path_col: Color = Color(0.55, 0.48, 0.72, 0.75) if lit else Color(0.25, 0.24, 0.30, 0.35)
		_draw_path_segment(from, to, path_col, 5.0 if lit else 3.0)
		if lit:
			draw_circle(from, 6.0, Color(0.85, 0.78, 0.95, 0.55))

func _draw_path_segment(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var mid := (from + to) * 0.5
	var dir := (to - from).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var ctrl := mid + normal * from.distance_to(to) * 0.18
	var steps := 24
	var prev := from
	for s in range(1, steps + 1):
		var t: float = float(s) / float(steps)
		var inv: float = 1.0 - t
		var pt := inv * inv * from + 2.0 * inv * t * ctrl + t * t * to
		draw_line(prev, pt, color, width)
		prev = pt

func _add_map_title() -> void:
	var title := Label.new()
	title.text = "暗影大陆"
	title.position = Vector2(16, 18)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var sub := Label.new()
	sub.text = "拖动探索 · 点击区域前往"
	sub.position = Vector2(18, 46)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.62, 0.58, 0.68))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

func _add_compass() -> void:
	var box := PanelContainer.new()
	box.position = Vector2(12, 72)
	box.custom_minimum_size = Vector2(52, 52)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.12, 0.82)
	s.border_color = Color(0.45, 0.40, 0.55, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	box.add_theme_stylebox_override("panel", s)
	var lbl := Label.new()
	lbl.text = "N"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	box.add_child(lbl)
	add_child(box)

func _add_tower_landmark() -> void:
	var btn := Button.new()
	btn.name = "TowerLandmark"
	btn.text = ""
	btn.flat = true
	btn.custom_minimum_size = Vector2(88, 100)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(func(): tower_requested.emit())
	add_child(btn)
	btn.set_meta("map_ratio_pos", TOWER_POS)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.06, 0.14, 0.92)
	ps.border_color = ThemeConfig.ACCENT_PURPLE
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", ps)
	btn.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var icon := Label.new()
	icon.text = "🗼"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	vbox.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = "深渊塔"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE)
	vbox.add_child(name_lbl)

	call_deferred("_position_tower", btn)

func _position_tower(btn: Button) -> void:
	var w: float = _get_map_width()
	var ratio: Vector2 = btn.get_meta("map_ratio_pos")
	btn.position = Vector2(w * ratio.x, MAP_HEIGHT * ratio.y) - btn.custom_minimum_size * 0.5

func _add_zone_node(zone_idx: int) -> void:
	var z: Dictionary = DataManager.ZONES[zone_idx]
	var locked: bool = zone_idx > _unlocked_zone
	var is_current: bool = zone_idx == _current_zone

	var btn := Button.new()
	btn.name = "Zone_%d" % zone_idx
	btn.text = ""
	btn.flat = true
	btn.custom_minimum_size = NODE_SIZE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP if not locked else Control.MOUSE_FILTER_IGNORE
	if not locked:
		var zi: int = zone_idx
		btn.pressed.connect(func(): zone_selected.emit(zi))
	btn.set_meta("is_current", is_current)
	_zone_nodes.append(btn)
	add_child(btn)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent: Color = z["accent_color"] if not locked else ThemeConfig.TXT_DISABLED
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.06, 0.10, 0.94)
	ps.border_color = ThemeConfig.ACCENT_GOLD if is_current else accent
	ps.border_width_left = 3 if is_current else 2
	ps.border_width_right = ps.border_width_left
	ps.border_width_top = ps.border_width_left
	ps.border_width_bottom = ps.border_width_left
	ps.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", ps)
	btn.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var thumb_wrap := CenterContainer.new()
	thumb_wrap.custom_minimum_size = Vector2(72, 52)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(68, 48)
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var tex_path: String = AssetRegistry.get_zone_map_texture(zone_idx)
	var tex: Texture2D = AssetRegistry.load_texture(tex_path)
	if tex:
		thumb.texture = tex
	thumb.modulate = Color(1, 1, 1, 0.35 if locked else 1.0)
	thumb_wrap.add_child(thumb)
	vbox.add_child(thumb_wrap)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d-%d" % [z["min_lv"], z["max_lv"]]
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.add_theme_font_size_override("font_size", 8)
	lv_lbl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY if not locked else ThemeConfig.TXT_DISABLED)
	vbox.add_child(lv_lbl)

	var name_lbl := Label.new()
	var prefix := "▶ " if is_current else ("🔒 " if locked else "")
	name_lbl.text = "%s%s" % [prefix, z["name"]]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(96, 0)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD if is_current else (ThemeConfig.TXT_PRIMARY if not locked else ThemeConfig.TXT_DISABLED))
	vbox.add_child(name_lbl)

	if not locked:
		var boss_lbl := Label.new()
		boss_lbl.text = "💀 %s" % _short_boss_name(z["boss"]["name"])
		boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_lbl.add_theme_font_size_override("font_size", 7)
		boss_lbl.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
		vbox.add_child(boss_lbl)

	if locked:
		var lock_overlay := ColorRect.new()
		lock_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_overlay.color = Color(0.02, 0.02, 0.04, 0.45)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lock_overlay)

func _short_boss_name(full_name: String) -> String:
	if "·" in full_name:
		return full_name.split("·")[1]
	return full_name

func _find_scroll_parent() -> ScrollContainer:
	var n: Node = get_parent()
	while n:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null
