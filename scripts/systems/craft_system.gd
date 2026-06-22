extends Node
class_name CraftSystem
## 暗影深渊 - 锻造系统

signal craft_success(item: Dictionary)
signal craft_failed(reason: String)

## 检查是否可以锻造
func can_craft(recipe: Dictionary) -> Dictionary:
	var data: Dictionary = GameManager.game_data
	
	# 检查等级
	if data["player"]["level"] < recipe["min_lv"]:
		return { "ok": false, "reason": "等级不足 (需要Lv.%d)" % recipe["min_lv"] }
	
	# 检查金币
	if data["player"]["gold"] < recipe["gold"]:
		return { "ok": false, "reason": "金币不足 (需要%d)" % recipe["gold"] }
	
	# 检查材料
	var mats: Dictionary = recipe["materials"]
	for mat_id in mats:
		var needed: int = mats[mat_id]
		var have: int = data["materials"].get(mat_id, 0)
		if have < needed:
			var mat_name: String = DataManager.MATERIALS[mat_id]["name"]
			return { "ok": false, "reason": "%s不足 (需要%d, 拥有%d)" % [mat_name, needed, have] }
	
	# 检查背包空间
	if data["inventory"].size() >= data["inventory_max"]:
		return { "ok": false, "reason": "背包已满" }
	
	return { "ok": true, "reason": "" }

## 执行锻造
func do_craft(recipe: Dictionary) -> Dictionary:
	var check := can_craft(recipe)
	if not check["ok"]:
		craft_failed.emit(check["reason"])
		AudioManager.play_sfx("error")
		return {}
	
	var data: Dictionary = GameManager.game_data
	
	# 扣除金币
	data["player"]["gold"] -= recipe["gold"]
	
	# 扣除材料
	var mats: Dictionary = recipe["materials"]
	for mat_id in mats:
		data["materials"][mat_id] -= mats[mat_id]
	
	# 确定装备槽位
	var slot: int = recipe["slot"]
	if slot == -1:  # 随机槽位
		slot = randi() % 6
	
	# 生成装备
	var level: int = data["player"]["level"]
	var item := DataManager.generate_item(slot, level, recipe["rarity_boost"])
	
	# 添加到背包
	data["inventory"].append(item)
	
	# 更新统计
	data["stats"]["total_crafts"] += 1
	data["stats"]["crafts_today"] += 1
	
	AudioManager.play_sfx("craft")
	craft_success.emit(item)
	GameManager.item_obtained.emit(item)
	GameManager.toast_message.emit("锻造成功: %s" % item["name"], DataManager.RARITY_INFO[item["rarity"] as DataManager.Rarity]["color"])
	
	return item
