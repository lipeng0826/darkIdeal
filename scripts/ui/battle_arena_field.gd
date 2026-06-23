extends Control
class_name BattleArenaField
## 战斗场地叠层 - 暗角晕影 + 轻微纵深参考线（不再绘制绿草地）

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 40.0 or h < 40.0:
		return

	var horizon: float = h * BattleLayout.HORIZON_Y_RATIO
	var vanish_x: float = w * BattleLayout.VANISH_X_RATIO

	# 底部暗角：保证角色与血条可读，不遮挡背景主体
	var bottom_grad := PackedVector2Array([
		Vector2(0, h * 0.42),
		Vector2(w, h * 0.42),
		Vector2(w, h),
		Vector2(0, h),
	])
	draw_colored_polygon(bottom_grad, Color(0.02, 0.02, 0.04, 0.38))

	var side_l := PackedVector2Array([
		Vector2(0, 0),
		Vector2(w * 0.18, 0),
		Vector2(w * 0.12, h),
		Vector2(0, h),
	])
	var side_r := PackedVector2Array([
		Vector2(w, 0),
		Vector2(w * 0.82, 0),
		Vector2(w * 0.88, h),
		Vector2(w, h),
	])
	draw_colored_polygon(side_l, Color(0.01, 0.01, 0.03, 0.22))
	draw_colored_polygon(side_r, Color(0.01, 0.01, 0.03, 0.22))

	# 轻微纵深透视线（仅辅助站位，极低透明度）
	for i in range(5):
		var t: float = float(i) / 4.0
		var bx: float = lerpf(0.0, w, t)
		var tx: float = lerpf(vanish_x - w * 0.08, vanish_x + w * 0.38, t)
		draw_line(Vector2(bx, h), Vector2(tx, horizon + 8), Color(0.15, 0.12, 0.20, 0.12), 1.0)

	# 深度等高线（角色站立参考）
	for depth in [0.0, 0.35, 0.7, 1.0]:
		var gy: float = BattleLayout.depth_to_ground_y(h, depth)
		var left_x: float = lerpf(w * 0.04, vanish_x - w * 0.06, depth * 0.55)
		var right_x: float = lerpf(w * 0.96, vanish_x + w * 0.44, depth * 0.4)
		draw_line(Vector2(left_x, gy), Vector2(right_x, gy), Color(0.20, 0.16, 0.28, 0.14), 1.0)
