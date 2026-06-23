extends Node
class_name EnhanceSystem
## 暗影深渊 - 装备强化系统
## 包含：强化等级、附魔、宝石镶嵌、套装效果

signal item_enhanced(item: Dictionary, new_level: int)
signal item_enchanted(item: Dictionary, enchant: String)
signal gem_socketed(item: Dictionary, gem: Dictionary)

# ==================== 强化系统 ====================
const MAX_ENHANCE_LEVEL := 30
# 强化成功率(根据当前等级)
const ENHANCE_SUCCESS_RATES := [
	1.0, 1.0, 1.0, 0.95, 0.90,     # +1到+5
	0.85, 0.80, 0.75, 0.70, 0.65,  # +6到+10
	0.60, 0.55, 0.50, 0.45, 0.40,  # +11到+15
	0.35, 0.30, 0.28, 0.25, 0.22,  # +16到+20
	0.20, 0.18, 0.16, 0.14, 0.12,  # +21到+25
	0.10, 0.08, 0.06, 0.05, 0.04,  # +26到+30
]

# 强化费用
func get_enhance_cost(current_level: int) -> Dictionary:
	var gold: int = (current_level + 1) * 500 + current_level * current_level * 100
	var materials: Dictionary = {}
	if current_level >= 5:
		materials["shadow_essence"] = current_level / 3
	if current_level >= 10:
		materials["cursed_iron"] = current_level / 5
	if current_level >= 15:
		materials["demon_blood"] = current_level / 5
	if current_level >= 20:
		materials["abyss_crystal"] = current_level / 8
	if current_level >= 25:
		materials["dragon_scale"] = current_level / 10
	return {"gold": gold, "materials": materials}

# 强化属性提升(每级+X%)
const ENHANCE_STAT_BONUS_PCT := 4  # 每强化1级，属性+4%

## 强化装备
func enhance_item(item: Dictionary) -> Dictionary:
	var current_lv: int = int(item.get("enhance_level", 0))
	if current_lv >= MAX_ENHANCE_LEVEL:
		GameManager.toast_message.emit("已达到最高强化等级!", Color(1.0, 0.3, 0.3))
		return {"success": false, "reason": "max_level"}
	
	var cost: Dictionary = get_enhance_cost(current_lv)
	var data: Dictionary = GameManager.game_data
	
	# 检查金币
	if int(data["player"]["gold"]) < int(cost["gold"]):
		GameManager.toast_message.emit("金币不足! 需要%d" % cost["gold"], Color(1.0, 0.3, 0.3))
		return {"success": false, "reason": "gold"}
	
	# 检查材料
	var mats: Dictionary = cost["materials"]
	for mat_id in mats:
		if int(data["materials"].get(mat_id, 0)) < int(mats[mat_id]):
			var mat_name: String = DataManager.MATERIALS[mat_id]["name"]
			GameManager.toast_message.emit("%s不足!" % mat_name, Color(1.0, 0.3, 0.3))
			return {"success": false, "reason": "material"}
	
	# 扣费
	data["player"]["gold"] = int(data["player"]["gold"]) - int(cost["gold"])
	for mat_id in mats:
		data["materials"][mat_id] = int(data["materials"][mat_id]) - int(mats[mat_id])
	
	# 判定成功/失败
	var rate: float = ENHANCE_SUCCESS_RATES[current_lv]
	var roll: float = randf()
	
	if roll < rate:
		# 成功
		item["enhance_level"] = current_lv + 1
		item_enhanced.emit(item, current_lv + 1)
		AudioManager.play_sfx("craft")
		GameManager.toast_message.emit("强化成功! +%d" % (current_lv + 1), Color(0.3, 1.0, 0.5))
		GameManager.stats_updated.emit()
		return {"success": true, "new_level": current_lv + 1}
	else:
		# 失败 (不降级，只浪费材料)
		AudioManager.play_sfx("error")
		GameManager.toast_message.emit("强化失败...", Color(1.0, 0.3, 0.3))
		return {"success": false, "reason": "failed"}

## 获取强化加成倍数
func get_enhance_multiplier(item: Dictionary) -> float:
	var enhance_lv: int = int(item.get("enhance_level", 0))
	return 1.0 + enhance_lv * ENHANCE_STAT_BONUS_PCT / 100.0

# ==================== 附魔系统 ====================
const ENCHANTS := {
	"fire": {"name": "烈焰附魔", "desc": "攻击附带火焰，ATK+15%", "stat": "atk_pct", "value": 15, "color": Color(1.0, 0.3, 0.0)},
	"ice": {"name": "寒冰附魔", "desc": "攻击附带冰霜，减速效果，DEF+12%", "stat": "def_pct", "value": 12, "color": Color(0.3, 0.7, 1.0)},
	"shadow": {"name": "暗影附魔", "desc": "暗影侵蚀，暴击率+8%", "stat": "crit", "value": 8, "color": Color(0.4, 0.1, 0.6)},
	"holy": {"name": "神圣附魔", "desc": "神圣祝福，生命回复+50%", "stat": "hp_regen_pct", "value": 50, "color": Color(1.0, 1.0, 0.5)},
	"blood": {"name": "嗜血附魔", "desc": "鲜血渴望，吸血+5%", "stat": "lifesteal", "value": 5, "color": Color(0.7, 0.0, 0.1)},
	"void": {"name": "虚空附魔", "desc": "虚空之力，暴击伤害+25%", "stat": "crit_dmg", "value": 25, "color": Color(0.3, 0.0, 0.5)},
	"thunder": {"name": "雷霆附魔", "desc": "雷电之怒，ATK+10%，暴击+5%", "stat": "atk_pct", "value": 10, "stat2": "crit", "value2": 5, "color": Color(0.8, 0.8, 0.2)},
	"earth": {"name": "大地附魔", "desc": "大地之力，HP+20%，DEF+8%", "stat": "hp_pct", "value": 20, "stat2": "def_pct", "value2": 8, "color": Color(0.5, 0.3, 0.1)},
}

const ENCHANT_COSTS := {
	"gold": 5000,
	"materials": {"soul_shard": 10, "shadow_essence": 5},
}

## 附魔装备(随机)
func enchant_item(item: Dictionary) -> bool:
	var data: Dictionary = GameManager.game_data
	
	# 检查费用
	if int(data["player"]["gold"]) < ENCHANT_COSTS["gold"]:
		GameManager.toast_message.emit("金币不足!", Color(1.0, 0.3, 0.3))
		return false
	for mat_id in ENCHANT_COSTS["materials"]:
		if int(data["materials"].get(mat_id, 0)) < int(ENCHANT_COSTS["materials"][mat_id]):
			GameManager.toast_message.emit("材料不足!", Color(1.0, 0.3, 0.3))
			return false
	
	# 扣费
	data["player"]["gold"] = int(data["player"]["gold"]) - ENCHANT_COSTS["gold"]
	for mat_id in ENCHANT_COSTS["materials"]:
		data["materials"][mat_id] = int(data["materials"][mat_id]) - int(ENCHANT_COSTS["materials"][mat_id])
	
	# 随机附魔
	var keys: Array = ENCHANTS.keys()
	var enchant_id: String = keys[randi() % keys.size()]
	item["enchant"] = enchant_id
	
	var enchant: Dictionary = ENCHANTS[enchant_id]
	item_enchanted.emit(item, enchant_id)
	AudioManager.play_sfx("craft")
	GameManager.toast_message.emit("附魔成功: %s" % enchant["name"], enchant["color"])
	GameManager.stats_updated.emit()
	return true

# ==================== 宝石镶嵌 ====================
const GEMS := {
	"ruby": {"name": "红宝石", "desc": "ATK+{v}", "stat": "atk", "base_value": 5, "per_grade": 5, "color": Color(0.9, 0.1, 0.1)},
	"sapphire": {"name": "蓝宝石", "desc": "DEF+{v}", "stat": "def", "base_value": 3, "per_grade": 3, "color": Color(0.1, 0.3, 0.9)},
	"emerald": {"name": "绿宝石", "desc": "HP+{v}", "stat": "hp", "base_value": 20, "per_grade": 15, "color": Color(0.1, 0.8, 0.2)},
	"amethyst": {"name": "紫水晶", "desc": "暴击率+{v}%", "stat": "crit", "base_value": 2, "per_grade": 1, "color": Color(0.6, 0.1, 0.9)},
	"topaz": {"name": "黄玉", "desc": "暴击伤害+{v}%", "stat": "crit_dmg", "base_value": 5, "per_grade": 5, "color": Color(0.9, 0.7, 0.1)},
	"obsidian": {"name": "黑曜石", "desc": "吸血+{v}%", "stat": "lifesteal", "base_value": 1, "per_grade": 1, "color": Color(0.1, 0.1, 0.1)},
}

const GEM_GRADES := ["粗糙", "普通", "精良", "完美", "传说"]
const GEM_MAX_GRADE := 5

## 宝石孔数(根据装备品质)
func get_gem_slots(item: Dictionary) -> int:
	var rarity: int = int(item.get("rarity", 0))
	if rarity <= 1: return 0
	if rarity == 2: return 1
	if rarity == 3: return 2
	if rarity == 4: return 3
	return 4  # 神话4孔

## 镶嵌宝石
func socket_gem(item: Dictionary, gem_type: String, gem_grade: int) -> bool:
	var max_slots: int = get_gem_slots(item)
	if max_slots <= 0:
		GameManager.toast_message.emit("该装备无法镶嵌宝石!", Color(1.0, 0.3, 0.3))
		return false
	
	if not item.has("gems"):
		item["gems"] = []
	
	var current_gems: Array = item["gems"]
	if current_gems.size() >= max_slots:
		GameManager.toast_message.emit("宝石孔已满!", Color(1.0, 0.3, 0.3))
		return false
	
	# 检查是否有该宝石
	var data: Dictionary = GameManager.game_data
	if not data.has("gem_inventory"):
		data["gem_inventory"] = {}
	var gem_key: String = gem_type + "_" + str(gem_grade)
	var have: int = int(data["gem_inventory"].get(gem_key, 0))
	if have <= 0:
		GameManager.toast_message.emit("没有该宝石!", Color(1.0, 0.3, 0.3))
		return false
	
	# 镶嵌
	data["gem_inventory"][gem_key] = have - 1
	current_gems.append({"type": gem_type, "grade": gem_grade})
	
	var gem_info: Dictionary = GEMS[gem_type]
	gem_socketed.emit(item, {"type": gem_type, "grade": gem_grade})
	AudioManager.play_sfx("pickup")
	GameManager.toast_message.emit("镶嵌成功: %s%s" % [GEM_GRADES[gem_grade], gem_info["name"]], gem_info["color"])
	GameManager.stats_updated.emit()
	return true

## 计算宝石总加成
func get_gem_bonus(item: Dictionary, stat: String) -> int:
	if not item.has("gems"):
		return 0
	var total: int = 0
	for gem in item["gems"]:
		var gem_type: String = gem["type"]
		var gem_grade: int = int(gem["grade"])
		if not GEMS.has(gem_type):
			continue
		var gem_info: Dictionary = GEMS[gem_type]
		if gem_info["stat"] == stat:
			total += int(gem_info["base_value"]) + int(gem_info["per_grade"]) * gem_grade
	return total

# ==================== 套装系统 ====================
const EQUIPMENT_SETS := {
	"shadow_set": {
		"name": "暗影套装", "color": Color(0.4, 0.1, 0.6),
		"pieces": ["暗影之刃", "暗影战甲", "暗影兜帽", "暗影战靴", "暗影之戒", "暗影坠饰"],
		"bonuses": {
			2: {"desc": "ATK+10%, 暗影伤害+5%", "atk_pct": 10, "skill_dmg_pct": 5},
			4: {"desc": "暴击率+8%, 暴击伤害+20%", "crit": 8, "crit_dmg": 20},
			6: {"desc": "全属性+15%, 获得暗影护盾", "all_stats_pct": 15, "shadow_shield": true},
		}
	},
	"abyss_set": {
		"name": "深渊套装", "color": Color(0.7, 0.0, 0.2),
		"pieces": ["深渊法杖", "深渊鳞甲", "深渊面具", "深渊行者", "深渊指环", "深渊之心"],
		"bonuses": {
			2: {"desc": "HP+15%, DEF+10%", "hp_pct": 15, "def_pct": 10},
			4: {"desc": "吸血+5%, 生命回复+50%", "lifesteal": 5, "hp_regen_pct": 50},
			6: {"desc": "受到致命伤时免死一次(CD60s), DEF+20%", "immortal_set": true, "def_pct": 20},
		}
	},
	"bone_set": {
		"name": "骸骨套装", "color": Color(0.8, 0.8, 0.7),
		"pieces": ["骨碎巨锤", "骨甲", "骨盔", "迅捷之靴", "嗜血戒指", "灵魂项链"],
		"bonuses": {
			2: {"desc": "ATK+8%, 击杀回复3%HP", "atk_pct": 8, "kill_heal_pct": 3},
			4: {"desc": "暴击伤害+30%, 20%双击", "crit_dmg": 30, "double_hit_pct": 20},
			6: {"desc": "攻击无视30%防御, ATK+25%", "armor_pen_pct": 30, "atk_pct": 25},
		}
	},
}

## 计算当前套装激活数
func get_active_set_bonuses() -> Dictionary:
	var data: Dictionary = GameManager.game_data
	var result: Dictionary = {}
	
	for set_id in EQUIPMENT_SETS:
		var set_info: Dictionary = EQUIPMENT_SETS[set_id]
		var count: int = 0
		for slot_key in data["equipment"]:
			var item = data["equipment"][slot_key]
			if item == null:
				continue
			var base_name: String = item["name"]
			# 去掉品质前缀
			for prefix in ["暗影·", "深渊·", "诅咒·", "虚无·", "混沌·", "灭世·", "永恒·"]:
				base_name = base_name.replace(prefix, "")
			if base_name in set_info["pieces"]:
				count += 1
		
		if count >= 2:
			result[set_id] = {"count": count, "bonuses": {}}
			for threshold in set_info["bonuses"]:
				if count >= int(threshold):
					var bonus: Dictionary = set_info["bonuses"][threshold]
					for key in bonus:
						if key != "desc":
							result[set_id]["bonuses"][key] = bonus[key]
	
	return result

## 获取套装属性加成
func get_set_stat_bonus(stat: String) -> float:
	var sets: Dictionary = get_active_set_bonuses()
	var total: float = 0.0
	for set_id in sets:
		var bonuses: Dictionary = sets[set_id]["bonuses"]
		if bonuses.has(stat):
			total += float(bonuses[stat])
	return total

# ==================== 装备分解系统 ====================
signal item_decomposed(materials_gained: Dictionary)

## 分解装备 → 获得材料 + 金币
func decompose_item(item: Dictionary) -> Dictionary:
	var rarity: int = int(item.get("rarity", 0))
	var level: int = int(item.get("level", 1))
	var enhance_lv: int = int(item.get("enhance_level", 0))
	
	# 基础材料回收
	var mats_gained: Dictionary = {}
	var gold_gained: int = (level * 20 + rarity * 100 + enhance_lv * 50)
	
	# 根据品质给不同材料
	var possible_mats: Array = ["shadow_essence", "bone_fragment", "cursed_iron", "soul_shard"]
	var mat_count: int = rarity + 1
	for i in range(mat_count):
		var mat_id: String = possible_mats[randi() % possible_mats.size()]
		mats_gained[mat_id] = mats_gained.get(mat_id, 0) + 1
	
	# 高品质额外给稀有材料
	if rarity >= DataManager.Rarity.EPIC:
		var rare_mats: Array = ["demon_blood", "abyss_crystal", "dragon_scale"]
		mats_gained[rare_mats[randi() % rare_mats.size()]] = rarity - 2
	
	# 强化等级返还部分材料
	if enhance_lv > 5:
		mats_gained["cursed_iron"] = mats_gained.get("cursed_iron", 0) + enhance_lv / 3
	
	# 应用奖励
	GameManager.add_gold(gold_gained)
	for mat_id in mats_gained:
		GameManager.game_data["materials"][mat_id] = int(GameManager.game_data["materials"].get(mat_id, 0)) + int(mats_gained[mat_id])
	
	item_decomposed.emit(mats_gained)
	GameManager.toast_message.emit("分解成功! +💰%d +材料x%d" % [gold_gained, mat_count], Color(0.5, 1.0, 0.8))
	return {"gold": gold_gained, "materials": mats_gained}

# ==================== 装备合成系统 ====================
signal item_synthesized(new_item: Dictionary)

# 合成配方: 3件同槽位装备 → 1件更高品质
## 合成装备(需要3件同槽位同品质装备)
func synthesize_items(items: Array) -> Dictionary:
	if items.size() < 3:
		GameManager.toast_message.emit("需要3件同槽位装备才能合成!", Color(1.0, 0.3, 0.3))
		return {"success": false}
	
	var slot: int = int(items[0]["slot"])
	var base_rarity: int = int(items[0]["rarity"])
	
	# 验证: 必须同槽位同品质
	for item in items:
		if int(item["slot"]) != slot:
			GameManager.toast_message.emit("装备槽位必须相同!", Color(1.0, 0.3, 0.3))
			return {"success": false}
		if int(item["rarity"]) != base_rarity:
			GameManager.toast_message.emit("装备品质必须相同!", Color(1.0, 0.3, 0.3))
			return {"success": false}
	
	# 合成费用
	var synth_cost: int = (base_rarity + 1) * 2000
	if int(GameManager.game_data["player"]["gold"]) < synth_cost:
		GameManager.toast_message.emit("金币不足! 需要%d" % synth_cost, Color(1.0, 0.3, 0.3))
		return {"success": false}
	
	# 扣费
	GameManager.game_data["player"]["gold"] -= synth_cost
	
	# 生成新装备(品质+1)
	var new_rarity: int = mini(base_rarity + 1, DataManager.Rarity.MYTHIC)
	var avg_level: int = 0
	for item in items:
		avg_level += int(item["level"])
	avg_level = avg_level / items.size()
	
	var new_item: Dictionary = DataManager.generate_item(slot, avg_level + 3, new_rarity - DataManager.roll_rarity(avg_level / 10))
	# 强制设置新品质
	new_item["rarity"] = new_rarity
	
	item_synthesized.emit(new_item)
	var rarity_name: String = DataManager.RARITY_INFO[new_rarity as DataManager.Rarity]["name"]
	GameManager.toast_message.emit("合成成功! 获得%s装备!" % rarity_name, DataManager.RARITY_INFO[new_rarity as DataManager.Rarity]["color"])
	AudioManager.play_sfx("reward")
	return {"success": true, "item": new_item}

## 获取分解预览(显示能获得什么)
func get_decompose_preview(item: Dictionary) -> Dictionary:
	var rarity: int = int(item.get("rarity", 0))
	var level: int = int(item.get("level", 1))
	var enhance_lv: int = int(item.get("enhance_level", 0))
	var gold: int = (level * 20 + rarity * 100 + enhance_lv * 50)
	var mat_count: int = rarity + 1
	return {"gold": gold, "material_count": mat_count, "has_rare": rarity >= DataManager.Rarity.EPIC}
