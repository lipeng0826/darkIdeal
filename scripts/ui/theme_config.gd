class_name ThemeConfig
extends RefCounted
## 暗影深渊 - 暗黑魔幻风 主题配置
## 集中管理所有色彩常量和样式工厂方法

# ==================== 背景色系 ====================
const BG_BASE := Color(0.05, 0.05, 0.08)           # 主背景
const BG_CARD := Color(0.10, 0.10, 0.15, 0.96)     # 卡片背景
const BG_ELEVATED := Color(0.14, 0.13, 0.20, 0.98) # 浮起面板
const BG_NAV := Color(0.07, 0.06, 0.11, 0.98)      # 导航栏底
const BG_HEADER := Color(0.09, 0.08, 0.13, 0.98)   # 顶栏底色
const BG_INPUT := Color(0.12, 0.11, 0.17)          # 输入框底

# ==================== 主题色 ====================
const PRIMARY := Color(0.78, 0.30, 0.16)           # 焰铜橙（主按钮）
const PRIMARY_LIGHT := Color(0.90, 0.54, 0.32)
const PRIMARY_DARK := Color(0.50, 0.17, 0.08)
const SECONDARY := Color(0.32, 0.53, 0.83)         # 魔法蓝
const SECONDARY_LIGHT := Color(0.58, 0.72, 0.94)

# ==================== 装饰色 ====================
const ACCENT_GOLD := Color(0.88, 0.72, 0.35)       # 暖金
const ACCENT_PURPLE := Color(0.60, 0.40, 0.82)     # 紫罗兰
const ACCENT_GREEN := Color(0.45, 0.78, 0.55)      # 薄荷绿
const ACCENT_ORANGE := Color(0.95, 0.62, 0.30)     # 暖橙

# ==================== 文字色 ====================
const TXT_PRIMARY := Color(0.88, 0.86, 0.92)       # 主文字
const TXT_SECONDARY := Color(0.68, 0.66, 0.74)     # 次要文字
const TXT_DISABLED := Color(0.44, 0.43, 0.50)      # 禁用文字
const TXT_ON_PRIMARY := Color(1.0, 1.0, 1.0)       # 主色上文字
const TXT_ON_DARK := Color(0.95, 0.93, 0.90)       # 深底上文字

# ==================== 功能色 ====================
const HP_GREEN := Color(0.45, 0.82, 0.52)          # 生命条
const HP_BG := Color(0.88, 0.92, 0.88)             # 生命条背景
const ENEMY_RED := Color(0.85, 0.35, 0.30)         # 敌人血条
const EXP_BLUE := Color(0.50, 0.72, 0.92)          # 经验条
const MP_PURPLE := Color(0.65, 0.50, 0.88)         # 技能/魔力
const CRIT_COLOR := Color(0.95, 0.55, 0.15)        # 暴击色

# ==================== 品质色 ====================
const RARITY_COMMON := Color(0.60, 0.60, 0.64)
const RARITY_UNCOMMON := Color(0.35, 0.78, 0.50)
const RARITY_RARE := Color(0.40, 0.65, 0.95)
const RARITY_EPIC := Color(0.72, 0.40, 0.92)
const RARITY_LEGENDARY := Color(0.95, 0.70, 0.25)
const RARITY_MYTHIC := Color(0.95, 0.30, 0.40)

const RARITY_COLORS := [RARITY_COMMON, RARITY_UNCOMMON, RARITY_RARE, RARITY_EPIC, RARITY_LEGENDARY, RARITY_MYTHIC]

# ==================== 样式工厂 ====================

## 圆角卡片（暗色金属框）
static func make_card(accent: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BG_CARD
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 2)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.44, 0.40, 0.54, 0.55)
	if accent != Color.TRANSPARENT:
		s.border_width_bottom = 3
		s.border_color = accent
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 14.0
	s.content_margin_bottom = 14.0
	return s

## 主按钮样式
static func make_btn_primary() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PRIMARY
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.content_margin_left = 20.0
	s.content_margin_right = 20.0
	s.content_margin_top = 10.0
	s.content_margin_bottom = 10.0
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.95, 0.74, 0.30, 0.55)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	s.shadow_size = 5
	return s

## 次要按钮样式
static func make_btn_secondary() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SECONDARY
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s

## 轻量按钮（透明底+边框）
static func make_btn_outline(color: Color = PRIMARY) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color.r, color.g, color.b, 0.08)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = color
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s

## 进度条背景
static func make_bar_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.90, 0.88, 0.85)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s

## 进度条填充
static func make_bar_fill(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s

## 导航栏背景
static func make_nav_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.05, 0.10, 0.96)
	s.border_width_top = 1
	s.border_color = Color(0.42, 0.34, 0.55, 0.55)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, -2)
	s.content_margin_left = 4.0
	s.content_margin_right = 4.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 8.0
	return s

## 顶栏背景
static func make_header_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BG_HEADER
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 1)
	s.border_width_bottom = 1
	s.border_color = Color(0.58, 0.46, 0.22, 0.45)
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s

## Tab指示器
static func make_tab_indicator() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.78, 0.38, 0.95)
	s.corner_radius_top_left = 3
	s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3
	s.corner_radius_bottom_right = 3
	return s

## 装备槽位样式
static func make_equip_slot(rarity_color: Color = TXT_DISABLED) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BG_CARD
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = rarity_color
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.05)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_left = 4.0
	s.content_margin_right = 4.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	return s

## 全屏底色
static func make_base_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BG_BASE
	return s
