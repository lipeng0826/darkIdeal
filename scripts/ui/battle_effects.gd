extends Node2D
class_name BattleEffects
## 暗影深渊 - 战斗特效系统
## 管理粒子、血花、打击特效、暴击闪光

var particles: Array[Dictionary] = []
var blood_particles: Array[Dictionary] = []

const MAX_PARTICLES := 50

## 生成攻击粒子
func spawn_hit_particles(pos: Vector2, color: Color, count: int = 5) -> void:
	for i in range(count):
		if particles.size() >= MAX_PARTICLES:
			break
		var angle := randf() * TAU
		var speed := randf_range(50.0, 150.0)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"life": 1.0,
			"size": randf_range(2.0, 5.0),
			"gravity": randf_range(50.0, 150.0),
		})

## 生成暴击特效
func spawn_crit_effect(pos: Vector2) -> void:
	# 金色爆裂
	for i in range(12):
		var angle := (float(i) / 12.0) * TAU
		var speed := randf_range(100.0, 200.0)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(1.0, 0.85, 0.0, 1.0),
			"life": 1.2,
			"size": randf_range(3.0, 7.0),
			"gravity": 0.0,
		})
	# 外圈白色
	for i in range(8):
		var angle := (float(i) / 8.0) * TAU + 0.3
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * 250.0,
			"color": Color(1.0, 1.0, 1.0, 0.8),
			"life": 0.5,
			"size": randf_range(1.5, 3.0),
			"gravity": 0.0,
		})

## 生成Boss出场特效
func spawn_boss_entrance(pos: Vector2) -> void:
	for i in range(30):
		var angle := randf() * TAU
		var dist := randf_range(20.0, 80.0)
		var start := pos + Vector2(cos(angle), sin(angle)) * dist
		particles.append({
			"pos": start,
			"vel": (pos - start).normalized() * randf_range(30.0, 80.0),
			"color": Color(0.8, 0.1, 0.1, 1.0),
			"life": 1.5,
			"size": randf_range(3.0, 8.0),
			"gravity": -20.0,
		})

## 生成血花
func spawn_blood(pos: Vector2, direction: Vector2) -> void:
	for i in range(6):
		var spread := direction.rotated(randf_range(-0.5, 0.5))
		var speed := randf_range(80.0, 180.0)
		blood_particles.append({
			"pos": pos,
			"vel": spread * speed,
			"color": Color(0.6, 0.0, 0.0, 0.9),
			"life": 0.8,
			"size": randf_range(2.0, 4.0),
			"gravity": 200.0,
		})

## 更新所有粒子
func _process(delta: float) -> void:
	# 更新普通粒子
	var i := particles.size() - 1
	while i >= 0:
		var p := particles[i]
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"].y += p["gravity"] * delta
		p["vel"] *= 0.98  # 阻力
		p["size"] *= 0.99
		if p["life"] <= 0:
			particles.remove_at(i)
		i -= 1
	
	# 更新血花
	i = blood_particles.size() - 1
	while i >= 0:
		var p := blood_particles[i]
		p["life"] -= delta * 1.5
		p["pos"] += p["vel"] * delta
		p["vel"].y += p["gravity"] * delta
		p["vel"] *= 0.95
		if p["life"] <= 0:
			blood_particles.remove_at(i)
		i -= 1
	
	queue_redraw()

func _draw() -> void:
	# 绘制粒子
	for p in particles:
		var alpha := clampf(p["life"], 0.0, 1.0)
		var color: Color = p["color"]
		color.a = alpha
		draw_circle(p["pos"], p["size"] * alpha, color)
	
	# 绘制血花
	for p in blood_particles:
		var alpha := clampf(p["life"], 0.0, 1.0)
		var color: Color = p["color"]
		color.a = alpha * 0.8
		draw_circle(p["pos"], p["size"], color)
