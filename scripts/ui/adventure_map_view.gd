extends Control
class_name AdventureMapView
## 冒险世界地图 - 可滚动节点路线图

signal zone_selected(zone_idx: int)
signal tower_requested()

const MAP_HEIGHT := 2480.0
const NODE_SIZE := Vector2(112, 118)
const MAP_BG_PATH := "res://assets/generated/maps/world_map_bg.png"

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
var _path_layer: MapPathLayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)

func _process(delta: float) -> void:
	_pulse += delta * 2.4
	for node in _zone_nodes:
		if node.has_meta("is_current") and node.get_meta("is_current"):
			var glow: float = 1.0 + sin(_pulse) * 0.05
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
	await get_tree().process_frame
	var target_y: float = _node_centers[zone_idx].y - scroll.size.y * 0.38
	scroll.scroll_vertical = int(clampf(target_y, 0.0, maxf(0.0, MAP_HEIGHT - scroll.size.y)))

func _build_map() -> void:
	for c in get_children():
		c.queue_free()
	_zone_nodes.clear()
	_node_centers = PackedVector2Array()

	var bg_tex := TextureRect.new()
	bg_tex.name = "MapBG"
	bg_tex.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bg_tex.custom_minimum_size = Vector2(0, MAP_HEIGHT)
	bg_tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = AssetRegistry.load_texture(MAP_BG_PATH)
	if tex:
		bg_tex.texture = tex
	else:
		bg_tex.modulate = Color(0.08, 0.07, 0.12)
	add_child(bg_tex)

	var shade := ColorRect.new()
	shade.name = "MapShade"
	shade.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shade.custom_minimum_size = Vector2(0, MAP_HEIGHT)
	shade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shade.color = Color(0.03, 0.02, 0.06, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_path_layer = MapPathLayer.new()
	_path_layer.name = "PathLayer"
	_path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_path_layer)

	_add_map_title()
	_add_compass()
	_add_tower_landmark()

	for i in DataManager.ZONES.size():
		_add_zone_node(i)

	call_deferred("_finalize_layout")

func _finalize_layout() -> void:
	var w: float = _get_map_width()
	custom_minimum_size = Vector2(w, MAP_HEIGHT)
	size = Vector2(w, MAP_HEIGHT)

	var bg := get_node_or_null("MapBG") as TextureRect
	if bg:
		bg.position = Vector2.ZERO
		bg.size = Vector2(w, MAP_HEIGHT)
	var shade := get_node_or_null("MapShade") as ColorRect
	if shade:
		shade.position = Vector2.ZERO
		shade.size = Vector2(w, MAP_HEIGHT)
	if _path_layer:
		_path_layer.position = Vector2.ZERO
		_path_layer.size = Vector2(w, MAP_HEIGHT)

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

	if _path_layer:
		_path_layer.centers = _node_centers
		_path_layer.unlocked_zone = _unlocked_zone
		_path_layer.queue_redraw()

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

func _add_map_title() -> void:
	var title := Label.new()
	title.text = "暗影大陆"
	title.position = Vector2(16, 18)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var sub := Label.new()
	sub.text = "拖动探索 · 点击区域前往"
	sub.position = Vector2(18, 46)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.72, 0.68, 0.78))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

func _add_compass() -> void:
	var box := PanelContainer.new()
	box.position = Vector2(12, 72)
	box.custom_minimum_size = Vector2(52, 52)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.12, 0.88)
	s.border_color = Color(0.72, 0.58, 0.32, 0.75)
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
	btn.custom_minimum_size = Vector2(84, 96)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(func(): tower_requested.emit())
	add_child(btn)
	btn.set_meta("map_ratio_pos", TOWER_POS)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.06, 0.14, 0.94)
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
	icon.add_theme_font_size_override("font_size", 26)
	vbox.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = "深渊塔"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE)
	vbox.add_child(name_lbl)

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
	ps.set_corner_radius_all(14)
	if is_current:
		ps.shadow_color = Color(0.92, 0.78, 0.38, 0.35)
		ps.shadow_size = 6
	panel.add_theme_stylebox_override("panel", ps)
	btn.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 4)
	vbox.add_child(badge_row)

	var num_badge := PanelContainer.new()
	num_badge.custom_minimum_size = Vector2(22, 22)
	var ns := StyleBoxFlat.new()
	ns.bg_color = accent if not locked else Color(0.25, 0.24, 0.28)
	ns.set_corner_radius_all(11)
	num_badge.add_theme_stylebox_override("panel", ns)
	var num_lbl := Label.new()
	num_lbl.text = str(zone_idx + 1)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 10)
	num_lbl.add_theme_color_override("font_color", Color(0.95, 0.93, 0.98))
	num_badge.add_child(num_lbl)
	badge_row.add_child(num_badge)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d-%d" % [z["min_lv"], z["max_lv"]]
	lv_lbl.add_theme_font_size_override("font_size", 8)
	lv_lbl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY if not locked else ThemeConfig.TXT_DISABLED)
	badge_row.add_child(lv_lbl)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(88, 44)
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var boss_path: String = AssetRegistry.get_boss_texture(zone_idx)
	var boss_tex: Texture2D = AssetRegistry.load_texture(boss_path)
	if boss_tex:
		thumb.texture = boss_tex
	thumb.modulate = Color(0.45, 0.45, 0.50, 0.5) if locked else Color(1, 1, 1, 0.92)
	vbox.add_child(thumb)

	var name_lbl := Label.new()
	var prefix := "▶ " if is_current else ("🔒 " if locked else "")
	name_lbl.text = "%s%s" % [prefix, z["name"]]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(100, 0)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD if is_current else (ThemeConfig.TXT_ON_DARK if not locked else ThemeConfig.TXT_DISABLED))
	vbox.add_child(name_lbl)

	if locked:
		var lock_overlay := ColorRect.new()
		lock_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_overlay.color = Color(0.02, 0.02, 0.04, 0.5)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lock_overlay)

func _find_scroll_parent() -> ScrollContainer:
	var n: Node = get_parent()
	while n:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null


class MapPathLayer extends Control:
	var centers: PackedVector2Array = PackedVector2Array()
	var unlocked_zone: int = 0

	func _draw() -> void:
		if centers.size() < 2:
			return
		for i in range(centers.size() - 1):
			var from: Vector2 = centers[i]
			var to: Vector2 = centers[i + 1]
			var lit: bool = i < unlocked_zone
			var path_col: Color = Color(0.85, 0.72, 0.38, 0.82) if lit else Color(0.35, 0.32, 0.42, 0.45)
			_draw_path_segment(from, to, path_col, 6.0 if lit else 3.0)
			if lit:
				draw_circle(from, 7.0, Color(0.92, 0.78, 0.42, 0.65))
		if centers.size() > 0:
			var last_i: int = centers.size() - 1
			if last_i <= unlocked_zone:
				draw_circle(centers[last_i], 7.0, Color(0.92, 0.78, 0.42, 0.65))

	func _draw_path_segment(from: Vector2, to: Vector2, color: Color, width: float) -> void:
		var mid := (from + to) * 0.5
		var dir := (to - from).normalized()
		var normal := Vector2(-dir.y, dir.x)
		var ctrl := mid + normal * from.distance_to(to) * 0.16
		var steps := 28
		var prev := from
		for s in range(1, steps + 1):
			var t: float = float(s) / float(steps)
			var inv: float = 1.0 - t
			var pt := inv * inv * from + 2.0 * inv * t * ctrl + t * t * to
			draw_line(prev, pt, color, width)
			prev = pt
