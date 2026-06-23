extends Node
class_name BattleWaveController
## 波次多怪战斗控制器

signal wave_started(enemies: Array)
signal enemy_spawned(enemy: Dictionary)
signal enemy_hp_changed(enemy_id: int, hp: int, max_hp: int)
signal enemy_died(enemy_id: int, enemy: Dictionary)
signal wave_cleared(killed_enemies: Array)
signal target_changed(enemy_id: int)
signal enemy_activated(enemy_id: int)

enum EnemyState { SPAWNING, ACTIVE, DYING, DEAD }

const WAVE_SIZES := [3, 3, 4, 4, 5]
const ENEMY_ATK_MULT := 0.85
const HITS_TO_KILL_BASE := 6

var wave_enemies: Array = []
var _next_id := 0
var _wave_active := false
var enemy_attack_timers: Dictionary = {}

func is_wave_active() -> bool:
	return _wave_active

func start_wave(zone_idx: int, player_lv: int) -> void:
	wave_enemies.clear()
	enemy_attack_timers.clear()
	var zone: Dictionary = DataManager.ZONES[zone_idx]
	var size: int = WAVE_SIZES[mini(zone_idx, WAVE_SIZES.size() - 1)]
	var base_stats: Dictionary = zone["enemy_stats"]
	var player_atk: int = int(GameManager.game_data["combat"]["atk"])
	var hits_to_kill: int = HITS_TO_KILL_BASE + mini(zone_idx, 2)

	for i in range(size):
		var enemy_idx: int = randi() % zone["enemies"].size()
		var scaled: Dictionary = DataManager.scale_enemy(base_stats, player_lv, zone_idx)
		scaled = DataManager.ensure_wave_enemy_hp(scaled, player_atk, zone_idx, hits_to_kill)
		var enemy := {
			"id": _next_id,
			"name": zone["enemies"][enemy_idx],
			"hp": scaled["hp"],
			"max_hp": scaled["hp"],
			"atk": int(scaled["atk"] * ENEMY_ATK_MULT),
			"def": scaled["def"],
			"exp": scaled["exp"],
			"gold": scaled["gold"],
			"slot_index": i,
			"state": EnemyState.SPAWNING,
		}
		_next_id += 1
		wave_enemies.append(enemy)
		enemy_attack_timers[enemy["id"]] = randf_range(0.8, 2.4)

	_wave_active = true
	wave_started.emit(wave_enemies.duplicate(true))

func activate_enemy(enemy_id: int) -> void:
	var enemy := _get_enemy(enemy_id)
	if enemy.is_empty():
		return
	if enemy["state"] == EnemyState.SPAWNING:
		enemy["state"] = EnemyState.ACTIVE
		enemy_activated.emit(enemy_id)
		_emit_target_changed()

func get_front_target() -> Dictionary:
	for enemy in wave_enemies:
		if enemy["state"] == EnemyState.ACTIVE:
			return enemy
	for enemy in wave_enemies:
		if enemy["state"] == EnemyState.SPAWNING:
			return enemy
	return {}

func get_active_enemies() -> Array:
	var result: Array = []
	for enemy in wave_enemies:
		if enemy["state"] == EnemyState.ACTIVE:
			result.append(enemy)
	return result

func get_enemy(enemy_id: int) -> Dictionary:
	return _get_enemy(enemy_id)

func damage_enemy(enemy_id: int, dmg: int) -> bool:
	var enemy := _get_enemy(enemy_id)
	if enemy.is_empty():
		return false
	if enemy["state"] == EnemyState.DEAD or enemy["state"] == EnemyState.DYING:
		return false
	enemy["hp"] = maxi(0, int(enemy["hp"]) - dmg)
	enemy_hp_changed.emit(enemy_id, int(enemy["hp"]), int(enemy["max_hp"]))
	if int(enemy["hp"]) <= 0:
		_kill_enemy(enemy_id)
		return true
	return false

func damage_front_target(dmg: int) -> bool:
	var target := get_front_target()
	if target.is_empty():
		return false
	return damage_enemy(int(target["id"]), dmg)

func _kill_enemy(enemy_id: int) -> void:
	var enemy := _get_enemy(enemy_id)
	if enemy.is_empty():
		return
	enemy["state"] = EnemyState.DYING
	enemy_died.emit(enemy_id, enemy.duplicate(true))
	enemy["state"] = EnemyState.DEAD
	_check_wave_complete()
	_emit_target_changed()

func _check_wave_complete() -> void:
	for enemy in wave_enemies:
		if enemy["state"] != EnemyState.DEAD:
			return
	_wave_active = false
	var killed: Array = []
	for enemy in wave_enemies:
		killed.append(enemy.duplicate(true))
	wave_cleared.emit(killed)

func is_complete() -> bool:
	if wave_enemies.is_empty():
		return true
	for enemy in wave_enemies:
		if enemy["state"] != EnemyState.DEAD:
			return false
	return true

func cancel_wave() -> void:
	wave_enemies.clear()
	enemy_attack_timers.clear()
	_wave_active = false

func _get_enemy(enemy_id: int) -> Dictionary:
	for enemy in wave_enemies:
		if int(enemy["id"]) == enemy_id:
			return enemy
	return {}

func _emit_target_changed() -> void:
	var target := get_front_target()
	if not target.is_empty():
		target_changed.emit(int(target["id"]))

func sync_legacy_hp() -> Dictionary:
	var target := get_front_target()
	if target.is_empty():
		return {"hp": 0, "max_hp": 0, "name": ""}
	return {
		"hp": int(target["hp"]),
		"max_hp": int(target["max_hp"]),
		"name": target["name"],
		"def": int(target["def"]),
		"atk": int(target["atk"]),
	}
