extends RefCounted
class_name BattleLayout
## 战斗场景布局 - 伪 2.5D 透视地面 + 纵深站位

const HORIZON_Y_RATIO := 0.48
const VANISH_X_RATIO := 0.34
const GROUND_NEAR_Y_RATIO := 0.86
const GROUND_FAR_Y_RATIO := 0.68
const HERO_HEIGHT_RATIO := 0.36
const ENEMY_HEIGHT_RATIO := 0.30
const MOB_HEIGHT_RATIO := 0.24
const BOSS_HEIGHT_RATIO := 0.50
const MOB_SPRITE_SCALE := 0.72
const BOSS_SPRITE_SCALE := 1.48
const BOSS_SCALE_THRESHOLD := 1.15
const SPRITE_FOOT_INSET := 8.0
const PLAYER_DEPTH := 0.06
const SCALE_NEAR := 1.0
const SCALE_FAR := 0.76

# 兼容旧引用（约等于前排地面）
const GROUND_Y_RATIO := 0.813

const ENEMY_SLOTS: Array = [
	{"x": 0.54, "depth": 0.62},
	{"x": 0.68, "depth": 0.10},
	{"x": 0.76, "depth": 0.38},
	{"x": 0.60, "depth": 0.82},
	{"x": 0.72, "depth": 0.24},
]

# 横版跑图模式（单车道）
const SIDE_HORIZON_Y_RATIO := 0.44
const SIDE_GROUND_Y_RATIO := 0.84
const PLAYER_SCREEN_X_RATIO := 0.22
const ENEMY_ENGAGE_X_RATIO := 0.56
const BOSS_ENGAGE_X_RATIO := 0.62
const ENEMY_SPAWN_X_OFFSET := 72.0
const LANE_DEPTH := 0.08
const LANE_X_RATIOS := [0.56, 0.66, 0.76]
const MAX_LANE_MOBS := 3

static func depth_to_ground_y(arena_h: float, depth: float) -> float:
	var d: float = clampf(depth, 0.0, 1.0)
	return lerpf(arena_h * GROUND_NEAR_Y_RATIO, arena_h * GROUND_FAR_Y_RATIO, d)

static func depth_to_scale(depth: float) -> float:
	return lerpf(SCALE_NEAR, SCALE_FAR, clampf(depth, 0.0, 1.0))

static func depth_to_z_index(ground_y: float) -> int:
	return int(ground_y)

static func ground_x_at_depth(arena_w: float, x_ratio: float, depth: float) -> float:
	var vanish_x: float = arena_w * VANISH_X_RATIO
	var screen_x: float = arena_w * x_ratio
	return lerpf(screen_x, vanish_x + (screen_x - vanish_x) * 0.15, depth * 0.25)

static func get_player_anchor(arena_size: Vector2) -> Dictionary:
	var ground_y: float = side_ground_y(arena_size.y)
	var sc: float = depth_to_scale(LANE_DEPTH)
	return {
		"ground_y": ground_y,
		"scale": sc,
		"z": depth_to_z_index(ground_y),
		"screen_x": arena_size.x * PLAYER_SCREEN_X_RATIO,
	}

static func side_ground_y(arena_h: float) -> float:
	return arena_h * SIDE_GROUND_Y_RATIO

static func get_lane_enemy_slot(arena_size: Vector2, lane_slot: int = 0, is_boss: bool = false) -> Dictionary:
	var depth: float = LANE_DEPTH
	var ground_y: float = side_ground_y(arena_size.y)
	var sc: float = depth_to_scale(depth)
	var x_ratio: float
	if is_boss:
		x_ratio = BOSS_ENGAGE_X_RATIO
	else:
		x_ratio = LANE_X_RATIOS[clampi(lane_slot, 0, LANE_X_RATIOS.size() - 1)]
	var x: float = arena_size.x * x_ratio
	return {
		"x": x,
		"ground_y": ground_y,
		"scale": sc,
		"depth": depth,
		"z": depth_to_z_index(ground_y),
		"lane_slot": lane_slot,
		"is_boss": is_boss,
	}

static func get_enemy_slot(slot_index: int, arena_size: Vector2) -> Dictionary:
	var slot: Dictionary = ENEMY_SLOTS[clampi(slot_index, 0, ENEMY_SLOTS.size() - 1)]
	var depth: float = float(slot["depth"])
	var ground_y: float = depth_to_ground_y(arena_size.y, depth)
	var sc: float = depth_to_scale(depth)
	var x: float = ground_x_at_depth(arena_size.x, float(slot["x"]), depth)
	return {
		"x": x,
		"ground_y": ground_y,
		"scale": sc,
		"depth": depth,
		"z": depth_to_z_index(ground_y),
	}
