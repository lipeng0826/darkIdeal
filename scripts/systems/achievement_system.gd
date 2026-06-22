extends Node
class_name AchievementSystem
## 暗影深渊 - 成就系统 + 转生/轮回系统
## 成就解锁称号和宝石奖励，转生重置获取永久加成

signal achievement_unlocked(ach_id: String)
signal title_obtained(title: String)
signal rebirth_completed(rebirth_count: int)

# ==================== 成就定义 ====================
const ACHIEVEMENTS := [
	# 战斗成就
	{"id": "kill_100", "name": "初露锋芒", "desc": "累计击杀100个敌人", "type": "kill", "target": 100, "reward": {"gems": 10}, "title": ""},
	{"id": "kill_1000", "name": "百战之士", "desc": "累计击杀1000个敌人", "type": "kill", "target": 1000, "reward": {"gems": 30}, "title": "百战勇士"},
	{"id": "kill_10000", "name": "万夫之敌", "desc": "累计击杀10000个敌人", "type": "kill", "target": 10000, "reward": {"gems": 100}, "title": "屠戮者"},
	{"id": "kill_100000", "name": "死神", "desc": "累计击杀100000个敌人", "type": "kill", "target": 100000, "reward": {"gems": 500}, "title": "死神"},
	
	# 等级成就
	{"id": "lv_10", "name": "探索者", "desc": "达到10级", "type": "level", "target": 10, "reward": {"gems": 10}, "title": ""},
	{"id": "lv_25", "name": "冒险者", "desc": "达到25级", "type": "level", "target": 25, "reward": {"gems": 30}, "title": "冒险者"},
	{"id": "lv_50", "name": "勇者", "desc": "达到50级", "type": "level", "target": 50, "reward": {"gems": 80}, "title": "勇者"},
	{"id": "lv_75", "name": "英雄", "desc": "达到75级", "type": "level", "target": 75, "reward": {"gems": 150}, "title": "英雄"},
	{"id": "lv_100", "name": "传说", "desc": "达到100级", "type": "level", "target": 100, "reward": {"gems": 500}, "title": "传说"},
	
	# Boss成就
	{"id": "boss_1", "name": "挑战者", "desc": "击败第一个Boss", "type": "boss_count", "target": 1, "reward": {"gems": 20}, "title": ""},
	{"id": "boss_10", "name": "Boss猎手", "desc": "击败10个Boss", "type": "boss_count", "target": 10, "reward": {"gems": 50}, "title": "Boss猎手"},
	{"id": "boss_50", "name": "深渊征服者", "desc": "击败50个Boss", "type": "boss_count", "target": 50, "reward": {"gems": 200}, "title": "深渊征服者"},
	{"id": "boss_all", "name": "万王之王", "desc": "击败所有区域Boss", "type": "boss_zones", "target": 10, "reward": {"gems": 1000}, "title": "万王之王"},
	
	# 锻造成就
	{"id": "craft_10", "name": "学徒铁匠", "desc": "锻造10件装备", "type": "craft", "target": 10, "reward": {"gems": 15}, "title": ""},
	{"id": "craft_50", "name": "熟练铁匠", "desc": "锻造50件装备", "type": "craft", "target": 50, "reward": {"gems": 50}, "title": "铁匠"},
	{"id": "craft_200", "name": "大师铁匠", "desc": "锻造200件装备", "type": "craft", "target": 200, "reward": {"gems": 150}, "title": "锻造大师"},
	
	# 财富成就
	{"id": "gold_10k", "name": "小富即安", "desc": "累计获得10000金币", "type": "gold", "target": 10000, "reward": {"gems": 10}, "title": ""},
	{"id": "gold_100k", "name": "富甲一方", "desc": "累计获得100000金币", "type": "gold", "target": 100000, "reward": {"gems": 50}, "title": "富豪"},
	{"id": "gold_1m", "name": "金山银海", "desc": "累计获得1000000金币", "type": "gold", "target": 1000000, "reward": {"gems": 200}, "title": "金王"},
	
	# 装备成就
	{"id": "equip_rare", "name": "稀有收藏", "desc": "获得一件稀有装备", "type": "rarity_get", "target": 2, "reward": {"gems": 10}, "title": ""},
	{"id": "equip_epic", "name": "史诗品鉴", "desc": "获得一件史诗装备", "type": "rarity_get", "target": 3, "reward": {"gems": 30}, "title": ""},
	{"id": "equip_legend", "name": "传说降临", "desc": "获得一件传说装备", "type": "rarity_get", "target": 4, "reward": {"gems": 80}, "title": "传说持有者"},
	{"id": "equip_mythic", "name": "神话诞生", "desc": "获得一件神话装备", "type": "rarity_get", "target": 5, "reward": {"gems": 300}, "title": "神话持有者"},
	
	# 强化成就
	{"id": "enhance_5", "name": "初次强化", "desc": "将装备强化到+5", "type": "enhance", "target": 5, "reward": {"gems": 15}, "title": ""},
	{"id": "enhance_10", "name": "精炼之道", "desc": "将装备强化到+10", "type": "enhance", "target": 10, "reward": {"gems": 50}, "title": "精炼师"},
	{"id": "enhance_20", "name": "强化大师", "desc": "将装备强化到+20", "type": "enhance", "target": 20, "reward": {"gems": 200}, "title": "强化大师"},
	{"id": "enhance_30", "name": "极限强化", "desc": "将装备强化到+30", "type": "enhance", "target": 30, "reward": {"gems": 500}, "title": "极限强化者"},
	
	# 深渊塔成就
	{"id": "tower_10", "name": "塔之新手", "desc": "深渊塔到达第10层", "type": "tower", "target": 10, "reward": {"gems": 20}, "title": ""},
	{"id": "tower_25", "name": "塔之勇者", "desc": "深渊塔到达第25层", "type": "tower", "target": 25, "reward": {"gems": 60}, "title": "塔之勇者"},
	{"id": "tower_50", "name": "塔之王者", "desc": "深渊塔到达第50层", "type": "tower", "target": 50, "reward": {"gems": 200}, "title": "塔之王者"},
	
	# 宠物成就
	{"id": "pet_1", "name": "驯兽师", "desc": "获得第一只宠物", "type": "pet_count", "target": 1, "reward": {"gems": 20}, "title": ""},
	{"id": "pet_5", "name": "宠物收藏家", "desc": "拥有5只宠物", "type": "pet_count", "target": 5, "reward": {"gems": 100}, "title": "驯兽大师"},
	{"id": "pet_evolve", "name": "进化之道", "desc": "进化一只宠物", "type": "pet_evolve", "target": 1, "reward": {"gems": 80}, "title": ""},
	
	# 转生成就
	{"id": "rebirth_1", "name": "轮回之始", "desc": "第一次转生", "type": "rebirth", "target": 1, "reward": {"gems": 100}, "title": "转生者"},
	{"id": "rebirth_5", "name": "轮回老手", "desc": "完成5次转生", "type": "rebirth", "target": 5, "reward": {"gems": 300}, "title": "轮回者"},
	{"id": "rebirth_10", "name": "永恒轮回", "desc": "完成10次转生", "type": "rebirth", "target": 10, "reward": {"gems": 1000}, "title": "永恒之人"},
]

# ==================== 称号系统 ====================
const TITLE_BONUSES := {
	"百战勇士":   {"atk_pct": 3},
	"屠戮者":     {"atk_pct": 5, "crit": 2},
	"死神":       {"atk_pct": 10, "crit": 5, "crit_dmg": 10},
	"冒险者":     {"exp_bonus_pct": 5},
	"勇者":       {"all_stats_pct": 3},
	"英雄":       {"all_stats_pct": 5},
	"传说":       {"all_stats_pct": 8},
	"Boss猎手":   {"atk_pct": 5},
	"深渊征服者": {"atk_pct": 8, "def_pct": 5},
	"万王之王":   {"all_stats_pct": 10},
	"铁匠":       {"gold_bonus_pct": 5},
	"锻造大师":   {"gold_bonus_pct": 10},
	"富豪":       {"gold_bonus_pct": 8},
	"金王":       {"gold_bonus_pct": 15},
	"传说持有者": {"drop_bonus_pct": 5},
	"神话持有者": {"drop_bonus_pct": 10, "rarity_bonus_pct": 5},
	"精炼师":     {"def_pct": 5},
	"强化大师":   {"all_stats_pct": 5},
	"极限强化者": {"all_stats_pct": 8, "atk_pct": 5},
	"塔之勇者":   {"hp_pct": 5, "def_pct": 3},
	"塔之王者":   {"all_stats_pct": 5, "hp_pct": 8},
	"驯兽大师":   {"atk_pct": 3, "hp_pct": 3},
	"转生者":     {"all_stats_pct": 3},
	"轮回者":     {"all_stats_pct": 5},
	"永恒之人":   {"all_stats_pct": 10},
}

## 检查所有成就进度(自动通知)
func check_achievements() -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("achievements"):
		data["achievements"] = {"claimed": []}
	var claimed: Array = data["achievements"]["claimed"]
	for ach in ACHIEVEMENTS:
		if ach["id"] in claimed:
			continue
		var progress: int = get_achievement_progress(ach)
		if progress >= int(ach["target"]):
			# 通知可领取（不自动领取，让玩家手动）
			pass  # UI会显示可领取状态

## 检查成就进度
func get_achievement_progress(ach: Dictionary) -> int:
	var data: Dictionary = GameManager.game_data
	var stats: Dictionary = data["stats"]
	match ach["type"]:
		"kill": return int(stats["total_kills"])
		"level": return int(data["player"]["level"])
		"boss_count": return int(stats["boss_kill_count"])
		"boss_zones": return int(stats["bosses_killed"].size()) if stats.has("bosses_killed") else 0
		"craft": return int(stats["total_crafts"])
		"gold": return int(stats["total_gold_earned"])
		"rarity_get": return _get_best_rarity(data)
		"enhance": return _get_best_enhance(data)
		"tower": return int(data.get("tower", {}).get("best_floor", 0))
		"pet_count": return _get_pet_count(data)
		"pet_evolve": return int(data.get("achievements_extra", {}).get("pet_evolves", 0))
		"rebirth": return int(data.get("rebirth", {}).get("count", 0))
	return 0

func _get_best_rarity(data: Dictionary) -> int:
	var best: int = 0
	for slot_key in data["equipment"]:
		var item = data["equipment"][slot_key]
		if item != null:
			best = maxi(best, int(item.get("rarity", 0)))
	for item in data["inventory"]:
		best = maxi(best, int(item.get("rarity", 0)))
	return best

func _get_best_enhance(data: Dictionary) -> int:
	var best: int = 0
	for slot_key in data["equipment"]:
		var item = data["equipment"][slot_key]
		if item != null:
			best = maxi(best, int(item.get("enhance_level", 0)))
	return best

func _get_pet_count(data: Dictionary) -> int:
	if not data.has("pets"):
		return 0
	return data["pets"]["owned"].size()

## 领取成就奖励
func claim_achievement(ach_id: String) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("achievements"):
		data["achievements"] = {"claimed": []}
	
	if ach_id in data["achievements"]["claimed"]:
		return false
	
	var ach: Dictionary = {}
	for a in ACHIEVEMENTS:
		if a["id"] == ach_id:
			ach = a
			break
	if ach.is_empty():
		return false
	
	var progress: int = get_achievement_progress(ach)
	if progress < int(ach["target"]):
		return false
	
	data["achievements"]["claimed"].append(ach_id)
	
	# 奖励
	var reward: Dictionary = ach["reward"]
	if reward.has("gems"):
		GameManager.add_gems(int(reward["gems"]))
	
	# 称号
	var title_str: String = ach.get("title", "")
	if not title_str.is_empty():
		if not data.has("titles"):
			data["titles"] = {"owned": [], "active": ""}
		if not title_str in data["titles"]["owned"]:
			data["titles"]["owned"].append(title_str)
			title_obtained.emit(title_str)
			GameManager.toast_message.emit("获得称号: 【%s】" % title_str, Color(1.0, 0.85, 0.0))
	
	achievement_unlocked.emit(ach_id)
	AudioManager.play_sfx("reward")
	GameManager.toast_message.emit("成就达成: %s!" % ach["name"], Color(1.0, 0.85, 0.0))
	return true

## 设置活跃称号
func set_active_title(title: String) -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("titles"):
		return
	if title in data["titles"]["owned"]:
		data["titles"]["active"] = title
		GameManager.stats_updated.emit()

## 获取当前称号加成
func get_title_bonus(stat: String) -> float:
	var data: Dictionary = GameManager.game_data
	if not data.has("titles"):
		return 0.0
	var active: String = data["titles"].get("active", "")
	if active.is_empty() or not TITLE_BONUSES.has(active):
		return 0.0
	return float(TITLE_BONUSES[active].get(stat, 0))

# ==================== 转生/轮回系统 ====================
# 转生条件：等级达到50+，转生后重置等级但获得永久加成
const REBIRTH_MIN_LEVEL := 50
const REBIRTH_BONUS_PER_COUNT := {
	"atk_pct": 5.0,      # 每次转生 ATK+5%
	"def_pct": 3.0,      # DEF+3%
	"hp_pct": 5.0,       # HP+5%
	"crit": 1.0,         # 暴击+1%
	"exp_bonus_pct": 5.0,# 经验+5%
	"gold_bonus_pct": 5.0,# 金币+5%
}

## 检查是否可以转生
func can_rebirth() -> bool:
	var data: Dictionary = GameManager.game_data
	return int(data["player"]["level"]) >= REBIRTH_MIN_LEVEL

## 执行转生
func do_rebirth() -> bool:
	if not can_rebirth():
		GameManager.toast_message.emit("等级不足! 需要Lv.%d" % REBIRTH_MIN_LEVEL, Color(1.0, 0.3, 0.3))
		return false
	
	var data: Dictionary = GameManager.game_data
	if not data.has("rebirth"):
		data["rebirth"] = {"count": 0, "total_levels": 0}
	
	var current_lv: int = int(data["player"]["level"])
	data["rebirth"]["count"] = int(data["rebirth"]["count"]) + 1
	data["rebirth"]["total_levels"] = int(data["rebirth"].get("total_levels", 0)) + current_lv
	
	# 重置等级
	data["player"]["level"] = 1
	data["player"]["exp"] = 0
	
	# 保留: 装备、材料、宝石、金币的50%、宠物、技能等级
	data["player"]["gold"] = int(int(data["player"]["gold"]) / 2)
	
	# 重置区域
	data["zone"]["current"] = 0
	# 保留解锁的区域(减少到一半)
	data["zone"]["unlocked"] = maxi(0, int(data["zone"]["unlocked"]) / 2)
	
	# 给天赋点奖励
	data["talent_points"] = int(data.get("talent_points", 0)) + 3
	
	# 重新计算属性
	GameManager.player_hp = int(data["combat"]["max_hp"])
	GameManager._recalculate_stats()
	
	var count: int = int(data["rebirth"]["count"])
	rebirth_completed.emit(count)
	AudioManager.play_sfx("reward")
	GameManager.toast_message.emit("转生成功! 第%d次轮回\n获得永久加成+天赋点×3" % count, Color(1.0, 0.85, 0.0))
	return true

## 获取转生永久加成
func get_rebirth_bonus(stat: String) -> float:
	var data: Dictionary = GameManager.game_data
	if not data.has("rebirth"):
		return 0.0
	var count: int = int(data["rebirth"]["count"])
	if count <= 0:
		return 0.0
	return float(REBIRTH_BONUS_PER_COUNT.get(stat, 0)) * count
