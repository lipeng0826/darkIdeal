extends Node
class_name SkillSystem
## 暗影深渊 - 技能与天赋系统
## 主动技能(战斗中自动释放) + 被动天赋树(永久加成)

signal skill_unlocked(skill_id: String)
signal skill_upgraded(skill_id: String, new_level: int)
signal talent_learned(talent_id: String)
signal skill_cast(skill_id: String, color: Color, target_pos: Vector2)

# ==================== 主动技能定义 ====================
const SKILLS := {
	# ---- 物理系 ----
	"slash_storm": {
		"name": "剑刃风暴", "desc": "对敌人连续攻击{hits}次，每次造成{dmg}%攻击力伤害",
		"type": "physical", "unlock_lv": 1, "max_lv": 20, "cooldown": 5.0,
		"base_hits": 3, "hit_per_lv": 1, "dmg_pct": 60, "dmg_per_lv": 8,
		"icon": "storm", "color": Color(1.0, 0.5, 0.2),
	},
	"execute": {
		"name": "斩杀", "desc": "对目标造成{dmg}%攻击力伤害，目标血量低于30%时伤害翻倍",
		"type": "physical", "unlock_lv": 5, "max_lv": 20, "cooldown": 8.0,
		"dmg_pct": 200, "dmg_per_lv": 25, "threshold": 0.3,
		"icon": "execute", "color": Color(0.8, 0.1, 0.1),
	},
	"bleed": {
		"name": "致命出血", "desc": "使敌人流血，每秒损失{dmg}%攻击力的生命，持续{dur}秒",
		"type": "physical", "unlock_lv": 10, "max_lv": 15, "cooldown": 10.0,
		"dmg_pct": 30, "dmg_per_lv": 5, "duration": 5.0, "dur_per_lv": 0.3,
		"icon": "bleed", "color": Color(0.7, 0.0, 0.0),
	},
	"whirlwind": {
		"name": "旋风斩", "desc": "释放旋风，对敌人造成{hits}次{dmg}%攻击力伤害，并降低{reduce}%防御",
		"type": "physical", "unlock_lv": 18, "max_lv": 20, "cooldown": 12.0,
		"base_hits": 5, "hit_per_lv": 1, "dmg_pct": 45, "dmg_per_lv": 6,
		"def_reduce_pct": 10, "reduce_per_lv": 2,
		"icon": "whirl", "color": Color(0.6, 0.8, 1.0),
	},
	# ---- 暗影系 ----
	"shadow_bolt": {
		"name": "暗影箭", "desc": "发射暗影箭矢，造成{dmg}%攻击力伤害，无视{ignore}%防御",
		"type": "shadow", "unlock_lv": 3, "max_lv": 20, "cooldown": 4.0,
		"dmg_pct": 150, "dmg_per_lv": 20, "ignore_def_pct": 20, "ignore_per_lv": 2,
		"icon": "bolt", "color": Color(0.5, 0.1, 0.8),
	},
	"soul_drain": {
		"name": "灵魂吸取", "desc": "吸取敌人灵魂，造成{dmg}%伤害并回复伤害{heal}%的生命",
		"type": "shadow", "unlock_lv": 12, "max_lv": 15, "cooldown": 9.0,
		"dmg_pct": 120, "dmg_per_lv": 15, "heal_pct": 30, "heal_per_lv": 3,
		"icon": "drain", "color": Color(0.3, 0.8, 0.3),
	},
	"dark_explosion": {
		"name": "暗影爆发", "desc": "释放暗影能量爆炸，造成{dmg}%攻击力伤害，暴击率+{cr}%",
		"type": "shadow", "unlock_lv": 22, "max_lv": 20, "cooldown": 15.0,
		"dmg_pct": 350, "dmg_per_lv": 35, "bonus_crit": 20, "crit_per_lv": 2,
		"icon": "explosion", "color": Color(0.4, 0.0, 0.6),
	},
	"void_rift": {
		"name": "虚空裂隙", "desc": "撕裂空间，持续{dur}秒，每秒造成{dmg}%伤害并降低攻击力{reduce}%",
		"type": "shadow", "unlock_lv": 35, "max_lv": 20, "cooldown": 20.0,
		"dmg_pct": 80, "dmg_per_lv": 10, "duration": 4.0, "dur_per_lv": 0.2,
		"atk_reduce_pct": 15, "reduce_per_lv": 1,
		"icon": "rift", "color": Color(0.2, 0.0, 0.5),
	},
	# ---- 神圣系 ----
	"holy_shield": {
		"name": "神圣护盾", "desc": "获得{shield}%最大生命值的护盾，持续{dur}秒",
		"type": "holy", "unlock_lv": 8, "max_lv": 15, "cooldown": 12.0,
		"shield_pct": 20, "shield_per_lv": 3, "duration": 6.0, "dur_per_lv": 0.3,
		"icon": "shield", "color": Color(1.0, 0.9, 0.3),
	},
	"divine_wrath": {
		"name": "神罚", "desc": "召唤神圣之光，造成{dmg}%攻击力真实伤害(无视防御)",
		"type": "holy", "unlock_lv": 28, "max_lv": 20, "cooldown": 18.0,
		"dmg_pct": 280, "dmg_per_lv": 30, "true_damage": true,
		"icon": "wrath", "color": Color(1.0, 1.0, 0.5),
	},
	"resurrection": {
		"name": "复生", "desc": "死亡时自动复活，回复{hp}%生命值，CD {cd}秒",
		"type": "holy", "unlock_lv": 40, "max_lv": 10, "cooldown": 60.0,
		"revive_hp_pct": 30, "hp_per_lv": 5, "cd_reduce_per_lv": 3.0,
		"icon": "revive", "color": Color(1.0, 1.0, 1.0),
	},
}

# ==================== 被动天赋树 ====================
# 三条路线：力量(红)、智慧(紫)、坚韧(蓝)
const TALENT_TREES := {
	"strength": {
		"name": "力量之路", "color": Color(0.9, 0.2, 0.1),
		"talents": [
			{"id": "str_atk_1", "name": "锋刃", "desc": "攻击力+5%", "max": 5, "stat": "atk_pct", "val": 5, "req": []},
			{"id": "str_atk_2", "name": "利刃", "desc": "攻击力+8%", "max": 5, "stat": "atk_pct", "val": 8, "req": ["str_atk_1"]},
			{"id": "str_crit_1", "name": "精准", "desc": "暴击率+3%", "max": 5, "stat": "crit", "val": 3, "req": ["str_atk_1"]},
			{"id": "str_crit_2", "name": "致命打击", "desc": "暴击伤害+10%", "max": 5, "stat": "crit_dmg", "val": 10, "req": ["str_crit_1"]},
			{"id": "str_pen", "name": "破甲", "desc": "无视敌人15%防御", "max": 3, "stat": "armor_pen_pct", "val": 15, "req": ["str_atk_2"]},
			{"id": "str_multi", "name": "连击", "desc": "20%概率攻击两次", "max": 3, "stat": "double_hit_pct", "val": 20, "req": ["str_crit_2"]},
			{"id": "str_execute", "name": "终结者", "desc": "敌人<20%血时伤害+30%", "max": 3, "stat": "execute_bonus", "val": 30, "req": ["str_pen", "str_multi"]},
			{"id": "str_berserker", "name": "狂战士", "desc": "血量越低攻击越高(最多+50%)", "max": 1, "stat": "berserker", "val": 50, "req": ["str_execute"]},
		]
	},
	"wisdom": {
		"name": "智慧之路", "color": Color(0.5, 0.2, 0.9),
		"talents": [
			{"id": "wis_exp_1", "name": "求知", "desc": "经验获取+8%", "max": 5, "stat": "exp_bonus_pct", "val": 8, "req": []},
			{"id": "wis_gold_1", "name": "贪婪", "desc": "金币获取+8%", "max": 5, "stat": "gold_bonus_pct", "val": 8, "req": []},
			{"id": "wis_drop_1", "name": "幸运", "desc": "装备掉落率+5%", "max": 5, "stat": "drop_bonus_pct", "val": 5, "req": ["wis_exp_1"]},
			{"id": "wis_rarity", "name": "鉴宝", "desc": "装备品质提升概率+8%", "max": 5, "stat": "rarity_bonus_pct", "val": 8, "req": ["wis_drop_1"]},
			{"id": "wis_cd", "name": "迅捷施法", "desc": "技能冷却-5%", "max": 5, "stat": "cooldown_reduce_pct", "val": 5, "req": ["wis_gold_1"]},
			{"id": "wis_skill_dmg", "name": "魔力精通", "desc": "技能伤害+10%", "max": 5, "stat": "skill_dmg_pct", "val": 10, "req": ["wis_cd"]},
			{"id": "wis_mat", "name": "采集大师", "desc": "材料掉落+10%", "max": 3, "stat": "mat_bonus_pct", "val": 10, "req": ["wis_rarity"]},
			{"id": "wis_ultimate", "name": "全知全能", "desc": "所有属性+5%", "max": 1, "stat": "all_stats_pct", "val": 5, "req": ["wis_skill_dmg", "wis_mat"]},
		]
	},
	"fortitude": {
		"name": "坚韧之路", "color": Color(0.2, 0.5, 0.9),
		"talents": [
			{"id": "for_hp_1", "name": "强壮", "desc": "生命值+8%", "max": 5, "stat": "hp_pct", "val": 8, "req": []},
			{"id": "for_def_1", "name": "坚盾", "desc": "防御力+6%", "max": 5, "stat": "def_pct", "val": 6, "req": []},
			{"id": "for_regen_1", "name": "再生", "desc": "生命回复+3/秒", "max": 5, "stat": "hp_regen", "val": 3, "req": ["for_hp_1"]},
			{"id": "for_block", "name": "格挡", "desc": "10%概率格挡50%伤害", "max": 5, "stat": "block_pct", "val": 10, "req": ["for_def_1"]},
			{"id": "for_lifesteal", "name": "嗜血", "desc": "吸血+3%", "max": 5, "stat": "lifesteal", "val": 3, "req": ["for_regen_1"]},
			{"id": "for_thorns", "name": "荆棘", "desc": "反弹10%受到的伤害", "max": 3, "stat": "thorns_pct", "val": 10, "req": ["for_block"]},
			{"id": "for_undying", "name": "不死之身", "desc": "血量低于10%时减伤50%", "max": 3, "stat": "undying_pct", "val": 50, "req": ["for_lifesteal", "for_thorns"]},
			{"id": "for_immortal", "name": "不灭意志", "desc": "致死伤害改为保留1HP(CD30s)", "max": 1, "stat": "immortal", "val": 30, "req": ["for_undying"]},
		]
	}
}

# ==================== 运行时状态 ====================
var skill_cooldowns: Dictionary = {}  # skill_id -> remaining_cd
var skill_timers: Dictionary = {}     # skill_id -> auto_cast_timer
var active_effects: Array[Dictionary] = []  # 持续效果列表
var shield_hp: int = 0
var immortal_cd: float = 0.0

func _ready() -> void:
	_init_cooldowns()

func _init_cooldowns() -> void:
	for skill_id in SKILLS:
		skill_cooldowns[skill_id] = 0.0
		skill_timers[skill_id] = 0.0

func _process(delta: float) -> void:
	if not GameManager.is_loaded or not GameManager.is_fighting:
		return
	if GameManager.is_wave_transition:
		return
	
	# 更新冷却
	for skill_id in skill_cooldowns:
		if skill_cooldowns[skill_id] > 0:
			skill_cooldowns[skill_id] -= delta
	
	# 更新不灭意志冷却
	if immortal_cd > 0:
		immortal_cd -= delta
	
	# 自动释放技能
	_auto_cast_skills(delta)
	
	# 处理持续效果
	_process_effects(delta)

func _auto_cast_skills(delta: float) -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("skills"):
		return
	if not GameManager.is_boss_fight:
		GameManager._sync_front_target()
	var equipped: Array = data["skills"].get("equipped", [])
	
	for skill_id in equipped:
		if not SKILLS.has(skill_id):
			continue
		var skill_lv: int = data["skills"]["levels"].get(skill_id, 0)
		if skill_lv <= 0:
			continue
		if skill_cooldowns[skill_id] > 0:
			continue
		
		# 释放技能
		_cast_skill(skill_id, skill_lv)
		var cd: float = SKILLS[skill_id]["cooldown"]
		# 天赋减CD
		var cd_reduce: float = get_talent_value("cooldown_reduce_pct")
		cd *= (1.0 - cd_reduce / 100.0)
		skill_cooldowns[skill_id] = cd
		_emit_skill_cast(skill_id, SKILLS[skill_id]["color"])

func _emit_skill_cast(skill_id: String, color: Color) -> void:
	var pos := Vector2(400, 300)
	if not GameManager.is_boss_fight:
		var target := GameManager.battle_wave.get_front_target()
		if not target.is_empty():
			pos = Vector2(500 + int(target.get("slot_index", 0)) * 40, 200)
	skill_cast.emit(skill_id, color, pos)

func _cast_skill(skill_id: String, level: int) -> void:
	var skill: Dictionary = SKILLS[skill_id]
	var combat: Dictionary = GameManager.game_data["combat"]
	var player_atk: int = int(combat["atk"])
	var skill_dmg_bonus: float = 1.0 + get_talent_value("skill_dmg_pct") / 100.0
	
	match skill_id:
		"slash_storm":
			var hits: int = int(skill["base_hits"]) + int(skill["hit_per_lv"]) * (level - 1)
			if not GameManager.is_boss_fight:
				hits = mini(hits, 4)
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var total_dmg: int = int(player_atk * dmg_pct * hits * skill_dmg_bonus)
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"execute":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var total_dmg: int = int(player_atk * dmg_pct * skill_dmg_bonus)
			var threshold_hp: int = GameManager.enemy_max_hp
			if not GameManager.is_boss_fight:
				var t := GameManager.battle_wave.get_front_target()
				if not t.is_empty():
					threshold_hp = int(t["max_hp"])
			if GameManager.enemy_hp < threshold_hp * skill["threshold"]:
				total_dmg *= 2
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"shadow_bolt":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var ignore: float = (float(skill["ignore_def_pct"]) + float(skill["ignore_per_lv"]) * (level - 1)) / 100.0
			var total_dmg: int = int(player_atk * dmg_pct * skill_dmg_bonus * (1.0 + ignore))
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"soul_drain":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var total_dmg: int = int(player_atk * dmg_pct * skill_dmg_bonus)
			var heal_pct: float = (float(skill["heal_pct"]) + float(skill["heal_per_lv"]) * (level - 1)) / 100.0
			var heal: int = int(total_dmg * heal_pct / 100.0)
			GameManager.player_hp = mini(GameManager.player_hp + heal, int(combat["max_hp"]))
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"dark_explosion":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var bonus_crit: float = float(skill["bonus_crit"]) + float(skill["crit_per_lv"]) * (level - 1)
			var is_crit: bool = randf() * 100.0 < (float(combat["crit"]) + bonus_crit)
			var total_dmg: int = int(player_atk * dmg_pct * skill_dmg_bonus)
			if is_crit:
				total_dmg = int(total_dmg * (1.0 + float(combat["crit_dmg"]) / 100.0))
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"holy_shield":
			var shield_pct: float = (float(skill["shield_pct"]) + float(skill["shield_per_lv"]) * (level - 1)) / 100.0
			shield_hp = int(int(combat["max_hp"]) * shield_pct)
			var dur: float = float(skill["duration"]) + float(skill["dur_per_lv"]) * (level - 1)
			active_effects.append({"type": "shield", "duration": dur, "time": 0.0})
			GameManager.battle_log.emit("🛡 %s 激活! 护盾: %d" % [skill["name"], shield_hp], skill["color"])
		
		"divine_wrath":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var total_dmg: int = int(player_atk * dmg_pct * skill_dmg_bonus)
			_deal_skill_damage(total_dmg, skill["name"], skill["color"])
		
		"bleed", "void_rift", "whirlwind":
			var dmg_pct: float = (float(skill["dmg_pct"]) + float(skill["dmg_per_lv"]) * (level - 1)) / 100.0
			var dur: float = float(skill["duration"]) + float(skill.get("dur_per_lv", 0)) * (level - 1)
			active_effects.append({
				"type": "dot", "skill_id": skill_id,
				"dmg_per_tick": int(player_atk * dmg_pct / 100.0 * skill_dmg_bonus),
				"duration": dur, "time": 0.0, "tick_timer": 0.0,
			})
			GameManager.battle_log.emit("🔥 %s 生效!" % skill["name"], skill["color"])

	AudioManager.play_sfx("crit")

func _deal_skill_damage(dmg: int, skill_name: String, color: Color) -> void:
	GameManager.apply_skill_damage(dmg, skill_name, color)

func _process_effects(delta: float) -> void:
	var i: int = active_effects.size() - 1
	while i >= 0:
		var eff: Dictionary = active_effects[i]
		eff["time"] += delta
		if eff["time"] >= eff["duration"]:
			if eff["type"] == "shield":
				shield_hp = 0
			active_effects.remove_at(i)
		elif eff["type"] == "dot":
			eff["tick_timer"] += delta
			if eff["tick_timer"] >= 1.0:
				eff["tick_timer"] -= 1.0
				GameManager.apply_dot_damage(int(eff["dmg_per_tick"]))
		i -= 1

## 护盾吸收伤害
func absorb_damage(dmg: int) -> int:
	if shield_hp <= 0:
		return dmg
	if dmg <= shield_hp:
		shield_hp -= dmg
		return 0
	else:
		var remaining: int = dmg - shield_hp
		shield_hp = 0
		return remaining

## 不灭意志检测
func check_immortal() -> bool:
	if immortal_cd > 0:
		return false
	var val: float = get_talent_value("immortal")
	if val > 0:
		immortal_cd = val
		return true
	return false

# ==================== 天赋计算 ====================
func get_talent_value(stat: String) -> float:
	var data: Dictionary = GameManager.game_data
	if not data.has("talents"):
		return 0.0
	var talents: Dictionary = data["talents"]
	var total: float = 0.0
	for tree_id in TALENT_TREES:
		var tree: Dictionary = TALENT_TREES[tree_id]
		for talent in tree["talents"]:
			var tid: String = talent["id"]
			var learned: int = int(talents.get(tid, 0))
			if learned > 0 and talent["stat"] == stat:
				total += float(talent["val"]) * learned
	return total

## 学习天赋
func learn_talent(talent_id: String) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("talents"):
		data["talents"] = {}
	
	# 查找天赋
	var found_talent: Dictionary = {}
	for tree_id in TALENT_TREES:
		for talent in TALENT_TREES[tree_id]["talents"]:
			if talent["id"] == talent_id:
				found_talent = talent
				break
	
	if found_talent.is_empty():
		return false
	
	var current: int = int(data["talents"].get(talent_id, 0))
	if current >= int(found_talent["max"]):
		GameManager.toast_message.emit("天赋已满级!", Color(1.0, 0.3, 0.3))
		return false
	
	# 检查前置
	for req in found_talent["req"]:
		var req_lv: int = int(data["talents"].get(req, 0))
		if req_lv <= 0:
			GameManager.toast_message.emit("前置天赋未学习!", Color(1.0, 0.3, 0.3))
			return false
	
	# 检查天赋点
	var tp: int = int(data.get("talent_points", 0))
	if tp <= 0:
		GameManager.toast_message.emit("天赋点不足!", Color(1.0, 0.3, 0.3))
		return false
	
	data["talent_points"] = tp - 1
	data["talents"][talent_id] = current + 1
	talent_learned.emit(talent_id)
	AudioManager.play_sfx("levelup")
	GameManager.toast_message.emit("学习天赋: %s" % found_talent["name"], Color(0.5, 1.0, 0.5))
	GameManager.stats_updated.emit()
	return true

## 升级技能
func upgrade_skill(skill_id: String) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("skills"):
		data["skills"] = {"levels": {}, "equipped": []}
	
	if not SKILLS.has(skill_id):
		return false
	
	var skill: Dictionary = SKILLS[skill_id]
	var current_lv: int = int(data["skills"]["levels"].get(skill_id, 0))
	
	if current_lv >= int(skill["max_lv"]):
		GameManager.toast_message.emit("技能已满级!", Color(1.0, 0.3, 0.3))
		return false
	
	# 升级消耗金币
	var cost: int = (current_lv + 1) * 500
	if not GameManager.spend_gold(cost):
		GameManager.toast_message.emit("金币不足! 需要%d" % cost, Color(1.0, 0.3, 0.3))
		return false
	
	data["skills"]["levels"][skill_id] = current_lv + 1
	
	if current_lv == 0:
		skill_unlocked.emit(skill_id)
		GameManager.toast_message.emit("解锁技能: %s" % skill["name"], skill["color"])
	else:
		skill_upgraded.emit(skill_id, current_lv + 1)
		GameManager.toast_message.emit("%s 升级到 Lv.%d" % [skill["name"], current_lv + 1], skill["color"])
	
	AudioManager.play_sfx("craft")
	return true

## 装备/卸下技能(最多4个)
func equip_skill(skill_id: String) -> bool:
	var data: Dictionary = GameManager.game_data
	if not data.has("skills"):
		return false
	var equipped: Array = data["skills"]["equipped"]
	if skill_id in equipped:
		return false
	if equipped.size() >= 4:
		GameManager.toast_message.emit("技能槽已满(最多4个)!", Color(1.0, 0.3, 0.3))
		return false
	equipped.append(skill_id)
	return true

func unequip_skill(skill_id: String) -> void:
	var data: Dictionary = GameManager.game_data
	if not data.has("skills"):
		return
	data["skills"]["equipped"].erase(skill_id)
