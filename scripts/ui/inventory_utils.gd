extends RefCounted
class_name InventoryUtils
## 背包与装备工具 — 排序、战力对比、筛选

enum SortMode { POWER_DESC, RARITY_DESC, LEVEL_DESC, SLOT_ASC }

const STAT_DISPLAY_ORDER: Array = [
	DataManager.StatType.ATK,
	DataManager.StatType.DEF,
	DataManager.StatType.HP,
	DataManager.StatType.CRIT,
	DataManager.StatType.CRIT_DMG,
	DataManager.StatType.HP_REGEN,
	DataManager.StatType.LIFESTEAL,
]

static func sell_price(item: Dictionary) -> int:
	item = DataManager.normalize_item(item)
	if item.is_empty():
		return 0
	var rarity_val: int = int(item.get("rarity", 0))
	var level_val: int = int(item.get("level", 1))
	var enh: int = int(item.get("enhance_level", 0))
	return (rarity_val + 1) * 50 * level_val + enh * 80

static func bag_fill_ratio(inventory: Array, max_size: int) -> float:
	if max_size <= 0:
		return 0.0
	return clampf(float(inventory.size()) / float(max_size), 0.0, 1.0)

static func filter_upgrades_only(inventory: Array, equipment: Dictionary) -> Array:
	var result: Array = []
	for it in inventory:
		if is_upgrade(it, equipment):
			result.append(it)
	return result

static func find_best_per_slot(inventory: Array) -> Dictionary:
	## slot_key -> best item in bag
	var best: Dictionary = {}
	for it in inventory:
		var norm := DataManager.normalize_item(it)
		if norm.is_empty():
			continue
		var sk := DataManager.item_slot_key(norm)
		if not best.has(sk) or item_power(norm) > item_power(best[sk]):
			best[sk] = norm
	return best

static func collect_equip_upgrades(inventory: Array, equipment: Dictionary) -> Array:
	## 每个部位最值得换上的背包装备（战力严格提升）
	var result: Array = []
	var best_per_slot := find_best_per_slot(inventory)
	for sk in best_per_slot:
		var candidate: Dictionary = best_per_slot[sk]
		var delta: int = power_delta_vs_equipped(candidate, equipment)
		if delta > 0:
			result.append(candidate)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return power_delta_vs_equipped(b, equipment) < power_delta_vs_equipped(a, equipment))
	return result

static func collect_junk_items(inventory: Array, equipment: Dictionary) -> Array:
	## 同部位已有更好装备（身上或背包最佳）时可出售的杂项
	var junk: Array = []
	var best_per_slot := find_best_per_slot(inventory)
	for it in inventory:
		var norm := DataManager.normalize_item(it)
		if norm.is_empty():
			continue
		var sk := DataManager.item_slot_key(norm)
		var equipped = equipment.get(sk)
		if equipped == null:
			continue
		var eq_power: int = item_power(DataManager.normalize_item(equipped))
		var my_power: int = item_power(norm)
		if my_power >= eq_power:
			continue
		if best_per_slot.has(sk) and str(best_per_slot[sk].get("uid", "")) == str(norm.get("uid", "")):
			continue
		junk.append(norm)
	return junk

static func total_junk_gold(inventory: Array, equipment: Dictionary) -> int:
	var total := 0
	for it in collect_junk_items(inventory, equipment):
		total += sell_price(it)
	return total

static func rarity_short(item: Dictionary) -> String:
	var r: int = int(item.get("rarity", 0))
	return DataManager.RARITY_INFO[r as DataManager.Rarity].get("name", "")

static func best_bag_item_for_slot(inventory: Array, slot_i: int) -> Dictionary:
	var best: Dictionary = {}
	var best_p := -1
	for it in inventory:
		var norm := DataManager.normalize_item(it)
		if norm.is_empty() or int(norm.get("slot", -1)) != slot_i:
			continue
		var p: int = item_power(norm)
		if p > best_p:
			best_p = p
			best = norm
	return best

static func slot_upgrade_delta(inventory: Array, equipment: Dictionary, slot_i: int) -> int:
	var best: Dictionary = best_bag_item_for_slot(inventory, slot_i)
	if best.is_empty():
		return 0
	return power_delta_vs_equipped(best, equipment)

static func slots_with_upgrades(inventory: Array, equipment: Dictionary) -> Array:
	var slots: Array = []
	for si in range(6):
		if slot_upgrade_delta(inventory, equipment, si) > 0:
			slots.append(si)
	return slots

static func format_stat_summary(item: Dictionary, max_stats: int = 3) -> String:
	item = DataManager.normalize_item(item)
	var parts: PackedStringArray = []
	var count := 0
	for stat_i in STAT_DISPLAY_ORDER:
		if count >= max_stats:
			break
		var val: int = DataManager.get_item_stat(item.get("stats", {}), stat_i)
		if val <= 0:
			continue
		var info: Dictionary = DataManager.STAT_INFO.get(stat_i, {})
		var suffix := "%" if stat_i in [DataManager.StatType.CRIT, DataManager.StatType.CRIT_DMG, DataManager.StatType.LIFESTEAL] else ""
		parts.append("%s%d%s" % [info.get("short", ""), val, suffix])
		count += 1
	return " · ".join(parts) if not parts.is_empty() else "无属性"

static func recommend_action(delta: int) -> String:
	if delta > 0:
		return "推荐替换"
	if delta < 0:
		return "战力降低"
	return "战力持平"

static func format_item_subtitle(item: Dictionary) -> String:
	item = DataManager.normalize_item(item)
	var parts: PackedStringArray = []
	parts.append(rarity_short(item))
	parts.append("Lv.%d" % int(item.get("level", 1)))
	var enh: int = int(item.get("enhance_level", 0))
	if enh > 0:
		parts.append("+%d" % enh)
	return " · ".join(parts)

static func sorted_stat_lines(item: Dictionary, compare: Dictionary = {}) -> PackedStringArray:
	item = DataManager.normalize_item(item)
	compare = DataManager.normalize_item(compare)
	var lines: PackedStringArray = []
	for stat_i in STAT_DISPLAY_ORDER:
		var val: int = DataManager.get_item_stat(item.get("stats", {}), stat_i)
		var old_v: int = DataManager.get_item_stat(compare.get("stats", {}), stat_i) if not compare.is_empty() else 0
		if val <= 0 and old_v <= 0:
			continue
		var info: Dictionary = DataManager.STAT_INFO.get(stat_i, {})
		var suffix := "%" if stat_i in [DataManager.StatType.CRIT, DataManager.StatType.CRIT_DMG, DataManager.StatType.LIFESTEAL] else ""
		var extra := ""
		if not compare.is_empty():
			var delta: int = val - old_v
			if delta > 0:
				extra = " [color=#7dcea0](+%d%s)[/color]" % [delta, suffix]
			elif delta < 0:
				extra = " [color=#e57373](%d%s)[/color]" % [delta, suffix]
		lines.append("%s %s: [color=#c8e6c9]+%d%s[/color]%s" % [info.get("icon", ""), info.get("short", ""), val, suffix, extra])
	return lines

static func sort_inventory(items: Array, mode: SortMode = SortMode.POWER_DESC) -> Array:
	var sorted: Array = items.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _compare_items(a, b, mode))
	return sorted

static func _compare_items(a: Dictionary, b: Dictionary, mode: SortMode) -> bool:
	var na := DataManager.normalize_item(a)
	var nb := DataManager.normalize_item(b)
	match mode:
		SortMode.RARITY_DESC:
			var ra: int = int(na.get("rarity", 0))
			var rb: int = int(nb.get("rarity", 0))
			if ra != rb:
				return ra > rb
		SortMode.LEVEL_DESC:
			var la: int = int(na.get("level", 1))
			var lb: int = int(nb.get("level", 1))
			if la != lb:
				return la > lb
		SortMode.SLOT_ASC:
			var sa: int = int(na.get("slot", 0))
			var sb: int = int(nb.get("slot", 0))
			if sa != sb:
				return sa < sb
	var pa: int = item_power(na)
	var pb: int = item_power(nb)
	if pa != pb:
		return pa > pb
	return str(na.get("uid", "")) < str(nb.get("uid", ""))

static func item_power(item: Dictionary) -> int:
	return DataManager.item_power(DataManager.normalize_item(item))

static func power_delta_vs_equipped(item: Dictionary, equipment: Dictionary) -> int:
	item = DataManager.normalize_item(item)
	if item.is_empty():
		return 0
	var slot_key := DataManager.item_slot_key(item)
	var current = equipment.get(slot_key)
	var new_p: int = item_power(item)
	if current == null:
		return new_p
	return new_p - item_power(DataManager.normalize_item(current))

static func is_upgrade(item: Dictionary, equipment: Dictionary) -> bool:
	return power_delta_vs_equipped(item, equipment) > 0

static func count_upgrades(inventory: Array, equipment: Dictionary) -> int:
	var n := 0
	for it in inventory:
		if is_upgrade(it, equipment):
			n += 1
	return n

static func total_equipped_power(equipment: Dictionary) -> int:
	var total := 0
	for sk in equipment:
		var it = equipment[sk]
		if it != null:
			total += item_power(DataManager.normalize_item(it))
	return total

static func format_power_delta(delta: int) -> String:
	if delta > 0:
		return "+%d" % delta
	if delta < 0:
		return "%d" % delta
	return "0"

static func sort_mode_label(mode: SortMode) -> String:
	match mode:
		SortMode.POWER_DESC: return "战力↓"
		SortMode.RARITY_DESC: return "品质↓"
		SortMode.LEVEL_DESC: return "等级↓"
		SortMode.SLOT_ASC: return "部位"
	return "排序"

enum BagCategory { ALL, EQUIP, MATERIAL }

static func bag_category_label(cat: BagCategory) -> String:
	match cat:
		BagCategory.ALL: return "全部"
		BagCategory.EQUIP: return "装备"
		BagCategory.MATERIAL: return "材料"
	return "全部"

static func material_icon(mat_id: String) -> String:
	match mat_id:
		"shadow_essence": return "◆"
		"bone_fragment": return "▣"
		"demon_blood": return "🩸"
		"soul_shard": return "✧"
		"abyss_crystal": return "◇"
		"cursed_iron": return "■"
		"dragon_scale": return "⬡"
		"void_dust": return "◎"
		_: return "●"

static func collect_material_entries(materials: Dictionary) -> Array:
	var entries: Array = []
	for mat_id in materials:
		var amount: int = int(materials[mat_id])
		if amount <= 0:
			continue
		if not DataManager.MATERIALS.has(mat_id):
			continue
		var info: Dictionary = DataManager.MATERIALS[mat_id]
		entries.append({
			"id": mat_id,
			"name": info["name"],
			"count": amount,
			"color": info["color"],
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["count"]) != int(b["count"]):
			return int(a["count"]) > int(b["count"])
		return str(a["name"]) < str(b["name"]))
	return entries

static func material_type_count(materials: Dictionary) -> int:
	return collect_material_entries(materials).size()
