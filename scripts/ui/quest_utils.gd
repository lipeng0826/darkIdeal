extends RefCounted
class_name QuestUtils
## 任务页工具 — 章节、图标、奖励格式化

enum QuestStatus { CLAIMED, CLAIMABLE, IN_PROGRESS, FOCUS }

const CHAPTERS: Array = [
	{
		"name": "第一章 · 初入深渊",
		"subtitle": "熟悉战斗，踏上旅程",
		"color": Color(0.45, 0.72, 0.55),
	},
	{
		"name": "第二章 · 锋芒渐露",
		"subtitle": "锻造装备，挑战强敌",
		"color": Color(0.40, 0.65, 0.95),
	},
	{
		"name": "第三章 · 深渊征途",
		"subtitle": "屠戮群敌，积累财富",
		"color": Color(0.72, 0.40, 0.92),
	},
	{
		"name": "第四章 · 终焉传说",
		"subtitle": "征服深渊，成就传说",
		"color": Color(0.95, 0.70, 0.25),
	},
]

const TYPE_META: Dictionary = {
	"kill": {"icon": "⚔", "label": "击杀"},
	"level": {"icon": "⬆", "label": "等级"},
	"equip_get": {"icon": "🎒", "label": "收集"},
	"craft": {"icon": "🔨", "label": "锻造"},
	"equip_all": {"icon": "🛡", "label": "装备"},
	"boss": {"icon": "👹", "label": "Boss"},
	"gold_total": {"icon": "💰", "label": "财富"},
}

static func chapter_index(quest_index: int) -> int:
	return clampi(quest_index / 5, 0, CHAPTERS.size() - 1)

static func chapter_info(quest_index: int) -> Dictionary:
	return CHAPTERS[chapter_index(quest_index)]

static func chapter_range(chapter_i: int) -> Vector2i:
	var start := chapter_i * 5
	var end_i: int = mini(start + 5, DataManager.QUESTS.size())
	return Vector2i(start, end_i)

static func type_icon(quest_type: String) -> String:
	return TYPE_META.get(quest_type, {}).get("icon", "📜")

static func type_label(quest_type: String) -> String:
	return TYPE_META.get(quest_type, {}).get("label", "任务")

static func progress_ratio(progress: int, target: int) -> float:
	if target <= 0:
		return 1.0
	return clampf(float(progress) / float(target), 0.0, 1.0)

static func format_rewards(reward: Dictionary) -> PackedStringArray:
	var parts: PackedStringArray = []
	if reward.has("gold"):
		parts.append("💰 %s" % _fmt_num(int(reward["gold"])))
	if reward.has("exp"):
		parts.append("✨ %s" % _fmt_num(int(reward["exp"])))
	if reward.has("gems"):
		parts.append("💎 %d" % int(reward["gems"]))
	return parts

static func resolve_status(claimed: bool, done: bool, is_focus: bool) -> QuestStatus:
	if claimed:
		return QuestStatus.CLAIMED
	if done:
		return QuestStatus.CLAIMABLE
	if is_focus:
		return QuestStatus.FOCUS
	return QuestStatus.IN_PROGRESS

static func status_text(status: QuestStatus) -> String:
	match status:
		QuestStatus.CLAIMED: return "已完成"
		QuestStatus.CLAIMABLE: return "可领取"
		QuestStatus.FOCUS: return "进行中"
		QuestStatus.IN_PROGRESS: return "未完成"
	return ""

static func status_color(status: QuestStatus) -> Color:
	match status:
		QuestStatus.CLAIMED: return ThemeConfig.ACCENT_GREEN
		QuestStatus.CLAIMABLE: return ThemeConfig.ACCENT_GOLD
		QuestStatus.FOCUS: return ThemeConfig.SECONDARY_LIGHT
		QuestStatus.IN_PROGRESS: return ThemeConfig.TXT_DISABLED
	return ThemeConfig.TXT_SECONDARY

static func card_accent(status: QuestStatus) -> Color:
	match status:
		QuestStatus.CLAIMED: return ThemeConfig.ACCENT_GREEN
		QuestStatus.CLAIMABLE: return ThemeConfig.ACCENT_GOLD
		QuestStatus.FOCUS: return ThemeConfig.SECONDARY
		QuestStatus.IN_PROGRESS: return ThemeConfig.TXT_DISABLED
	return ThemeConfig.TXT_DISABLED

static func _fmt_num(n: int) -> String:
	if n >= 10000:
		return "%.1f万" % (float(n) / 10000.0)
	if n >= 1000:
		return "%d" % n
	return str(n)
