extends Control
## 暗影深渊 - 专业级暗黑奇幻UI v3
## 核心: StyleBoxFlat.shadow制造发光深度 + 浮动粒子氛围 + 装饰框架

# ==================== 节点引用 ====================
@onready var bg_panel: Panel = $BG
@onready var top_bar: PanelContainer = $SafeArea/VBox/TopBar
@onready var level_label: Label = $SafeArea/VBox/TopBar/Margin/HBox/LevelLabel
@onready var gold_label: Label = $SafeArea/VBox/TopBar/Margin/HBox/GoldLabel
@onready var gold_icon: Label = $SafeArea/VBox/TopBar/Margin/HBox/GoldIcon
@onready var gems_label: Label = $SafeArea/VBox/TopBar/Margin/HBox/GemsLabel
@onready var gem_icon: Label = $SafeArea/VBox/TopBar/Margin/HBox/GemIcon

@onready var content_area: Control = $SafeArea/VBox/ContentArea
@onready var battle_view: Control = $SafeArea/VBox/ContentArea/BattleView
@onready var panel_view: Control = $SafeArea/VBox/ContentArea/PanelView

# 战斗
@onready var enemy_section: PanelContainer = $SafeArea/VBox/ContentArea/BattleView/EnemySection
@onready var zone_label: Label = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/ZoneLabel
@onready var enemy_sprite: Panel = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/EnemySprite
@onready var enemy_icon: TextureRect = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/EnemySprite/EnemyIcon
@onready var enemy_name_label: Label = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/EnemyName
@onready var enemy_hp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/HPRow/EnemyHPBar
@onready var enemy_hp_label: Label = $SafeArea/VBox/ContentArea/BattleView/EnemySection/EnemyMargin/EnemyVBox/HPRow/EnemyHPLabel
@onready var player_section: PanelContainer = $SafeArea/VBox/ContentArea/BattleView/PlayerSection
@onready var player_name_label: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/Row1/PlayerName
@onready var player_hp_text: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/Row1/HPText
@onready var player_hp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/PlayerHPBar
@onready var exp_text: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/Row2/ExpText
@onready var exp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/Row2/ExpBar
@onready var exp_pct: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/Row2/ExpPct
@onready var atk_label: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/StatsBar/Atk
@onready var def_label: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/StatsBar/Def
@onready var crit_label: Label = $SafeArea/VBox/ContentArea/BattleView/PlayerSection/PlayerMargin/PlayerVBox/StatsBar/Crit
@onready var boss_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/BossBtn
@onready var prev_zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/PrevZone
@onready var zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/ZoneBtn
@onready var next_zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/NextZone
@onready var battle_log: RichTextLabel = $SafeArea/VBox/ContentArea/BattleView/BattleLog
@onready var dmg_layer: Control = $SafeArea/VBox/ContentArea/BattleView/DmgLayer

# 面板
@onready var panel_bg: Panel = $SafeArea/VBox/ContentArea/PanelView/PanelBG
@onready var panel_header: PanelContainer = $SafeArea/VBox/ContentArea/PanelView/PanelLayout/Header
@onready var panel_back_btn: Button = $SafeArea/VBox/ContentArea/PanelView/PanelLayout/Header/HBox/BackBtn
@onready var panel_title: Label = $SafeArea/VBox/ContentArea/PanelView/PanelLayout/Header/HBox/Title
@onready var sub_tab_bar: HBoxContainer = $SafeArea/VBox/ContentArea/PanelView/PanelLayout/SubTabBar
@onready var item_list: VBoxContainer = $SafeArea/VBox/ContentArea/PanelView/PanelLayout/Scroll/ListContainer/ListMargin/ItemList

# 底部导航
@onready var bottom_nav: PanelContainer = $SafeArea/VBox/BottomNav
@onready var nav_row: HBoxContainer = $SafeArea/VBox/BottomNav/NavRow
@onready var toast_layer: VBoxContainer = $ToastLayer

# ==================== 子系统 ====================
var craft_system: CraftSystem
var quest_system: QuestSystem

# ==================== 状态 ====================
var current_tab := 0
var current_sub := ""
var _shake_t := 0.0
var _enemy_flash := 0.0
var _prev_ehp := 0
var _prev_php := 0
var _atmo_time := 0.0
var _breath_phase := 0.0
var _particles: Array = []
var _zone_bg: TextureRect = null

# ==================== 色彩方案(产品级暗黑RPG) ====================
const BG_DEEP := Color(0.02, 0.025, 0.055)       # 最深底色
const BG_MAIN := Color(0.035, 0.04, 0.075)       # 主背景
const BG_CARD := Color(0.06, 0.065, 0.11, 0.96)  # 卡片底色
const BG_ELEVATED := Color(0.08, 0.085, 0.14, 0.97) # 浮起面板
const BG_NAV := Color(0.02, 0.022, 0.045, 0.99)  # 导航栏
# 金色系 - 核心装饰色
const GOLD := Color(0.88, 0.72, 0.25)
const GOLD_DIM := Color(0.5, 0.4, 0.12)
const GOLD_GLOW := Color(0.95, 0.8, 0.2, 0.4)   # 发光用
const GOLD_BRIGHT := Color(1.0, 0.88, 0.4)
# 文字
const TXT := Color(0.85, 0.82, 0.76)
const TXT_DIM := Color(0.42, 0.4, 0.36)
const TXT_BRIGHT := Color(1.0, 0.97, 0.92)
# 敌人图片映射(按区域)
const ENEMY_TEXTURES: Array = [
	"res://assets/enemies/shadow_wolf.png",
	"res://assets/enemies/skeleton_warrior.png",
	"res://assets/enemies/fire_demon.png",
	"res://assets/enemies/spider_queen.png",
	"res://assets/enemies/ghost_wraith.png",
	"res://assets/enemies/void_cultist.png",
	"res://assets/enemies/dark_dragon.png",
]
const BOSS_TEXTURE := "res://assets/enemies/dark_dragon.png"
const ZONE_BG_TEXTURES: Array = [
	"res://assets/zones/dark_forest.png",
	"res://assets/zones/lava_cavern.png",
	"res://assets/zones/abyss.png",
]
# 功能色
const RED := Color(0.85, 0.18, 0.1)
const RED_GLOW := Color(0.9, 0.15, 0.05, 0.35)
const GREEN := Color(0.15, 0.75, 0.3)
const BLUE := Color(0.25, 0.4, 0.85)
const PURPLE := Color(0.5, 0.22, 0.7)
const TEAL := Color(0.15, 0.6, 0.55)

# ==================== 初始化 ====================
func _ready() -> void:
	craft_system = CraftSystem.new()
	add_child(craft_system)
	quest_system = QuestSystem.new()
	add_child(quest_system)
	# 创建区域背景层(半透明感觉)
	_zone_bg = TextureRect.new()
	_zone_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zone_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_zone_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_zone_bg.modulate = Color(1, 1, 1, 0.08)
	_zone_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_view.add_child(_zone_bg)
	battle_view.move_child(_zone_bg, 0)
	_apply_theme()
	_connect_all()
	_create_particles()
	_refresh_top()
	_refresh_stats()
	_refresh_zone()
	_highlight_tab()

func _connect_all() -> void:
	for i in range(nav_row.get_child_count()):
		var tab_vbox: VBoxContainer = nav_row.get_child(i)
		var idx: int = i
		tab_vbox.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				_switch_tab(idx))
	boss_btn.pressed.connect(_on_boss)
	prev_zone_btn.pressed.connect(_on_prev_zone)
	next_zone_btn.pressed.connect(_on_next_zone)
	panel_back_btn.pressed.connect(_close_panel)
	GameManager.battle_log.connect(_on_log)
	GameManager.toast_message.connect(_show_toast)
	GameManager.player_level_up.connect(func(_l: int): _shake_t = 0.25; _refresh_stats())
	GameManager.stats_updated.connect(_refresh_stats)
	GameManager.zone_changed.connect(func(_z: int): _refresh_zone())
	GameManager.show_offline_rewards.connect(_show_offline)
	GameManager.item_obtained.connect(func(item: Dictionary):
		if int(item["rarity"]) >= DataManager.Rarity.RARE: _shake_t = 0.15)

func _process(delta: float) -> void:
	if not GameManager.is_loaded:
		return
	_atmo_time += delta
	_breath_phase += delta * 1.5
	if current_tab == 0:
		_update_battle(delta)
		_update_particles(delta)
		# 敌人呼吸脉动(通过modulate微调亮度)
		var pulse: float = 0.92 + sin(_breath_phase) * 0.08
		enemy_sprite.self_modulate = Color(pulse, pulse, pulse + 0.05)
	_refresh_top()
	if _shake_t > 0:
		_shake_t -= delta
		var intensity: float = _shake_t * 6.0
		$SafeArea.position = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	else:
		$SafeArea.position = Vector2.ZERO

# ==================== 粒子系统(大气氛围) ====================
func _create_particles() -> void:
	for i in range(12):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(2, 2)
		p.size = Vector2(2, 2)
		var ps := StyleBoxFlat.new()
		var c: Color = GOLD_DIM if i % 3 == 0 else Color(0.2, 0.25, 0.5, 0.4)
		ps.bg_color = c
		ps.corner_radius_top_left = 1; ps.corner_radius_top_right = 1
		ps.corner_radius_bottom_left = 1; ps.corner_radius_bottom_right = 1
		p.add_theme_stylebox_override("panel", ps)
		p.position = Vector2(randf_range(20, 680), randf_range(50, 500))
		p.modulate.a = randf_range(0.2, 0.5)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dmg_layer.add_child(p)
		_particles.append({"node": p, "speed": randf_range(8, 25), "drift": randf_range(-0.4, 0.4), "base_a": p.modulate.a})

func _update_particles(delta: float) -> void:
	for pd in _particles:
		var node: Panel = pd["node"]
		node.position.y -= pd["speed"] * delta
		node.position.x += pd["drift"]
		node.modulate.a = pd["base_a"] * (0.6 + sin(_atmo_time * 2.0 + node.position.x * 0.01) * 0.4)
		if node.position.y < 30:
			node.position.y = 550
			node.position.x = randf_range(20, 680)

# ==================== 主题(核心: 阴影深度 + 金色发光框) ====================
func _apply_theme() -> void:
	# === 大背景 ===
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = BG_DEEP
	bg_panel.add_theme_stylebox_override("panel", bgs)

	# === 顶栏: 暗底+底部金线+微弱下阴影 ===
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.02, 0.025, 0.05, 0.98)
	ts.border_width_bottom = 1
	ts.border_color = GOLD_DIM
	ts.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	ts.shadow_size = 3
	ts.shadow_offset = Vector2(0, 2)
	top_bar.add_theme_stylebox_override("panel", ts)
	level_label.add_theme_color_override("font_color", GOLD_BRIGHT)
	gold_icon.add_theme_color_override("font_color", GOLD)
	gold_label.add_theme_color_override("font_color", TXT)
	gem_icon.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
	gems_label.add_theme_color_override("font_color", TXT)

	# === 敌人区: 金色装饰边框 + 外发光阴影 ===
	var es := StyleBoxFlat.new()
	es.bg_color = Color(0.025, 0.03, 0.065, 0.96)
	es.corner_radius_top_left = 6; es.corner_radius_top_right = 6
	es.corner_radius_bottom_left = 6; es.corner_radius_bottom_right = 6
	es.border_width_left = 1; es.border_width_right = 1
	es.border_width_top = 1; es.border_width_bottom = 1
	es.border_color = GOLD_DIM
	es.shadow_color = Color(0.4, 0.3, 0.05, 0.25)
	es.shadow_size = 6
	enemy_section.add_theme_stylebox_override("panel", es)

	# 敌人精灵区: 内凹深色 + 内发光
	var sps := StyleBoxFlat.new()
	sps.bg_color = Color(0.015, 0.02, 0.04)
	sps.corner_radius_top_left = 4; sps.corner_radius_top_right = 4
	sps.corner_radius_bottom_left = 4; sps.corner_radius_bottom_right = 4
	sps.border_width_left = 1; sps.border_width_right = 1
	sps.border_width_top = 1; sps.border_width_bottom = 1
	sps.border_color = Color(0.15, 0.12, 0.05, 0.5)
	sps.shadow_color = Color(0.3, 0.2, 0.0, 0.15)
	sps.shadow_size = 4
	enemy_sprite.add_theme_stylebox_override("panel", sps)

	zone_label.add_theme_color_override("font_color", GOLD_DIM)
	enemy_name_label.add_theme_color_override("font_color", RED)
	enemy_hp_label.add_theme_color_override("font_color", TXT_DIM)
	_style_hp_bar(enemy_hp_bar, RED, Color(0.06, 0.02, 0.02))

	# === 玩家区: 蓝色微光边 ===
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.035, 0.07, 0.96)
	ps.corner_radius_top_left = 6; ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 1
	ps.border_color = Color(0.2, 0.25, 0.5, 0.4)
	ps.shadow_color = Color(0.1, 0.15, 0.4, 0.2)
	ps.shadow_size = 5
	player_section.add_theme_stylebox_override("panel", ps)
	player_name_label.add_theme_color_override("font_color", TXT_BRIGHT)
	player_hp_text.add_theme_color_override("font_color", GREEN)
	_style_hp_bar(player_hp_bar, GREEN, Color(0.02, 0.08, 0.03))
	exp_text.add_theme_color_override("font_color", BLUE)
	_style_hp_bar(exp_bar, BLUE, Color(0.02, 0.03, 0.08))
	exp_pct.add_theme_color_override("font_color", TXT_DIM)
	atk_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.2))
	def_label.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
	crit_label.add_theme_color_override("font_color", GOLD)

	# === 按钮: 有深度的3D感 ===
	_style_btn_glow(boss_btn, Color(0.35, 0.08, 0.05), RED_GLOW)
	_style_btn_glow(zone_btn, Color(0.08, 0.06, 0.18), Color(0.2, 0.15, 0.5, 0.2))
	_style_btn_flat(prev_zone_btn, Color(0.05, 0.05, 0.1))
	_style_btn_flat(next_zone_btn, Color(0.05, 0.05, 0.1))
	boss_btn.add_theme_color_override("font_color", TXT_BRIGHT)
	zone_btn.add_theme_color_override("font_color", TXT)
	prev_zone_btn.add_theme_color_override("font_color", TXT_DIM)
	next_zone_btn.add_theme_color_override("font_color", TXT_DIM)
	_style_btn_flat(panel_back_btn, Color(0.05, 0.05, 0.1))

	# === 战斗日志: 加背景面板 ===
	battle_log.add_theme_color_override("default_color", TXT_DIM)
	var log_bg := StyleBoxFlat.new()
	log_bg.bg_color = Color(0.02, 0.025, 0.05, 0.9)
	log_bg.corner_radius_top_left = 4; log_bg.corner_radius_top_right = 4
	log_bg.corner_radius_bottom_left = 4; log_bg.corner_radius_bottom_right = 4
	log_bg.content_margin_left = 8.0; log_bg.content_margin_right = 8.0
	log_bg.content_margin_top = 4.0; log_bg.content_margin_bottom = 4.0
	battle_log.add_theme_stylebox_override("normal", log_bg)

	# === 面板背景 ===
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = BG_MAIN
	panel_bg.add_theme_stylebox_override("panel", pbg)

	# === 面板头: 金色底边+阴影 ===
	var ph := StyleBoxFlat.new()
	ph.bg_color = Color(0.025, 0.03, 0.055, 0.98)
	ph.border_width_bottom = 1
	ph.border_color = GOLD_DIM
	ph.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	ph.shadow_size = 2
	ph.shadow_offset = Vector2(0, 1)
	ph.content_margin_left = 8.0; ph.content_margin_right = 8.0
	panel_header.add_theme_stylebox_override("panel", ph)
	panel_title.add_theme_color_override("font_color", GOLD)
	panel_back_btn.add_theme_color_override("font_color", TXT_DIM)

	# === 底部导航: 最深色+顶部金线+上阴影 ===
	var ns := StyleBoxFlat.new()
	ns.bg_color = BG_NAV
	ns.border_width_top = 1
	ns.border_color = GOLD_DIM
	ns.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	ns.shadow_size = 4
	ns.shadow_offset = Vector2(0, -2)
	ns.content_margin_top = 6.0; ns.content_margin_bottom = 4.0
	bottom_nav.add_theme_stylebox_override("panel", ns)
	for tab_vbox in nav_row.get_children():
		tab_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		for child in tab_vbox.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", TXT_DIM)

# ==================== 样式工具 ====================
func _style_hp_bar(bar: ProgressBar, fill_c: Color, bg_c: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_c
	bg.corner_radius_top_left = 3; bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3; bg.corner_radius_bottom_right = 3
	bg.border_width_left = 1; bg.border_width_right = 1
	bg.border_width_top = 1; bg.border_width_bottom = 1
	bg.border_color = fill_c * 0.3
	bar.add_theme_stylebox_override("background", bg)
	var f := StyleBoxFlat.new()
	f.bg_color = fill_c
	f.corner_radius_top_left = 2; f.corner_radius_top_right = 2
	f.corner_radius_bottom_left = 2; f.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", f)

func _style_btn_glow(btn: Button, bg_c: Color, glow_c: Color) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg_c
	n.corner_radius_top_left = 5; n.corner_radius_top_right = 5
	n.corner_radius_bottom_left = 5; n.corner_radius_bottom_right = 5
	n.border_width_left = 1; n.border_width_right = 1
	n.border_width_top = 1; n.border_width_bottom = 1
	n.border_color = glow_c
	n.shadow_color = glow_c
	n.shadow_size = 4
	n.content_margin_left = 10.0; n.content_margin_right = 10.0
	n.content_margin_top = 6.0; n.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = bg_c * 1.3
	h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = bg_c * 0.6
	p.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", p)

func _style_btn_flat(btn: Button, bg_c: Color) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg_c
	n.corner_radius_top_left = 4; n.corner_radius_top_right = 4
	n.corner_radius_bottom_left = 4; n.corner_radius_bottom_right = 4
	n.content_margin_left = 8.0; n.content_margin_right = 8.0
	n.content_margin_top = 4.0; n.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = bg_c * 1.4
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = bg_c * 0.6
	btn.add_theme_stylebox_override("pressed", p)

func _highlight_tab() -> void:
	for i in range(nav_row.get_child_count()):
		var tab_vbox: VBoxContainer = nav_row.get_child(i)
		var active: bool = (i == current_tab)
		# 移除旧指示条
		var to_remove: Array = []
		for child in tab_vbox.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", GOLD_BRIGHT if active else TXT_DIM)
				if child.name == "Icon":
					child.add_theme_font_size_override("font_size", 20 if active else 18)
			if child.name == "Indicator":
				to_remove.append(child)
		for old in to_remove:
			old.free()
		# 给激活Tab加发光指示条
		if active:
			var ind := Panel.new()
			ind.name = "Indicator"
			ind.custom_minimum_size = Vector2(28, 3)
			ind.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var ind_s := StyleBoxFlat.new()
			ind_s.bg_color = GOLD
			ind_s.corner_radius_top_left = 2; ind_s.corner_radius_top_right = 2
			ind_s.corner_radius_bottom_left = 2; ind_s.corner_radius_bottom_right = 2
			ind_s.shadow_color = GOLD_GLOW
			ind_s.shadow_size = 4
			ind.add_theme_stylebox_override("panel", ind_s)
			tab_vbox.add_child(ind)

# ==================== 标签切换 ====================
func _switch_tab(t: int) -> void:
	current_tab = t
	_highlight_tab()
	AudioManager.play_sfx("button")
	match t:
		0:
			battle_view.visible = true
			panel_view.visible = false
		1: _open_panel("角色", ["装备", "技能", "天赋", "宠物"], "装备")
		2: _open_panel("冒险", ["区域", "深渊塔"], "区域")
		3: _open_panel("工坊", ["锻造", "强化"], "锻造")
		4: _open_panel("更多", ["任务", "每日", "商店", "成就"], "任务")

func _open_panel(title: String, tabs: Array, default_sub: String) -> void:
	panel_title.text = title
	battle_view.visible = false
	panel_view.visible = true
	for c in sub_tab_bar.get_children():
		c.queue_free()
	for tab_name in tabs:
		var btn := Button.new()
		btn.text = tab_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 12)
		var tn: String = tab_name
		btn.pressed.connect(func(): _on_sub(tn))
		sub_tab_bar.add_child(btn)
	_on_sub(default_sub)

func _close_panel() -> void:
	current_tab = 0
	battle_view.visible = true
	panel_view.visible = false
	_highlight_tab()
	AudioManager.play_sfx("button")

func _on_sub(sub_name: String) -> void:
	current_sub = sub_name
	for btn in sub_tab_bar.get_children():
		if btn is Button:
			if btn.text == sub_name:
				_style_btn_glow(btn, Color(0.18, 0.14, 0.04), GOLD_GLOW)
				btn.add_theme_color_override("font_color", GOLD)
			else:
				_style_btn_flat(btn, Color(0.04, 0.04, 0.08))
				btn.add_theme_color_override("font_color", TXT_DIM)
	for c in item_list.get_children():
		c.queue_free()
	match sub_name:
		"装备": _build_equipment()
		"技能": _build_skills()
		"天赋": _build_talents()
		"宠物": _build_pets()
		"区域": _build_zones()
		"深渊塔": _build_tower()
		"锻造": _build_craft()
		"强化": _build_enhance()
		"任务": _build_quests()
		"每日": _build_daily()
		"商店": _build_shop()
		"成就": _build_achievements()

# ==================== 战斗界面 ====================
func _update_battle(delta: float) -> void:
	if GameManager.enemy_max_hp > 0:
		enemy_hp_bar.max_value = GameManager.enemy_max_hp
		enemy_hp_bar.value = maxi(0, GameManager.enemy_hp)
		enemy_hp_label.text = "%d/%d" % [maxi(0, GameManager.enemy_hp), GameManager.enemy_max_hp]
	if GameManager.is_boss_fight:
		enemy_name_label.text = "💀 %s" % GameManager.current_boss.get("name", "Boss")
		enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.05))
		var boss_tex: Texture2D = load(BOSS_TEXTURE)
		if boss_tex:
			enemy_icon.texture = boss_tex
	else:
		enemy_name_label.text = GameManager.current_enemy.get("name", "")
		enemy_name_label.add_theme_color_override("font_color", RED)
		var zi: int = GameManager.game_data["zone"]["current"]
		var tex_path: String = ENEMY_TEXTURES[zi % ENEMY_TEXTURES.size()]
		var tex: Texture2D = load(tex_path)
		if tex:
			enemy_icon.texture = tex
	# 伤害浮字
	if GameManager.enemy_hp < _prev_ehp and _prev_ehp > 0:
		var dmg: int = _prev_ehp - GameManager.enemy_hp
		_float_dmg(str(dmg), GOLD_BRIGHT if dmg > 50 else GOLD, true, dmg > 100)
		_enemy_flash = 1.0
	if GameManager.player_hp < _prev_php and _prev_php > 0:
		_float_dmg(str(_prev_php - GameManager.player_hp), RED, false, false)
	_prev_ehp = GameManager.enemy_hp
	_prev_php = GameManager.player_hp
	# 敌人闪白
	if _enemy_flash > 0:
		_enemy_flash -= delta * 4.0
		enemy_sprite.modulate = Color(1, 1, 1).lerp(Color(2.0, 0.6, 0.6), clampf(_enemy_flash, 0, 1))
	else:
		enemy_sprite.modulate = Color(1, 1, 1)
	# 玩家信息
	var combat: Dictionary = GameManager.game_data["combat"]
	player_hp_bar.max_value = combat["max_hp"]
	player_hp_bar.value = GameManager.player_hp
	player_hp_text.text = "%d/%d" % [GameManager.player_hp, combat["max_hp"]]
	var p: Dictionary = GameManager.game_data["player"]
	var need: int = DataManager.exp_for_level(int(p["level"]))
	exp_bar.max_value = need
	exp_bar.value = int(p["exp"])
	exp_pct.text = "%.0f%%" % (float(p["exp"]) / float(maxi(1, need)) * 100.0)
	exp_text.text = "EXP"

func _float_dmg(text: String, color: Color, top: bool, big: bool) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22 if big else (16 if top else 13))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(randf_range(100, 380), 50 if top else 320)
	dmg_layer.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	if big:
		tw.tween_property(l, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.1)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)

func _refresh_top() -> void:
	var d: Dictionary = GameManager.game_data
	level_label.text = "Lv.%d" % d["player"]["level"]
	gold_label.text = _fmt(int(d["player"]["gold"]))
	gems_label.text = str(d["player"]["gems"])

func _refresh_stats() -> void:
	var c: Dictionary = GameManager.game_data["combat"]
	atk_label.text = "⚔ %d" % c["atk"]
	def_label.text = "🛡 %d" % c["def"]
	crit_label.text = "✦ %d%%" % c["crit"]

func _refresh_zone() -> void:
	var zi: int = GameManager.game_data["zone"]["current"]
	var z: Dictionary = DataManager.ZONES[zi]
	zone_label.text = "━━ %s ━━" % z["name"]
	zone_btn.text = "%s Lv.%d" % [z["name"], z["min_lv"]]
	# 更新区域背景图
	if _zone_bg:
		var bg_path: String = ZONE_BG_TEXTURES[zi % ZONE_BG_TEXTURES.size()]
		var bg_tex: Texture2D = load(bg_path)
		if bg_tex:
			_zone_bg.texture = bg_tex

# ==================== 面板构建 ====================
func _build_equipment() -> void:
	var d: Dictionary = GameManager.game_data
	_section_header("已装备")
	for sk in d["equipment"]:
		var item = d["equipment"][sk]
		var si: int = int(sk)
		var sn: String = DataManager.SLOT_NAMES[si as DataManager.SlotType]
		item_list.add_child(_card_equip(sn, item, si))
	_section_header("背包 (%d/%d)" % [d["inventory"].size(), int(d["inventory_max"])])
	if d["inventory"].is_empty():
		_hint_text("击杀怪物获取装备掉落")
	for item in d["inventory"]:
		item_list.add_child(_card_bag(item))

func _build_skills() -> void:
	var d: Dictionary = GameManager.game_data
	var plv: int = int(d["player"]["level"])
	var eq: Array = d.get("skills", {}).get("equipped", [])
	_section_header("技能栏 %d/4" % eq.size())
	for sid in SkillSystem.SKILLS:
		var sk: Dictionary = SkillSystem.SKILLS[sid]
		if int(sk["unlock_lv"]) > plv + 5:
			continue
		var lv: int = int(d.get("skills", {}).get("levels", {}).get(sid, 0))
		item_list.add_child(_card_skill(sid, sk, lv, plv, eq))

func _build_talents() -> void:
	var d: Dictionary = GameManager.game_data
	var tp: int = int(d.get("talent_points", 0))
	_section_header("天赋点: %d" % tp)
	for tid in SkillSystem.TALENT_TREES:
		var tree: Dictionary = SkillSystem.TALENT_TREES[tid]
		var h := Label.new()
		h.text = "◆ %s" % tree["name"]
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_font_size_override("font_size", 12)
		h.add_theme_color_override("font_color", tree["color"])
		item_list.add_child(h)
		for talent in tree["talents"]:
			item_list.add_child(_card_talent(talent, d, tp))

func _build_pets() -> void:
	var d: Dictionary = GameManager.game_data
	var pd: Dictionary = d.get("pets", {"owned": {}, "active": ""})
	var ap: String = pd.get("active", "")
	var owned: Dictionary = pd.get("owned", {})
	if owned.is_empty():
		_section_header("暂无宠物")
		_hint_text("击杀敌人有几率获得")
		return
	_section_header("出战: %s" % (PetSystem.PETS[ap]["name"] if PetSystem.PETS.has(ap) else "无"))
	for pid in owned:
		if PetSystem.PETS.has(pid):
			item_list.add_child(_card_pet(pid, owned[pid], ap))

func _build_zones() -> void:
	var d: Dictionary = GameManager.game_data
	var cur: int = int(d["zone"]["current"])
	var unl: int = int(d["zone"]["unlocked"])
	_section_header("区域探索")
	for i in range(unl + 1):
		item_list.add_child(_card_zone(i, DataManager.ZONES[i], i == cur))

func _build_tower() -> void:
	var d: Dictionary = GameManager.game_data
	var td: Dictionary = d.get("tower", {"best_floor": 0, "attempts_today": 0})
	var best: int = int(td.get("best_floor", 0))
	var att: int = int(td.get("attempts_today", 0))
	_section_header("深渊塔 · 最高%d层 · %d/5次" % [best, att])
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 48)
	if att < 5:
		_style_btn_glow(btn, Color(0.15, 0.06, 0.25), Color(0.4, 0.2, 0.6, 0.3))
		btn.text = "⚡ 挑战第%d层" % (best + 1)
		btn.add_theme_color_override("font_color", TXT_BRIGHT)
		btn.pressed.connect(func():
			var ts_ref: TowerSystem = GameManager.tower_system
			var r: Dictionary = ts_ref.start_challenge()
			if r.get("started", false): ts_ref.simulate_tower_run()
			_on_sub("深渊塔"))
	else:
		_style_btn_flat(btn, Color(0.03, 0.03, 0.06))
		btn.text = "今日已用完"
		btn.disabled = true
	item_list.add_child(btn)

func _build_craft() -> void:
	var plv: int = int(GameManager.game_data["player"]["level"])
	_section_header("锻造台")
	for r in DataManager.RECIPES:
		if int(r["min_lv"]) > plv + 10:
			continue
		item_list.add_child(_card_craft(r))

func _build_enhance() -> void:
	var d: Dictionary = GameManager.game_data
	_section_header("选择装备强化")
	for sk in d["equipment"]:
		var item = d["equipment"][sk]
		if item != null:
			item_list.add_child(_card_enhance(item))

func _build_quests() -> void:
	_section_header("主线任务")
	for q in DataManager.QUESTS:
		item_list.add_child(_card_quest(q))

func _build_daily() -> void:
	var d: Dictionary = GameManager.game_data
	var daily: Dictionary = d["daily"]
	_section_header("签到 (连续%d天)" % daily["login_streak"])
	if not daily["today_claimed"]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		_style_btn_glow(btn, Color(0.05, 0.18, 0.08), Color(0.1, 0.5, 0.2, 0.3))
		btn.text = "✦ 领取今日签到"
		btn.add_theme_color_override("font_color", GREEN)
		btn.pressed.connect(func(): quest_system.claim_login_reward(); _on_sub("每日"))
		item_list.add_child(btn)
	else:
		_hint_text("✓ 今日已签到")
	_section_header("每日任务")
	for i in range(daily["tasks"].size()):
		item_list.add_child(_card_daily(daily["tasks"][i], i))

func _build_shop() -> void:
	_section_header("商店")
	for si in DataManager.SHOP_ITEMS:
		item_list.add_child(_card_shop(si))

func _build_achievements() -> void:
	var d: Dictionary = GameManager.game_data
	var ach_sys: AchievementSystem = GameManager.achievement_system
	var rc: int = int(d.get("rebirth", {}).get("count", 0))
	_section_header("转生 (第%d世)" % rc)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	if ach_sys.can_rebirth():
		_style_btn_glow(btn, Color(0.2, 0.06, 0.28), Color(0.5, 0.2, 0.7, 0.3))
		btn.text = "✦ 执行转生 Lv.%d → Lv.1" % int(d["player"]["level"])
		btn.add_theme_color_override("font_color", GOLD_BRIGHT)
		btn.pressed.connect(func(): ach_sys.do_rebirth(); _on_sub("成就"))
	else:
		_style_btn_flat(btn, Color(0.03, 0.03, 0.06))
		btn.text = "需 Lv.50 (当前%d)" % int(d["player"]["level"])
		btn.disabled = true
	item_list.add_child(btn)
	_section_header("成就列表")
	var claimed: Array = d.get("achievements", {}).get("claimed", [])
	for ach in AchievementSystem.ACHIEVEMENTS:
		item_list.add_child(_card_ach(ach, claimed))

# ==================== 卡片工厂(左侧色条+阴影=深度) ====================
func _make_card(accent_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = BG_CARD
	s.corner_radius_top_left = 5; s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5; s.corner_radius_bottom_right = 5
	s.border_width_left = 3
	s.border_width_right = 0; s.border_width_top = 0; s.border_width_bottom = 0
	s.border_color = accent_color
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 3
	s.shadow_offset = Vector2(1, 2)
	s.content_margin_left = 14.0; s.content_margin_right = 12.0
	s.content_margin_top = 10.0; s.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", s)
	return card

func _card_equip(slot: String, item, slot_i: int) -> PanelContainer:
	var accent: Color = TXT_DIM
	if item != null:
		var ri2: Dictionary = DataManager.RARITY_INFO[item["rarity"] as DataManager.Rarity]
		accent = ri2["color"]
	var card := _make_card(accent)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if item == null:
		var l := Label.new()
		l.text = "[%s] 空位" % slot
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", TXT_DIM)
		info.add_child(l)
	else:
		var ri: Dictionary = DataManager.RARITY_INFO[item["rarity"] as DataManager.Rarity]
		var nl := Label.new()
		var enh: int = int(item.get("enhance_level", 0))
		nl.text = "[%s] %s%s" % [slot, item["name"], " +%d" % enh if enh > 0 else ""]
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", ri["color"])
		info.add_child(nl)
		var ub := Button.new()
		_style_btn_flat(ub, Color(0.06, 0.04, 0.08))
		ub.text = "卸下"
		ub.add_theme_font_size_override("font_size", 10)
		ub.add_theme_color_override("font_color", TXT_DIM)
		var si: int = slot_i
		ub.pressed.connect(func(): GameManager.unequip_item(si); _on_sub("装备"))
		hbox.add_child(ub)
	hbox.add_child(info)
	hbox.move_child(info, 0)
	return card

func _card_bag(item: Dictionary) -> PanelContainer:
	var ri: Dictionary = DataManager.RARITY_INFO[item["rarity"] as DataManager.Rarity]
	var card := _make_card(ri["color"])
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s [%s]" % [item["name"], ri["name"]]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", ri["color"])
	hbox.add_child(l)
	var eb := Button.new()
	_style_btn_glow(eb, Color(0.04, 0.1, 0.05), Color(0.1, 0.4, 0.15, 0.3))
	eb.text = "装备"
	eb.add_theme_font_size_override("font_size", 10)
	eb.add_theme_color_override("font_color", GREEN)
	var ir: Dictionary = item
	eb.pressed.connect(func(): GameManager.equip_item(ir); _on_sub("装备"))
	hbox.add_child(eb)
	var sb := Button.new()
	_style_btn_flat(sb, Color(0.08, 0.06, 0.03))
	sb.text = "售"
	sb.add_theme_font_size_override("font_size", 10)
	sb.add_theme_color_override("font_color", GOLD_DIM)
	sb.pressed.connect(func(): GameManager.sell_item(ir); _on_sub("装备"))
	hbox.add_child(sb)
	return card

func _card_skill(sid: String, sk: Dictionary, lv: int, plv: int, eq: Array) -> PanelContainer:
	var card := _make_card(sk["color"] if lv > 0 else TXT_DIM)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s Lv.%d" % [sk["name"], lv]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", sk["color"] if lv > 0 else TXT_DIM)
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s · CD:%.1fs" % [sk["type"], sk["cooldown"]]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", TXT_DIM)
	info.add_child(dl)
	hbox.add_child(info)
	var ss: SkillSystem = GameManager.skill_system
	if plv >= int(sk["unlock_lv"]):
		if lv < int(sk["max_lv"]):
			var ub := Button.new()
			_style_btn_glow(ub, Color(0.1, 0.08, 0.02), GOLD_GLOW)
			ub.text = "升级"
			ub.add_theme_font_size_override("font_size", 10)
			ub.add_theme_color_override("font_color", GOLD)
			var s: String = sid
			ub.pressed.connect(func(): ss.upgrade_skill(s); _on_sub("技能"))
			hbox.add_child(ub)
		if lv > 0:
			var eb := Button.new()
			var is_eq: bool = sid in eq
			if is_eq:
				_style_btn_glow(eb, Color(0.12, 0.1, 0.02), GOLD_GLOW)
			else:
				_style_btn_flat(eb, Color(0.04, 0.04, 0.08))
			eb.text = "卸" if is_eq else "装"
			eb.add_theme_font_size_override("font_size", 10)
			eb.add_theme_color_override("font_color", GOLD if is_eq else TXT_DIM)
			var s2: String = sid
			if is_eq:
				eb.pressed.connect(func(): ss.unequip_skill(s2); _on_sub("技能"))
			else:
				eb.pressed.connect(func(): ss.equip_skill(s2); _on_sub("技能"))
			hbox.add_child(eb)
	return card

func _card_talent(t: Dictionary, d: Dictionary, tp: int) -> PanelContainer:
	var tid: String = t["id"]
	var cur: int = int(d.get("talents", {}).get(tid, 0))
	var card := _make_card(GREEN if cur > 0 else TXT_DIM)
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s (%d/%d)" % [t["name"], cur, t["max"]]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", GREEN if cur > 0 else TXT_DIM)
	hbox.add_child(l)
	if cur < int(t["max"]) and tp > 0:
		var btn := Button.new()
		_style_btn_glow(btn, Color(0.04, 0.12, 0.05), Color(0.1, 0.4, 0.15, 0.3))
		btn.text = "+"
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", GREEN)
		var ss: SkillSystem = GameManager.skill_system
		var t2: String = tid
		btn.pressed.connect(func(): ss.learn_talent(t2); _on_sub("天赋"))
		hbox.add_child(btn)
	return card

func _card_pet(pid: String, pd: Dictionary, ap: String) -> PanelContainer:
	var pet: Dictionary = PetSystem.PETS[pid]
	var active: bool = (pid == ap)
	var card := _make_card(pet["color"] if active else TXT_DIM)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s Lv.%d%s" % [pet["name"], int(pd.get("level", 1)), " ★" if active else ""]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", pet["color"])
	info.add_child(nl)
	hbox.add_child(info)
	var ps2: PetSystem = GameManager.pet_system
	var ub := Button.new()
	_style_btn_glow(ub, Color(0.1, 0.08, 0.02), GOLD_GLOW)
	ub.text = "升级"
	ub.add_theme_font_size_override("font_size", 10)
	ub.add_theme_color_override("font_color", GOLD)
	var p2: String = pid
	ub.pressed.connect(func(): ps2.level_up_pet(p2); _on_sub("宠物"))
	hbox.add_child(ub)
	if not active:
		var sb := Button.new()
		_style_btn_glow(sb, Color(0.03, 0.1, 0.06), Color(0.1, 0.4, 0.2, 0.3))
		sb.text = "出战"
		sb.add_theme_font_size_override("font_size", 10)
		sb.add_theme_color_override("font_color", GREEN)
		var p3: String = pid
		sb.pressed.connect(func(): GameManager.game_data["pets"]["active"] = p3; _on_sub("宠物"))
		hbox.add_child(sb)
	return card

func _card_zone(idx: int, z: Dictionary, is_cur: bool) -> PanelContainer:
	var card := _make_card(GOLD if is_cur else Color(0.2, 0.2, 0.35, 0.4))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s%s (Lv.%d-%d)" % ["▶ " if is_cur else "", z["name"], z["min_lv"], z["max_lv"]]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", GOLD if is_cur else TXT)
	hbox.add_child(l)
	if not is_cur:
		var btn := Button.new()
		_style_btn_glow(btn, Color(0.06, 0.04, 0.14), Color(0.3, 0.2, 0.6, 0.25))
		btn.text = "前往"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", PURPLE)
		var i: int = idx
		btn.pressed.connect(func(): GameManager.change_zone(i); _on_sub("区域"))
		hbox.add_child(btn)
	return card

func _card_craft(recipe: Dictionary) -> PanelContainer:
	var can: Dictionary = craft_system.can_craft(recipe)
	var card := _make_card(PURPLE if can["ok"] else TXT_DIM)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	var hbox := HBoxContainer.new()
	var nl := Label.new()
	nl.text = recipe["name"]
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", GOLD if can["ok"] else TXT_DIM)
	hbox.add_child(nl)
	var btn := Button.new()
	if can["ok"]:
		_style_btn_glow(btn, Color(0.12, 0.06, 0.2), Color(0.4, 0.2, 0.6, 0.3))
	else:
		_style_btn_flat(btn, Color(0.03, 0.03, 0.06))
	btn.text = "锻造"
	btn.disabled = not can["ok"]
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", PURPLE if can["ok"] else TXT_DIM)
	var r: Dictionary = recipe
	btn.pressed.connect(func(): craft_system.do_craft(r); _on_sub("锻造"))
	hbox.add_child(btn)
	vbox.add_child(hbox)
	var rl := Label.new()
	var rt := "💰%d" % recipe["gold"]
	for mid in recipe["materials"]:
		var mi: Dictionary = DataManager.MATERIALS[mid]
		rt += " %s %d/%d" % [mi["name"], GameManager.game_data["materials"].get(mid, 0), recipe["materials"][mid]]
	rl.text = rt
	rl.add_theme_font_size_override("font_size", 9)
	rl.add_theme_color_override("font_color", TXT_DIM)
	vbox.add_child(rl)
	return card

func _card_enhance(item: Dictionary) -> PanelContainer:
	var ri: Dictionary = DataManager.RARITY_INFO[item["rarity"] as DataManager.Rarity]
	var card := _make_card(ri["color"])
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	var elv: int = int(item.get("enhance_level", 0))
	var nl := Label.new()
	nl.text = "%s%s" % [item["name"], " +%d" % elv if elv > 0 else ""]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", ri["color"])
	vbox.add_child(nl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var es: EnhanceSystem = GameManager.enhance_system
	if elv < EnhanceSystem.MAX_ENHANCE_LEVEL:
		var rate: float = EnhanceSystem.ENHANCE_SUCCESS_RATES[elv] * 100.0
		var eb := Button.new()
		_style_btn_glow(eb, Color(0.1, 0.08, 0.02), GOLD_GLOW)
		eb.text = "+%d (%.0f%%)" % [elv + 1, rate]
		eb.add_theme_font_size_override("font_size", 10)
		eb.add_theme_color_override("font_color", GOLD)
		var ir: Dictionary = item
		eb.pressed.connect(func(): es.enhance_item(ir); _on_sub("强化"))
		row.add_child(eb)
	var ench: String = item.get("enchant", "")
	if ench.is_empty():
		var ecb := Button.new()
		_style_btn_glow(ecb, Color(0.08, 0.04, 0.14), Color(0.4, 0.2, 0.6, 0.25))
		ecb.text = "附魔"
		ecb.add_theme_font_size_override("font_size", 10)
		ecb.add_theme_color_override("font_color", PURPLE)
		var ir2: Dictionary = item
		ecb.pressed.connect(func(): es.enchant_item(ir2); _on_sub("强化"))
		row.add_child(ecb)
	vbox.add_child(row)
	return card

func _card_quest(q: Dictionary) -> PanelContainer:
	var d: Dictionary = GameManager.game_data
	var claimed: bool = q["id"] in d["quests"]["claimed"]
	var prog: int = quest_system.get_quest_progress(q)
	var done: bool = prog >= int(q["target"])
	var card := _make_card(GREEN if claimed else (GOLD if done else TXT_DIM))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = q["name"] + (" ✓" if claimed else "")
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", GREEN if claimed else (GOLD if done else TXT))
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s (%d/%d)" % [q["desc"], mini(prog, int(q["target"])), q["target"]]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", TXT_DIM)
	info.add_child(dl)
	hbox.add_child(info)
	if done and not claimed:
		var btn := Button.new()
		_style_btn_glow(btn, Color(0.04, 0.14, 0.06), Color(0.1, 0.4, 0.15, 0.3))
		btn.text = "领取"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", GREEN)
		var qr: Dictionary = q
		btn.pressed.connect(func(): quest_system.claim_quest(qr); _on_sub("任务"))
		hbox.add_child(btn)
	return card

func _card_daily(task: Dictionary, idx: int) -> PanelContainer:
	var prog: int = quest_system.get_daily_progress(task)
	var done: bool = prog >= int(task["target"])
	var card := _make_card(GREEN if task["claimed"] else (GOLD if done else TXT_DIM))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s (%d/%d)%s" % [task["name"], mini(prog, int(task["target"])), task["target"], " ✓" if task["claimed"] else ""]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", GREEN if task["claimed"] else (GOLD if done else TXT))
	hbox.add_child(l)
	if done and not task["claimed"]:
		var btn := Button.new()
		_style_btn_glow(btn, Color(0.04, 0.14, 0.06), Color(0.1, 0.4, 0.15, 0.3))
		btn.text = "领"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", GREEN)
		var ti: int = idx
		btn.pressed.connect(func(): quest_system.claim_daily_task(ti); _on_sub("每日"))
		hbox.add_child(btn)
	return card

func _card_shop(si: Dictionary) -> PanelContainer:
	var card := _make_card(GOLD_DIM)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	var l := Label.new()
	l.text = si["name"]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", TXT)
	hbox.add_child(l)
	var cl := Label.new()
	cl.text = "%s%d" % ["💰" if si["currency"] == "gold" else "💎", si["cost"]]
	cl.add_theme_font_size_override("font_size", 10)
	cl.add_theme_color_override("font_color", GOLD if si["currency"] == "gold" else Color(0.45, 0.75, 1.0))
	hbox.add_child(cl)
	var btn := Button.new()
	_style_btn_glow(btn, Color(0.06, 0.05, 0.12), Color(0.2, 0.15, 0.4, 0.25))
	btn.text = "购买"
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", TXT)
	var ref: Dictionary = si
	btn.pressed.connect(func(): quest_system.buy_shop_item(ref); _on_sub("商店"))
	hbox.add_child(btn)
	return card

func _card_ach(ach: Dictionary, claimed: Array) -> PanelContainer:
	var is_claimed: bool = ach["id"] in claimed
	var asys: AchievementSystem = GameManager.achievement_system
	var prog: int = asys.get_achievement_progress(ach)
	var tgt: int = int(ach["target"])
	var done: bool = prog >= tgt
	var card := _make_card(GOLD if is_claimed else (GOLD_DIM if done else TXT_DIM))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s%s" % [ach["name"], " ✓" if is_claimed else ""]
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color", GOLD if is_claimed else (GOLD_DIM if done else TXT_DIM))
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s (%d/%d) 💎%d" % [ach["desc"], mini(prog, tgt), tgt, int(ach["reward"].get("gems", 0))]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", TXT_DIM)
	info.add_child(dl)
	hbox.add_child(info)
	if done and not is_claimed:
		var btn := Button.new()
		_style_btn_glow(btn, Color(0.1, 0.08, 0.02), GOLD_GLOW)
		btn.text = "领"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", GOLD)
		var aid: String = ach["id"]
		btn.pressed.connect(func(): asys.claim_achievement(aid); _on_sub("成就"))
		hbox.add_child(btn)
	return card

# ==================== 辅助 ====================
func _section_header(text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var left := Label.new()
	left.text = "━━"
	left.add_theme_font_size_override("font_size", 10)
	left.add_theme_color_override("font_color", GOLD_DIM)
	hbox.add_child(left)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", GOLD)
	hbox.add_child(l)
	var right := Label.new()
	right.text = "━━"
	right.add_theme_font_size_override("font_size", 10)
	right.add_theme_color_override("font_color", GOLD_DIM)
	hbox.add_child(right)
	item_list.add_child(hbox)

func _hint_text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", TXT_DIM)
	item_list.add_child(l)

func _on_boss() -> void:
	GameManager.start_boss_fight()
	_shake_t = 0.35
	AudioManager.play_sfx("boss")

func _on_prev_zone() -> void:
	var c: int = GameManager.game_data["zone"]["current"]
	if c > 0:
		GameManager.change_zone(c - 1)
		_refresh_zone()
		AudioManager.play_sfx("button")

func _on_next_zone() -> void:
	var c: int = GameManager.game_data["zone"]["current"]
	if c < int(GameManager.game_data["zone"]["unlocked"]):
		GameManager.change_zone(c + 1)
		_refresh_zone()
		AudioManager.play_sfx("button")

func _on_log(msg: String, col: Color) -> void:
	battle_log.append_text("[color=#%s]%s[/color]\n" % [col.to_html(false), msg])

func _show_toast(text: String, col: Color) -> void:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.025, 0.03, 0.06, 0.96)
	s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_color = GOLD_DIM
	s.shadow_color = Color(0.3, 0.25, 0.05, 0.3)
	s.shadow_size = 5
	s.content_margin_left = 16.0; s.content_margin_right = 16.0
	s.content_margin_top = 10.0; s.content_margin_bottom = 10.0
	pc.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 12)
	pc.add_child(l)
	toast_layer.add_child(pc)
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 0.0, 1.2).set_delay(1.8)
	tw.tween_callback(pc.queue_free)

func _show_offline(rewards: Dictionary) -> void:
	var h := int(rewards["elapsed"] / 3600)
	var m := int(fmod(rewards["elapsed"], 3600.0) / 60)
	_show_toast("离线%d时%d分 击杀:%d 💰+%s" % [h, m, rewards["kills"], _fmt(int(rewards["gold"]))], GOLD)

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
