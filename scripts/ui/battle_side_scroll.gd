extends RefCounted
class_name BattleSideScrollState
## 横版跑图战斗节奏：跑步推进 → 遇敌(可多怪) → 接战 → 清场后继续跑

enum Phase { IDLE, RUNNING, APPROACH, COMBAT, BOSS }

const RUN_SPEED := 168.0
const RUN_SEGMENT_LEN := 220.0
const FIRST_SEGMENT_SCALE := 0.38
const REINFORCE_SEGMENT_SCALE := 0.48

var phase := Phase.IDLE
var scroll_offset := 0.0
var run_segment_progress := 0.0
var wave_total := 0
var wave_cleared_count := 0
var on_field_max := BattleLayout.MAX_LANE_MOBS
var _first_segment := true

func reset_wave(enemy_count: int) -> void:
	phase = Phase.RUNNING if enemy_count > 0 else Phase.IDLE
	scroll_offset = 0.0
	run_segment_progress = 0.0
	wave_total = enemy_count
	wave_cleared_count = 0
	_first_segment = true

func reset_boss() -> void:
	phase = Phase.BOSS
	run_segment_progress = 0.0

func stop() -> void:
	phase = Phase.IDLE

func tick(delta: float) -> void:
	if phase == Phase.RUNNING or phase == Phase.COMBAT:
		scroll_offset += RUN_SPEED * delta * (0.35 if phase == Phase.COMBAT else 1.0)
	if phase == Phase.RUNNING or (phase == Phase.COMBAT and run_segment_progress < segment_need(1)):
		run_segment_progress += RUN_SPEED * delta

func segment_need(on_field_count: int = 0) -> float:
	if on_field_count > 0:
		return RUN_SEGMENT_LEN * REINFORCE_SEGMENT_SCALE
	if _first_segment:
		return RUN_SEGMENT_LEN * FIRST_SEGMENT_SCALE
	return RUN_SEGMENT_LEN

func should_spawn(queue_has_enemy: bool, on_field_count: int) -> bool:
	if not queue_has_enemy:
		return false
	if on_field_count >= on_field_max:
		return false
	if phase == Phase.BOSS or phase == Phase.IDLE:
		return false
	if phase == Phase.APPROACH:
		return false
	if on_field_count == 0:
		return phase == Phase.RUNNING and run_segment_progress >= segment_need(0)
	# 战斗中允许援军从右侧补位，最多同屏 3 只
	return run_segment_progress >= segment_need(on_field_count)

func on_spawn_started(on_field_before: int) -> void:
	if on_field_before == 0:
		phase = Phase.APPROACH
	run_segment_progress = 0.0
	_first_segment = false

func on_combat_started() -> void:
	if phase != Phase.BOSS:
		phase = Phase.COMBAT

func on_enemy_killed(queue_has_enemy: bool, field_has_enemy: bool) -> void:
	wave_cleared_count += 1
	if not queue_has_enemy and not field_has_enemy:
		phase = Phase.IDLE
	elif field_has_enemy:
		phase = Phase.COMBAT
	else:
		phase = Phase.RUNNING
		run_segment_progress = 0.0

func is_running() -> bool:
	return phase == Phase.RUNNING

func is_scrolling() -> bool:
	return phase == Phase.RUNNING or phase == Phase.APPROACH or phase == Phase.COMBAT

func get_run_progress() -> float:
	var need: float = segment_need(1 if phase == Phase.COMBAT else 0)
	if need <= 0.0:
		return 0.0
	return clampf(run_segment_progress / need, 0.0, 1.0)

func status_text() -> String:
	match phase:
		Phase.RUNNING:
			return "推进中"
		Phase.APPROACH:
			return "接敌"
		Phase.COMBAT:
			return "战斗中"
		Phase.BOSS:
			return "BOSS战"
		_:
			return ""
