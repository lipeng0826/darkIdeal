extends Node
class_name PetSystem
## 暗影深渊 - 宠物/召唤兽系统
## 收集宠物，升级宠物，宠物参与战斗提供被动加成和主动攻击

signal pet_obtained(pet_id: String)
signal pet_leveled_up(pet_id: String, new_level: int)
signal pet_evolved(pet_id: String)

# ==================== 宠物定义 ====================
const PETS := {
	# ---- 暗影系宠物 ----
	"shadow_wolf": {
		"name": "暗影狼", "desc": "忠诚的暗影猎犬，提供攻击加成",
		"rarity": 0, "type": "attack",
		"base_stats": {"atk": 5, "atk_pct": 3},
		"per_lv": {"atk": 2, "atk_pct": 0.5},
		"skill": "每3秒对敌人造成{dmg}点伤害",
		"skill_dmg_base": 10, "skill_dmg_per_lv": 5, "skill_cd": 3.0,
		"evolve_to": "shadow_alpha",
		"color": Color(0.3, 0.1, 0.4),
	},
	"shadow_alpha": {
		"name": "暗影狼王", "desc": "狼群之王，攻击力大幅提升",
		"rarity": 2, "type": "attack",
		"base_stats": {"atk": 20, "atk_pct": 8, "crit": 3},
		"per_lv": {"atk": 5, "atk_pct": 1, "crit": 0.3},
		"skill": "每3秒造成{dmg}伤害，10%概率造成双倍",
		"skill_dmg_base": 40, "skill_dmg_per_lv": 12, "skill_cd": 3.0,
		"evolve_to": "", "color": Color(0.4, 0.1, 0.6),
	},
	"bone_imp": {
		"name": "骨魔小鬼", "desc": "墓穴中的小家伙，提供金币加成",
		"rarity": 0, "type": "support",
		"base_stats": {"gold_bonus_pct": 5},
		"per_lv": {"gold_bonus_pct": 1},
		"skill": "每次击杀额外获得{dmg}金币",
		"skill_dmg_base": 3, "skill_dmg_per_lv": 2, "skill_cd": 0.0,
		"evolve_to": "bone_lord",
		"color": Color(0.7, 0.7, 0.6),
	},
	"bone_lord": {
		"name": "骨魔领主", "desc": "贪婪的领主，大幅提升金币收入",
		"rarity": 2, "type": "support",
		"base_stats": {"gold_bonus_pct": 15, "exp_bonus_pct": 5},
		"per_lv": {"gold_bonus_pct": 2, "exp_bonus_pct": 0.5},
		"skill": "每次击杀额外获得{dmg}金币",
		"skill_dmg_base": 15, "skill_dmg_per_lv": 8, "skill_cd": 0.0,
		"evolve_to": "", "color": Color(0.9, 0.8, 0.5),
	},
	"fire_sprite": {
		"name": "烈焰精灵", "desc": "小小的火焰生物，提供持续伤害",
		"rarity": 1, "type": "attack",
		"base_stats": {"atk": 3, "atk_pct": 2},
		"per_lv": {"atk": 1, "atk_pct": 0.3},
		"skill": "每2秒灼烧敌人造成{dmg}伤害",
		"skill_dmg_base": 8, "skill_dmg_per_lv": 4, "skill_cd": 2.0,
		"evolve_to": "inferno_lord",
		"color": Color(1.0, 0.3, 0.0),
	},
	"inferno_lord": {
		"name": "炼狱之主", "desc": "烈焰的化身，灼烧一切",
		"rarity": 3, "type": "attack",
		"base_stats": {"atk": 15, "atk_pct": 10, "crit_dmg": 10},
		"per_lv": {"atk": 4, "atk_pct": 1.5, "crit_dmg": 1},
		"skill": "每2秒灼烧敌人{dmg}伤害，15%暴击",
		"skill_dmg_base": 35, "skill_dmg_per_lv": 15, "skill_cd": 2.0,
		"evolve_to": "", "color": Color(1.0, 0.1, 0.0),
	},
	"ice_golem": {
		"name": "寒冰傀儡", "desc": "坚固的冰晶守护者，提供防御",
		"rarity": 1, "type": "defense",
		"base_stats": {"def": 5, "def_pct": 3, "hp": 20},
		"per_lv": {"def": 2, "def_pct": 0.5, "hp": 8},
		"skill": "受击时{dmg}%概率冰冻敌人1秒(减速)",
		"skill_dmg_base": 10, "skill_dmg_per_lv": 2, "skill_cd": 5.0,
		"evolve_to": "frost_titan",
		"color": Color(0.3, 0.7, 1.0),
	},
	"frost_titan": {
		"name": "霜冻巨人", "desc": "永冻之地的巨人，极致防御",
		"rarity": 3, "type": "defense",
		"base_stats": {"def": 20, "def_pct": 10, "hp": 80, "hp_pct": 5},
		"per_lv": {"def": 5, "def_pct": 1.5, "hp": 20, "hp_pct": 0.5},
		"skill": "受击时{dmg}%减伤，并反弹5%伤害",
		"skill_dmg_base": 15, "skill_dmg_per_lv": 3, "skill_cd": 5.0,
		"evolve_to": "", "color": Color(0.1, 0.4, 0.9),
	},
	"soul_wisp": {
		"name": "灵魂火花", "desc": "飘荡的灵魂，提供经验加成",
		"rarity": 0, "type": "support",
		"base_stats": {"exp_bonus_pct": 8},
		"per_lv": {"exp_bonus_pct": 1.5},
		"skill": "击杀时{dmg}%概率获得双倍经验",
		"skill_dmg_base": 5, "skill_dmg_per_lv": 2, "skill_cd": 0.0,
		"evolve_to": "soul_phoenix",
		"color": Color(0.5, 0.8, 1.0),
	},
	"soul_phoenix": {
		"name": "灵魂凤凰", "desc": "浴火重生的灵魂鸟，全方位辅助",
		"rarity": 4, "type": "support",
		"base_stats": {"exp_bonus_pct": 20, "gold_bonus_pct": 10, "hp_regen": 5},
		"per_lv": {"exp_bonus_pct": 2, "gold_bonus_pct": 1, "hp_regen": 1},
		"skill": "死亡时自动复活(CD60s)，{dmg}%恢复全部HP",
		"skill_dmg_base": 30, "skill_dmg_per_lv": 5, "skill_cd": 60.0,
		"evolve_to": "", "color": Color(1.0, 0.5, 0.0),
	},
	"void_serpent": {
		"name": "虚空蛇", "desc": "来自虚空的古老生物，削弱敌人",
		"rarity": 2, "type": "debuff",
		"base_stats": {"atk": 8, "atk_pct": 5},
		"per_lv": {"atk": 3, "atk_pct": 0.8},
		"skill": "每4秒降低敌人{dmg}%攻防，持续3秒",
		"skill_dmg_base": 8, "skill_dmg_per_lv": 2, "skill_cd": 4.0,
		"evolve_to": "void_dragon",
		"color": Color(0.3, 0.0, 0.5),
	},
	"void_dragon": {
		"name": "虚空巨龙", "desc": "吞噬一切的巨龙",
		"rarity": 5, "type": "attack",
		"base_stats": {"atk": 50, "atk_pct": 15, "crit": 5, "crit_dmg": 20},
		"per_lv": {"atk": 12, "atk_pct": 2, "crit": 0.5, "crit_dmg": 2},
		"skill": "每3秒龙息攻击造成{dmg}真实伤害",
		"skill_dmg_base": 100, "skill_dmg_per_lv": 30, "skill_cd": 3.0,
		"evolve_to": "", "color": Color(0.2, 0.0, 0.3),
	},
}

# 宠物获取方式
const PET_SOURCES := {
	"shadow_wolf":  {"type": "zone_drop", "zone": 0, "chance": 0.02},
	"bone_imp":     {"type": "zone_drop", "zone": 1, "chance": 0.02},
	"fire_sprite":  {"type": "zone_drop", "zone": 3, "chance": 0.015},
	"ice_golem":    {"type": "zone_drop", "zone": 6, "chance": 0.015},
	"soul_wisp":    {"type": "zone_drop", "zone": 2, "chance": 0.02},
	"void_serpent": {"type": "zone_drop", "zone": 5, "chance": 0.01},
}

# 进化材料需求
const EVOLVE_COSTS := {
	"shadow_wolf":  {"level": 20, "materials": {"shadow_essence": 30, "soul_shard": 20}, "gold": 10000},
	"bone_imp":     {"level": 20, "materials": {"bone_fragment": 30, "soul_shard": 20}, "gold": 10000},
	"fire_sprite":  {"level": 25, "materials": {"demon_blood": 25, "dragon_scale": 10}, "gold": 25000},
	"ice_golem":    {"level": 25, "materials": {"abyss_crystal": 15, "void_dust": 10}, "gold": 25000},
	"soul_wisp":    {"level": 30, "materials": {"soul_shard": 40, "abyss_crystal": 20}, "gold": 50000},
	"void_serpent": {"level": 35, "materials": {"void_dust": 30, "dragon_scale": 20, "abyss_crystal": 15}, "gold": 100000},
}

# 运行时
var pet_skill_timers: Dictionary = {}

func _process(delta: float) -> void:
	if not GameManager.is_loaded or not GameManager.is_fighting:
		return
	_process_pet_skills(delta)

func _process_pet_skills(delta: float) -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets"):
		return
	var active_pet: String = data["pets"].get("active", "")
	if active_pet.is_empty() or not PETS.has(active_pet):
		return
	
	var pet: Dictionary = PETS[active_pet]
	var pet_lv: int = int(data["pets"]["owned"].get(active_pet, {}).get("level", 1))
	var cd: float = float(pet["skill_cd"])
	
	if cd <= 0:
		return  # 被动技能，在击杀时触发
	
	if not pet_skill_timers.has(active_pet):
		pet_skill_timers[active_pet] = 0.0
	
	pet_skill_timers[active_pet] += delta
	if pet_skill_timers[active_pet] >= cd:
		pet_skill_timers[active_pet] = 0.0
		var dmg: int = int(pet["skill_dmg_base"]) + int(pet["skill_dmg_per_lv"]) * (pet_lv - 1)
		GameManager.enemy_hp -= dmg
		GameManager.battle_log.emit("🐾 %s: %d 伤害" % [pet["name"], dmg], pet["color"])

## 获取宠物被动属性加成
func get_pet_bonus(stat: String) -> float:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets"):
		return 0.0
	var active_pet: String = data["pets"].get("active", "")
	if active_pet.is_empty() or not PETS.has(active_pet):
		return 0.0
	
	var pet: Dictionary = PETS[active_pet]
	var pet_lv: int = int(data["pets"]["owned"].get(active_pet, {}).get("level", 1))
	var base_val: float = float(pet["base_stats"].get(stat, 0))
	var per_lv_val: float = float(pet["per_lv"].get(stat, 0))
	return base_val + per_lv_val * (pet_lv - 1)

## 击杀时触发宠物被动
func on_enemy_killed() -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets"):
		return
	var active_pet: String = data["pets"].get("active", "")
	if active_pet.is_empty() or not PETS.has(active_pet):
		return
	var pet: Dictionary = PETS[active_pet]
	var pet_lv: int = int(data["pets"]["owned"].get(active_pet, {}).get("level", 1))
	
	if float(pet["skill_cd"]) <= 0:
		# 被动型（击杀触发）
		var val: int = int(pet["skill_dmg_base"]) + int(pet["skill_dmg_per_lv"]) * (pet_lv - 1)
		match pet["type"]:
			"support":
				if "gold" in pet["skill"]:
					GameManager.add_gold(val)

## 升级宠物
func level_up_pet(pet_id: String) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets") or not data["pets"]["owned"].has(pet_id):
		return false
	
	var pet_data: Dictionary = data["pets"]["owned"][pet_id]
	var current_lv: int = int(pet_data["level"])
	var cost: int = current_lv * 300 + current_lv * current_lv * 50
	
	if not GameManager.spend_gold(cost):
		GameManager.toast_message.emit("金币不足! 需要%d" % cost, Color(1.0, 0.3, 0.3))
		return false
	
	pet_data["level"] = current_lv + 1
	pet_leveled_up.emit(pet_id, current_lv + 1)
	AudioManager.play_sfx("levelup")
	GameManager.toast_message.emit("%s 升级到 Lv.%d!" % [PETS[pet_id]["name"], current_lv + 1], PETS[pet_id]["color"])
	GameManager.stats_updated.emit()
	return true

## 进化宠物
func evolve_pet(pet_id: String) -> bool:
	if not EVOLVE_COSTS.has(pet_id):
		return false
	var data: Dictionary = GameManager.game_data
	if not data.has("pets") or not data["pets"]["owned"].has(pet_id):
		return false
	
	var costs: Dictionary = EVOLVE_COSTS[pet_id]
	var pet_data: Dictionary = data["pets"]["owned"][pet_id]
	
	if int(pet_data["level"]) < int(costs["level"]):
		GameManager.toast_message.emit("宠物等级不足! 需要Lv.%d" % costs["level"], Color(1.0, 0.3, 0.3))
		return false
	
	if not GameManager.spend_gold(int(costs["gold"])):
		GameManager.toast_message.emit("金币不足!", Color(1.0, 0.3, 0.3))
		return false
	
	var mats: Dictionary = costs["materials"]
	for mat_id in mats:
		if int(data["materials"].get(mat_id, 0)) < int(mats[mat_id]):
			GameManager.toast_message.emit("材料不足!", Color(1.0, 0.3, 0.3))
			return false
	
	for mat_id in mats:
		data["materials"][mat_id] = int(data["materials"][mat_id]) - int(mats[mat_id])
	
	var evolve_to: String = PETS[pet_id]["evolve_to"]
	data["pets"]["owned"][evolve_to] = {"level": 1, "obtained_at": Time.get_unix_time_from_system()}
	data["pets"]["owned"].erase(pet_id)
	if data["pets"]["active"] == pet_id:
		data["pets"]["active"] = evolve_to
	
	pet_evolved.emit(evolve_to)
	AudioManager.play_sfx("reward")
	GameManager.toast_message.emit("进化成功! 获得 %s!" % PETS[evolve_to]["name"], Color(1.0, 0.85, 0.0))
	return true

## 尝试掉落宠物(击杀时调用)
func try_drop_pet(zone_index: int) -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets"):
		data["pets"] = {"owned": {}, "active": ""}
	
	for pet_id in PET_SOURCES:
		var source: Dictionary = PET_SOURCES[pet_id]
		if int(source["zone"]) != zone_index:
			continue
		if data["pets"]["owned"].has(pet_id):
			continue  # 已拥有
		if randf() < float(source["chance"]):
			data["pets"]["owned"][pet_id] = {"level": 1, "exp": 0, "obtained_at": Time.get_unix_time_from_system()}
			if data["pets"]["active"].is_empty():
				data["pets"]["active"] = pet_id
			pet_obtained.emit(pet_id)
			AudioManager.play_sfx("reward")
			GameManager.toast_message.emit("获得宠物: %s!" % PETS[pet_id]["name"], PETS[pet_id]["color"])
			break

# ==================== 宠物喂养系统 ====================
signal pet_fed(pet_id: String, exp_gained: int)

# 喂养材料对应经验值
const FEED_MATERIALS := {
	"shadow_essence": 30,
	"bone_fragment": 20,
	"soul_shard": 50,
	"demon_blood": 80,
	"abyss_crystal": 120,
	"dragon_scale": 200,
	"void_dust": 150,
	"cursed_iron": 40,
}

## 宠物升级所需经验
func pet_exp_for_level(lv: int) -> int:
	return int(50.0 * pow(lv, 1.4) * (1.0 + lv * 0.08))

## 喂养宠物(用材料提供经验)
func feed_pet(pet_id: String, material_id: String, amount: int = 1) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets") or not data["pets"]["owned"].has(pet_id):
		return false
	if not FEED_MATERIALS.has(material_id):
		GameManager.toast_message.emit("该材料不能喂养!", Color(1.0, 0.3, 0.3))
		return false
	
	# 检查材料
	var have: int = int(data["materials"].get(material_id, 0))
	if have < amount:
		GameManager.toast_message.emit("材料不足!", Color(1.0, 0.3, 0.3))
		return false
	
	# 扣除材料
	data["materials"][material_id] = have - amount
	
	# 增加经验
	var exp_per: int = FEED_MATERIALS[material_id]
	var total_exp: int = exp_per * amount
	var pet_data: Dictionary = data["pets"]["owned"][pet_id]
	pet_data["exp"] = int(pet_data.get("exp", 0)) + total_exp
	
	# 检查升级
	var current_lv: int = int(pet_data["level"])
	var needed: int = pet_exp_for_level(current_lv)
	while int(pet_data["exp"]) >= needed:
		pet_data["exp"] = int(pet_data["exp"]) - needed
		pet_data["level"] = int(pet_data["level"]) + 1
		current_lv = int(pet_data["level"])
		needed = pet_exp_for_level(current_lv)
		pet_leveled_up.emit(pet_id, current_lv)
		AudioManager.play_sfx("levelup")
	
	var mat_name: String = DataManager.MATERIALS[material_id]["name"]
	GameManager.toast_message.emit("喂养%s! +%dEXP (Lv.%d)" % [mat_name, total_exp, current_lv], PETS[pet_id]["color"])
	pet_fed.emit(pet_id, total_exp)
	GameManager.stats_updated.emit()
	return true

## 获取宠物当前经验进度
func get_pet_exp_progress(pet_id: String) -> Dictionary:
	var data: Dictionary = GameManager.game_data
	if not data.has("pets") or not data["pets"]["owned"].has(pet_id):
		return {"current": 0, "needed": 100, "level": 1}
	var pet_data: Dictionary = data["pets"]["owned"][pet_id]
	var lv: int = int(pet_data["level"])
	return {"current": int(pet_data.get("exp", 0)), "needed": pet_exp_for_level(lv), "level": lv}
