extends Node
## 暗影深渊 - 游戏管理器 (核心Autoload)
## 管理游戏状态、战斗循环、挂机逻辑

# ==================== 信号 ====================
signal game_started
signal player_level_up(new_level: int)
signal enemy_killed(enemy_name: String, rewards: Dictionary)
signal boss_killed(boss_name: String, rewards: Dictionary)
signal player_died
signal gold_changed(amount: int)
signal gems_changed(amount: int)
signal item_obtained(item: Dictionary)
signal stats_updated
signal zone_changed(zone_index: int)
signal battle_log(message: String, color: Color)
signal toast_message(text: String, color: Color)
signal show_offline_rewards(rewards: Dictionary)

# ==================== 子系统引用 ====================
var skill_system: SkillSystem
var pet_system: PetSystem
var tower_system: TowerSystem
var enhance_system: EnhanceSystem
var achievement_system: AchievementSystem

# ==================== 游戏状态 ====================
var game_data: Dictionary = {}
var is_loaded := false

# 战斗状态
var is_fighting := true
var is_boss_fight := false
var current_enemy := {}
var current_boss := {}
var enemy_hp := 0
var enemy_max_hp := 0
var player_hp := 0
var attack_timer := 0.0
var enemy_attack_timer := 0.0
var boss_timer := 0.0
var boss_enrage := false

# 战斗参数
const PLAYER_ATTACK_SPEED := 1.2  # 秒
const ENEMY_ATTACK_SPEED := 1.5
const DROP_RATE := 0.15  # 装备掉率
const MATERIAL_DROP_RATE := 0.3  # 材料掉率

# 死亡惩罚系统
var _death_debuff_timer := 0.0
var _death_debuff_active := false
const DEATH_DEBUFF_ATK_PENALTY := 0.20  # 攻击力降低20%

# ==================== 初始化 ====================
func _ready() -> void:
	# 初始化子系统
	skill_system = SkillSystem.new()
	add_child(skill_system)
	pet_system = PetSystem.new()
	add_child(pet_system)
	tower_system = TowerSystem.new()
	add_child(tower_system)
	enhance_system = EnhanceSystem.new()
	add_child(enhance_system)
	achievement_system = AchievementSystem.new()
	add_child(achievement_system)
	
	# 尝试加载存档
	var save_data := SaveManager.load_game()
	if save_data.is_empty():
		game_data = SaveManager.create_new_save()
	else:
		game_data = save_data
		# 计算离线收益
		var offline := SaveManager.calculate_offline_rewards(game_data)
		if not offline.is_empty():
			_apply_offline_rewards(offline)
	
	player_hp = game_data["combat"]["hp"]
	is_loaded = true
	_spawn_enemy()
	_check_daily_reset()
	game_started.emit()

func _process(delta: float) -> void:
	if not is_loaded:
		return
	# 死亡debuff计时器
	if _death_debuff_active:
		_death_debuff_timer -= delta
		if _death_debuff_timer <= 0.0:
			_death_debuff_active = false
			_death_debuff_timer = 0.0
			toast_message.emit("虚弱状态已解除", Color(0.5, 1.0, 0.5))
	if is_fighting:
		_process_battle(delta)

# ==================== 战斗系统 ====================
func _process_battle(delta: float) -> void:
	if is_boss_fight:
		_process_boss_fight(delta)
		return
	
	# 玩家攻击
	attack_timer += delta
	if attack_timer >= PLAYER_ATTACK_SPEED:
		attack_timer = 0.0
		_player_attack_enemy()
	
	# 敌人攻击
	enemy_attack_timer += delta
	if enemy_attack_timer >= ENEMY_ATTACK_SPEED:
		enemy_attack_timer = 0.0
		_enemy_attack_player()

func _player_attack_enemy() -> void:
	var combat: Dictionary = game_data["combat"]
	var base_dmg: int = combat["atk"]
	# 死亡虚弱debuff减伤
	if _death_debuff_active:
		base_dmg = int(base_dmg * (1.0 - DEATH_DEBUFF_ATK_PENALTY))
	var enemy_def: int = current_enemy.get("def", 0)
	
	# 计算伤害
	var dmg: int = maxi(1, base_dmg - enemy_def / 2)
	
	# 暴击判定
	var is_crit: bool = randf() * 100.0 < float(combat["crit"])
	if is_crit:
		dmg = int(dmg * (1.0 + float(combat["crit_dmg"]) / 100.0))
	
	enemy_hp -= dmg
	
	# 吸血
	if int(combat["lifesteal"]) > 0:
		var heal: int = int(dmg * float(combat["lifesteal"]) / 100.0)
		player_hp = mini(player_hp + heal, int(combat["max_hp"]))
	
	# 发送战斗日志
	var log_color := Color(1.0, 0.8, 0.2) if is_crit else Color(0.8, 0.8, 0.8)
	var crit_text := " [暴击!]" if is_crit else ""
	battle_log.emit("对 %s 造成 %d 伤害%s" % [current_enemy["name"], dmg, crit_text], log_color)
	
	AudioManager.play_sfx("hit" if not is_crit else "crit")
	
	if enemy_hp <= 0:
		_on_enemy_killed()

func _enemy_attack_player() -> void:
	var combat: Dictionary = game_data["combat"]
	var enemy_atk: int = current_enemy.get("atk", 1)
	var dmg: int = maxi(1, enemy_atk - int(combat["def"]) / 2)
	
	# 护盾吸收
	dmg = skill_system.absorb_damage(dmg)
	if dmg <= 0:
		battle_log.emit("🛡 护盾吸收了伤害!", Color(0.3, 0.8, 1.0))
		return
	
	player_hp -= dmg
	AudioManager.play_sfx("enemy_hit")
	battle_log.emit("%s 对你造成 %d 伤害" % [current_enemy["name"], dmg], Color(1.0, 0.3, 0.3))
	
	if player_hp <= 0:
		# 不灭意志检测
		if skill_system.check_immortal():
			player_hp = int(combat["max_hp"] * 0.2)
			battle_log.emit("✨ 不灭意志触发! 免死一次!", Color(1.0, 0.85, 0.0))
			AudioManager.play_sfx("reward")
		else:
			_on_player_died()

func _on_enemy_killed() -> void:
	var rewards := {
		"exp": current_enemy["exp"],
		"gold": current_enemy["gold"],
	}
	
	# 金币加成 (boost + 宠物 + 转生)
	var gold_bonus_pct: float = 0.0
	if game_data["boosts"]["gold"] > 0:
		gold_bonus_pct += 50.0
	gold_bonus_pct += pet_system.get_pet_bonus("gold_bonus_pct")
	gold_bonus_pct += achievement_system.get_rebirth_bonus("gold_bonus_pct")
	if gold_bonus_pct > 0:
		rewards["gold"] = int(rewards["gold"] * (1.0 + gold_bonus_pct / 100.0))
	
	# 经验加成 (boost + 宠物 + 转生)
	var exp_bonus_pct: float = 0.0
	if game_data["boosts"]["exp"] > 0:
		exp_bonus_pct += 50.0
	exp_bonus_pct += pet_system.get_pet_bonus("exp_bonus_pct")
	exp_bonus_pct += achievement_system.get_rebirth_bonus("exp_bonus_pct")
	if exp_bonus_pct > 0:
		rewards["exp"] = int(rewards["exp"] * (1.0 + exp_bonus_pct / 100.0))
	
	# 加经验和金币
	add_exp(rewards["exp"])
	add_gold(rewards["gold"])
	
	# 更新统计
	game_data["stats"]["total_kills"] += 1
	game_data["stats"]["kills_today"] += 1
	
	# 宠物击杀触发
	pet_system.on_enemy_killed()
	
	# 宠物掉落
	var zone_idx: int = game_data["zone"]["current"]
	pet_system.try_drop_pet(zone_idx)
	
	# 材料掉落
	if randf() < MATERIAL_DROP_RATE:
		var zone: Dictionary = DataManager.ZONES[zone_idx]
		var mats: Array = zone["materials"]
		var mat_id: String = mats[randi() % mats.size()]
		game_data["materials"][mat_id] += 1
		rewards["material"] = mat_id
	
	# 装备掉落
	if randf() < DROP_RATE:
		var slot := randi() % 6
		var level: int = game_data["player"]["level"]
		var item := DataManager.generate_item(slot, level, 0)
		_add_to_inventory(item)
		rewards["item"] = item
		game_data["stats"]["total_equips_found"] += 1
		item_obtained.emit(item)
	
	enemy_killed.emit(current_enemy["name"], rewards)
	
	# 成就检查
	achievement_system.check_achievements()
	
	# 生命回复
	var regen: int = game_data["combat"]["hp_regen"]
	if regen > 0:
		player_hp = mini(player_hp + regen, game_data["combat"]["max_hp"])
	
	# 生成下一个敌人
	_spawn_enemy()

func _on_player_died() -> void:
	player_died.emit()
	AudioManager.play_sfx("death")
	# 死亡惩罚: 损失10%金币 + 虚弱状态
	var gold_lost: int = int(game_data["player"]["gold"] * 0.10)
	game_data["player"]["gold"] = maxi(0, game_data["player"]["gold"] - gold_lost)
	game_data["stats"]["total_deaths"] = int(game_data["stats"].get("total_deaths", 0)) + 1
	# 虚弱debuff: 5秒内攻击力-20%
	_death_debuff_timer = 5.0
	_death_debuff_active = true
	# 复活
	player_hp = game_data["combat"]["max_hp"]
	attack_timer = 0.0
	enemy_attack_timer = 0.0
	_spawn_enemy()
	var msg := "你被击败了! 损失💰%s，虚弱5秒" % _fmt_num(gold_lost)
	toast_message.emit(msg, Color(1.0, 0.3, 0.3))

func _spawn_enemy() -> void:
	var zone_idx: int = game_data["zone"]["current"]
	var zone: Dictionary = DataManager.ZONES[zone_idx]
	var enemy_idx: int = randi() % zone["enemies"].size()
	var base_stats: Dictionary = zone["enemy_stats"]
	var player_lv: int = game_data["player"]["level"]
	var scaled := DataManager.scale_enemy(base_stats, player_lv)
	
	current_enemy = {
		"name": zone["enemies"][enemy_idx],
		"hp": scaled["hp"],
		"atk": scaled["atk"],
		"def": scaled["def"],
		"exp": scaled["exp"],
		"gold": scaled["gold"],
	}
	enemy_hp = scaled["hp"]
	enemy_max_hp = scaled["hp"]
	attack_timer = 0.0
	enemy_attack_timer = 0.0

# ==================== Boss战 ====================
func start_boss_fight() -> bool:
	var zone_idx: int = game_data["zone"]["current"]
	var zone: Dictionary = DataManager.ZONES[zone_idx]
	var player_lv: int = game_data["player"]["level"]
	var boss_data := DataManager.scale_boss(zone["boss"], player_lv)
	
	current_boss = boss_data
	enemy_hp = boss_data["hp"]
	enemy_max_hp = boss_data["hp"]
	boss_timer = 0.0
	boss_enrage = false
	is_boss_fight = true
	
	AudioManager.play_sfx("boss")
	battle_log.emit("Boss出现: %s!" % boss_data["name"], Color(1.0, 0.2, 0.2))
	return true

func _process_boss_fight(delta: float) -> void:
	boss_timer += delta
	
	# 狂暴检测
	if not boss_enrage and boss_timer >= current_boss["enrage"]:
		boss_enrage = true
		battle_log.emit("%s 进入狂暴状态!" % current_boss["name"], Color(1.0, 0.0, 0.0))
	
	# 玩家攻击Boss
	attack_timer += delta
	var atk_speed := PLAYER_ATTACK_SPEED * 0.9  # 打Boss稍快
	if attack_timer >= atk_speed:
		attack_timer = 0.0
		_player_attack_boss()
	
	# Boss攻击玩家
	enemy_attack_timer += delta
	var boss_speed := 2.0 if not boss_enrage else 1.0
	if enemy_attack_timer >= boss_speed:
		enemy_attack_timer = 0.0
		_boss_attack_player()

func _player_attack_boss() -> void:
	var combat: Dictionary = game_data["combat"]
	var base_dmg: int = combat["atk"]
	var boss_def: int = current_boss["def"]
	var dmg: int = maxi(1, base_dmg - boss_def / 3)
	
	var is_crit: bool = randf() * 100.0 < float(combat["crit"])
	if is_crit:
		dmg = int(dmg * (1.0 + float(combat["crit_dmg"]) / 100.0))
	
	enemy_hp -= dmg
	
	if int(combat["lifesteal"]) > 0:
		var heal: int = int(dmg * float(combat["lifesteal"]) / 100.0)
		player_hp = mini(player_hp + heal, int(combat["max_hp"]))
	
	AudioManager.play_sfx("hit" if not is_crit else "crit")
	
	if enemy_hp <= 0:
		_on_boss_killed()

func _boss_attack_player() -> void:
	var combat: Dictionary = game_data["combat"]
	var boss_atk: int = current_boss["atk"]
	if boss_enrage:
		boss_atk = int(boss_atk * 1.8)
	var dmg: int = maxi(1, boss_atk - int(combat["def"]) / 2)
	
	# 护盾吸收
	dmg = skill_system.absorb_damage(dmg)
	if dmg <= 0:
		battle_log.emit("🛡 护盾吸收了Boss伤害!", Color(0.3, 0.8, 1.0))
		return
	
	player_hp -= dmg
	AudioManager.play_sfx("enemy_hit")
	
	if player_hp <= 0:
		if skill_system.check_immortal():
			player_hp = int(combat["max_hp"] * 0.2)
			battle_log.emit("✨ 不灭意志触发!", Color(1.0, 0.85, 0.0))
		else:
			_on_boss_fight_lost()

func _on_boss_killed() -> void:
	var zone_idx: int = game_data["zone"]["current"]
	var rewards := {
		"gold": current_boss["hp"] / 10,
		"exp": current_boss["hp"] / 5,
	}
	
	add_exp(rewards["exp"])
	add_gold(rewards["gold"])
	
	# 统计
	game_data["stats"]["boss_kill_count"] += 1
	game_data["stats"]["boss_today"] += 1
	if not zone_idx in game_data["stats"]["bosses_killed"]:
		game_data["stats"]["bosses_killed"].append(zone_idx)
	
	# Boss击败后解锁下一区域
	if zone_idx == game_data["zone"]["unlocked"] and zone_idx < DataManager.ZONES.size() - 1:
		game_data["zone"]["unlocked"] = zone_idx + 1
		toast_message.emit("解锁新区域: %s" % DataManager.ZONES[zone_idx + 1]["name"], Color(1.0, 0.8, 0.0))
	
	# Boss掉落高品质装备
	var slot := randi() % 6
	var level: int = game_data["player"]["level"]
	var item := DataManager.generate_item(slot, level, 2)  # +2品质提升
	_add_to_inventory(item)
	rewards["item"] = item
	item_obtained.emit(item)
	
	# Boss掉落材料
	var zone: Dictionary = DataManager.ZONES[zone_idx]
	for mat_id in zone["materials"]:
		var amount := randi_range(3, 8)
		game_data["materials"][mat_id] += amount
	
	is_boss_fight = false
	boss_killed.emit(current_boss["name"], rewards)
	AudioManager.play_sfx("reward")
	achievement_system.check_achievements()
	_spawn_enemy()

func _on_boss_fight_lost() -> void:
	is_boss_fight = false
	player_hp = game_data["combat"]["max_hp"]
	battle_log.emit("Boss战失败...", Color(1.0, 0.3, 0.3))
	toast_message.emit("Boss击败了你，提升实力再来！", Color(1.0, 0.3, 0.3))
	AudioManager.play_sfx("death")
	_spawn_enemy()

# ==================== 经验与升级 ====================
func add_exp(amount: int) -> void:
	game_data["player"]["exp"] += amount
	var needed := DataManager.exp_for_level(game_data["player"]["level"])
	while game_data["player"]["exp"] >= needed:
		game_data["player"]["exp"] -= needed
		game_data["player"]["level"] += 1
		_on_level_up()
		needed = DataManager.exp_for_level(game_data["player"]["level"])

func _on_level_up() -> void:
	var lv: int = game_data["player"]["level"]
	# 属性成长(优化后: 防御成长提升, 攻击成长加速)
	game_data["combat"]["max_hp"] += 18 + lv * 4
	game_data["combat"]["atk"] += 3 + lv / 4
	game_data["combat"]["def"] += 2 + lv / 5
	game_data["combat"]["hp_regen"] += 1 + lv / 15
	player_hp = game_data["combat"]["max_hp"]
	
	# 每5级获得1天赋点
	if lv % 5 == 0:
		game_data["talent_points"] = int(game_data.get("talent_points", 0)) + 1
		toast_message.emit("获得1天赋点!", Color(0.5, 1.0, 0.5))
	
	player_level_up.emit(lv)
	AudioManager.play_sfx("levelup")
	toast_message.emit("升级! 达到 Lv.%d" % lv, Color(1.0, 0.85, 0.0))
	_recalculate_stats()
	stats_updated.emit()
	
	# 成就检查
	achievement_system.check_achievements()

# ==================== 金币/宝石 ====================
func add_gold(amount: int) -> void:
	game_data["player"]["gold"] += amount
	game_data["stats"]["total_gold_earned"] += amount
	game_data["stats"]["gold_today"] += amount
	gold_changed.emit(amount)

func spend_gold(amount: int) -> bool:
	if game_data["player"]["gold"] >= amount:
		game_data["player"]["gold"] -= amount
		return true
	return false

func add_gems(amount: int) -> void:
	game_data["player"]["gems"] += amount
	gems_changed.emit(amount)

func spend_gems(amount: int) -> bool:
	if game_data["player"]["gems"] >= amount:
		game_data["player"]["gems"] -= amount
		return true
	return false

# ==================== 装备系统 ====================
func _add_to_inventory(item: Dictionary) -> void:
	if game_data["inventory"].size() >= game_data["inventory_max"]:
		# 自动分解最差品质物品
		_auto_salvage_worst()
	game_data["inventory"].append(item)
	
	# 自动装备逻辑
	if game_data["settings"]["auto_equip"]:
		_try_auto_equip(item)

func equip_item(item: Dictionary) -> void:
	var slot_key := str(item["slot"])
	var old_item = game_data["equipment"][slot_key]
	
	# 从背包移除
	for i in range(game_data["inventory"].size()):
		if game_data["inventory"][i]["uid"] == item["uid"]:
			game_data["inventory"].remove_at(i)
			break
	
	# 装备
	game_data["equipment"][slot_key] = item
	
	# 旧装备放回背包
	if old_item != null:
		game_data["inventory"].append(old_item)
	
	_recalculate_stats()

func unequip_item(slot: int) -> void:
	var slot_key := str(slot)
	var item = game_data["equipment"][slot_key]
	if item == null:
		return
	if game_data["inventory"].size() >= game_data["inventory_max"]:
		toast_message.emit("背包已满!", Color(1.0, 0.3, 0.3))
		return
	game_data["inventory"].append(item)
	game_data["equipment"][slot_key] = null
	_recalculate_stats()

func sell_item(item: Dictionary) -> void:
	# 从背包移除
	for i in range(game_data["inventory"].size()):
		if game_data["inventory"][i]["uid"] == item["uid"]:
			game_data["inventory"].remove_at(i)
			break
	# 获得金币 (根据品质)
	var rarity_val: int = int(item["rarity"])
	var level_val: int = int(item["level"])
	var sell_gold: int = (rarity_val + 1) * 50 * level_val
	add_gold(sell_gold)
	toast_message.emit("出售获得 %d 金币" % sell_gold, Color(1.0, 0.85, 0.0))

func _try_auto_equip(item: Dictionary) -> void:
	var slot_key := str(item["slot"])
	var current = game_data["equipment"][slot_key]
	if current == null:
		equip_item(item)
		return
	# 比较品质和战力
	if item["rarity"] > current["rarity"]:
		equip_item(item)
	elif item["rarity"] == current["rarity"] and _item_power(item) > _item_power(current):
		equip_item(item)

func _item_power(item: Dictionary) -> int:
	var power := 0
	for stat in item["stats"]:
		power += item["stats"][stat]
	return power

func _auto_salvage_worst() -> void:
	if game_data["inventory"].is_empty():
		return
	var worst_idx := 0
	var worst_power := _item_power(game_data["inventory"][0])
	for i in range(1, game_data["inventory"].size()):
		var p := _item_power(game_data["inventory"][i])
		if p < worst_power:
			worst_power = p
			worst_idx = i
	var item: Dictionary = game_data["inventory"][worst_idx]
	game_data["inventory"].remove_at(worst_idx)
	add_gold((item["rarity"] + 1) * 20)

func _recalculate_stats() -> void:
	var base_lv: int = game_data["player"]["level"]
	var combat: Dictionary = game_data["combat"]
	
	# 基础属性 (根据等级)
	combat["max_hp"] = 100 + base_lv * 18
	combat["atk"] = 8 + base_lv * 2
	combat["def"] = 3 + base_lv
	combat["crit"] = 5
	combat["crit_dmg"] = 50
	combat["hp_regen"] = 1 + base_lv / 3
	combat["lifesteal"] = 0
	
	# 加上装备基础属性
	for slot_key in game_data["equipment"]:
		var item = game_data["equipment"][slot_key]
		if item == null:
			continue
		var stats: Dictionary = item["stats"]
		for stat_key in stats:
			var stat_int: int = int(stat_key)
			var val: int = stats[stat_key]
			match stat_int:
				DataManager.StatType.ATK:       combat["atk"] += val
				DataManager.StatType.DEF:       combat["def"] += val
				DataManager.StatType.HP:        combat["max_hp"] += val
				DataManager.StatType.CRIT:      combat["crit"] += val
				DataManager.StatType.CRIT_DMG:  combat["crit_dmg"] += val
				DataManager.StatType.HP_REGEN:  combat["hp_regen"] += val
				DataManager.StatType.LIFESTEAL: combat["lifesteal"] += val
		
		# 强化加成
		var enhance_lv: int = int(item.get("enhance_level", 0))
		if enhance_lv > 0:
			var pct: float = float(enhance_lv * EnhanceSystem.ENHANCE_STAT_BONUS_PCT) / 100.0
			for stat_key2 in stats:
				var stat_int2: int = int(stat_key2)
				var bonus: int = int(float(stats[stat_key2]) * pct)
				match stat_int2:
					DataManager.StatType.ATK:       combat["atk"] += bonus
					DataManager.StatType.DEF:       combat["def"] += bonus
					DataManager.StatType.HP:        combat["max_hp"] += bonus
					DataManager.StatType.CRIT:      combat["crit"] += bonus
					DataManager.StatType.CRIT_DMG:  combat["crit_dmg"] += bonus
					DataManager.StatType.HP_REGEN:  combat["hp_regen"] += bonus
					DataManager.StatType.LIFESTEAL: combat["lifesteal"] += bonus
		
		# 附魔加成
		var enchant: String = item.get("enchant", "")
		if not enchant.is_empty() and EnhanceSystem.ENCHANTS.has(enchant):
			var ench_data: Dictionary = EnhanceSystem.ENCHANTS[enchant]
			var ench_stat: String = ench_data["stat"]
			var ench_val: int = int(ench_data["value"])
			if ench_stat == "atk_pct":
				combat["atk"] = int(combat["atk"] * (1.0 + float(ench_val) / 100.0))
			elif ench_stat == "def_pct":
				combat["def"] = int(combat["def"] * (1.0 + float(ench_val) / 100.0))
			elif ench_stat == "hp_pct":
				combat["max_hp"] = int(combat["max_hp"] * (1.0 + float(ench_val) / 100.0))
			elif ench_stat == "hp_regen_pct":
				combat["hp_regen"] = int(combat["hp_regen"] * (1.0 + float(ench_val) / 100.0))
			elif combat.has(ench_stat):
				combat[ench_stat] += ench_val
			# 双属性附魔
			if ench_data.has("stat2"):
				var s2: String = ench_data["stat2"]
				var v2: int = int(ench_data["value2"])
				if combat.has(s2):
					combat[s2] += v2
	
	# 天赋加成
	var talent_atk: float = skill_system.get_talent_value("atk_pct")
	var talent_def: float = skill_system.get_talent_value("def_pct")
	var talent_hp: float = skill_system.get_talent_value("hp_pct")
	var talent_crit: float = skill_system.get_talent_value("crit")
	var talent_cd: float = skill_system.get_talent_value("crit_dmg")
	var talent_regen: float = skill_system.get_talent_value("hp_regen")
	var talent_ls: float = skill_system.get_talent_value("lifesteal")
	
	combat["atk"] = int(combat["atk"] * (1.0 + talent_atk / 100.0))
	combat["def"] = int(combat["def"] * (1.0 + talent_def / 100.0))
	combat["max_hp"] = int(combat["max_hp"] * (1.0 + talent_hp / 100.0))
	combat["crit"] += int(talent_crit)
	combat["crit_dmg"] += int(talent_cd)
	combat["hp_regen"] += int(talent_regen)
	combat["lifesteal"] += int(talent_ls)
	
	# 宠物加成
	combat["atk"] += int(pet_system.get_pet_bonus("atk"))
	combat["atk"] = int(combat["atk"] * (1.0 + pet_system.get_pet_bonus("atk_pct") / 100.0))
	combat["crit"] += int(pet_system.get_pet_bonus("crit"))
	combat["max_hp"] = int(combat["max_hp"] * (1.0 + pet_system.get_pet_bonus("hp_pct") / 100.0))
	combat["def"] += int(pet_system.get_pet_bonus("def"))
	
	# 转生永久加成
	var rb_atk: float = achievement_system.get_rebirth_bonus("atk_pct")
	var rb_def: float = achievement_system.get_rebirth_bonus("def_pct")
	var rb_hp: float = achievement_system.get_rebirth_bonus("hp_pct")
	var rb_crit: float = achievement_system.get_rebirth_bonus("crit")
	combat["atk"] = int(combat["atk"] * (1.0 + rb_atk / 100.0))
	combat["def"] = int(combat["def"] * (1.0 + rb_def / 100.0))
	combat["max_hp"] = int(combat["max_hp"] * (1.0 + rb_hp / 100.0))
	combat["crit"] += int(rb_crit)
	
	# 称号加成
	var title_atk: float = achievement_system.get_title_bonus("atk_pct")
	var title_hp: float = achievement_system.get_title_bonus("hp_pct")
	var title_crit: float = achievement_system.get_title_bonus("crit")
	var title_cd2: float = achievement_system.get_title_bonus("crit_dmg")
	combat["atk"] = int(combat["atk"] * (1.0 + title_atk / 100.0))
	combat["max_hp"] = int(combat["max_hp"] * (1.0 + title_hp / 100.0))
	combat["crit"] += int(title_crit)
	combat["crit_dmg"] += int(title_cd2)
	
	combat["hp"] = mini(player_hp, combat["max_hp"])
	stats_updated.emit()

# ==================== 区域切换 ====================
func change_zone(zone_idx: int) -> bool:
	if zone_idx < 0 or zone_idx > game_data["zone"]["unlocked"]:
		return false
	game_data["zone"]["current"] = zone_idx
	_spawn_enemy()
	zone_changed.emit(zone_idx)
	return true

# ==================== 每日重置 ====================
func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if game_data["daily"]["tasks_date"] != today:
		# 重置每日数据
		game_data["stats"]["gold_today"] = 0
		game_data["stats"]["kills_today"] = 0
		game_data["stats"]["crafts_today"] = 0
		game_data["stats"]["boss_today"] = 0
		game_data["daily"]["tasks_date"] = today
		game_data["daily"]["today_claimed"] = false
		_generate_daily_tasks()
		
		# 减少增益次数
		if game_data["boosts"]["exp"] > 0:
			game_data["boosts"]["exp"] -= 1
		if game_data["boosts"]["gold"] > 0:
			game_data["boosts"]["gold"] -= 1

func _generate_daily_tasks() -> void:
	var tasks := []
	var templates: Array = DataManager.DAILY_TEMPLATES.duplicate()
	templates.shuffle()
	for i in range(mini(3, templates.size())):
		var tmpl: Dictionary = templates[i]
		var targets: Array = tmpl["targets"]
		var target: int = targets[randi() % targets.size()]
		tasks.append({
			"id": tmpl["id"],
			"name": tmpl["name"],
			"desc": tmpl["desc"].replace("{t}", str(target)),
			"type": tmpl["type"],
			"target": target,
			"progress": 0,
			"completed": false,
			"claimed": false,
			"reward": tmpl["reward"].duplicate(),
		})
	game_data["daily"]["tasks"] = tasks

# ==================== 离线收益应用 ====================
func _apply_offline_rewards(rewards: Dictionary) -> void:
	add_exp(rewards["exp"])
	add_gold(rewards["gold"])
	game_data["stats"]["total_kills"] += rewards["kills"]
	for mat_id in rewards["materials"]:
		game_data["materials"][mat_id] += rewards["materials"][mat_id]
	
	# 延迟发送信号（等UI就绪）
	call_deferred("_emit_offline_rewards", rewards)

func _emit_offline_rewards(rewards: Dictionary) -> void:
	show_offline_rewards.emit(rewards)

func _fmt_num(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
