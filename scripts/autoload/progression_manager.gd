extends Node
## 养成进度管理器 — 加载 data/*.json，提供等级段、解锁、曲线查询

signal system_unlocked(system_id: String, system_info: Dictionary)
signal bracket_changed(old_id: String, new_id: String)

var _curves: Dictionary = {}
var _systems: Array = []
var _milestones: Array = []
var _synthesis: Dictionary = {}
var _systems_by_id: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	_curves = _load_json("res://data/balance_curves.json")
	var prog: Dictionary = _load_json("res://data/progression_systems.json")
	_systems = prog.get("systems", [])
	_milestones = prog.get("bracket_milestones", [])
	_synthesis = _load_json("res://data/synthesis_catalog.json")
	_systems_by_id.clear()
	for sys in _systems:
		_systems_by_id[sys["id"]] = sys

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("ProgressionManager: missing %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	push_error("ProgressionManager: invalid JSON %s" % path)
	return {}

func is_ready() -> bool:
	return not _curves.is_empty()

# ==================== 经验曲线 ====================

func exp_for_level(lv: int) -> int:
	var formula: Dictionary = _curves.get("exp_formula", {})
	var base_f: float = float(formula.get("base", 55))
	var power: float = float(formula.get("power", 1.42))
	var factor: float = float(formula.get("level_factor", 0.035))
	lv = maxi(1, lv)
	return int(base_f * pow(float(lv), power) * (1.0 + float(lv) * factor))

func get_player_base_stats() -> Dictionary:
	return _curves.get("player_base_stats", {})

# ==================== 等级段 ====================

func get_bracket(level: int) -> Dictionary:
	for bracket in _curves.get("level_brackets", []):
		if level >= int(bracket["min_level"]) and level <= int(bracket["max_level"]):
			return bracket
	var brackets: Array = _curves.get("level_brackets", [])
	if brackets.is_empty():
		return {}
	return brackets[brackets.size() - 1]

func get_bracket_id(level: int) -> String:
	return str(get_bracket(level).get("id", ""))

func get_drop_rates(level: int) -> Dictionary:
	var b: Dictionary = get_bracket(level)
	return {
		"equip": float(b.get("drop_rate_equip", 0.15)),
		"material": float(b.get("drop_rate_material", 0.30)),
		"equip_pity_waves": int(b.get("equip_pity_waves", 5)),
	}

func get_reward_multipliers(level: int) -> Dictionary:
	var b: Dictionary = get_bracket(level)
	return {
		"exp": float(b.get("exp_reward_mult", 1.0)),
		"gold": float(b.get("gold_reward_mult", 1.0)),
	}

func get_unlocked_materials(level: int) -> Array:
	var b: Dictionary = get_bracket(level)
	return b.get("materials_unlocked", [])

func get_all_brackets() -> Array:
	return _curves.get("level_brackets", [])

# ==================== 系统解锁 ====================

func get_system(system_id: String) -> Dictionary:
	return _systems_by_id.get(system_id, {})

func get_all_systems() -> Array:
	return _systems

func is_system_unlocked(system_id: String, level: int) -> bool:
	var sys: Dictionary = get_system(system_id)
	if sys.is_empty():
		return false
	return level >= int(sys.get("unlock_level", 999))

func get_unlocks_at_level(level: int) -> Array:
	var result: Array = []
	for sys in _systems:
		if int(sys.get("unlock_level", 999)) == level:
			result.append(sys)
	return result

func get_unlocked_systems(level: int) -> Array:
	var result: Array = []
	for sys in _systems:
		if level >= int(sys.get("unlock_level", 999)):
			result.append(sys["id"])
	return result

func get_next_unlock(level: int) -> Dictionary:
	var best: Dictionary = {}
	var best_lv := 999
	for sys in _systems:
		var ul: int = int(sys.get("unlock_level", 999))
		if ul > level and ul < best_lv:
			best_lv = ul
			best = sys
	return best

func get_milestone(level: int) -> Dictionary:
	for m in _milestones:
		if int(m.get("level", 0)) == level:
			return m
	return {}

# ==================== 合成表 ====================

func get_synthesis_categories() -> Dictionary:
	return _synthesis.get("categories", {})

func get_synthesis_for_system(system_id: String) -> Dictionary:
	return get_synthesis_categories().get(system_id, {})

func get_available_synthesis_tiers(system_id: String, level: int) -> Array:
	var cat: Dictionary = get_synthesis_for_system(system_id)
	if cat.is_empty():
		return []
	if level < int(cat.get("unlock_level", 999)):
		return []
	var result: Array = []
	for tier in cat.get("tiers", []):
		var rng: Array = tier.get("level_range", [0, 999])
		if level >= int(rng[0]) and level <= int(rng[1]):
			result.append(tier)
	return result

# ==================== 存档同步 ====================

func ensure_progression_data(game_data: Dictionary) -> void:
	if not game_data.has("progression"):
		game_data["progression"] = {
			"unlocked_systems": [],
			"system_tiers": {},
			"waves_since_equip": 0,
			"current_bracket": "",
		}

func sync_unlocks(game_data: Dictionary, level: int, notify: bool = false) -> Array:
	ensure_progression_data(game_data)
	var prog: Dictionary = game_data["progression"]
	var newly: Array = []
	var all_unlocked: Array = get_unlocked_systems(level)
	for sid in all_unlocked:
		if sid not in prog["unlocked_systems"]:
			prog["unlocked_systems"].append(sid)
			newly.append(sid)
			if notify:
				system_unlocked.emit(sid, get_system(sid))
	var new_bracket: String = get_bracket_id(level)
	var old_bracket: String = str(prog.get("current_bracket", ""))
	if new_bracket != old_bracket and not old_bracket.is_empty():
		bracket_changed.emit(old_bracket, new_bracket)
	prog["current_bracket"] = new_bracket
	return newly

func check_level_up_unlocks(game_data: Dictionary, new_level: int) -> void:
	var unlocks: Array = get_unlocks_at_level(new_level)
	sync_unlocks(game_data, new_level, false)
	for sys in unlocks:
		system_unlocked.emit(sys["id"], sys)
		var status: String = str(sys.get("status", ""))
		if status != "planned":
			GameManager.toast_message.emit(
				"解锁: %s (Lv.%d)" % [sys.get("name", ""), int(sys.get("unlock_level", 0))],
				Color(0.5, 0.9, 1.0)
			)
	var milestone: Dictionary = get_milestone(new_level)
	if not milestone.is_empty():
		GameManager.toast_message.emit(
			"【%s】%s" % [milestone.get("title", ""), milestone.get("unlock_hint", "")],
			Color(1.0, 0.85, 0.3)
		)

# ==================== 掉落保底 ====================

func should_force_equip_drop(game_data: Dictionary, level: int) -> bool:
	ensure_progression_data(game_data)
	var prog: Dictionary = game_data["progression"]
	var pity: int = get_drop_rates(level).get("equip_pity_waves", 5)
	return int(prog.get("waves_since_equip", 0)) >= pity

func record_wave_loot(game_data: Dictionary, had_equip: bool) -> void:
	ensure_progression_data(game_data)
	var prog: Dictionary = game_data["progression"]
	if had_equip:
		prog["waves_since_equip"] = 0
	else:
		prog["waves_since_equip"] = int(prog.get("waves_since_equip", 0)) + 1

func filter_material_drop(mat_id: String, level: int) -> bool:
	var allowed: Array = get_unlocked_materials(level)
	if allowed.is_empty():
		return true
	return mat_id in allowed
