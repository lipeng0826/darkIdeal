extends Node
## 暗影深渊 - 数据管理器 (Autoload单例)
## 存储所有游戏配置数据：品质、装备、区域、敌人、Boss、配方、任务、每日、商店

# ==================== 信号 ====================
signal data_ready

# ==================== 品质系统 ====================
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

const RARITY_INFO := {
	Rarity.COMMON:    { "name": "普通", "color": Color(0.62, 0.62, 0.62), "mult": 1.0,  "extra": 0, "glow": 0.0 },
	Rarity.UNCOMMON:  { "name": "精良", "color": Color(0.18, 1.0, 0.35),  "mult": 1.35, "extra": 1, "glow": 0.1 },
	Rarity.RARE:      { "name": "稀有", "color": Color(0.23, 0.56, 1.0),  "mult": 1.8,  "extra": 2, "glow": 0.2 },
	Rarity.EPIC:      { "name": "史诗", "color": Color(0.70, 0.28, 1.0),  "mult": 2.4,  "extra": 3, "glow": 0.3 },
	Rarity.LEGENDARY: { "name": "传说", "color": Color(1.0, 0.61, 0.18),  "mult": 3.2,  "extra": 4, "glow": 0.5 },
	Rarity.MYTHIC:    { "name": "神话", "color": Color(1.0, 0.18, 0.30),  "mult": 4.5,  "extra": 5, "glow": 0.7 },
}

# 每个区域的品质掉落权重
const RARITY_WEIGHTS := [
	[60.0, 28.0, 9.0, 2.5, 0.4, 0.1],   # zone 0
	[45.0, 32.0, 16.0, 5.5, 1.2, 0.3],   # zone 1
	[32.0, 34.0, 22.0, 9.0, 2.5, 0.5],   # zone 2
	[22.0, 32.0, 28.0, 13.0, 3.8, 1.2],  # zone 3
	[15.0, 28.0, 30.0, 18.0, 6.5, 2.5],  # zone 4
	[10.0, 22.0, 30.0, 23.0, 10.0, 5.0], # zone 5
	[6.0, 16.0, 28.0, 27.0, 15.0, 8.0],  # zone 6
	[3.0, 10.0, 24.0, 30.0, 21.0, 12.0], # zone 7
	[1.0, 6.0, 18.0, 30.0, 27.0, 18.0],  # zone 8
	[0.0, 3.0, 12.0, 27.0, 33.0, 25.0],  # zone 9
]

# ==================== 属性定义 ====================
enum StatType { ATK, DEF, HP, CRIT, CRIT_DMG, HP_REGEN, LIFESTEAL }

const STAT_INFO := {
	StatType.ATK:       { "name": "攻击力",   "short": "ATK", "icon": "⚔" },
	StatType.DEF:       { "name": "防御力",   "short": "DEF", "icon": "🛡" },
	StatType.HP:        { "name": "生命值",   "short": "HP",  "icon": "❤" },
	StatType.CRIT:      { "name": "暴击率",   "short": "CR",  "icon": "✦" },
	StatType.CRIT_DMG:  { "name": "暴击伤害", "short": "CD",  "icon": "☠" },
	StatType.HP_REGEN:  { "name": "生命回复", "short": "REG", "icon": "✚" },
	StatType.LIFESTEAL: { "name": "吸血",     "short": "LS",  "icon": "🩸" },
}

# ==================== 装备系统 ====================
enum SlotType { WEAPON, ARMOR, HELMET, BOOTS, RING, AMULET }

const SLOT_NAMES := {
	SlotType.WEAPON: "武器", SlotType.ARMOR: "护甲", SlotType.HELMET: "头盔",
	SlotType.BOOTS: "靴子", SlotType.RING: "戒指", SlotType.AMULET: "项链",
}

const EQUIP_TEMPLATES := {
	SlotType.WEAPON: [
		{ "name": "暗影之刃",   "base_atk": 12, "base_def": 0,  "base_hp": 0,   "icon": "sword" },
		{ "name": "骨碎巨锤",   "base_atk": 16, "base_def": 0,  "base_hp": 0,   "icon": "hammer" },
		{ "name": "怨灵长弓",   "base_atk": 10, "base_def": 0,  "base_hp": 0,   "icon": "bow" },
		{ "name": "深渊法杖",   "base_atk": 8,  "base_def": 0,  "base_hp": 0,   "icon": "staff" },
		{ "name": "血饮双刃",   "base_atk": 14, "base_def": 0,  "base_hp": 0,   "icon": "dual" },
		{ "name": "寂灭之镰",   "base_atk": 18, "base_def": 0,  "base_hp": 0,   "icon": "scythe" },
	],
	SlotType.ARMOR: [
		{ "name": "暗影战甲",   "base_atk": 0,  "base_def": 10, "base_hp": 30,  "icon": "plate" },
		{ "name": "骨甲",       "base_atk": 0,  "base_def": 14, "base_hp": 20,  "icon": "bone_armor" },
		{ "name": "深渊鳞甲",   "base_atk": 0,  "base_def": 8,  "base_hp": 50,  "icon": "scale_armor" },
		{ "name": "亡魂披风",   "base_atk": 0,  "base_def": 6,  "base_hp": 40,  "icon": "cloak" },
	],
	SlotType.HELMET: [
		{ "name": "暗影兜帽",   "base_atk": 0,  "base_def": 6,  "base_hp": 15,  "icon": "hood" },
		{ "name": "骨盔",       "base_atk": 0,  "base_def": 9,  "base_hp": 10,  "icon": "skull_helm" },
		{ "name": "深渊面具",   "base_atk": 2,  "base_def": 5,  "base_hp": 20,  "icon": "mask" },
	],
	SlotType.BOOTS: [
		{ "name": "暗影战靴",   "base_atk": 0,  "base_def": 4,  "base_hp": 15,  "icon": "heavy_boots" },
		{ "name": "迅捷之靴",   "base_atk": 3,  "base_def": 2,  "base_hp": 10,  "icon": "swift_boots" },
		{ "name": "深渊行者",   "base_atk": 0,  "base_def": 6,  "base_hp": 25,  "icon": "abyss_boots" },
	],
	SlotType.RING: [
		{ "name": "暗影之戒",   "base_atk": 4,  "base_def": 2,  "base_hp": 0,   "icon": "dark_ring" },
		{ "name": "嗜血戒指",   "base_atk": 6,  "base_def": 0,  "base_hp": 0,   "icon": "blood_ring" },
		{ "name": "深渊指环",   "base_atk": 3,  "base_def": 3,  "base_hp": 10,  "icon": "abyss_ring" },
	],
	SlotType.AMULET: [
		{ "name": "暗影坠饰",   "base_atk": 3,  "base_def": 3,  "base_hp": 20,  "icon": "pendant" },
		{ "name": "灵魂项链",   "base_atk": 5,  "base_def": 0,  "base_hp": 15,  "icon": "soul_neck" },
		{ "name": "深渊之心",   "base_atk": 2,  "base_def": 4,  "base_hp": 30,  "icon": "abyss_heart" },
	],
}

# ==================== 材料定义 ====================
const MATERIALS := {
	"shadow_essence":  { "name": "暗影精华", "color": Color(0.48, 0.23, 1.0) },
	"bone_fragment":   { "name": "骨片",     "color": Color(0.83, 0.83, 0.83) },
	"demon_blood":     { "name": "恶魔之血", "color": Color(0.77, 0.12, 0.23) },
	"soul_shard":      { "name": "灵魂碎片", "color": Color(0.35, 0.78, 1.0) },
	"abyss_crystal":   { "name": "深渊水晶", "color": Color(0.70, 0.28, 1.0) },
	"cursed_iron":     { "name": "诅咒之铁", "color": Color(0.42, 0.42, 0.48) },
	"dragon_scale":    { "name": "龙鳞",     "color": Color(1.0, 0.61, 0.18) },
	"void_dust":       { "name": "虚空之尘", "color": Color(0.60, 0.23, 1.0) },
}

# ==================== 区域定义 ====================
const ZONES := [
	{
		"name": "黑暗森林", "min_lv": 1, "max_lv": 10,
		"bg_color": Color(0.04, 0.09, 0.06),
		"accent_color": Color(0.1, 0.25, 0.13),
		"enemies": ["暗影蝙蝠", "腐尸食客", "影狼", "枯木精"],
		"boss": { "name": "森林之主·枯萎者", "hp": 2000, "atk": 35, "def": 15, "enrage": 30 },
		"materials": ["shadow_essence", "bone_fragment"],
		"enemy_stats": { "hp": 40, "atk": 6, "def": 2, "exp": 8, "gold": 4 },
	},
	{
		"name": "被遗忘的墓穴", "min_lv": 10, "max_lv": 20,
		"bg_color": Color(0.09, 0.06, 0.09),
		"accent_color": Color(0.25, 0.19, 0.25),
		"enemies": ["骷髅战士", "怨灵", "墓穴食尸鬼", "暗影法师"],
		"boss": { "name": "墓穴之王·骸骨领主", "hp": 8000, "atk": 80, "def": 30, "enrage": 30 },
		"materials": ["bone_fragment", "soul_shard"],
		"enemy_stats": { "hp": 120, "atk": 15, "def": 6, "exp": 20, "gold": 12 },
	},
	{
		"name": "影之领域", "min_lv": 20, "max_lv": 30,
		"bg_color": Color(0.08, 0.04, 0.10),
		"accent_color": Color(0.31, 0.13, 0.38),
		"enemies": ["影魔", "暗影刺客", "虚空行者", "梦魇"],
		"boss": { "name": "影之女王·暗夜玫瑰", "hp": 25000, "atk": 150, "def": 55, "enrage": 25 },
		"materials": ["soul_shard", "demon_blood"],
		"enemy_stats": { "hp": 350, "atk": 35, "def": 14, "exp": 45, "gold": 28 },
	},
	{
		"name": "深渊裂隙", "min_lv": 30, "max_lv": 40,
		"bg_color": Color(0.10, 0.04, 0.04),
		"accent_color": Color(0.38, 0.13, 0.13),
		"enemies": ["深渊恶魔", "熔岩兽", "裂隙守卫", "烈焰骷髅"],
		"boss": { "name": "深渊领主·炎魔贝利亚尔", "hp": 70000, "atk": 280, "def": 100, "enrage": 25 },
		"materials": ["demon_blood", "cursed_iron"],
		"enemy_stats": { "hp": 1000, "atk": 70, "def": 28, "exp": 100, "gold": 60 },
	},
	{
		"name": "恶魔王座", "min_lv": 40, "max_lv": 50,
		"bg_color": Color(0.10, 0.04, 0.02),
		"accent_color": Color(0.38, 0.25, 0.06),
		"enemies": ["王座卫士", "堕落天使", "恶魔骑士", "地狱犬"],
		"boss": { "name": "恶魔之王·路西法", "hp": 200000, "atk": 500, "def": 180, "enrage": 20 },
		"materials": ["cursed_iron", "dragon_scale"],
		"enemy_stats": { "hp": 3000, "atk": 130, "def": 55, "exp": 230, "gold": 140 },
	},
	{
		"name": "混沌虚空", "min_lv": 50, "max_lv": 60,
		"bg_color": Color(0.04, 0.04, 0.10),
		"accent_color": Color(0.13, 0.13, 0.38),
		"enemies": ["虚空巨兽", "混沌畸变体", "虚空之眼", "时空裂痕"],
		"boss": { "name": "虚空之主·混沌", "hp": 600000, "atk": 900, "def": 320, "enrage": 20 },
		"materials": ["dragon_scale", "void_dust"],
		"enemy_stats": { "hp": 9000, "atk": 240, "def": 100, "exp": 520, "gold": 320 },
	},
	{
		"name": "永夜之地", "min_lv": 60, "max_lv": 70,
		"bg_color": Color(0.02, 0.04, 0.09),
		"accent_color": Color(0.06, 0.19, 0.38),
		"enemies": ["永夜亡魂", "暗夜领主", "寒冰恶魔", "月之骑士"],
		"boss": { "name": "永夜君王·暗月", "hp": 1800000, "atk": 1600, "def": 580, "enrage": 18 },
		"materials": ["void_dust", "abyss_crystal"],
		"enemy_stats": { "hp": 28000, "atk": 450, "def": 190, "exp": 1200, "gold": 750 },
	},
	{
		"name": "炼狱深渊", "min_lv": 70, "max_lv": 80,
		"bg_color": Color(0.10, 0.02, 0.02),
		"accent_color": Color(0.38, 0.06, 0.06),
		"enemies": ["炼狱魔神", "业火亡灵", "炼狱守卫", "灰烬巨兽"],
		"boss": { "name": "炼狱之主·业火", "hp": 3000000, "atk": 2200, "def": 800, "enrage": 15 },
		"materials": ["abyss_crystal", "demon_blood"],
		"enemy_stats": { "hp": 70000, "atk": 700, "def": 300, "exp": 2800, "gold": 1700 },
	},
	{
		"name": "灭世之境", "min_lv": 80, "max_lv": 90,
		"bg_color": Color(0.08, 0.02, 0.06),
		"accent_color": Color(0.31, 0.06, 0.25),
		"enemies": ["灭世使者", "末日审判者", "混沌之源", "虚无之主"],
		"boss": { "name": "灭世者·终焉", "hp": 8000000, "atk": 3800, "def": 1400, "enrage": 15 },
		"materials": ["abyss_crystal", "void_dust"],
		"enemy_stats": { "hp": 200000, "atk": 1300, "def": 550, "exp": 6500, "gold": 4000 },
	},
	{
		"name": "终焉之地", "min_lv": 90, "max_lv": 100,
		"bg_color": Color(0.04, 0.02, 0.03),
		"accent_color": Color(0.25, 0.03, 0.13),
		"enemies": ["终焉之影", "虚无使者", "末日之刃", "永恒暗影"],
		"boss": { "name": "终焉之主·虚无", "hp": 20000000, "atk": 6500, "def": 2500, "enrage": 12 },
		"materials": ["abyss_crystal", "dragon_scale"],
		"enemy_stats": { "hp": 550000, "atk": 2400, "def": 1000, "exp": 15000, "gold": 9000 },
	},
]

# ==================== 锻造配方 ====================
const RECIPES := [
	{ "id": "craft_weapon_1", "name": "锻造随机武器", "slot": SlotType.WEAPON, "min_lv": 1,
	  "materials": { "shadow_essence": 5, "bone_fragment": 3 }, "gold": 200, "rarity_boost": 0 },
	{ "id": "craft_weapon_2", "name": "精铸武器", "slot": SlotType.WEAPON, "min_lv": 15,
	  "materials": { "demon_blood": 5, "cursed_iron": 3 }, "gold": 1000, "rarity_boost": 1 },
	{ "id": "craft_weapon_3", "name": "深渊锻造武器", "slot": SlotType.WEAPON, "min_lv": 35,
	  "materials": { "dragon_scale": 5, "abyss_crystal": 3 }, "gold": 5000, "rarity_boost": 2 },
	{ "id": "craft_armor_1", "name": "锻造随机护甲", "slot": SlotType.ARMOR, "min_lv": 1,
	  "materials": { "shadow_essence": 4, "bone_fragment": 4 }, "gold": 200, "rarity_boost": 0 },
	{ "id": "craft_armor_2", "name": "精铸护甲", "slot": SlotType.ARMOR, "min_lv": 15,
	  "materials": { "demon_blood": 4, "cursed_iron": 4 }, "gold": 1000, "rarity_boost": 1 },
	{ "id": "craft_helmet_1", "name": "锻造头盔", "slot": SlotType.HELMET, "min_lv": 1,
	  "materials": { "shadow_essence": 3, "bone_fragment": 5 }, "gold": 150, "rarity_boost": 0 },
	{ "id": "craft_boots_1", "name": "锻造靴子", "slot": SlotType.BOOTS, "min_lv": 1,
	  "materials": { "shadow_essence": 3, "bone_fragment": 3 }, "gold": 150, "rarity_boost": 0 },
	{ "id": "craft_ring_1", "name": "锻造戒指", "slot": SlotType.RING, "min_lv": 5,
	  "materials": { "soul_shard": 3, "shadow_essence": 3 }, "gold": 300, "rarity_boost": 0 },
	{ "id": "craft_ring_2", "name": "精铸戒指", "slot": SlotType.RING, "min_lv": 25,
	  "materials": { "abyss_crystal": 3, "demon_blood": 3 }, "gold": 2000, "rarity_boost": 2 },
	{ "id": "craft_amulet_1", "name": "锻造项链", "slot": SlotType.AMULET, "min_lv": 5,
	  "materials": { "soul_shard": 4, "shadow_essence": 2 }, "gold": 300, "rarity_boost": 0 },
	{ "id": "craft_amulet_2", "name": "精铸项链", "slot": SlotType.AMULET, "min_lv": 25,
	  "materials": { "abyss_crystal": 4, "dragon_scale": 2 }, "gold": 2000, "rarity_boost": 2 },
	{ "id": "craft_random_epic", "name": "神秘锻造(保底史诗)", "slot": -1, "min_lv": 20,
	  "materials": { "abyss_crystal": 5, "demon_blood": 5, "soul_shard": 5 }, "gold": 5000, "rarity_boost": 3 },
	{ "id": "craft_random_legend", "name": "传说锻造(保底传说)", "slot": -1, "min_lv": 40,
	  "materials": { "abyss_crystal": 10, "dragon_scale": 5, "void_dust": 5 }, "gold": 20000, "rarity_boost": 4 },
]

# ==================== 任务节点 ====================
const QUESTS := [
	{ "id": "q1",  "name": "初入深渊",   "desc": "击败10个敌人",       "type": "kill",      "target": 10,    "reward": { "gold": 100, "exp": 50 } },
	{ "id": "q2",  "name": "初尝战果",   "desc": "达到5级",            "type": "level",     "target": 5,     "reward": { "gold": 300, "gems": 5 } },
	{ "id": "q3",  "name": "装备收集者", "desc": "获得5件装备",        "type": "equip_get", "target": 5,     "reward": { "gold": 200, "exp": 100 } },
	{ "id": "q4",  "name": "森林清道夫", "desc": "击败50个敌人",       "type": "kill",      "target": 50,    "reward": { "gold": 500, "gems": 10 } },
	{ "id": "q5",  "name": "锋芒初露",   "desc": "达到10级",           "type": "level",     "target": 10,    "reward": { "gold": 800, "exp": 300 } },
	{ "id": "q6",  "name": "初次锻造",   "desc": "锻造1件装备",        "type": "craft",     "target": 1,     "reward": { "gold": 500, "gems": 10 } },
	{ "id": "q7",  "name": "屠戮者",     "desc": "击败200个敌人",      "type": "kill",      "target": 200,   "reward": { "gold": 1500, "gems": 20 } },
	{ "id": "q8",  "name": "装备大师",   "desc": "装备6件装备",        "type": "equip_all", "target": 6,     "reward": { "gold": 2000, "gems": 30 } },
	{ "id": "q9",  "name": "墓穴探险",   "desc": "击败墓穴之王",       "type": "boss",      "target": 1,     "reward": { "gold": 3000, "gems": 50 } },
	{ "id": "q10", "name": "财富积累",   "desc": "累计获得10000金币",  "type": "gold_total","target": 10000, "reward": { "gems": 50 } },
	{ "id": "q11", "name": "锻造大师",   "desc": "锻造10件装备",       "type": "craft",     "target": 10,    "reward": { "gold": 5000, "gems": 50 } },
	{ "id": "q12", "name": "影之征服",   "desc": "击败影之女王",       "type": "boss",      "target": 2,     "reward": { "gold": 8000, "gems": 80 } },
	{ "id": "q13", "name": "深渊勇者",   "desc": "达到30级",           "type": "level",     "target": 30,    "reward": { "gold": 10000, "gems": 100 } },
	{ "id": "q14", "name": "杀敌如麻",   "desc": "击败1000个敌人",     "type": "kill",      "target": 1000,  "reward": { "gold": 15000, "gems": 150 } },
	{ "id": "q15", "name": "恶魔猎手",   "desc": "击败恶魔之王",       "type": "boss",      "target": 4,     "reward": { "gold": 30000, "gems": 200 } },
	{ "id": "q16", "name": "传说锻造师", "desc": "锻造30件装备",       "type": "craft",     "target": 30,    "reward": { "gold": 25000, "gems": 200 } },
	{ "id": "q17", "name": "虚空之主",   "desc": "击败虚空之主",       "type": "boss",      "target": 5,     "reward": { "gold": 50000, "gems": 300 } },
	{ "id": "q18", "name": "巅峰之路",   "desc": "达到60级",           "type": "level",     "target": 60,    "reward": { "gold": 80000, "gems": 400 } },
	{ "id": "q19", "name": "灭世者",     "desc": "击败灭世者·终焉",   "type": "boss",      "target": 8,     "reward": { "gold": 200000, "gems": 800 } },
	{ "id": "q20", "name": "终极传说",   "desc": "达到100级",          "type": "level",     "target": 100,   "reward": { "gold": 500000, "gems": 2000 } },
]

# ==================== 每日任务模板 ====================
const DAILY_TEMPLATES := [
	{ "id": "d_kill",  "name": "每日击杀", "desc": "击败{t}个敌人",          "type": "kill",      "targets": [50, 100, 200], "reward": { "gold": 2000, "gems": 10 } },
	{ "id": "d_gold",  "name": "每日金币", "desc": "获得{t}金币",            "type": "gold_day",  "targets": [5000, 10000],  "reward": { "gold": 1000, "gems": 10 } },
	{ "id": "d_craft", "name": "每日锻造", "desc": "锻造{t}件装备",          "type": "craft_day", "targets": [1, 2, 3],      "reward": { "gold": 3000, "gems": 15 } },
	{ "id": "d_boss",  "name": "每日挑战", "desc": "挑战Boss {t}次",         "type": "boss_day",  "targets": [1, 2],         "reward": { "gold": 5000, "gems": 20 } },
	{ "id": "d_zone",  "name": "每日探索", "desc": "击杀{t}个当前区域敌人",  "type": "zone_kill", "targets": [30, 50],       "reward": { "gold": 2500, "gems": 12 } },
]

# 签到奖励（7天循环）
const DAILY_LOGIN_REWARDS := [
	{ "day": 1, "reward": { "gold": 1000 } },
	{ "day": 2, "reward": { "gold": 2000 } },
	{ "day": 3, "reward": { "gold": 3000, "gems": 10 } },
	{ "day": 4, "reward": { "gold": 5000 } },
	{ "day": 5, "reward": { "gold": 5000, "gems": 20 } },
	{ "day": 6, "reward": { "gold": 8000, "gems": 30 } },
	{ "day": 7, "reward": { "gold": 10000, "gems": 50 } },
]

# ==================== 商店 ====================
const SHOP_ITEMS := [
	{ "id": "mat_essence", "name": "暗影精华×10", "type": "material", "mat_id": "shadow_essence", "amount": 10, "cost": 500, "currency": "gold" },
	{ "id": "mat_bone",    "name": "骨片×10",     "type": "material", "mat_id": "bone_fragment",  "amount": 10, "cost": 500, "currency": "gold" },
	{ "id": "mat_blood",   "name": "恶魔之血×10", "type": "material", "mat_id": "demon_blood",    "amount": 10, "cost": 2000, "currency": "gold" },
	{ "id": "mat_soul",    "name": "灵魂碎片×10", "type": "material", "mat_id": "soul_shard",     "amount": 10, "cost": 2000, "currency": "gold" },
	{ "id": "mat_iron",    "name": "诅咒之铁×10", "type": "material", "mat_id": "cursed_iron",    "amount": 10, "cost": 5000, "currency": "gold" },
	{ "id": "mat_scale",   "name": "龙鳞×10",     "type": "material", "mat_id": "dragon_scale",   "amount": 10, "cost": 10000, "currency": "gold" },
	{ "id": "mat_crystal", "name": "深渊水晶×5",  "type": "material", "mat_id": "abyss_crystal",  "amount": 5,  "cost": 20000, "currency": "gold" },
	{ "id": "mat_dust",    "name": "虚空之尘×5",  "type": "material", "mat_id": "void_dust",      "amount": 5,  "cost": 20000, "currency": "gold" },
	{ "id": "exp_boost",   "name": "经验药水",    "type": "boost",    "effect": "exp",            "amount": 1,  "cost": 50, "currency": "gems" },
	{ "id": "gold_boost",  "name": "金币加成",    "type": "boost",    "effect": "gold",           "amount": 1,  "cost": 50, "currency": "gems" },
	{ "id": "boss_ticket", "name": "Boss挑战券",  "type": "ticket",   "effect": "boss",           "amount": 1,  "cost": 100, "currency": "gems" },
	{ "id": "random_box",  "name": "神秘宝箱",    "type": "box",      "amount": 1,                "cost": 200, "currency": "gems" },
]

# ==================== 工具函数 ====================

## 经验值公式（数据来自 data/balance_curves.json）
func exp_for_level(lv: int) -> int:
	if ProgressionManager.is_ready():
		return ProgressionManager.exp_for_level(lv)
	return int(55.0 * pow(lv, 1.42) * (1.0 + lv * 0.035))

## 敌人属性缩放（根据玩家等级 + 区域，Lv1时几乎不缩放）
func scale_enemy(base: Dictionary, player_lv: int, zone_idx: int = 0) -> Dictionary:
	var zone: Dictionary = ZONES[clampi(zone_idx, 0, ZONES.size() - 1)]
	# 以玩家实际等级驱动缩放，Lv1时倍率=1.0
	var lv_mult: float = 1.0 + (player_lv - 1) * 0.10 + zone_idx * 0.25
	# HP温和成长
	var hp_mult: float = lv_mult * 1.5
	var stat_mult: float = lv_mult
	# 越级刑图惩罚（玩家等级超出区域上限）
	var gap: int = maxi(0, player_lv - int(zone["max_lv"]))
	if gap > 0:
		hp_mult *= 1.0 + gap * 0.15
		stat_mult *= 1.0 + gap * 0.05
	return {
		"hp": maxi(1, int(base["hp"] * hp_mult)),
		"atk": maxi(1, int(base["atk"] * stat_mult)),
		"def": maxi(1, int(base["def"] * stat_mult)),
		"exp": maxi(1, int(base["exp"] * lv_mult)),
		"gold": maxi(1, int(base["gold"] * lv_mult)),
	}

## 根据玩家攻击力确保小怪需要若干次普攻才能击杀
func ensure_wave_enemy_hp(scaled: Dictionary, player_atk: int, zone_idx: int, hits_to_kill: int = 6) -> Dictionary:
	var result: Dictionary = scaled.duplicate(true)
	var enemy_def: int = int(result.get("def", 0))
	var est_hit: int = maxi(1, player_atk - enemy_def / 2)
	var min_hp: int = est_hit * hits_to_kill
	result["hp"] = maxi(int(result["hp"]), min_hp)
	result["max_hp"] = result["hp"]
	return result

## Boss属性缩放
func scale_boss(boss: Dictionary, zone_lv: int) -> Dictionary:
	var mult := 1.0 + zone_lv * 0.12
	return {
		"name": boss["name"],
		"hp": int(boss["hp"] * mult),
		"atk": int(boss["atk"] * mult),
		"def": int(boss["def"] * mult),
		"enrage": boss["enrage"],
	}

## 根据区域掉落品质
func roll_rarity(zone_index: int, boost: int = 0) -> int:
	var weights: Array = RARITY_WEIGHTS[mini(zone_index, 9)]
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var acc := 0.0
	for i in range(weights.size()):
		acc += weights[i]
		if roll <= acc:
			return mini(i + boost, 5)
	return 0

## 生成随机装备
func generate_item(slot: int, level: int, rarity_boost: int = 0) -> Dictionary:
	var rarity_id := roll_rarity(level / 10, rarity_boost)
	var rarity_key := rarity_id as Rarity
	var rarity_info: Dictionary = RARITY_INFO[rarity_key]
	var templates: Array = EQUIP_TEMPLATES[slot as SlotType]
	var tmpl: Dictionary = templates[randi() % templates.size()]
	var lv_mult := 1.0 + level * 0.12

	var item := {
		"uid": str(Time.get_unix_time_from_system()) + "_" + str(randi() % 99999),
		"name": tmpl["name"],
		"slot": slot,
		"rarity": rarity_id,
		"level": level,
		"icon": tmpl["icon"],
		"stats": {},
	}

	# 主属性
	if tmpl["base_atk"] > 0:
		item["stats"][StatType.ATK] = int(tmpl["base_atk"] * rarity_info["mult"] * lv_mult)
	if tmpl["base_def"] > 0:
		item["stats"][StatType.DEF] = int(tmpl["base_def"] * rarity_info["mult"] * lv_mult)
	if tmpl["base_hp"] > 0:
		item["stats"][StatType.HP] = int(tmpl["base_hp"] * rarity_info["mult"] * lv_mult)

	# 额外属性
	var extra_pool := [StatType.CRIT, StatType.CRIT_DMG, StatType.HP_REGEN, StatType.LIFESTEAL, StatType.ATK, StatType.DEF, StatType.HP]
	for i in range(rarity_info["extra"]):
		if extra_pool.is_empty():
			break
		var idx := randi() % extra_pool.size()
		var stat: int = extra_pool[idx]
		extra_pool.remove_at(idx)
		var val := 0
		match stat:
			StatType.ATK:       val = int((3.0 + level * 0.5) * rarity_info["mult"])
			StatType.DEF:       val = int((2.0 + level * 0.4) * rarity_info["mult"])
			StatType.HP:        val = int((10.0 + level * 2.0) * rarity_info["mult"])
			StatType.CRIT:      val = int((2.0 + randf() * 4.0) * (1.0 + rarity_boost * 0.2))
			StatType.CRIT_DMG:  val = int((5.0 + randf() * 10.0) * (1.0 + rarity_boost * 0.2))
			StatType.HP_REGEN:  val = int((1.0 + randf() * 3.0) * (1.0 + level * 0.05))
			StatType.LIFESTEAL: val = int((1.0 + randf() * 2.0) * (1.0 + rarity_boost * 0.1))
		if item["stats"].has(stat):
			item["stats"][stat] += val
		else:
			item["stats"][stat] = val

	# 品质前缀
	if rarity_id >= 2:
		var prefixes := ["暗影", "深渊", "诅咒", "虚无", "混沌", "灭世", "永恒"]
		item["name"] = prefixes[mini(rarity_id - 2, prefixes.size() - 1)] + "·" + item["name"]

	return normalize_item(item)

## 规范化装备数据（JSON 存档加载后 slot/stats 键可能变成 float/string）
static func normalize_item(item: Variant) -> Dictionary:
	if item == null or not item is Dictionary:
		return {}
	var src: Dictionary = item
	if src.is_empty():
		return src
	var out: Dictionary = src.duplicate(true)
	out["slot"] = int(out.get("slot", 0))
	out["rarity"] = int(out.get("rarity", 0))
	out["level"] = int(out.get("level", 1))
	if out.has("enhance_level"):
		out["enhance_level"] = int(out.get("enhance_level", 0))
	var stats_raw: Variant = out.get("stats", {})
	if stats_raw is Dictionary:
		var stats_norm := {}
		for k in stats_raw:
			stats_norm[int(k)] = int(stats_raw[k])
		out["stats"] = stats_norm
	return out

static func item_slot_key(item: Dictionary) -> String:
	return str(int(item.get("slot", 0)))

static func get_item_stat(stats: Dictionary, stat_type: int) -> int:
	for k in stats:
		if int(k) == stat_type:
			return int(stats[k])
	return 0

static func item_power(item: Dictionary) -> int:
	var power := 0
	for k in item.get("stats", {}):
		power += int(item["stats"][k])
	return power

func _ready() -> void:
	data_ready.emit()
