extends Control
class_name BattleWaveProgress
## 局内波次进度条：节点表示每波，末端大节点表示 Boss

signal boss_tap_requested()

var total_waves := 3
var cleared_waves := 0
var boss_ready := false
var is_boss_fight := false
var _pulse := 0.0

const NODE_R := 7.0
const BOSS_R := 12.0
const TRACK_H := 3.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_pulse += delta * 3.2
	queue_redraw()

func set_run_state(cleared: int, total: int, boss_ready_state: bool, boss_fight: bool) -> void:
	cleared_waves = maxi(0, cleared)
	total_waves = maxi(1, total)
	boss_ready = boss_ready_state
	is_boss_fight = boss_fight
	mouse_filter = Control.MOUSE_FILTER_STOP if boss_ready and not is_boss_fight else Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not boss_ready or is_boss_fight:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			boss_tap_requested.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 60.0:
		return
	var cy: float = h * 0.52
	var pad: float = 28.0
	var end_x: float = w - pad
	var track_w: float = end_x - pad
	var step: float = track_w / float(total_waves) if total_waves > 0 else track_w

	# 轨道底色
	draw_rect(Rect2(pad, cy - TRACK_H * 0.5, track_w, TRACK_H), Color(0.12, 0.11, 0.16, 0.9))
	# 已完成轨道填充
	var fill_w: float = 0.0
	if cleared_waves > 0:
		fill_w = step * float(mini(cleared_waves, total_waves))
	elif is_boss_fight or boss_ready:
		fill_w = track_w
	draw_rect(Rect2(pad, cy - TRACK_H * 0.5, fill_w, TRACK_H), Color(0.42, 0.62, 0.48, 0.85))

	# 小怪波次节点
	for i in range(total_waves):
		var x: float = pad + step * float(i)
		var done: bool = i < cleared_waves
		var current: bool = i == cleared_waves and not boss_ready and not is_boss_fight
		_draw_wave_node(Vector2(x, cy), done, current, i + 1)

	# Boss 大节点
	var bx: float = pad + step * float(total_waves)
	_draw_boss_node(Vector2(bx, cy))

	# 标题
	var title: String = "BOSS战" if is_boss_fight else ("点击挑战 Boss" if boss_ready else "第 %d/%d 波" % [mini(cleared_waves + 1, total_waves), total_waves])
	_draw_centered_text(title, Vector2(w * 0.5, h * 0.18), 10, Color(0.90, 0.84, 0.68, 0.95))

func _draw_wave_node(pos: Vector2, done: bool, current: bool, index: int) -> void:
	var fill_col := Color(0.48, 0.78, 0.55, 1.0) if done else Color(0.18, 0.17, 0.24, 0.95)
	var border_col := Color(0.55, 0.48, 0.32, 0.9)
	if current:
		var pulse_a: float = 0.45 + sin(_pulse) * 0.35
		draw_circle(pos, NODE_R + 4.0 + sin(_pulse) * 1.5, Color(0.88, 0.72, 0.35, pulse_a))
		border_col = Color(0.92, 0.78, 0.42, 1.0)
	draw_circle(pos, NODE_R + 1.5, border_col)
	draw_circle(pos, NODE_R, fill_col)
	if done:
		_draw_centered_text("✓", pos + Vector2(0, -1), 9, Color(0.12, 0.16, 0.12, 0.9))
	else:
		_draw_centered_text(str(index), pos + Vector2(0, -1), 8, Color(0.82, 0.80, 0.88, 0.9 if current else 0.55))

func _draw_boss_node(pos: Vector2) -> void:
	var fill_col: Color
	var border_col: Color
	if is_boss_fight:
		var pulse_a: float = 0.5 + sin(_pulse * 1.4) * 0.4
		draw_circle(pos, BOSS_R + 6.0 + sin(_pulse * 1.2) * 2.0, Color(0.95, 0.28, 0.22, pulse_a))
		fill_col = Color(0.82, 0.22, 0.20, 1.0)
		border_col = Color(1.0, 0.45, 0.35, 1.0)
	elif boss_ready:
		var pulse_a2: float = 0.35 + sin(_pulse) * 0.25
		draw_circle(pos, BOSS_R + 5.0, Color(0.95, 0.55, 0.22, pulse_a2))
		fill_col = Color(0.72, 0.28, 0.22, 1.0)
		border_col = Color(0.95, 0.72, 0.32, 1.0)
	else:
		fill_col = Color(0.16, 0.14, 0.20, 0.95)
		border_col = Color(0.40, 0.34, 0.28, 0.75)
	draw_circle(pos, BOSS_R + 2.0, border_col)
	draw_circle(pos, BOSS_R, fill_col)
	_draw_centered_text("💀", pos + Vector2(0, -1), 11, Color(1, 1, 1, 0.95 if (boss_ready or is_boss_fight) else 0.45))

func _draw_centered_text(text: String, pos: Vector2, font_size: int, col: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - Vector2(sz.x * 0.5, -sz.y * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
