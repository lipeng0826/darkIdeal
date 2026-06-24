extends Node
## 暗影深渊 - 存档管理器

signal save_completed
signal load_completed

const SAVE_PATH := "user://shadow_abyss_save.json"
const AUTO_SAVE_INTERVAL := 30.0 # 每30秒自动存档

var _auto_save_timer := 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()

## 创建初始存档数据
func create_new_save() -> Dictionary:
	return {
		"version": 1,
		"created_at": Time.get_unix_time_from_system(),
		"last_save_time": Time.get_unix_time_from_system(),
		
		# 玩家基本信息
		"player": {
			"name": "暗影行者",
			"gender": "secret",
			"motto": "",
			"level": 1,
			"exp": 0,
			"gold": 0,
			"gems": 0,
		},
		
		# 战斗属性
		"combat": {
			"hp": 100,
			"max_hp": 100,
			"atk": 8,
			"def": 3,
			"crit": 5,
			"crit_dmg": 50,
			"hp_regen": 1,
			"lifesteal": 0,
		},
		
		# 当前区域
		"zone": {
			"current": 0,
			"unlocked": 0,
		},
		
		# 装备系统 (slot -> item or null)
		"equipment": {
			"0": null, # weapon
			"1": null, # armor
			"2": null, # helmet
			"3": null, # boots
			"4": null, # ring
			"5": null, # amulet
		},
		
		# 背包
		"inventory": [],
		"inventory_max": 50,
		
		# 材料
		"materials": {
			"shadow_essence": 0,
			"bone_fragment": 0,
			"demon_blood": 0,
			"soul_shard": 0,
			"abyss_crystal": 0,
			"cursed_iron": 0,
			"dragon_scale": 0,
			"void_dust": 0,
		},
		
		# 统计数据
		"stats": {
			"total_kills": 0,
			"total_gold_earned": 0,
			"total_crafts": 0,
			"total_equips_found": 0,
			"bosses_killed": [],  # [zone_index, ...]
			"boss_kill_count": 0,
			"gold_today": 0,
			"kills_today": 0,
			"crafts_today": 0,
			"boss_today": 0,
		},
		
		# 任务进度
		"quests": {
			"completed": [],
			"claimed": [],
		},
		
		# 每日系统
		"daily": {
			"last_login_date": "",
			"login_streak": 0,
			"today_claimed": false,
			"tasks": [],         # 今日生成的每日任务
			"tasks_date": "",    # 任务生成日期
		},
		
		# 增益
		"boosts": {
			"exp": 0,
			"gold": 0,
			"boss_tickets": 0,
		},
		
		# 技能系统
		"skills": {
			"levels": {"arc_cleave": 1},
			"equipped": ["arc_cleave"],
		},
		
		# 天赋系统
		"talents": {},
		"talent_points": 0,
		
		# 宠物系统
		"pets": {
			"owned": {},
			"active": "",
		},
		
		# 深渊塔
		"tower": {
			"best_floor": 0,
			"attempts_today": 0,
			"last_attempt_date": "",
		},
		
		# 宝石背包
		"gem_inventory": {},
		
		# 成就
		"achievements": {
			"claimed": [],
		},
		"achievements_extra": {
			"pet_evolves": 0,
		},
		
		# 称号
		"titles": {
			"owned": [],
			"active": "",
		},
		
		# 转生
		"rebirth": {
			"count": 0,
			"total_levels": 0,
		},
		
		"inventory_meta": {
			"new_uids": [],
			"locked_uids": [],
		},
		
		# 设置
		"settings": {
			"sound": true,
			"auto_equip": true,
			"notifications": true,
		},
		
		# 养成进度（等级段解锁、掉落保底）
		"progression": {
			"unlocked_systems": ["equipment"],
			"system_tiers": {},
			"waves_since_equip": 0,
			"current_bracket": "bracket_1_10",
		},
		
		# 万界裂隙叙事进度
		"lore": {
			"visited_realms": [],
			"seen_first_game": false,
		},
	}

## 保存游戏
func save_game() -> void:
	if not GameManager.game_data:
		return
	GameManager.game_data["last_save_time"] = Time.get_unix_time_from_system()
	var json_str := JSON.stringify(GameManager.game_data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		save_completed.emit()

## 加载游戏
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_str)
	if error != OK:
		return {}
	var data: Dictionary = json.data
	load_completed.emit()
	return _normalize_loaded_data(data)

func _normalize_loaded_data(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	for sk in data.get("equipment", {}):
		var it = data["equipment"][sk]
		if it != null:
			data["equipment"][sk] = DataManager.normalize_item(it)
	var inv: Array = data.get("inventory", [])
	for i in range(inv.size()):
		inv[i] = DataManager.normalize_item(inv[i])
	data["inventory"] = inv
	_ensure_starter_skills(data)
	ProgressionManager.ensure_progression_data(data)
	var lv: int = int(data.get("player", {}).get("level", 1))
	ProgressionManager.sync_unlocks(data, lv, false)
	LoreManager.ensure_lore_save(data)
	_migrate_lore_for_existing_save(data)
	if not data.has("inventory_meta"):
		data["inventory_meta"] = {"new_uids": [], "locked_uids": []}
	elif not data["inventory_meta"].has("locked_uids"):
		data["inventory_meta"]["locked_uids"] = []
	_ensure_player_profile(data)
	return data

func _ensure_player_profile(data: Dictionary) -> void:
	if not data.has("player"):
		data["player"] = {}
	var player: Dictionary = data["player"]
	if not player.has("name") or str(player.get("name", "")).strip_edges().is_empty():
		player["name"] = PlayerProfileUtils.DEFAULT_NAME
	if not player.has("gender"):
		player["gender"] = "secret"
	else:
		player["gender"] = PlayerProfileUtils.normalize_gender(str(player["gender"]))
	if not player.has("motto"):
		player["motto"] = ""
	data["player"] = player

func _migrate_lore_for_existing_save(data: Dictionary) -> void:
	var lore: Dictionary = data["lore"]
	if lore.get("_migrated", false):
		return
	# 老存档：跳过开场叙事，已解锁界域标记为已访问
	lore["seen_first_game"] = true
	var unl: int = int(data.get("zone", {}).get("unlocked", 0))
	var visited: Array = lore.get("visited_realms", [])
	for i in range(unl + 1):
		if i not in visited:
			visited.append(i)
	lore["visited_realms"] = visited
	lore["_migrated"] = true

func _ensure_starter_skills(data: Dictionary) -> void:
	if not data.has("skills"):
		data["skills"] = {"levels": {}, "equipped": []}
	if not data["skills"].has("levels"):
		data["skills"]["levels"] = {}
	if not data["skills"].has("equipped"):
		data["skills"]["equipped"] = []
	var levels: Dictionary = data["skills"]["levels"]
	var equipped: Array = data["skills"]["equipped"]
	if int(levels.get("arc_cleave", 0)) <= 0:
		levels["arc_cleave"] = 1
	if "arc_cleave" not in equipped and equipped.size() < 4:
		equipped.append("arc_cleave")

## 计算离线收益
func calculate_offline_rewards(data: Dictionary) -> Dictionary:
	var last_time: float = data.get("last_save_time", 0.0)
	var now := Time.get_unix_time_from_system()
	var elapsed := now - last_time
	
	# 最多计算8小时离线
	elapsed = minf(elapsed, 8.0 * 3600.0)
	
	# 少于60秒不计算
	if elapsed < 60.0:
		return {}
	
	var zone_idx: int = data["zone"]["current"]
	var zone: Dictionary = DataManager.ZONES[zone_idx]
	var enemy_stats: Dictionary = zone["enemy_stats"]
	var player_lv: int = data["player"]["level"]
	var scaled := DataManager.scale_enemy(enemy_stats, player_lv, zone_idx)
	
	# 估算每秒击杀效率 (简化: 假设每3秒一次击杀)
	var kills_per_sec := 1.0 / 3.0
	# 离线效率降低到60%
	kills_per_sec *= 0.6
	
	var total_kills := int(elapsed * kills_per_sec)
	var total_gold: int = total_kills * int(scaled["gold"])
	var total_exp: int = total_kills * int(scaled["exp"])
	
	# 材料掉落 (20%概率)
	var mat_drops := {}
	var zone_mats: Array = zone["materials"]
	for mat_id in zone_mats:
		mat_drops[mat_id] = int(total_kills * 0.2 / zone_mats.size())
	
	return {
		"elapsed": elapsed,
		"kills": total_kills,
		"gold": total_gold,
		"exp": total_exp,
		"materials": mat_drops,
	}

## 删除存档
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
