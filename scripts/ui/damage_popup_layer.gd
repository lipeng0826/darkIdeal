extends Control
class_name DamagePopupLayer
## 战斗伤害飘字层

const KIND_COLORS := {
	"normal": Color(0.92, 0.90, 0.86),
	"crit": Color(1.0, 0.82, 0.22),
	"skill": Color(0.55, 0.85, 1.0),
	"taken": Color(1.0, 0.35, 0.32),
	"heal": Color(0.45, 0.92, 0.55),
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func show_at_world(world_pos: Vector2, amount: int, kind: String = "normal", label_prefix: String = "") -> void:
	if amount <= 0:
		return
	var local_pos: Vector2 = get_global_transform().affine_inverse() * world_pos
	local_pos += Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 2.0))

	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = "%s%d" % [label_prefix, amount]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var color: Color = KIND_COLORS.get(kind, KIND_COLORS["normal"])
	var font_size: int = 11
	var start_scale := Vector2(0.65, 0.65)
	match kind:
		"crit":
			font_size = 15
			start_scale = Vector2(0.8, 0.8)
			lbl.text = "%s%d!" % [label_prefix, amount]
		"skill":
			font_size = 13
			start_scale = Vector2(0.72, 0.72)
		"taken":
			font_size = 12
		"heal":
			font_size = 11
			lbl.text = "+%d" % amount

	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.pivot_offset = Vector2(20, 10)
	lbl.position = local_pos - lbl.pivot_offset
	lbl.scale = start_scale
	add_child(lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - randf_range(28.0, 42.0), 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.05, 1.05) if kind == "crit" else Vector2.ONE, 0.12)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.28).set_delay(0.22)
	tw.tween_callback(lbl.queue_free).set_delay(0.55)
