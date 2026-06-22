extends Control
## 暗影深渊 - 二次元精致温暖风 UI v4
## 风格: 明日方舟/原神式温暖色调 | 左右对战布局 | 纵向路线图

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

# 战斗 - 新左右对战
@onready var zone_banner: PanelContainer = $SafeArea/VBox/ContentArea/BattleView/ZoneBanner
@onready var zone_label: Label = $SafeArea/VBox/ContentArea/BattleView/ZoneBanner/ZoneLabel
@onready var battle_arena: Control = $SafeArea/VBox/ContentArea/BattleView/BattleArena
@onready var zone_bg: TextureRect = $SafeArea/VBox/ContentArea/BattleView/BattleArena/ZoneBG
@onready var player_sprite: TextureRect = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerSprite
@onready var vs_label: Label = $SafeArea/VBox/ContentArea/BattleView/BattleArena/VSLabel
@onready var enemy_sprite: TextureRect = $SafeArea/VBox/ContentArea/BattleView/BattleArena/EnemySprite
@onready var effect_layer: Control = $SafeArea/VBox/ContentArea/BattleView/BattleArena/EffectLayer

@onready var player_name_label: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/PlayerHPRow/PlayerName
@onready var player_hp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/HPSection/PlayerHPRow/PlayerHPBar
@onready var player_hp_label: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/PlayerHPRow/PlayerHPLabel
@onready var enemy_name_label: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/EnemyHPRow/EnemyName
@onready var enemy_hp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/HPSection/EnemyHPRow/EnemyHPBar
@onready var enemy_hp_label: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/EnemyHPRow/EnemyHPLabel
@onready var exp_text: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpText
@onready var exp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpBar
@onready var exp_pct: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpPct

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
var _prev_ehp := 0
var _prev_php := 0
var _idle_phase := 0.0
var _atk_anim_playing := false

# ==================== 图片资源路径 ====================
const PLAYER_TEXTURE := "res://assets/characters/player_idle.png"
const NAV_ICONS: Array = [
	"res://assets/ui/icons/nav_battle.png",
	"res://assets/ui/icons/nav_character.png",
	"res://assets/ui/icons/nav_adventure.png",
	"res://assets/ui/icons/nav_workshop.png",
	"res://assets/ui/icons/nav_more.png",
]
const ENEMY_TEXTURES: Array = [
	"res://assets/enemies/shadow_wolf_v2.png",
	"res://assets/enemies/skeleton_v2.png",
	"res://assets/enemies/demon_v2.png",
	"res://assets/enemies/shadow_wolf_v2.png",
	"res://assets/enemies/skeleton_v2.png",
	"res://assets/enemies/demon_v2.png",
	"res://assets/enemies/shadow_wolf_v2.png",
	"res://assets/enemies/skeleton_v2.png",
	"res://assets/enemies/demon_v2.png",
	"res://assets/enemies/shadow_wolf_v2.png",
]
const ZONE_BG_TEXTURES: Array = [
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/forest_v2.png",
]

# ==================== 初始化 ====================
func _ready() -> void:
	craft_system = CraftSystem.new()
	add_child(craft_system)
	quest_system = QuestSystem.new()
	add_child(quest_system)
	_apply_theme()
	_load_nav_icons()
	_load_player_sprite()
	_connect_all()
	_refresh_top()
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
	GameManager.player_level_up.connect(func(_l: int): _shake_t = 0.25; _refresh_top())
	GameManager.stats_updated.connect(func(): _refresh_top())
	GameManager.zone_changed.connect(func(_z: int): _refresh_zone())
	GameManager.show_offline_rewards.connect(_show_offline)
	GameManager.item_obtained.connect(func(item: Dictionary):
		if int(item["rarity"]) >= DataManager.Rarity.RARE: _shake_t = 0.15)

func _process(delta: float) -> void:
	if not GameManager.is_loaded:
		return
	if current_tab == 0:
		_update_battle(delta)
		_idle_animation(delta)
	_refresh_top()
	if _shake_t > 0:
		_shake_t -= delta
		var intensity: float = _shake_t * 5.0
		$SafeArea.position = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	else:
		$SafeArea.position = Vector2.ZERO

# ==================== 主题应用(温暖二次元风) ====================
func _apply_theme() -> void:
	# 大背景 - 米白
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = ThemeConfig.BG_BASE
	bg_panel.add_theme_stylebox_override("panel", bgs)

	# 顶栏 - 浅奶油色+底部微影
	var ts := ThemeConfig.make_header_bg()
	top_bar.add_theme_stylebox_override("panel", ts)
	level_label.add_theme_color_override("font_color", ThemeConfig.PRIMARY)
	gold_icon.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	gold_label.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	gem_icon.add_theme_color_override("font_color", ThemeConfig.SECONDARY)
	gems_label.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)

	# 区域横幅 - 半透明圆角卡片
	var zbs := StyleBoxFlat.new()
	zbs.bg_color = Color(1.0, 1.0, 1.0, 0.85)
	zbs.corner_radius_top_left = 16
	zbs.corner_radius_top_right = 16
	zbs.corner_radius_bottom_left = 16
	zbs.corner_radius_bottom_right = 16
	zbs.shadow_color = Color(0, 0, 0, 0.05)
	zbs.shadow_size = 3
	zbs.shadow_offset = Vector2(0, 1)
	zone_banner.add_theme_stylebox_override("panel", zbs)
	zone_label.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)

	# VS标签
	vs_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_ORANGE)

	# HP条样式
	_style_hp_bar(player_hp_bar, ThemeConfig.HP_GREEN)
	_style_hp_bar(enemy_hp_bar, ThemeConfig.ENEMY_RED)
	_style_hp_bar(exp_bar, ThemeConfig.EXP_BLUE)
	player_name_label.add_theme_color_override("font_color", ThemeConfig.SECONDARY)
	player_hp_label.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	enemy_name_label.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
	enemy_hp_label.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	exp_text.add_theme_color_override("font_color", ThemeConfig.EXP_BLUE)
	exp_pct.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)

	# 按钮
	_style_btn_primary(boss_btn)
	_style_btn_outline(zone_btn, ThemeConfig.SECONDARY)
	_style_btn_light(prev_zone_btn)
	_style_btn_light(next_zone_btn)
	boss_btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
	zone_btn.add_theme_color_override("font_color", ThemeConfig.SECONDARY)
	prev_zone_btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	next_zone_btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)

	# 战斗日志
	battle_log.add_theme_color_override("default_color", ThemeConfig.TXT_SECONDARY)
	var log_bg := StyleBoxFlat.new()
	log_bg.bg_color = Color(1.0, 1.0, 1.0, 0.7)
	log_bg.corner_radius_top_left = 8
	log_bg.corner_radius_top_right = 8
	log_bg.corner_radius_bottom_left = 8
	log_bg.corner_radius_bottom_right = 8
	log_bg.content_margin_left = 10.0
	log_bg.content_margin_right = 10.0
	log_bg.content_margin_top = 6.0
	log_bg.content_margin_bottom = 6.0
	battle_log.add_theme_stylebox_override("normal", log_bg)

	# 面板背景
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = ThemeConfig.BG_BASE
	panel_bg.add_theme_stylebox_override("panel", pbg)

	# 面板头
	var ph := ThemeConfig.make_header_bg()
	panel_header.add_theme_stylebox_override("panel", ph)
	panel_title.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	panel_back_btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	_style_btn_light(panel_back_btn)

	# 底部导航
	var ns := ThemeConfig.make_nav_bg()
	bottom_nav.add_theme_stylebox_override("panel", ns)
	for tab_vbox in nav_row.get_children():
		tab_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		for child in tab_vbox.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)

func _load_nav_icons() -> void:
	for i in range(nav_row.get_child_count()):
		var tab_vbox: VBoxContainer = nav_row.get_child(i)
		var icon_rect: TextureRect = tab_vbox.get_child(0)
		if i < NAV_ICONS.size():
			var tex: Texture2D = load(NAV_ICONS[i])
			if tex:
				icon_rect.texture = tex

func _load_player_sprite() -> void:
	var tex: Texture2D = load(PLAYER_TEXTURE)
	if tex:
		player_sprite.texture = tex

# ==================== 样式工具 ====================
func _style_hp_bar(bar: ProgressBar, fill_c: Color) -> void:
	var bg := ThemeConfig.make_bar_bg()
	bar.add_theme_stylebox_override("background", bg)
	var f := ThemeConfig.make_bar_fill(fill_c)
	bar.add_theme_stylebox_override("fill", f)

func _style_btn_primary(btn: Button) -> void:
	var n := ThemeConfig.make_btn_primary()
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = ThemeConfig.PRIMARY_LIGHT
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = ThemeConfig.PRIMARY_DARK
	btn.add_theme_stylebox_override("pressed", p)

func _style_btn_outline(btn: Button, color: Color) -> void:
	var n := ThemeConfig.make_btn_outline(color)
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(color.r, color.g, color.b, 0.15)
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(color.r, color.g, color.b, 0.25)
	btn.add_theme_stylebox_override("pressed", p)

func _style_btn_light(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.94, 0.92, 0.88, 0.6)
	n.corner_radius_top_left = 12
	n.corner_radius_top_right = 12
	n.corner_radius_bottom_left = 12
	n.corner_radius_bottom_right = 12
	n.content_margin_left = 10.0
	n.content_margin_right = 10.0
	n.content_margin_top = 6.0
	n.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(0.92, 0.90, 0.85, 0.8)
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(0.88, 0.86, 0.82, 0.9)
	btn.add_theme_stylebox_override("pressed", p)

func _highlight_tab() -> void:
	for i in range(nav_row.get_child_count()):
		var tab_vbox: VBoxContainer = nav_row.get_child(i)
		var active: bool = (i == current_tab)
		var to_remove: Array = []
		for child in tab_vbox.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", ThemeConfig.PRIMARY if active else ThemeConfig.TXT_DISABLED)
			if child is TextureRect:
				child.modulate = Color(1, 1, 1, 1.0) if active else Color(1, 1, 1, 0.45)
			if child.name == "Indicator":
				to_remove.append(child)
		for old in to_remove:
			old.free()
		if active:
			var ind := Panel.new()
			ind.name = "Indicator"
			ind.custom_minimum_size = Vector2(24, 3)
			ind.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var ind_s := ThemeConfig.make_tab_indicator()
			ind.add_theme_stylebox_override("panel", ind_s)
			tab_vbox.add_child(ind)

# ==================== 对战动画系统 ====================
func _idle_animation(delta: float) -> void:
	if _atk_anim_playing:
		return
	_idle_phase += delta * 2.0
	player_sprite.position.y += sin(_idle_phase) * 0.3
	enemy_sprite.position.y += sin(_idle_phase * 0.85 + 1.0) * 0.3

func _play_player_attack() -> void:
	if _atk_anim_playing:
		return
	_atk_anim_playing = true
	var orig_x: float = player_sprite.position.x
	var tw := create_tween()
	tw.tween_property(player_sprite, "position:x", orig_x + 30, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(player_sprite, "position:x", orig_x, 0.15).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _atk_anim_playing = false)
	_shake_enemy()
	_spawn_slash()

func _play_enemy_attack() -> void:
	if _atk_anim_playing:
		return
	_atk_anim_playing = true
	var orig_x: float = enemy_sprite.position.x
	var tw := create_tween()
	tw.tween_property(enemy_sprite, "position:x", orig_x - 30, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(enemy_sprite, "position:x", orig_x, 0.15).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _atk_anim_playing = false)
	_shake_player()

func _shake_enemy() -> void:
	var orig := enemy_sprite.position
	var tw := create_tween()
	for n in range(4):
		tw.tween_property(enemy_sprite, "position", orig + Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.03)
	tw.tween_property(enemy_sprite, "position", orig, 0.04)

func _shake_player() -> void:
	var orig := player_sprite.position
	var tw := create_tween()
	for n in range(4):
		tw.tween_property(player_sprite, "position", orig + Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.03)
	tw.tween_property(player_sprite, "position", orig, 0.04)

func _spawn_slash() -> void:
	var slash := Label.new()
	slash.text = "✦"
	slash.add_theme_font_size_override("font_size", 32)
	slash.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	slash.position = Vector2(effect_layer.size.x * 0.5 - 10, effect_layer.size.y * 0.4)
	slash.modulate.a = 0.9
	effect_layer.add_child(slash)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(slash, "scale", Vector2(2.0, 2.0), 0.2)
	tw.tween_property(slash, "modulate:a", 0.0, 0.35)
	tw.tween_property(slash, "rotation", 0.8, 0.35)
	tw.set_parallel(false)
	tw.tween_callback(slash.queue_free)

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
		2: _open_panel("冒险", ["路线图", "深渊塔"], "路线图")
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
				_style_btn_primary(btn)
				btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
			else:
				_style_btn_light(btn)
				btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	for c in item_list.get_children():
		c.queue_free()
	match sub_name:
		"装备": _build_equipment()
		"技能": _build_skills()
		"天赋": _build_talents()
		"宠物": _build_pets()
		"路线图": _build_route_map()
		"深渊塔": _build_tower()
		"锻造": _build_craft()
		"强化": _build_enhance()
		"任务": _build_quests()
		"每日": _build_daily()
		"商店": _build_shop()
		"成就": _build_achievements()

# ==================== 战斗界面更新 ====================
func _update_battle(_delta: float) -> void:
	if GameManager.enemy_max_hp > 0:
		enemy_hp_bar.max_value = GameManager.enemy_max_hp
		enemy_hp_bar.value = maxi(0, GameManager.enemy_hp)
		enemy_hp_label.text = "%d/%d" % [maxi(0, GameManager.enemy_hp), GameManager.enemy_max_hp]
	if GameManager.is_boss_fight:
		enemy_name_label.text = "💀 %s" % GameManager.current_boss.get("name", "Boss")
	else:
		enemy_name_label.text = GameManager.current_enemy.get("name", "")
	# 加载敌人贴图
	var zi: int = GameManager.game_data["zone"]["current"]
	var tex_path: String = ENEMY_TEXTURES[zi % ENEMY_TEXTURES.size()]
	var tex: Texture2D = load(tex_path)
	if tex and enemy_sprite.texture != tex:
		enemy_sprite.texture = tex
	# 伤害浮字 + 攻击动画
	if GameManager.enemy_hp < _prev_ehp and _prev_ehp > 0:
		var dmg: int = _prev_ehp - GameManager.enemy_hp
		_float_dmg(str(dmg), ThemeConfig.ACCENT_ORANGE if dmg > 50 else ThemeConfig.TXT_PRIMARY, true, dmg > 100)
		_play_player_attack()
	if GameManager.player_hp < _prev_php and _prev_php > 0:
		var dmg2: int = _prev_php - GameManager.player_hp
		_float_dmg(str(dmg2), ThemeConfig.ENEMY_RED, false, false)
		_play_enemy_attack()
	_prev_ehp = GameManager.enemy_hp
	_prev_php = GameManager.player_hp
	# 玩家信息
	var combat: Dictionary = GameManager.game_data["combat"]
	player_hp_bar.max_value = combat["max_hp"]
	player_hp_bar.value = GameManager.player_hp
	player_hp_label.text = "%d/%d" % [GameManager.player_hp, combat["max_hp"]]
	player_name_label.text = "Lv.%d" % GameManager.game_data["player"]["level"]
	var p: Dictionary = GameManager.game_data["player"]
	var need: int = DataManager.exp_for_level(int(p["level"]))
	exp_bar.max_value = need
	exp_bar.value = int(p["exp"])
	exp_pct.text = "%.0f%%" % (float(p["exp"]) / float(maxi(1, need)) * 100.0)

func _float_dmg(text: String, color: Color, is_enemy: bool, big: bool) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20 if big else 14)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 伤害从对应角色头顶飘出
	if is_enemy:
		l.position = Vector2(dmg_layer.size.x * 0.7 + randf_range(-30, 30), dmg_layer.size.y * 0.15)
	else:
		l.position = Vector2(dmg_layer.size.x * 0.2 + randf_range(-30, 30), dmg_layer.size.y * 0.15)
	dmg_layer.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 40.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.2)
	if big:
		tw.tween_property(l, "scale", Vector2(1.4, 1.4), 0.08)
		tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.08)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)

func _refresh_top() -> void:
	var d: Dictionary = GameManager.game_data
	level_label.text = "Lv.%d" % d["player"]["level"]
	gold_label.text = _fmt(int(d["player"]["gold"]))
	gems_label.text = str(d["player"]["gems"])

func _refresh_zone() -> void:
	var zi: int = GameManager.game_data["zone"]["current"]
	var z: Dictionary = DataManager.ZONES[zi]
	zone_label.text = "%s" % z["name"]
	zone_btn.text = "%s Lv.%d" % [z["name"], z["min_lv"]]
	# 更新区域背景
	var bg_path: String = ZONE_BG_TEXTURES[zi % ZONE_BG_TEXTURES.size()]
	var bg_tex: Texture2D = load(bg_path)
	if bg_tex:
		zone_bg.texture = bg_tex


# ==================== 路线图系统(纵向分支) ====================
func _build_route_map() -> void:
	var d: Dictionary = GameManager.game_data
	var cur: int = int(d["zone"]["current"])
	var unl: int = int(d["zone"]["unlocked"])
	_section_header("冒险路线")
	# 从上到下显示各区域(当前→已解锁→锁定)
	for i in range(mini(unl + 2, DataManager.ZONES.size()) - 1, -1, -1):
		var z: Dictionary = DataManager.ZONES[i]
		var is_cur: bool = (i == cur)
		var locked: bool = (i > unl)
		var card := _make_card(ThemeConfig.PRIMARY if is_cur else (ThemeConfig.TXT_DISABLED if locked else ThemeConfig.SECONDARY))
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)
		# 标题行
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 8)
		var stage_label := Label.new()
		stage_label.text = "%s %s" % ["▶" if is_cur else ("🔒" if locked else "●"), z["name"]]
		stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_label.add_theme_font_size_override("font_size", 13)
		if locked:
			stage_label.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
		elif is_cur:
			stage_label.add_theme_color_override("font_color", ThemeConfig.PRIMARY)
		else:
			stage_label.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
		hrow.add_child(stage_label)
		var lv_label := Label.new()
		lv_label.text = "Lv.%d-%d" % [z["min_lv"], z["max_lv"]]
		lv_label.add_theme_font_size_override("font_size", 10)
		lv_label.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
		hrow.add_child(lv_label)
		vbox.add_child(hrow)
		# 节点行(模拟路线节点)
		if not locked:
			var node_row := HBoxContainer.new()
			node_row.add_theme_constant_override("separation", 6)
			var enemies: Array = z["enemies"]
			for ei in range(mini(enemies.size(), 4)):
				var node_btn := Button.new()
				node_btn.text = "⚔ %s" % enemies[ei]
				node_btn.add_theme_font_size_override("font_size", 9)
				_style_btn_light(node_btn)
				node_btn.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
				node_row.add_child(node_btn)
			vbox.add_child(node_row)
			# Boss节点
			var boss_row := HBoxContainer.new()
			boss_row.add_theme_constant_override("separation", 8)
			var boss_btn2 := Button.new()
			boss_btn2.text = "💀 %s" % z["boss"]["name"]
			boss_btn2.add_theme_font_size_override("font_size", 10)
			_style_btn_outline(boss_btn2, ThemeConfig.ENEMY_RED)
			boss_btn2.add_theme_color_override("font_color", ThemeConfig.ENEMY_RED)
			boss_row.add_child(boss_btn2)
			vbox.add_child(boss_row)
		# 前往按钮
		if not locked and not is_cur:
			var go_btn := Button.new()
			go_btn.text = "前往"
			go_btn.add_theme_font_size_override("font_size", 11)
			_style_btn_primary(go_btn)
			go_btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
			go_btn.custom_minimum_size = Vector2(80, 32)
			var zi2: int = i
			go_btn.pressed.connect(func(): GameManager.change_zone(zi2); _on_sub("路线图"))
			vbox.add_child(go_btn)
		item_list.add_child(card)
		# 连接线(视觉)
		if i > 0:
			var conn := Label.new()
			conn.text = "│"
			conn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			conn.add_theme_font_size_override("font_size", 14)
			conn.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
			item_list.add_child(conn)

# ==================== 角色概览 ====================
func _build_character_overview(d: Dictionary) -> void:
	var combat: Dictionary = d["combat"]
	var player: Dictionary = d["player"]
	# 角色信息卡片
	var card := _make_card(ThemeConfig.PRIMARY)
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	card.add_child(main_vbox)
	# 名字+等级
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	var name_l := Label.new()
	name_l.text = "⚔ 暗影行者"
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_l)
	var lv_l := Label.new()
	lv_l.text = "Lv.%d" % int(player["level"])
	lv_l.add_theme_font_size_override("font_size", 14)
	lv_l.add_theme_color_override("font_color", ThemeConfig.PRIMARY)
	name_row.add_child(lv_l)
	main_vbox.add_child(name_row)
	# 属性网格 (2列)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	var stats: Array = [
		{"label": "⚔ 攻击", "value": str(combat["atk"]), "color": ThemeConfig.ACCENT_ORANGE},
		{"label": "🛡 防御", "value": str(combat["def"]), "color": ThemeConfig.SECONDARY},
		{"label": "❤ 生命", "value": str(combat["max_hp"]), "color": ThemeConfig.HP_GREEN},
		{"label": "✦ 暴击", "value": "%d%%" % combat["crit"], "color": ThemeConfig.ACCENT_GOLD},
		{"label": "✚ 回复", "value": str(combat["hp_regen"]), "color": ThemeConfig.ACCENT_GREEN},
		{"label": "♦ 吸血", "value": "%d%%" % combat["lifesteal"], "color": ThemeConfig.ENEMY_RED},
	]
	for s in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var sl := Label.new()
		sl.text = s["label"]
		sl.add_theme_font_size_override("font_size", 11)
		sl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
		row.add_child(sl)
		var vl := Label.new()
		vl.text = s["value"]
		vl.add_theme_font_size_override("font_size", 12)
		vl.add_theme_color_override("font_color", s["color"])
		row.add_child(vl)
		grid.add_child(row)
	main_vbox.add_child(grid)
	item_list.add_child(card)

# ==================== 面板构建 ====================
func _build_equipment() -> void:
	var d: Dictionary = GameManager.game_data
	# 角色概览卡片
	_build_character_overview(d)
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

func _build_tower() -> void:
	var d: Dictionary = GameManager.game_data
	var td: Dictionary = d.get("tower", {"best_floor": 0, "attempts_today": 0})
	var best: int = int(td.get("best_floor", 0))
	var att: int = int(td.get("attempts_today", 0))
	_section_header("深渊塔 · 最高%d层 · %d/5次" % [best, att])
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	if att < 5:
		_style_btn_primary(btn)
		btn.text = "⚡ 挑战第%d层" % (best + 1)
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
		btn.pressed.connect(func():
			var ts_ref: TowerSystem = GameManager.tower_system
			var r: Dictionary = ts_ref.start_challenge()
			if r.get("started", false): ts_ref.simulate_tower_run()
			_on_sub("深渊塔"))
	else:
		_style_btn_light(btn)
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
		btn.custom_minimum_size = Vector2(0, 42)
		_style_btn_primary(btn)
		btn.text = "✦ 领取今日签到"
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
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
	btn.custom_minimum_size = Vector2(0, 42)
	if ach_sys.can_rebirth():
		_style_btn_outline(btn, ThemeConfig.ACCENT_PURPLE)
		btn.text = "✦ 执行转生 Lv.%d → Lv.1" % int(d["player"]["level"])
		btn.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE)
		btn.pressed.connect(func(): ach_sys.do_rebirth(); _on_sub("成就"))
	else:
		_style_btn_light(btn)
		btn.text = "需 Lv.50 (当前%d)" % int(d["player"]["level"])
		btn.disabled = true
	item_list.add_child(btn)
	_section_header("成就列表")
	var claimed: Array = d.get("achievements", {}).get("claimed", [])
	for ach in AchievementSystem.ACHIEVEMENTS:
		item_list.add_child(_card_ach(ach, claimed))

# ==================== 卡片工厂(圆角+柔和阴影) ====================
func _make_card(accent_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var s := ThemeConfig.make_card(accent_color)
	card.add_theme_stylebox_override("panel", s)
	return card

func _card_equip(slot: String, item, slot_i: int) -> PanelContainer:
	var accent: Color = ThemeConfig.TXT_DISABLED
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
		l.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
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
		_style_btn_light(ub)
		ub.text = "卸下"
		ub.add_theme_font_size_override("font_size", 10)
		ub.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
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
	_style_btn_primary(eb)
	eb.text = "装备"
	eb.add_theme_font_size_override("font_size", 10)
	eb.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
	var ir: Dictionary = item
	eb.pressed.connect(func(): GameManager.equip_item(ir); _on_sub("装备"))
	hbox.add_child(eb)
	var sb := Button.new()
	_style_btn_light(sb)
	sb.text = "售"
	sb.add_theme_font_size_override("font_size", 10)
	sb.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	sb.pressed.connect(func(): GameManager.sell_item(ir); _on_sub("装备"))
	hbox.add_child(sb)
	return card

func _card_skill(sid: String, sk: Dictionary, lv: int, plv: int, eq: Array) -> PanelContainer:
	var card := _make_card(sk["color"] if lv > 0 else ThemeConfig.TXT_DISABLED)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s Lv.%d" % [sk["name"], lv]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", sk["color"] if lv > 0 else ThemeConfig.TXT_DISABLED)
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s · CD:%.1fs" % [sk["type"], sk["cooldown"]]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(dl)
	hbox.add_child(info)
	var ss: SkillSystem = GameManager.skill_system
	if plv >= int(sk["unlock_lv"]):
		if lv < int(sk["max_lv"]):
			var ub := Button.new()
			_style_btn_outline(ub, ThemeConfig.ACCENT_GOLD)
			ub.text = "升级"
			ub.add_theme_font_size_override("font_size", 10)
			ub.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
			var s: String = sid
			ub.pressed.connect(func(): ss.upgrade_skill(s); _on_sub("技能"))
			hbox.add_child(ub)
		if lv > 0:
			var eb := Button.new()
			var is_eq: bool = sid in eq
			if is_eq:
				_style_btn_primary(eb)
				eb.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
			else:
				_style_btn_light(eb)
				eb.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
			eb.text = "卸" if is_eq else "装"
			eb.add_theme_font_size_override("font_size", 10)
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
	var card := _make_card(ThemeConfig.ACCENT_GREEN if cur > 0 else ThemeConfig.TXT_DISABLED)
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s (%d/%d)" % [t["name"], cur, t["max"]]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN if cur > 0 else ThemeConfig.TXT_DISABLED)
	hbox.add_child(l)
	if cur < int(t["max"]) and tp > 0:
		var btn := Button.new()
		_style_btn_primary(btn)
		btn.text = "+"
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
		var ss: SkillSystem = GameManager.skill_system
		var t2: String = tid
		btn.pressed.connect(func(): ss.learn_talent(t2); _on_sub("天赋"))
		hbox.add_child(btn)
	return card

func _card_pet(pid: String, pd: Dictionary, ap: String) -> PanelContainer:
	var pet: Dictionary = PetSystem.PETS[pid]
	var active: bool = (pid == ap)
	var card := _make_card(pet["color"] if active else ThemeConfig.TXT_DISABLED)
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
	_style_btn_outline(ub, ThemeConfig.ACCENT_GOLD)
	ub.text = "升级"
	ub.add_theme_font_size_override("font_size", 10)
	ub.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	var p2: String = pid
	ub.pressed.connect(func(): ps2.level_up_pet(p2); _on_sub("宠物"))
	hbox.add_child(ub)
	if not active:
		var sb := Button.new()
		_style_btn_primary(sb)
		sb.text = "出战"
		sb.add_theme_font_size_override("font_size", 10)
		sb.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
		var p3: String = pid
		sb.pressed.connect(func(): GameManager.game_data["pets"]["active"] = p3; _on_sub("宠物"))
		hbox.add_child(sb)
	return card

func _card_craft(recipe: Dictionary) -> PanelContainer:
	var can: Dictionary = craft_system.can_craft(recipe)
	var card := _make_card(ThemeConfig.ACCENT_PURPLE if can["ok"] else ThemeConfig.TXT_DISABLED)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	var hbox := HBoxContainer.new()
	var nl := Label.new()
	nl.text = recipe["name"]
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE if can["ok"] else ThemeConfig.TXT_DISABLED)
	hbox.add_child(nl)
	var btn := Button.new()
	if can["ok"]:
		_style_btn_outline(btn, ThemeConfig.ACCENT_PURPLE)
		btn.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE)
	else:
		_style_btn_light(btn)
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
	btn.text = "锻造"
	btn.disabled = not can["ok"]
	btn.add_theme_font_size_override("font_size", 10)
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
	rl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
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
		_style_btn_outline(eb, ThemeConfig.ACCENT_GOLD)
		eb.text = "+%d (%.0f%%)" % [elv + 1, rate]
		eb.add_theme_font_size_override("font_size", 10)
		eb.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
		var ir: Dictionary = item
		eb.pressed.connect(func(): es.enhance_item(ir); _on_sub("强化"))
		row.add_child(eb)
	var ench: String = item.get("enchant", "")
	if ench.is_empty():
		var ecb := Button.new()
		_style_btn_outline(ecb, ThemeConfig.ACCENT_PURPLE)
		ecb.text = "附魔"
		ecb.add_theme_font_size_override("font_size", 10)
		ecb.add_theme_color_override("font_color", ThemeConfig.ACCENT_PURPLE)
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
	var card := _make_card(ThemeConfig.ACCENT_GREEN if claimed else (ThemeConfig.ACCENT_GOLD if done else ThemeConfig.TXT_DISABLED))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = q["name"] + (" ✓" if claimed else "")
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN if claimed else (ThemeConfig.ACCENT_GOLD if done else ThemeConfig.TXT_PRIMARY))
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s (%d/%d)" % [q["desc"], mini(prog, int(q["target"])), q["target"]]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(dl)
	hbox.add_child(info)
	if done and not claimed:
		var btn := Button.new()
		_style_btn_primary(btn)
		btn.text = "领取"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
		var qr: Dictionary = q
		btn.pressed.connect(func(): quest_system.claim_quest(qr); _on_sub("任务"))
		hbox.add_child(btn)
	return card

func _card_daily(task: Dictionary, idx: int) -> PanelContainer:
	var prog: int = quest_system.get_daily_progress(task)
	var done: bool = prog >= int(task["target"])
	var card := _make_card(ThemeConfig.ACCENT_GREEN if task["claimed"] else (ThemeConfig.ACCENT_GOLD if done else ThemeConfig.TXT_DISABLED))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var l := Label.new()
	l.text = "%s (%d/%d)%s" % [task["name"], mini(prog, int(task["target"])), task["target"], " ✓" if task["claimed"] else ""]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", ThemeConfig.ACCENT_GREEN if task["claimed"] else (ThemeConfig.ACCENT_GOLD if done else ThemeConfig.TXT_PRIMARY))
	hbox.add_child(l)
	if done and not task["claimed"]:
		var btn := Button.new()
		_style_btn_primary(btn)
		btn.text = "领"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
		var ti: int = idx
		btn.pressed.connect(func(): quest_system.claim_daily_task(ti); _on_sub("每日"))
		hbox.add_child(btn)
	return card

func _card_shop(si: Dictionary) -> PanelContainer:
	var card := _make_card(ThemeConfig.ACCENT_GOLD)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	var l := Label.new()
	l.text = si["name"]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	hbox.add_child(l)
	var cl := Label.new()
	cl.text = "%s%d" % ["💰" if si["currency"] == "gold" else "💎", si["cost"]]
	cl.add_theme_font_size_override("font_size", 10)
	cl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD if si["currency"] == "gold" else ThemeConfig.SECONDARY)
	hbox.add_child(cl)
	var btn := Button.new()
	_style_btn_outline(btn, ThemeConfig.SECONDARY)
	btn.text = "购买"
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", ThemeConfig.SECONDARY)
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
	var card := _make_card(ThemeConfig.ACCENT_GOLD if is_claimed else (ThemeConfig.ACCENT_ORANGE if done else ThemeConfig.TXT_DISABLED))
	var hbox := HBoxContainer.new()
	card.add_child(hbox)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s%s" % [ach["name"], " ✓" if is_claimed else ""]
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD if is_claimed else (ThemeConfig.ACCENT_ORANGE if done else ThemeConfig.TXT_DISABLED))
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "%s (%d/%d) 💎%d" % [ach["desc"], mini(prog, tgt), tgt, int(ach["reward"].get("gems", 0))]
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(dl)
	hbox.add_child(info)
	if done and not is_claimed:
		var btn := Button.new()
		_style_btn_outline(btn, ThemeConfig.ACCENT_GOLD)
		btn.text = "领"
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
		var aid: String = ach["id"]
		btn.pressed.connect(func(): asys.claim_achievement(aid); _on_sub("成就"))
		hbox.add_child(btn)
	return card

# ==================== 辅助 ====================
func _section_header(text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var left := Label.new()
	left.text = "──"
	left.add_theme_font_size_override("font_size", 10)
	left.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
	hbox.add_child(left)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	hbox.add_child(l)
	var right := Label.new()
	right.text = "──"
	right.add_theme_font_size_override("font_size", 10)
	right.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)
	hbox.add_child(right)
	item_list.add_child(hbox)

func _hint_text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
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
	s.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.shadow_color = Color(0, 0, 0, 0.08)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_left = 20.0
	s.content_margin_right = 20.0
	s.content_margin_top = 12.0
	s.content_margin_bottom = 12.0
	pc.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 12)
	pc.add_child(l)
	toast_layer.add_child(pc)
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 0.0, 1.0).set_delay(2.0)
	tw.tween_callback(pc.queue_free)

func _show_offline(rewards: Dictionary) -> void:
	var h := int(rewards["elapsed"] / 3600)
	var m := int(fmod(rewards["elapsed"], 3600.0) / 60)
	_show_toast("离线%d时%d分 击杀:%d 💰+%s" % [h, m, rewards["kills"], _fmt(int(rewards["gold"]))], ThemeConfig.ACCENT_GOLD)

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
