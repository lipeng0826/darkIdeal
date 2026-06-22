extends Node
class_name TowerSystem
## 暗影深渊 - 无尽深渊塔
## 爬塔挑战模式，层数越高奖励越好，每层敌人更强

signal floor_cleared(floor_num: int, rewards: Dictionary)
signal tower_failed(floor_num: int)
signal new_record(floor_num: int)

# ==================== 塔层配置 ====================
const BASE_ENEMY_HP := 200
const BASE_ENEMY_ATK := 20
const BASE_ENEMY_DEF := 8
const HP_SCALE_PER_FLOOR := 1.18    # 每层HP增长18%
const ATK_SCALE_PER_FLOOR := 1.12   # 每层攻击增长12%
const DEF_SCALE_PER_FLOOR := 1.10   # 每层防御增长10%
const ENEMIES_PER_FLOOR := 3        # 每层3波敌人
const BOSS_EVERY := 10              # 每10层一个Boss

# 特殊层效果
const FLOOR_MODIFIERS := {
	5:  {"name": "狂暴", "desc": "敌人攻击+50%", "atk_mult": 1.5},
	10: {"name": "Boss层", "desc": "面对强大的守护者", "is_boss": true, "hp_mult": 5.0, "atk_mult": 1.3},
	15: {"name": "铁壁", "desc": "敌人防御+80%", "def_mult": 1.8},
	20: {"name": "Boss层", "desc": "面对精英守护者", "is_boss": true, "hp_mult": 6.0, "atk_mult": 1.5},
	25: {"name": "双倍", "desc": "敌人全属性+30%", "all_mult": 1.3},
	30: {"name": "Boss层", "desc": "面对恐怖的深渊领主", "is_boss": true, "hp_mult": 8.0, "atk_mult": 1.8},
	35: {"name": "嗜血", "desc": "敌人吸血20%", "lifesteal": 0.2},
	40: {"name": "Boss层", "desc": "面对传说中的巨兽", "is_boss": true, "hp_mult": 10.0, "atk_mult": 2.0},
	45: {"name": "末日", "desc": "全属性+50%，带狂暴", "all_mult": 1.5, "enrage": true},
	50: {"name": "深渊之王", "desc": "终极Boss挑战!", "is_boss": true, "hp_mult": 15.0, "atk_mult": 2.5},
}

# 塔层奖励（每层通关）
const FLOOR_REWARDS := {
	"gold_base": 500,
	"gold_per_floor": 200,
	"exp_base": 100,
	"exp_per_floor": 80,
	"gems_per_10": 20,       # 每10层给宝石
	"material_chance": 0.4,  # 材料掉率
	"equip_chance": 0.2,     # 装备掉率（高层提高）
}

# 塔层敌人名称
const TOWER_ENEMIES := [
	"深渊哨兵", "暗影护卫", "虚空潜伏者", "骸骨勇士",
	"炼狱看守", "末日先锋", "混沌行者", "永恒守护",
	"深渊之眼", "虚无使者", "终焉骑士", "灭世卫兵",
]

const TOWER_BOSSES := [
	"深渊塔·石像守卫", "深渊塔·暗影将军", "深渊塔·炼狱魔神",
	"深渊塔·虚空之主", "深渊塔·终焉巨龙",
]

# ==================== 运行时状态 ====================
var is_in_tower := false
var current_floor := 0
var current_wave := 0
var tower_enemy_hp := 0
var tower_enemy_max_hp := 0
var tower_enemy_atk := 0
var tower_enemy_def := 0
var tower_enemy_name := ""
var is_tower_boss := false
var tower_attack_timer := 0.0
var tower_enemy_timer := 0.0

func _process(delta: float) -> void:
	if not is_in_tower or not GameManager.is_loaded:
		return
	_process_tower_battle(delta)

# ==================== 塔战斗 ====================
func start_tower() -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("tower"):
		data["tower"] = {"best_floor": 0, "attempts_today": 0, "last_attempt_date": ""}
	
	# 每天最多5次
	var today: String = Time.get_date_string_from_system()
	if data["tower"]["last_attempt_date"] != today:
		data["tower"]["attempts_today"] = 0
		data["tower"]["last_attempt_date"] = today
	
	if int(data["tower"]["attempts_today"]) >= 5:
		GameManager.toast_message.emit("今日挑战次数已用完(5/5)", Color(1.0, 0.3, 0.3))
		return
	
	data["tower"]["attempts_today"] = int(data["tower"]["attempts_today"]) + 1
	is_in_tower = true
	current_floor = 1
	current_wave = 0
	GameManager.is_fighting = false  # 暂停普通战斗
	GameManager.player_hp = int(GameManager.game_data["combat"]["max_hp"])
	
	_spawn_tower_enemy()
	GameManager.battle_log.emit("⚔ 进入深渊塔! 第1层", Color(0.8, 0.6, 0.2))
	AudioManager.play_sfx("boss")

func _spawn_tower_enemy() -> void:
	var floor_stats: Dictionary = _get_floor_stats(current_floor)
	
	is_tower_boss = floor_stats.get("is_boss", false)
	tower_enemy_hp = int(floor_stats["hp"])
	tower_enemy_max_hp = tower_enemy_hp
	tower_enemy_atk = int(floor_stats["atk"])
	tower_enemy_def = int(floor_stats["def"])
	
	if is_tower_boss:
		var boss_idx: int = mini((current_floor / 10) - 1, TOWER_BOSSES.size() - 1)
		tower_enemy_name = TOWER_BOSSES[maxi(0, boss_idx)]
	else:
		tower_enemy_name = TOWER_ENEMIES[randi() % TOWER_ENEMIES.size()]
	
	tower_attack_timer = 0.0
	tower_enemy_timer = 0.0

func _get_floor_stats(floor_num: int) -> Dictionary:
	var hp: float = BASE_ENEMY_HP * pow(HP_SCALE_PER_FLOOR, floor_num - 1)
	var atk: float = BASE_ENEMY_ATK * pow(ATK_SCALE_PER_FLOOR, floor_num - 1)
	var def: float = BASE_ENEMY_DEF * pow(DEF_SCALE_PER_FLOOR, floor_num - 1)
	
	var result: Dictionary = {"hp": int(hp), "atk": int(atk), "def": int(def)}
	
	# 应用层修饰符
	if FLOOR_MODIFIERS.has(floor_num):
		var mod: Dictionary = FLOOR_MODIFIERS[floor_num]
		if mod.has("hp_mult"):
			result["hp"] = int(result["hp"] * float(mod["hp_mult"]))
		if mod.has("atk_mult"):
			result["atk"] = int(result["atk"] * float(mod["atk_mult"]))
		if mod.has("def_mult"):
			result["def"] = int(result["def"] * float(mod["def_mult"]))
		if mod.has("all_mult"):
			var m: float = float(mod["all_mult"])
			result["hp"] = int(result["hp"] * m)
			result["atk"] = int(result["atk"] * m)
			result["def"] = int(result["def"] * m)
		if mod.has("is_boss"):
			result["is_boss"] = true
	
	# 每10层为Boss层
	if floor_num % 10 == 0 and not result.has("is_boss"):
		result["is_boss"] = true
		result["hp"] = int(result["hp"] * 5)
		result["atk"] = int(result["atk"] * 1.3)
	
	return result

func _process_tower_battle(delta: float) -> void:
	var combat: Dictionary = GameManager.game_data["combat"]
	
	# 玩家攻击
	tower_attack_timer += delta
	if tower_attack_timer >= 1.0:
		tower_attack_timer = 0.0
		var player_atk: int = int(combat["atk"])
		var dmg: int = maxi(1, player_atk - tower_enemy_def / 3)
		
		var is_crit: bool = randf() * 100.0 < float(combat["crit"])
		if is_crit:
			dmg = int(dmg * (1.0 + float(combat["crit_dmg"]) / 100.0))
		
		tower_enemy_hp -= dmg
		AudioManager.play_sfx("hit" if not is_crit else "crit")
		
		if tower_enemy_hp <= 0:
			_on_tower_enemy_killed()
			return
	
	# 敌人攻击
	tower_enemy_timer += delta
	var enemy_speed: float = 1.8 if not is_tower_boss else 1.2
	if tower_enemy_timer >= enemy_speed:
		tower_enemy_timer = 0.0
		var dmg: int = maxi(1, tower_enemy_atk - int(combat["def"]) / 2)
		GameManager.player_hp -= dmg
		AudioManager.play_sfx("enemy_hit")
		
		if GameManager.player_hp <= 0:
			_on_tower_failed()

func _on_tower_enemy_killed() -> void:
	current_wave += 1
	var waves_needed: int = ENEMIES_PER_FLOOR if not is_tower_boss else 1
	
	if current_wave >= waves_needed:
		# 当前层通关
		var rewards: Dictionary = _calculate_floor_rewards(current_floor)
		_apply_rewards(rewards)
		floor_cleared.emit(current_floor, rewards)
		
		GameManager.battle_log.emit("✦ 深渊塔第%d层通关!" % current_floor, Color(1.0, 0.85, 0.0))
		
		# 记录最高层
		var data: Dictionary = GameManager.game_data
		if current_floor > int(data["tower"]["best_floor"]):
			data["tower"]["best_floor"] = current_floor
			new_record.emit(current_floor)
			GameManager.toast_message.emit("新纪录! 深渊塔第%d层!" % current_floor, Color(1.0, 0.85, 0.0))
		
		# 回复部分生命
		var heal: int = int(int(GameManager.game_data["combat"]["max_hp"]) * 0.15)
		GameManager.player_hp = mini(GameManager.player_hp + heal, int(GameManager.game_data["combat"]["max_hp"]))
		
		# 下一层
		current_floor += 1
		current_wave = 0
		_spawn_tower_enemy()
	else:
		_spawn_tower_enemy()

func _on_tower_failed() -> void:
	is_in_tower = false
	GameManager.is_fighting = true  # 恢复普通战斗
	GameManager.player_hp = int(GameManager.game_data["combat"]["max_hp"])
	
	tower_failed.emit(current_floor)
	GameManager.battle_log.emit("☠ 深渊塔挑战失败，止步第%d层" % current_floor, Color(1.0, 0.3, 0.3))
	GameManager.toast_message.emit("深渊塔失败! 到达第%d层" % current_floor, Color(1.0, 0.3, 0.3))
	AudioManager.play_sfx("death")

func exit_tower() -> void:
	if is_in_tower:
		is_in_tower = false
		GameManager.is_fighting = true
		GameManager.player_hp = int(GameManager.game_data["combat"]["max_hp"])
		GameManager.toast_message.emit("退出深渊塔", Color(0.7, 0.7, 0.7))

## UI调用入口
func start_challenge() -> Dictionary:
	var data: Dictionary = GameManager.game_data
	if not data.has("tower"):
		data["tower"] = {"best_floor": 0, "attempts_today": 0, "last_attempt_date": ""}
	var today: String = Time.get_date_string_from_system()
	if data["tower"]["last_attempt_date"] != today:
		data["tower"]["attempts_today"] = 0
		data["tower"]["last_attempt_date"] = today
	if int(data["tower"]["attempts_today"]) >= 5:
		GameManager.toast_message.emit("今日次数已用完(5/5)", Color(1.0, 0.3, 0.3))
		return {"started": false}
	data["tower"]["attempts_today"] = int(data["tower"]["attempts_today"]) + 1
	return {"started": true}

## 快速结算模拟(用于UI快速显示结果)
func simulate_tower_run() -> int:
	var data: Dictionary = GameManager.game_data
	var combat: Dictionary = data["combat"]
	var player_atk: int = int(combat["atk"])
	var player_def: int = int(combat["def"])
	var player_hp_sim: int = int(combat["max_hp"])
	var player_crit: float = float(combat["crit"])
	var player_crit_dmg: float = float(combat["crit_dmg"])
	var floors_cleared: int = 0
	
	# 快速模拟战斗
	for floor_num in range(1, 200):
		var stats: Dictionary = _get_floor_stats(floor_num)
		var enemy_hp: int = int(stats["hp"])
		var enemy_atk: int = int(stats["atk"])
		var enemy_def: int = int(stats["def"])
		var waves: int = ENEMIES_PER_FLOOR if not stats.get("is_boss", false) else 1
		
		for wave in range(waves):
			var ehp: int = enemy_hp
			# 模拟回合制战斗
			var turns: int = 0
			while ehp > 0 and player_hp_sim > 0 and turns < 100:
				# 玩家攻击
				var dmg: int = maxi(1, player_atk - enemy_def / 3)
				if randf() * 100.0 < player_crit:
					dmg = int(dmg * (1.0 + player_crit_dmg / 100.0))
				ehp -= dmg
				if ehp <= 0:
					break
				# 敌人攻击
				var edmg: int = maxi(1, enemy_atk - player_def / 2)
				player_hp_sim -= edmg
				turns += 1
			
			if player_hp_sim <= 0:
				break
		
		if player_hp_sim <= 0:
			break
		
		floors_cleared = floor_num
		# 每层回复15%
		player_hp_sim = mini(player_hp_sim + int(int(combat["max_hp"]) * 0.15), int(combat["max_hp"]))
		# 发放奖励
		var rewards: Dictionary = _calculate_floor_rewards(floor_num)
		_apply_rewards(rewards)
	
	# 更新最高记录
	if floors_cleared > int(data["tower"].get("best_floor", 0)):
		data["tower"]["best_floor"] = floors_cleared
		GameManager.toast_message.emit("深渊塔新纪录! 第%d层!" % floors_cleared, Color(1.0, 0.85, 0.0))
	else:
		GameManager.toast_message.emit("深渊塔挑战完成: 到达第%d层" % floors_cleared, Color(0.8, 0.7, 0.3))
	
	# 恢复普通战斗
	is_in_tower = false
	GameManager.is_fighting = true
	GameManager.player_hp = int(combat["max_hp"])
	return floors_cleared

func _calculate_floor_rewards(floor_num: int) -> Dictionary:
	var rewards: Dictionary = {
		"gold": FLOOR_REWARDS["gold_base"] + FLOOR_REWARDS["gold_per_floor"] * floor_num,
		"exp": FLOOR_REWARDS["exp_base"] + FLOOR_REWARDS["exp_per_floor"] * floor_num,
	}
	
	# 每10层给宝石
	if floor_num % 10 == 0:
		rewards["gems"] = FLOOR_REWARDS["gems_per_10"] * (floor_num / 10)
	
	# 材料
	if randf() < FLOOR_REWARDS["material_chance"]:
		var zone_idx: int = mini(floor_num / 5, DataManager.ZONES.size() - 1)
		var zone: Dictionary = DataManager.ZONES[zone_idx]
		var mats: Array = zone["materials"]
		rewards["material"] = mats[randi() % mats.size()]
		rewards["material_amount"] = randi_range(2, 5 + floor_num / 10)
	
	# 装备（高层提高）
	var equip_chance: float = FLOOR_REWARDS["equip_chance"] + floor_num * 0.005
	if randf() < equip_chance:
		rewards["equip"] = true
		rewards["equip_rarity_boost"] = floor_num / 15
	
	return rewards

func _apply_rewards(rewards: Dictionary) -> void:
	GameManager.add_gold(int(rewards["gold"]))
	GameManager.add_exp(int(rewards["exp"]))
	if rewards.has("gems"):
		GameManager.add_gems(int(rewards["gems"]))
	if rewards.has("material"):
		var data: Dictionary = GameManager.game_data
		var mat_id: String = rewards["material"]
		data["materials"][mat_id] = int(data["materials"].get(mat_id, 0)) + int(rewards["material_amount"])
	if rewards.has("equip"):
		var slot: int = randi() % 6
		var lv: int = int(GameManager.game_data["player"]["level"])
		var item: Dictionary = DataManager.generate_item(slot, lv, int(rewards["equip_rarity_boost"]))
		GameManager.game_data["inventory"].append(item)
		GameManager.item_obtained.emit(item)
