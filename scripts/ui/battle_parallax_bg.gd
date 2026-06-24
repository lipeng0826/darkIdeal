extends Control
class_name BattleParallaxBg
## 横版战斗视差背景：天空 + 远景贴图 + 山脊 + 滚动地面

var _zone_tex: Texture2D
var _scroll := 0.0
var _zone_tint := Color(0.72, 0.78, 0.92, 1.0)

const TILE_W := 420.0

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

func set_zone_texture(tex: Texture2D, tint: Color = Color.WHITE) -> void:
	_zone_tex = tex
	_zone_tint = tint
	queue_redraw()

func set_scroll(offset: float) -> void:
	if absf(offset - _scroll) > 0.4:
		_scroll = offset
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 40.0 or h < 40.0:
		return

	var horizon: float = h * BattleLayout.SIDE_HORIZON_Y_RATIO
	var ground_y: float = h * BattleLayout.SIDE_GROUND_Y_RATIO

	# 天空渐变
	var sky_top := Color(0.06, 0.05, 0.12, 1.0)
	var sky_mid := Color(0.14, 0.10, 0.20, 1.0)
	var sky_bot := Color(0.22, 0.16, 0.28, 1.0)
	for i in range(24):
		var t0: float = float(i) / 24.0
		var t1: float = float(i + 1) / 24.0
		var c0: Color = sky_top.lerp(sky_mid, t0).lerp(sky_bot, t0 * t0)
		var c1: Color = sky_top.lerp(sky_mid, t1).lerp(sky_bot, t1 * t1)
		var y0: float = h * t0 * 0.72
		var y1: float = h * t1 * 0.72
		draw_rect(Rect2(0, y0, w, y1 - y0 + 1.0), c0.lerp(c1, 0.5))

	# 远景区域贴图（慢速视差）
	if _zone_tex:
		var far_off: float = fmod(_scroll * 0.10, TILE_W)
		var far_h: float = horizon + 24.0
		var tiles: int = int(ceil(w / TILE_W)) + 2
		for i in range(-1, tiles):
			var tx: float = i * TILE_W - far_off
			var rect := Rect2(tx, 18.0, TILE_W, far_h)
			draw_texture_rect(_zone_tex, rect, false, Color(_zone_tint.r, _zone_tint.g, _zone_tint.b, 0.34))

	# 中山脊剪影
	var mid_off: float = fmod(_scroll * 0.28, TILE_W)
	for i in range(-1, int(ceil(w / TILE_W)) + 2):
		var base_x: float = i * TILE_W - mid_off
		_draw_ridge(base_x, horizon + 6.0, TILE_W * 0.92, Color(0.10, 0.08, 0.14, 0.88), 0.78)
		_draw_ridge(base_x + TILE_W * 0.38, horizon + 18.0, TILE_W * 0.55, Color(0.08, 0.06, 0.11, 0.92), 0.62)

	# 近景矮丘
	var near_off: float = fmod(_scroll * 0.52, TILE_W * 0.7)
	for i in range(-1, int(ceil(w / (TILE_W * 0.7))) + 2):
		var base_x2: float = i * TILE_W * 0.7 - near_off
		_draw_ridge(base_x2, ground_y - 34.0, TILE_W * 0.44, Color(0.05, 0.04, 0.08, 0.95), 0.38)

	# 地面主体
	var ground_poly := PackedVector2Array([
		Vector2(0, ground_y),
		Vector2(w, ground_y - 8.0),
		Vector2(w, h),
		Vector2(0, h),
	])
	draw_colored_polygon(ground_poly, Color(0.07, 0.06, 0.10, 0.98))

	# 地面纹理线（快速滚动）
	var path_off: float = fmod(_scroll * 1.05, 56.0)
	var path_y: float = ground_y + 10.0
	for x in range(-1, int(w / 56.0) + 3):
		var px: float = x * 56.0 - path_off
		draw_line(Vector2(px, path_y), Vector2(px + 28.0, path_y + 2.0), Color(0.22, 0.18, 0.28, 0.35), 2.0)
		draw_circle(Vector2(px + 8.0, path_y + 1.0), 2.0, Color(0.30, 0.24, 0.36, 0.28))

	# 前景暗角
	var fg := PackedVector2Array([
		Vector2(0, ground_y - 6.0),
		Vector2(w, ground_y - 14.0),
		Vector2(w, h),
		Vector2(0, h),
	])
	draw_colored_polygon(fg, Color(0.02, 0.02, 0.04, 0.22))

func _draw_ridge(base_x: float, base_y: float, width: float, col: Color, height_ratio: float) -> void:
	var peak_h: float = 48.0 + width * height_ratio * 0.08
	var poly := PackedVector2Array([
		Vector2(base_x, base_y),
		Vector2(base_x + width * 0.22, base_y - peak_h * 0.55),
		Vector2(base_x + width * 0.48, base_y - peak_h),
		Vector2(base_x + width * 0.74, base_y - peak_h * 0.62),
		Vector2(base_x + width, base_y),
	])
	draw_colored_polygon(poly, col)
