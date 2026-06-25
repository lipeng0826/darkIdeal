extends Node
class_name QuestSystem
## 暗影深渊 - 任务系统 (主线任务 + 每日任务 + 商店)

signal quest_completed(quest_id: String)
signal daily_completed(task_id: String)
signal login_reward_claimed(day: int)

## 检查任务进度
func get_quest_progress(quest: Dictionary) -> int:
	var data: Dictionary = GameManager.game_data
	var stats: Dictionary = data["stats"]
	match quest["type"]:
		"kill":
			return stats["total_kills"]
		"level":
			return data["player"]["level"]
		"equip_get":
			return stats["total_equips_found"]
		"craft":
			return stats["total_crafts"]
		"equip_all":
			var count := 0
			for slot_key in data["equipment"]:
				if data["equipment"][slot_key] != null:
					count += 1
			return count
		"boss":
			return stats["boss_kill_count"]
		"gold_total":
			return stats["total_gold_earned"]
	return 0

## 检查是否可以领取任务奖励
func can_claim_quest(quest: Dictionary) -> bool:
	var data: Dictionary = GameManager.game_data
	if quest["id"] in data["quests"]["claimed"]:
		return false
	return get_quest_progress(quest) >= quest["target"]

## 领取任务奖励
func claim_quest(quest: Dictionary, silent: bool = false) -> bool:
	if not can_claim_quest(quest):
		return false
	var data: Dictionary = GameManager.game_data
	var reward: Dictionary = quest["reward"]
	
	if reward.has("gold"):
		GameManager.add_gold(reward["gold"])
	if reward.has("exp"):
		GameManager.add_exp(reward["exp"])
	if reward.has("gems"):
		GameManager.add_gems(reward["gems"])
	
	data["quests"]["claimed"].append(quest["id"])
	if not quest["id"] in data["quests"]["completed"]:
		data["quests"]["completed"].append(quest["id"])
	
	AudioManager.play_sfx("reward")
	quest_completed.emit(quest["id"])
	if not silent:
		GameManager.toast_message.emit("任务完成: %s" % quest["name"], Color(1.0, 0.85, 0.0))
	return true

func get_active_quest() -> Dictionary:
	var data: Dictionary = GameManager.game_data
	var claimed: Array = data["quests"]["claimed"]
	for q in DataManager.QUESTS:
		if q["id"] not in claimed:
			return q
	return {}

func get_quest_summary() -> Dictionary:
	var data: Dictionary = GameManager.game_data
	var claimed: Array = data["quests"]["claimed"]
	var claimable: Array = []
	var active: Dictionary = {}
	for q in DataManager.QUESTS:
		if q["id"] in claimed:
			continue
		if can_claim_quest(q):
			claimable.append(q)
		elif active.is_empty():
			active = q
	return {
		"total": DataManager.QUESTS.size(),
		"claimed_count": claimed.size(),
		"claimable_count": claimable.size(),
		"claimable": claimable,
		"active": active,
	}

func claim_all_quests() -> int:
	var summary: Dictionary = get_quest_summary()
	var count := 0
	for q in summary["claimable"]:
		if claim_quest(q, true):
			count += 1
	if count > 1:
		GameManager.toast_message.emit("已领取 %d 个任务奖励" % count, Color(1.0, 0.85, 0.0))
	return count

func quest_index_of(quest_id: String) -> int:
	for i in range(DataManager.QUESTS.size()):
		if DataManager.QUESTS[i]["id"] == quest_id:
			return i
	return -1

func is_focus_quest(quest: Dictionary) -> bool:
	var active: Dictionary = get_active_quest()
	return not active.is_empty() and active.get("id", "") == quest.get("id", "")

## ==================== 每日任务 ====================

## 获取每日任务进度
func get_daily_progress(task: Dictionary) -> int:
	var data: Dictionary = GameManager.game_data
	var stats: Dictionary = data["stats"]
	match task["type"]:
		"kill":
			return stats["kills_today"]
		"gold_day":
			return stats["gold_today"]
		"craft_day":
			return stats["crafts_today"]
		"boss_day":
			return stats["boss_today"]
		"zone_kill":
			return stats.get("zone_kills_today", 0)
	return 0

## 领取每日任务奖励
func claim_daily_task(task_index: int) -> bool:
	var data: Dictionary = GameManager.game_data
	var tasks: Array = data["daily"]["tasks"]
	if task_index < 0 or task_index >= tasks.size():
		return false
	
	var task: Dictionary = tasks[task_index]
	if task["claimed"]:
		return false
	
	var progress := get_daily_progress(task)
	if progress < task["target"]:
		return false
	
	task["claimed"] = true
	task["completed"] = true
	
	var reward: Dictionary = task["reward"]
	if reward.has("gold"):
		GameManager.add_gold(reward["gold"])
	if reward.has("gems"):
		GameManager.add_gems(reward["gems"])
	
	AudioManager.play_sfx("reward")
	daily_completed.emit(task["id"])
	GameManager.toast_message.emit("每日任务完成!", Color(0.3, 1.0, 0.5))
	return true

## ==================== 签到系统 ====================

## 领取签到奖励
func claim_login_reward() -> bool:
	var data: Dictionary = GameManager.game_data
	var daily: Dictionary = data["daily"]
	var today := Time.get_date_string_from_system()
	
	if daily["today_claimed"]:
		return false
	
	# 更新连续登录
	if daily["last_login_date"] != today:
		if _is_consecutive_day(daily["last_login_date"], today):
			daily["login_streak"] += 1
		else:
			daily["login_streak"] = 1
		daily["last_login_date"] = today
	
	daily["today_claimed"] = true
	
	# 获取奖励（7天循环）
	var day_index: int = (int(daily["login_streak"]) - 1) % 7
	var reward_data: Dictionary = DataManager.DAILY_LOGIN_REWARDS[day_index]
	var reward: Dictionary = reward_data["reward"]
	
	if reward.has("gold"):
		GameManager.add_gold(reward["gold"])
	if reward.has("gems"):
		GameManager.add_gems(reward["gems"])
	
	AudioManager.play_sfx("reward")
	login_reward_claimed.emit(daily["login_streak"])
	GameManager.toast_message.emit("签到第%d天! " % daily["login_streak"], Color(1.0, 0.85, 0.0))
	return true

func _is_consecutive_day(last_date: String, today: String) -> bool:
	if last_date.is_empty():
		return false
	# 简单判断：解析日期比较
	var last_dict := Time.get_datetime_dict_from_datetime_string(last_date + "T00:00:00", false)
	var today_dict := Time.get_datetime_dict_from_datetime_string(today + "T00:00:00", false)
	var last_unix := Time.get_unix_time_from_datetime_dict(last_dict)
	var today_unix := Time.get_unix_time_from_datetime_dict(today_dict)
	var diff := today_unix - last_unix
	return diff >= 86400 and diff < 172800

## ==================== 商店系统 ====================

## 购买商品
func buy_shop_item(shop_item: Dictionary) -> bool:
	if not shop_item.has("cost") or not shop_item.has("currency") or not shop_item.has("type"):
		GameManager.toast_message.emit("商品数据异常!", Color(1.0, 0.3, 0.3))
		return false
	var data: Dictionary = GameManager.game_data
	var cost: int = shop_item["cost"]
	var currency: String = shop_item["currency"]
	
	# 扣费
	if currency == "gold":
		if not GameManager.spend_gold(cost):
			GameManager.toast_message.emit("金币不足!", Color(1.0, 0.3, 0.3))
			AudioManager.play_sfx("error")
			return false
	elif currency == "gems":
		if not GameManager.spend_gems(cost):
			GameManager.toast_message.emit("宝石不足!", Color(1.0, 0.3, 0.3))
			AudioManager.play_sfx("error")
			return false
	
	# 给予物品
	match shop_item["type"]:
		"material":
			data["materials"][shop_item["mat_id"]] += shop_item["amount"]
			var mat_name: String = DataManager.MATERIALS[shop_item["mat_id"]]["name"]
			GameManager.toast_message.emit("获得 %s ×%d" % [mat_name, shop_item["amount"]], Color(0.5, 0.8, 1.0))
		"boost":
			data["boosts"][shop_item["effect"]] += shop_item["amount"]
			GameManager.toast_message.emit("获得增益: %s" % shop_item["name"], Color(0.3, 1.0, 0.5))
		"ticket":
			data["boosts"]["boss_tickets"] += shop_item["amount"]
			GameManager.toast_message.emit("获得Boss挑战券!", Color(1.0, 0.5, 0.0))
		"box":
			# 神秘宝箱: 随机高品质装备
			var slot := randi() % 6
			var level: int = data["player"]["level"]
			var item := DataManager.generate_item(slot, level, 3)
			data["inventory"].append(item)
			GameManager.item_obtained.emit(item)
			GameManager.toast_message.emit("打开宝箱: %s!" % item["name"], Color(1.0, 0.8, 0.0))
	
	AudioManager.play_sfx("pickup")
	return true
