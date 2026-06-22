extends Node2D
class_name EnemyRenderer
## 暗影深渊 - 程序化敌人渲染器
## 根据敌人类型程序化绘制暗黑风角色

var enemy_name := ""
var zone_index := 0
var is_boss := false
var hit_flash := 0.0
var idle_time := 0.0
var death_progress := 0.0
var is_dying := false

# 视觉参数
var base_color := Color(0.4, 0.1, 0.1)
var accent_color := Color(0.8, 0.2, 0.1)
var eye_color := Color(1.0, 0.2, 0.0)
var body_scale := Vector2(1.0, 1.0)

func setup(name: String, zone_idx: int, boss: bool = false) -> void:
	enemy_name = name
	zone_index = zone_idx
	is_boss = boss
	_generate_colors()
	if boss:
		body_scale = Vector2(1.5, 1.5)
	else:
		body_scale = Vector2(0.8 + randf() * 0.4, 0.8 + randf() * 0.4)

func flash() -> void:
	hit_flash = 1.0

func start_death() -> void:
	is_dying = true
	death_progress = 0.0

func _generate_colors() -> void:
	# 根据区域生成颜色风格
	var zone_colors := [
		[Color(0.1, 0.3, 0.1), Color(0.2, 0.5, 0.1)],   # 森林-绿
		[Color(0.3, 0.2, 0.3), Color(0.5, 0.3, 0.5)],   # 墓穴-紫灰
		[Color(0.2, 0.1, 0.3), Color(0.4, 0.1, 0.6)],   # 影域-暗紫
		[Color(0.4, 0.1, 0.0), Color(0.8, 0.2, 0.0)],   # 深渊-暗红
		[Color(0.3, 0.2, 0.0), Color(0.6, 0.4, 0.0)],   # 王座-暗金
		[Color(0.1, 0.1, 0.3), Color(0.2, 0.2, 0.6)],   # 虚空-深蓝
		[Color(0.05, 0.1, 0.2), Color(0.1, 0.2, 0.5)],  # 永夜-冰蓝
		[Color(0.3, 0.05, 0.0), Color(0.7, 0.1, 0.0)],  # 炼狱-火红
		[Color(0.2, 0.0, 0.2), Color(0.5, 0.0, 0.4)],   # 灭世-暗粉
		[Color(0.1, 0.0, 0.1), Color(0.3, 0.0, 0.2)],   # 终焉-极暗
	]
	var idx := clampi(zone_index, 0, zone_colors.size() - 1)
	base_color = zone_colors[idx][0]
	accent_color = zone_colors[idx][1]
	
	if is_boss:
		accent_color = accent_color.lightened(0.3)
		eye_color = Color(1.0, 0.0, 0.0)
	else:
		eye_color = accent_color.lightened(0.5)

func _process(delta: float) -> void:
	idle_time += delta
	if hit_flash > 0:
		hit_flash -= delta * 5.0
	if is_dying:
		death_progress += delta * 2.0
		if death_progress >= 1.0:
			is_dying = false
	queue_redraw()

func _draw() -> void:
	if is_dying and death_progress >= 1.0:
		return
	
	var center := Vector2.ZERO
	var s := body_scale
	var alpha := 1.0 - death_progress if is_dying else 1.0
	
	# 呼吸动画
	var breathe := sin(idle_time * 2.0) * 0.02
	s.y += breathe
	
	# 身体颜色（受击闪白）
	var body_col := base_color
	if hit_flash > 0:
		body_col = body_col.lerp(Color.WHITE, hit_flash * 0.8)
	body_col.a = alpha
	
	# 绘制阴影
	var shadow_col := Color(0.0, 0.0, 0.0, 0.3 * alpha)
	draw_ellipse(center + Vector2(0, 40 * s.y), Vector2(30 * s.x, 8 * s.y), shadow_col)
	
	# 主体
	if is_boss:
		_draw_boss(center, s, body_col, alpha)
	else:
		_draw_enemy(center, s, body_col, alpha)

func _draw_enemy(center: Vector2, s: Vector2, body_col: Color, alpha: float) -> void:
	# 身体（椭圆）
	draw_ellipse(center, Vector2(22 * s.x, 30 * s.y), body_col)
	
	# 轮廓
	var outline_col := accent_color
	outline_col.a = alpha * 0.6
	draw_arc(center, 22 * s.x, 0.0, TAU, 32, outline_col, 1.5)
	
	# 眼睛
	var eye_l := center + Vector2(-8 * s.x, -8 * s.y)
	var eye_r := center + Vector2(8 * s.x, -8 * s.y)
	var ec := eye_color
	ec.a = alpha
	draw_circle(eye_l, 3.0 * s.x, ec)
	draw_circle(eye_r, 3.0 * s.x, ec)
	
	# 嘴/爪痕
	var mouth_col := Color(0.0, 0.0, 0.0, 0.7 * alpha)
	var mouth_y := center.y + 6 * s.y
	draw_line(Vector2(center.x - 6 * s.x, mouth_y), Vector2(center.x + 6 * s.x, mouth_y + 3), mouth_col, 2.0)

func _draw_boss(center: Vector2, s: Vector2, body_col: Color, alpha: float) -> void:
	# Boss更大更复杂
	# 身体
	draw_ellipse(center, Vector2(35 * s.x, 45 * s.y), body_col)
	
	# 暗黑光环
	var aura_col := accent_color
	aura_col.a = alpha * (0.3 + sin(idle_time * 3.0) * 0.15)
	draw_arc(center, 50 * s.x, 0.0, TAU, 48, aura_col, 3.0)
	draw_arc(center, 55 * s.x, 0.0, TAU, 48, aura_col * 0.5, 2.0)
	
	# 角
	var horn_col := accent_color
	horn_col.a = alpha
	var horn_l := center + Vector2(-20 * s.x, -35 * s.y)
	var horn_r := center + Vector2(20 * s.x, -35 * s.y)
	draw_line(center + Vector2(-15 * s.x, -30 * s.y), horn_l + Vector2(-5, -15), horn_col, 3.0)
	draw_line(center + Vector2(15 * s.x, -30 * s.y), horn_r + Vector2(5, -15), horn_col, 3.0)
	
	# 双眼（更大更亮）
	var eye_l := center + Vector2(-12 * s.x, -10 * s.y)
	var eye_r := center + Vector2(12 * s.x, -10 * s.y)
	var ec := eye_color
	ec.a = alpha
	draw_circle(eye_l, 5.0 * s.x, ec)
	draw_circle(eye_r, 5.0 * s.x, ec)
	
	# 瞳孔
	var pupil_col := Color(0.0, 0.0, 0.0, alpha)
	draw_circle(eye_l, 2.0 * s.x, pupil_col)
	draw_circle(eye_r, 2.0 * s.x, pupil_col)
	
	# 嘴
	var mouth_col := Color(0.0, 0.0, 0.0, 0.8 * alpha)
	var teeth_col := Color(0.9, 0.9, 0.9, alpha)
	draw_line(center + Vector2(-15 * s.x, 10 * s.y), center + Vector2(15 * s.x, 10 * s.y), mouth_col, 2.5)
	# 牙齿
	for i in range(5):
		var tx := center.x + (-12 + i * 6) * s.x
		draw_line(Vector2(tx, center.y + 10 * s.y), Vector2(tx, center.y + 15 * s.y), teeth_col, 1.5)

## 辅助绘制函数
func draw_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := float(i) / 32.0 * TAU
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)
