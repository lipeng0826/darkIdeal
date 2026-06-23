extends RefCounted
class_name AssetRegistry
## 敌人名/装备 icon → 贴图路径映射（v2 战斗精灵）

# 精确敌人名 → Q版战斗精灵（与骑士主角风格统一，降低恐怖感）
const ENEMY_EXACT_MAP := {
	"暗影蝙蝠": "res://assets/generated/enemies_v2/enemy_shadow_bat_v2.png",
	"腐尸食客": "res://assets/generated/enemies_v2/enemy_slime_v2.png",
	"影狼": "res://assets/generated/enemies_v2/enemy_shadow_bat_v2.png",
	"枯木精": "res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"骷髅战士": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"怨灵": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"墓穴食尸鬼": "res://assets/generated/enemies_v2/enemy_slime_v2.png",
	"暗影法师": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"影魔": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"暗影刺客": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"虚空行者": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"梦魇": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"深渊恶魔": "res://assets/sprites/enemy_idle_2.png",
	"熔岩兽": "res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"烈焰骷髅": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"裂隙守卫": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"王座卫士": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"堕落天使": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"恶魔骑士": "res://assets/sprites/enemy_idle_1.png",
	"地狱犬": "res://assets/generated/enemies_v2/enemy_shadow_bat_v2.png",
	"虚空巨兽": "res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"混沌畸变体": "res://assets/sprites/enemy_idle_2.png",
	"虚空之眼": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"时空裂痕": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"永夜亡魂": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"暗夜领主": "res://assets/sprites/enemy_idle_1.png",
	"寒冰恶魔": "res://assets/sprites/enemy_idle_2.png",
	"月之骑士": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"炼狱魔神": "res://assets/sprites/enemy_idle_2.png",
	"业火亡灵": "res://assets/sprites/enemy_idle_1.png",
	"炼狱守卫": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"灰烬巨兽": "res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"灭世使者": "res://assets/sprites/enemy_idle_2.png",
	"末日审判者": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"混沌之源": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"虚无之主": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"终焉之影": "res://assets/sprites/enemy_idle_1.png",
	"虚无使者": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"末日之刃": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"永恒暗影": "res://assets/sprites/enemy_idle_2.png",
}

const ENEMY_KEYWORD_MAP: Array = [
	{"keys": ["蝙蝠", "犬", "狼"], "path": "res://assets/generated/enemies_v2/enemy_shadow_bat_v2.png"},
	{"keys": ["骷髅", "骸骨", "骑士", "卫士"], "path": "res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png"},
	{"keys": ["枯木", "精", "树", "巨兽", "兽"], "path": "res://assets/generated/enemies_v2/enemy_dry_treant_v2.png"},
	{"keys": ["怨灵", "亡魂", "幽灵", "梦魇", "虚空", "法师", "刺客", "影魔", "之眼"], "path": "res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png"},
	{"keys": ["食尸", "腐尸", "僵尸"], "path": "res://assets/generated/enemies_v2/enemy_slime_v2.png"},
	{"keys": ["恶魔", "使者"], "path": "res://assets/sprites/enemy_idle_1.png"},
	{"keys": ["炼狱", "熔岩", "烈焰", "混沌", "末日", "永恒"], "path": "res://assets/sprites/enemy_idle_2.png"},
]

const ZONE_DEFAULT_ENEMIES: Array = [
	"res://assets/generated/enemies_v2/enemy_shadow_bat_v2.png",
	"res://assets/generated/enemies_v2/enemy_slime_v2.png",
	"res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"res://assets/sprites/enemy_idle_2.png",
	"res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
	"res://assets/generated/enemies_v2/enemy_shadow_mage_v2.png",
	"res://assets/generated/enemies_v2/enemy_dry_treant_v2.png",
	"res://assets/generated/enemies_v2/enemy_slime_v2.png",
	"res://assets/generated/enemies_v2/enemy_skeleton_warrior_v2.png",
]

const EQUIP_ICON_TEXTURES := {
	"sword": "res://assets/generated/equipment/equip_sword.png",
	"hammer": "res://assets/generated/equipment/equip_hammer.png",
	"bow": "res://assets/generated/equipment/equip_bow.png",
	"staff": "res://assets/generated/equipment/equip_staff.png",
	"dual": "res://assets/generated/equipment/equip_dual_blades.png",
	"scythe": "res://assets/generated/equipment/equip_scythe.png",
	"plate": "res://assets/generated/equipment/equip_plate_armor.png",
	"bone_armor": "res://assets/generated/equipment/equip_plate_armor.png",
	"scale_armor": "res://assets/generated/equipment/equip_plate_armor.png",
	"cloak": "res://assets/generated/equipment/equip_dark_cloak.png",
	"hood": "res://assets/generated/equipment/equip_hood.png",
	"skull_helm": "res://assets/generated/equipment/equip_dark_helmet.png",
	"mask": "res://assets/generated/equipment/equip_dark_helmet.png",
	"heavy_boots": "res://assets/generated/equipment/equip_boots.png",
	"swift_boots": "res://assets/generated/equipment/equip_boots.png",
	"abyss_boots": "res://assets/generated/equipment/equip_boots.png",
	"dark_ring": "res://assets/generated/equipment/equip_dark_ring.png",
	"blood_ring": "res://assets/generated/equipment/equip_dark_ring.png",
	"abyss_ring": "res://assets/generated/equipment/equip_dark_ring.png",
	"pendant": "res://assets/generated/equipment/equip_amulet.png",
	"soul_neck": "res://assets/generated/equipment/equip_amulet.png",
	"abyss_heart": "res://assets/generated/equipment/equip_amulet.png",
}

const SLOT_ICON_FALLBACK := {
	0: "res://assets/equipment/sword.png",
	1: "res://assets/equipment/armor.png",
	2: "res://assets/equipment/helmet.png",
	3: "res://assets/equipment/armor.png",
	4: "res://assets/equipment/ring.png",
	5: "res://assets/equipment/ring.png",
}

static func get_equip_icon(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var icon_key: String = str(item.get("icon", ""))
	if EQUIP_ICON_TEXTURES.has(icon_key):
		return EQUIP_ICON_TEXTURES[icon_key]
	var slot_i: int = int(item.get("slot", 0))
	if SLOT_ICON_FALLBACK.has(slot_i):
		return SLOT_ICON_FALLBACK[slot_i]
	return "res://assets/equipment/sword.png"

static func get_slot_fallback_icon(slot_i: int) -> String:
	if SLOT_ICON_FALLBACK.has(slot_i):
		return SLOT_ICON_FALLBACK[slot_i]
	return "res://assets/equipment/sword.png"

# v2 装备叠加层（侧视、可贴合角色，非背包大图标）
const EQUIP_OVERLAY_TEXTURES := {
	"sword": "res://assets/generated/equipment_v2/overlay_sword_v2.png",
	"hammer": "res://assets/generated/equipment_v2/overlay_hammer_v2.png",
	"bow": "res://assets/generated/equipment_v2/overlay_bow_v2.png",
	"staff": "res://assets/generated/equipment_v2/overlay_staff_v2.png",
	"dual": "res://assets/generated/equipment_v2/overlay_sword_v2.png",
	"scythe": "res://assets/generated/equipment_v2/overlay_hammer_v2.png",
	"plate": "res://assets/generated/equipment_v2/overlay_armor_v2.png",
	"bone_armor": "res://assets/generated/equipment_v2/overlay_armor_v2.png",
	"scale_armor": "res://assets/generated/equipment_v2/overlay_armor_v2.png",
	"cloak": "res://assets/generated/equipment_v2/overlay_armor_v2.png",
	"hood": "res://assets/generated/equipment_v2/overlay_helmet_v2.png",
	"skull_helm": "res://assets/generated/equipment_v2/overlay_helmet_v2.png",
	"mask": "res://assets/generated/equipment_v2/overlay_helmet_v2.png",
}

const SKILL_VFX_TEXTURES := {
	"slash_storm": "res://assets/generated/skills/skill_slash_storm.png",
	"arc_cleave": "res://assets/generated/skills/skill_whirlwind.png",
	"execute": "res://assets/generated/skills/skill_execute.png",
	"bleed": "res://assets/generated/skills/skill_bleed.png",
	"whirlwind": "res://assets/generated/skills/skill_whirlwind.png",
	"shadow_bolt": "res://assets/generated/skills/skill_shadow_bolt.png",
	"soul_drain": "res://assets/generated/skills/skill_soul_drain.png",
	"dark_explosion": "res://assets/generated/skills/skill_dark_explosion.png",
	"void_rift": "res://assets/generated/skills/skill_void_rift.png",
	"holy_shield": "res://assets/generated/skills/skill_holy_shield.png",
	"divine_wrath": "res://assets/generated/skills/skill_divine_wrath.png",
	"resurrection": "res://assets/generated/skills/skill_resurrection.png",
}

static func get_enemy_texture(enemy_name: String, zone_idx: int = 0) -> String:
	if ENEMY_EXACT_MAP.has(enemy_name):
		return ENEMY_EXACT_MAP[enemy_name]
	for entry in ENEMY_KEYWORD_MAP:
		for key in entry["keys"]:
			if key in enemy_name:
				return entry["path"]
	var idx := clampi(zone_idx, 0, ZONE_DEFAULT_ENEMIES.size() - 1)
	return ZONE_DEFAULT_ENEMIES[idx]

static func get_equip_texture(icon_key: String) -> String:
	if EQUIP_OVERLAY_TEXTURES.has(icon_key):
		return EQUIP_OVERLAY_TEXTURES[icon_key]
	return ""

static func get_skill_vfx(skill_id: String) -> String:
	if SKILL_VFX_TEXTURES.has(skill_id):
		return SKILL_VFX_TEXTURES[skill_id]
	return "res://assets/generated/skills/skill_hit_generic.png"

static func get_skill_icon(skill_id: String) -> String:
	return get_skill_vfx(skill_id)

const PET_ICON_TEXTURES := {
	"shadow_wolf": "res://assets/generated/pets/pet_shadow_wolf.png",
	"shadow_alpha": "res://assets/generated/pets/pet_shadow_wolf.png",
	"bone_imp": "res://assets/generated/pets/pet_bone_imp.png",
	"bone_lord": "res://assets/generated/pets/pet_bone_imp.png",
	"fire_sprite": "res://assets/generated/pets/pet_fire_sprite.png",
	"inferno_lord": "res://assets/generated/pets/pet_fire_sprite.png",
	"ice_golem": "res://assets/generated/pets/pet_ice_golem.png",
	"frost_titan": "res://assets/generated/pets/pet_ice_golem.png",
	"soul_wisp": "res://assets/generated/pets/pet_soul_wisp.png",
	"soul_phoenix": "res://assets/generated/pets/pet_soul_wisp.png",
	"void_serpent": "res://assets/generated/pets/pet_void_serpent.png",
	"void_dragon": "res://assets/generated/pets/pet_void_serpent.png",
}

const PET_ICON_FALLBACK := "res://assets/generated/pets/pet_shadow_wolf.png"

static func get_pet_icon(pet_id: String) -> String:
	if PET_ICON_TEXTURES.has(pet_id):
		return PET_ICON_TEXTURES[pet_id]
	return PET_ICON_FALLBACK

const ZONE_MAP_TEXTURES := [
	"res://assets/generated/zones/zone_dark_forest.png",
	"res://assets/generated/zones/zone_forgotten_tomb.png",
	"res://assets/generated/zones/zone_shadow_realm.png",
	"res://assets/generated/zones/zone_abyss_rift.png",
	"res://assets/generated/zones/zone_demon_throne.png",
	"res://assets/generated/zones/zone_chaos_void.png",
	"res://assets/generated/zones/zone_eternal_night.png",
	"res://assets/generated/zones/zone_purgatory.png",
	"res://assets/generated/zones/zone_apocalypse.png",
	"res://assets/generated/zones/zone_final_end.png",
]

const BATTLE_BG_TEXTURES := [
	"res://assets/generated/battle_bgs/battle_bg_forest.png",
	"res://assets/generated/battle_bgs/battle_bg_tomb.png",
	"res://assets/generated/battle_bgs/battle_bg_shadow.png",
	"res://assets/generated/battle_bgs/battle_bg_lava.png",
	"res://assets/generated/battle_bgs/battle_bg_throne.png",
	"res://assets/generated/battle_bgs/battle_bg_void.png",
	"res://assets/generated/battle_bgs/battle_bg_night.png",
	"res://assets/generated/battle_bgs/battle_bg_lava.png",
	"res://assets/generated/battle_bgs/battle_bg_void.png",
	"res://assets/generated/battle_bgs/battle_bg_void.png",
]

const BOSS_TEXTURES := [
	"res://assets/generated/bosses/boss_forest_lord.png",
	"res://assets/generated/bosses/boss_skeleton_king.png",
	"res://assets/generated/bosses/boss_shadow_queen.png",
	"res://assets/generated/bosses/boss_inferno_demon.png",
	"res://assets/generated/bosses/boss_lucifer.png",
	"res://assets/generated/bosses/boss_void_chaos.png",
	"res://assets/generated/bosses/boss_dark_moon.png",
	"res://assets/generated/bosses/boss_hellfire.png",
	"res://assets/generated/bosses/boss_apocalypse.png",
	"res://assets/generated/bosses/boss_void_nihil.png",
]

static func get_boss_texture(zone_idx: int) -> String:
	var idx := clampi(zone_idx, 0, BOSS_TEXTURES.size() - 1)
	return BOSS_TEXTURES[idx]

static func get_zone_battle_texture(zone_idx: int) -> String:
	var idx := clampi(zone_idx, 0, BATTLE_BG_TEXTURES.size() - 1)
	return BATTLE_BG_TEXTURES[idx]

static func get_zone_map_texture(zone_idx: int) -> String:
	var idx := clampi(zone_idx, 0, ZONE_MAP_TEXTURES.size() - 1)
	return ZONE_MAP_TEXTURES[idx]

static func uses_chroma_key(path: String) -> bool:
	return "_v2" in path or "hero_" in path or "sprites/player" in path or "sprites/enemy" in path or "generated/pets" in path

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
