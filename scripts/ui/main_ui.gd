extends Control
## 暗影深渊 - 二次元精致温暖风 UI v4
## 风格: 明日方舟/原神式温暖色调 | 左右对战布局 | 冒险世界地图

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
@onready var player_visual: PlayerVisual = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerVisual
@onready var vs_label: Label = $SafeArea/VBox/ContentArea/BattleView/BattleArena/VSLabel
@onready var enemy_container: Control = $SafeArea/VBox/ContentArea/BattleView/BattleArena/EnemyContainer
@onready var effect_layer: Control = $SafeArea/VBox/ContentArea/BattleView/BattleArena/EffectLayer
@onready var battle_effects: BattleEffects = $SafeArea/VBox/ContentArea/BattleView/BattleArena/EffectLayer/BattleEffects
@onready var player_info_overlay: VBoxContainer = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerInfoOverlay
@onready var player_avatar: TextureRect = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerInfoOverlay/PlayerInfoRow/Avatar
@onready var overlay_level_label: Label = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerInfoOverlay/PlayerInfoRow/LevelLabel
@onready var player_hp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerInfoOverlay/PlayerHPBar
@onready var player_hp_label: Label = $SafeArea/VBox/ContentArea/BattleView/BattleArena/PlayerInfoOverlay/PlayerHPLabel
@onready var loot_dialog: LootDialog = $LootDialogLayer/LootDialog
@onready var exp_text: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpText
@onready var exp_bar: ProgressBar = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpBar
@onready var exp_pct: Label = $SafeArea/VBox/ContentArea/BattleView/HPSection/ExpRow/ExpPct

@onready var action_row: HBoxContainer = $SafeArea/VBox/ContentArea/BattleView/ActionRow
@onready var boss_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/BossBtn
@onready var prev_zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/PrevZone
@onready var zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/ZoneBtn
@onready var next_zone_btn: Button = $SafeArea/VBox/ContentArea/BattleView/ActionRow/NextZone
@onready var battle_log: RichTextLabel = $SafeArea/VBox/ContentArea/BattleView/BattleArena/BattleLog
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
var _enemy_units: Dictionary = {}
var _boss_unit: BattleEnemyUnit = null
var _spawn_queue: Array = []
var _spawn_delay := 0.0
var _player_atk_anim_playing := false
var _wave_label: Label
var _arena_polish_done := false
var _equip_tooltip: EquipTooltip
var _equip_compare: EquipCompareDialog
const SPAWN_STAGGER := 0.35

func _get_player_sprite() -> TextureRect:
	if player_visual and player_visual.get_body_sprite():
		return player_visual.get_body_sprite()
	return null
# 玩家帧动画路径
const PLAYER_IDLE_FRAMES: Array = [
	"res://assets/sprites/player_idle_1.png",
	"res://assets/sprites/player_idle_2.png",
]
const PLAYER_ATTACK_FRAMES: Array = [
	"res://assets/sprites/player_attack_1.png",
]
# 敌人帧动画路径
const ENEMY_IDLE_FRAMES: Array = [
	"res://assets/sprites/enemy_idle_1.png",
	"res://assets/sprites/enemy_idle_2.png",
]
const ENEMY_ATTACK_FRAMES: Array = [
	"res://assets/sprites/enemy_attack_1.png",
]

# Shader路径
const CHROMA_KEY_SHADER := "res://shaders/chroma_key.gdshader"

# 帧动画缓存
var _player_idle_textures: Array = []
var _player_attack_textures: Array = []
var _enemy_idle_textures: Array = []
var _enemy_attack_textures: Array = []
var _frame_timer := 0.0
var _current_frame := 0
const FRAME_DURATION := 0.4  # 每帧0.4秒
var _player_shader_mat: ShaderMaterial
var _enemy_shader_mat: ShaderMaterial
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
	"res://assets/enemies/demon_v2.png",
	"res://assets/enemies/fallen_angel_v2.png",
	"res://assets/enemies/void_beast_v2.png",
	"res://assets/enemies/fallen_angel_v2.png",
	"res://assets/enemies/demon_v2.png",
	"res://assets/enemies/void_beast_v2.png",
	"res://assets/enemies/shadow_wolf_v2.png",
]
const ZONE_BG_TEXTURES: Array = [
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/tomb_v2.png",
	"res://assets/zones/abyss_v2.png",
	"res://assets/zones/abyss_v2.png",
	"res://assets/zones/tomb_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/abyss_v2.png",
	"res://assets/zones/tomb_v2.png",
	"res://assets/zones/forest_v2.png",
	"res://assets/zones/abyss_v2.png",
]

# ==================== 初始化 ====================
func _ready() -> void:
	craft_system = CraftSystem.new()
	add_child(craft_system)
	quest_system = QuestSystem.new()
	add_child(quest_system)
	_equip_tooltip = EquipTooltip.new()
	panel_view.add_child(_equip_tooltip)
	_equip_compare = EquipCompareDialog.new()
	panel_view.add_child(_equip_compare)
	_equip_compare.equip_confirmed.connect(_on_equip_compare_confirm)
	_apply_theme()
	_setup_battle_arena_polish()
	_load_nav_icons()
	_load_player_sprite()
	_connect_all()
	_connect_battle()
	_refresh_top()
	_refresh_zone()
	_highlight_tab()
	call_deferred("_sync_battle_on_ready")

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
	GameManager.zone_changed.connect(func(_z: int): _refresh_zone(); _clear_enemy_units())
	GameManager.show_offline_rewards.connect(_show_offline)
	GameManager.item_obtained.connect(func(item: Dictionary):
		if int(item["rarity"]) >= DataManager.Rarity.RARE: _shake_t = 0.15)
	GameManager.wave_cleared.connect(_on_wave_cleared)
	loot_dialog.closed.connect(_on_loot_closed)
	GameManager.game_started.connect(_sync_battle_on_ready)

func _sync_battle_on_ready() -> void:
	if not GameManager.is_loaded:
		return
	if GameManager.is_boss_fight:
		_spawn_boss_unit()
		return
	if GameManager.battle_wave.is_wave_active() and _enemy_units.is_empty():
		_on_wave_started(GameManager.battle_wave.wave_enemies.duplicate(true))

func _connect_battle() -> void:
	GameManager.battle_wave.wave_started.connect(_on_wave_started)
	GameManager.battle_wave.enemy_hp_changed.connect(_on_enemy_hp_changed)
	GameManager.battle_wave.enemy_died.connect(_on_enemy_unit_died)
	GameManager.skill_system.skill_cast.connect(_on_skill_cast)
	GameManager.combat_player_hit.connect(_on_combat_player_hit)
	GameManager.combat_enemy_hit.connect(_on_combat_enemy_hit)

func _process(delta: float) -> void:
	if not GameManager.is_loaded:
		return
	if current_tab == 0:
		_update_battle(delta)
		_idle_animation(delta)
		_process_spawn_queue(delta)
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

	# 区域横幅 - 暗色奇幻标题条
	var zbs := StyleBoxFlat.new()
	zbs.bg_color = Color(0.08, 0.06, 0.12, 0.88)
	zbs.corner_radius_top_left = 14
	zbs.corner_radius_top_right = 14
	zbs.corner_radius_bottom_left = 14
	zbs.corner_radius_bottom_right = 14
	zbs.border_width_bottom = 2
	zbs.border_color = Color(0.55, 0.38, 0.62, 0.75)
	zbs.shadow_color = Color(0, 0, 0, 0.25)
	zbs.shadow_size = 4
	zbs.shadow_offset = Vector2(0, 2)
	zone_banner.add_theme_stylebox_override("panel", zbs)
	zone_label.add_theme_color_override("font_color", ThemeConfig.TXT_ON_DARK)
	zone_label.add_theme_font_size_override("font_size", 13)

	# VS标签
	vs_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_ORANGE)

	# HP条样式（玩家头顶 + EXP）
	_style_hp_bar(player_hp_bar, ThemeConfig.HP_GREEN)
	_style_hp_bar(exp_bar, ThemeConfig.EXP_BLUE)
	overlay_level_label.add_theme_color_override("font_color", ThemeConfig.SECONDARY)
	player_hp_label.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	exp_text.add_theme_color_override("font_color", ThemeConfig.EXP_BLUE)
	exp_pct.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)

	# 按钮
	_style_btn_boss(boss_btn)
	_style_btn_zone(zone_btn)
	_style_btn_light(prev_zone_btn)
	_style_btn_light(next_zone_btn)
	boss_btn.add_theme_color_override("font_color", ThemeConfig.TXT_ON_PRIMARY)
	zone_btn.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98))
	prev_zone_btn.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78))
	next_zone_btn.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78))

	# 战斗日志 - 战场底部悬浮条
	battle_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_log.add_theme_color_override("default_color", Color(0.88, 0.86, 0.92, 0.92))
	battle_log.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	battle_log.add_theme_constant_override("shadow_offset_x", 1)
	battle_log.add_theme_constant_override("shadow_offset_y", 1)
	battle_log.add_theme_font_size_override("normal_font_size", 8)
	var log_bg := StyleBoxFlat.new()
	log_bg.bg_color = Color(0.02, 0.02, 0.05, 0.48)
	log_bg.corner_radius_top_left = 6
	log_bg.corner_radius_top_right = 6
	log_bg.corner_radius_bottom_left = 6
	log_bg.corner_radius_bottom_right = 6
	log_bg.border_width_top = 1
	log_bg.border_color = Color(0.35, 0.30, 0.42, 0.35)
	log_bg.content_margin_left = 8.0
	log_bg.content_margin_right = 8.0
	log_bg.content_margin_top = 2.0
	log_bg.content_margin_bottom = 2.0
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
	# LootDialog 样式由 loot_dialog.gd 自行管理
	for tab_vbox in nav_row.get_children():
		tab_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		for child in tab_vbox.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", ThemeConfig.TXT_DISABLED)

func _setup_battle_arena_polish() -> void:
	if _arena_polish_done:
		return
	_arena_polish_done = true
	battle_arena.clip_contents = true
	zone_bg.modulate = Color(1, 1, 1, 0.58)

	var frame := Panel.new()
	frame.name = "ArenaFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.04, 0.03, 0.07, 0.28)
	fs.border_width_left = 2
	fs.border_width_right = 2
	fs.border_width_top = 2
	fs.border_width_bottom = 2
	fs.border_color = Color(0.42, 0.34, 0.55, 0.8)
	fs.corner_radius_top_left = 12
	fs.corner_radius_top_right = 12
	fs.corner_radius_bottom_left = 12
	fs.corner_radius_bottom_right = 12
	frame.add_theme_stylebox_override("panel", fs)
	battle_arena.add_child(frame)
	battle_arena.move_child(frame, 1)

	var ground_grad := ColorRect.new()
	ground_grad.name = "GroundGrad"
	ground_grad.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground_grad.anchor_top = 0.62
	ground_grad.offset_top = 0
	ground_grad.color = Color(0.02, 0.02, 0.04, 0.35)
	ground_grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_arena.add_child(ground_grad)

	var ground_line := ColorRect.new()
	ground_line.name = "GroundLine"
	ground_line.anchor_left = 0.04
	ground_line.anchor_top = BattleLayout.GROUND_Y_RATIO - 0.005
	ground_line.anchor_right = 0.96
	ground_line.anchor_bottom = BattleLayout.GROUND_Y_RATIO + 0.005
	ground_line.offset_left = 0
	ground_line.offset_top = 0
	ground_line.offset_right = 0
	ground_line.offset_bottom = 0
	ground_line.color = Color(0.15, 0.12, 0.2, 0.55)
	ground_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_arena.add_child(ground_line)

	var vig_top := ColorRect.new()
	vig_top.name = "VignetteTop"
	vig_top.anchor_right = 1.0
	vig_top.anchor_bottom = 0.18
	vig_top.color = Color(0, 0, 0, 0.22)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_arena.add_child(vig_top)

	_wave_label = Label.new()
	_wave_label.name = "WaveLabel"
	_wave_label.anchor_left = 0.68
	_wave_label.anchor_top = 0.03
	_wave_label.anchor_right = 0.97
	_wave_label.anchor_bottom = 0.1
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 10)
	_wave_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
	_wave_label.text = ""
	battle_arena.add_child(_wave_label)

	var nameplate := Panel.new()
	nameplate.name = "PlayerNameplate"
	nameplate.anchor_left = 0.01
	nameplate.anchor_top = 0.68
	nameplate.anchor_right = 0.40
	nameplate.anchor_bottom = 0.97
	nameplate.offset_left = 0
	nameplate.offset_top = 0
	nameplate.offset_right = 0
	nameplate.offset_bottom = 0
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nps := StyleBoxFlat.new()
	nps.bg_color = Color(0.05, 0.04, 0.08, 0.72)
	nps.corner_radius_top_left = 8
	nps.corner_radius_top_right = 8
	nps.corner_radius_bottom_left = 8
	nps.corner_radius_bottom_right = 8
	nps.border_width_left = 1
	nps.border_width_right = 1
	nps.border_width_top = 1
	nps.border_width_bottom = 1
	nps.border_color = Color(0.35, 0.55, 0.45, 0.55)
	nameplate.add_theme_stylebox_override("panel", nps)
	battle_arena.add_child(nameplate)
	battle_arena.move_child(nameplate, player_info_overlay.get_index())

	var hp_section: VBoxContainer = battle_view.get_node("HPSection")
	if hp_section and not hp_section.get_node_or_null("ExpBackdrop"):
		var exp_back := Panel.new()
		exp_back.name = "ExpBackdrop"
		exp_back.set_anchors_preset(Control.PRESET_FULL_RECT)
		exp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ebs := StyleBoxFlat.new()
		ebs.bg_color = Color(0.07, 0.06, 0.11, 0.7)
		ebs.corner_radius_top_left = 10
		ebs.corner_radius_top_right = 10
		ebs.corner_radius_bottom_left = 10
		ebs.corner_radius_bottom_right = 10
		ebs.border_width_left = 1
		ebs.border_width_right = 1
		ebs.border_width_top = 1
		ebs.border_width_bottom = 1
		ebs.border_color = Color(0.38, 0.45, 0.62, 0.5)
		exp_back.add_theme_stylebox_override("panel", ebs)
		hp_section.add_child(exp_back)
		hp_section.move_child(exp_back, 0)
	exp_text.add_theme_color_override("font_color", Color(0.65, 0.82, 0.95))

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.06, 0.06, 0.08, 0.92)
	hp_bg.corner_radius_top_left = 4
	hp_bg.corner_radius_top_right = 4
	hp_bg.corner_radius_bottom_left = 4
	hp_bg.corner_radius_bottom_right = 4
	player_hp_bar.add_theme_stylebox_override("background", hp_bg)
	player_hp_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.82))
	overlay_level_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.96))

	if action_row and not action_row.get_node_or_null("RowBackdrop"):
		var row_back := Panel.new()
		row_back.name = "RowBackdrop"
		row_back.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_back.offset_left = -8
		row_back.offset_top = -6
		row_back.offset_right = 8
		row_back.offset_bottom = 6
		row_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rbs := StyleBoxFlat.new()
		rbs.bg_color = Color(0.06, 0.05, 0.09, 0.82)
		rbs.corner_radius_top_left = 12
		rbs.corner_radius_top_right = 12
		rbs.corner_radius_bottom_left = 12
		rbs.corner_radius_bottom_right = 12
		rbs.border_width_left = 1
		rbs.border_width_right = 1
		rbs.border_width_top = 1
		rbs.border_width_bottom = 1
		rbs.border_color = Color(0.35, 0.28, 0.42, 0.6)
		row_back.add_theme_stylebox_override("panel", rbs)
		action_row.add_child(row_back)
		action_row.move_child(row_back, 0)

func _load_nav_icons() -> void:
	for i in range(nav_row.get_child_count()):
		var tab_vbox: VBoxContainer = nav_row.get_child(i)
		var icon_rect: TextureRect = tab_vbox.get_child(0)
		if i < NAV_ICONS.size():
			var tex: Texture2D = load(NAV_ICONS[i])
			if tex:
				icon_rect.texture = tex

func _load_player_sprite() -> void:
	call_deferred("_refresh_player_avatar")

func _refresh_player_avatar() -> void:
	if player_visual:
		var tex: Texture2D = player_visual.get_avatar_texture()
		if tex and player_avatar:
			player_avatar.texture = tex

# ==================== 样式工具 ====================
func _style_hp_bar(bar: ProgressBar, fill_c: Color) -> void:
	var bg := ThemeConfig.make_bar_bg()
	bar.add_theme_stylebox_override("background", bg)
	var f := ThemeConfig.make_bar_fill(fill_c)
	bar.add_theme_stylebox_override("fill", f)

func _style_btn_boss(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.78, 0.24, 0.30)
	n.corner_radius_top_left = 18
	n.corner_radius_top_right = 18
	n.corner_radius_bottom_left = 18
	n.corner_radius_bottom_right = 18
	n.shadow_color = Color(0.4, 0.08, 0.12, 0.35)
	n.shadow_size = 4
	n.shadow_offset = Vector2(0, 2)
	n.content_margin_left = 18.0
	n.content_margin_right = 18.0
	n.content_margin_top = 10.0
	n.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(0.88, 0.32, 0.38)
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(0.62, 0.16, 0.22)
	btn.add_theme_stylebox_override("pressed", p)

func _style_btn_zone(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.10, 0.12, 0.18, 0.88)
	n.corner_radius_top_left = 16
	n.corner_radius_top_right = 16
	n.corner_radius_bottom_left = 16
	n.corner_radius_bottom_right = 16
	n.border_width_left = 1
	n.border_width_right = 1
	n.border_width_top = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.42, 0.55, 0.72, 0.55)
	n.content_margin_left = 14.0
	n.content_margin_right = 14.0
	n.content_margin_top = 8.0
	n.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(0.14, 0.16, 0.24, 0.95)
	btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(0.08, 0.09, 0.14, 0.95)
	btn.add_theme_stylebox_override("pressed", p)

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
				child.add_theme_font_size_override("font_size", 10 if active else 9)
			if child is TextureRect:
				# 选中状态: 完全不透明 + 主色调 + 微放大
				if active:
					child.modulate = Color(1.0, 0.42, 0.54, 1.0)  # 珊瑩粉
					child.custom_minimum_size = Vector2(38, 38)
				else:
					child.modulate = Color(0.6, 0.6, 0.6, 0.5)  # 灰色半透明
					child.custom_minimum_size = Vector2(36, 36)
			if child.name == "Indicator":
				to_remove.append(child)
		for old in to_remove:
			old.free()
		if active:
			var ind := Panel.new()
			ind.name = "Indicator"
			ind.custom_minimum_size = Vector2(28, 3)
			ind.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var ind_s := ThemeConfig.make_tab_indicator()
			ind.add_theme_stylebox_override("panel", ind_s)
			tab_vbox.add_child(ind)

# ==================== 帧动画 + 对战动画系统 ====================
func _idle_animation(delta: float) -> void:
	if _player_atk_anim_playing:
		return
	_frame_timer += delta
	if _frame_timer >= FRAME_DURATION:
		_frame_timer = 0.0
		_current_frame += 1
		if player_visual:
			player_visual.set_idle_frame(_current_frame)
	if player_visual:
		player_visual.apply_idle_motion(_idle_phase)
	_idle_phase += delta * 2.5

func _get_arena_size() -> Vector2:
	var sz: Vector2 = enemy_container.size
	if sz.x < 80.0:
		sz = battle_arena.size
	if sz.x < 80.0:
		sz = Vector2(680, 360)
	return sz

# ---------- 战斗动作：多帧攻击 + 受击反馈 ----------
func _on_combat_player_hit(enemy_id: int) -> void:
	_play_player_attack_on(enemy_id)

func _on_combat_enemy_hit(enemy_id: int) -> void:
	_play_enemy_attack_on(enemy_id)

func _play_player_attack_on(enemy_id: int) -> void:
	if _player_atk_anim_playing or not player_visual:
		return
	_player_atk_anim_playing = true
	var strike_cb := func():
		_spawn_slash_arc()
		if enemy_id >= 0 and _enemy_units.has(enemy_id):
			_enemy_units[enemy_id].play_hit()
		elif enemy_id == -1 and _boss_unit and is_instance_valid(_boss_unit):
			_boss_unit.play_hit()
		_spawn_hit_sparks()
	var finish_cb := func(): _player_atk_anim_playing = false
	player_visual.play_attack_sequence(strike_cb, finish_cb)

func _play_enemy_attack_on(enemy_id: int) -> void:
	var attacker: BattleEnemyUnit = null
	if enemy_id >= 0 and _enemy_units.has(enemy_id):
		attacker = _enemy_units[enemy_id]
	elif enemy_id == -1 and _boss_unit and is_instance_valid(_boss_unit):
		attacker = _boss_unit
	if attacker:
		attacker.play_attack_toward(100)
		_spawn_enemy_claw_slash(attacker)
	if player_visual:
		player_visual.play_hit_reaction()
	# 多只怪同时出手时叠加轻微震屏
	if _enemy_units.size() > 1:
		_shake_t = maxf(_shake_t, 0.06)
	_spawn_enemy_skill_effect()

func _play_player_attack() -> void:
	_play_player_attack_on(GameManager.current_target_id)

func _play_enemy_attack() -> void:
	_play_enemy_attack_on(-1 if GameManager.is_boss_fight else GameManager.current_target_id)

func _spawn_enemy_claw_slash(attacker: BattleEnemyUnit) -> void:
	var slash := Label.new()
	slash.text = "✦"
	slash.add_theme_font_size_override("font_size", 28)
	slash.add_theme_color_override("font_color", Color(0.95, 0.35, 0.30, 0.9))
	slash.position = attacker.position + Vector2(-18, 38)
	slash.z_index = 8
	enemy_container.add_child(slash)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(slash, "position:x", slash.position.x - 22, 0.12)
	tw.tween_property(slash, "modulate:a", 0.0, 0.18)
	tw.tween_property(slash, "scale", Vector2(1.4, 1.4), 0.08)
	tw.set_parallel(false)
	tw.tween_callback(slash.queue_free)

# ---------- 帧动画辅助函数 ----------
func _restore_idle_frames() -> void:
	if player_visual:
		player_visual.restore_idle_frame()

func _flash_player_hit() -> void:
	var ps := _get_player_sprite()
	if not ps:
		return
	var tw := create_tween()
	tw.tween_property(ps, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.03)
	tw.tween_property(ps, "modulate", Color(1, 1, 1, 1), 0.12)

func _shake_player() -> void:
	if not player_visual:
		return
	var orig: Vector2 = player_visual.motion_offset
	var tw := create_tween()
	for n in range(5):
		var offset := Vector2(randf_range(-6, 6), randf_range(-4, 4))
		tw.tween_property(player_visual, "motion_offset", orig + offset, 0.025)
	tw.tween_property(player_visual, "motion_offset", orig, 0.04)

# ---------- 斩击弧光特效(玩家攻击时) ----------
func _spawn_slash_arc() -> void:
	# 主斩击弧线
	var slash := Label.new()
	slash.text = "⚔"
	slash.add_theme_font_size_override("font_size", 48)
	slash.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	slash.position = Vector2(effect_layer.size.x * 0.55, effect_layer.size.y * 0.3)
	slash.pivot_offset = Vector2(24, 24)
	slash.modulate.a = 0.0
	effect_layer.add_child(slash)
	var tw := create_tween()
	tw.tween_property(slash, "modulate:a", 1.0, 0.04)
	tw.parallel().tween_property(slash, "rotation", 1.2, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(slash, "scale", Vector2(1.8, 1.8), 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(slash, "modulate:a", 0.0, 0.2)
	tw.tween_callback(slash.queue_free)
	# 辅助斩痕
	var slash2 := Label.new()
	slash2.text = "╲"
	slash2.add_theme_font_size_override("font_size", 64)
	slash2.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 0.8))
	slash2.position = Vector2(effect_layer.size.x * 0.52, effect_layer.size.y * 0.25)
	slash2.pivot_offset = Vector2(16, 32)
	effect_layer.add_child(slash2)
	var tw2 := create_tween()
	tw2.tween_property(slash2, "scale", Vector2(2.5, 2.5), 0.12).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(slash2, "modulate:a", 0.0, 0.3)
	tw2.tween_callback(slash2.queue_free)

# ---------- 命中火花(玩家攻击时) ----------
func _spawn_hit_sparks() -> void:
	var center := Vector2(effect_layer.size.x * 0.6, effect_layer.size.y * 0.4)
	for i in range(6):
		var spark := Label.new()
		spark.text = ["✦", "✧", "◆", "•"][randi() % 4]
		spark.add_theme_font_size_override("font_size", randi_range(12, 22))
		spark.add_theme_color_override("font_color", [ThemeConfig.ACCENT_GOLD, ThemeConfig.PRIMARY, Color(1, 0.8, 0.3)][randi() % 3])
		spark.position = center
		spark.modulate.a = 1.0
		effect_layer.add_child(spark)
		var angle := randf() * TAU
		var dist := randf_range(30, 70)
		var target_pos := center + Vector2(cos(angle) * dist, sin(angle) * dist)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", target_pos, 0.25).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 0.0, 0.35)
		tw.tween_property(spark, "scale", Vector2(0.3, 0.3), 0.35)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)

# ---------- 敌人技能特效(魔法圈+冲击波) ----------
func _spawn_enemy_skill_effect() -> void:
	# 魔法圈
	var circle := Label.new()
	circle.text = "◎"
	circle.add_theme_font_size_override("font_size", 56)
	circle.add_theme_color_override("font_color", Color(0.9, 0.2, 0.3, 0.9))
	circle.position = Vector2(effect_layer.size.x * 0.25, effect_layer.size.y * 0.35)
	circle.pivot_offset = Vector2(28, 28)
	circle.scale = Vector2(0.3, 0.3)
	effect_layer.add_child(circle)
	var tw := create_tween()
	tw.tween_property(circle, "scale", Vector2(2.2, 2.2), 0.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(circle, "rotation", TAU, 0.4)
	tw.parallel().tween_property(circle, "modulate:a", 0.0, 0.4)
	tw.tween_callback(circle.queue_free)
	# 冲击能量球
	for i in range(4):
		var orb := Label.new()
		orb.text = ["◆", "★", "▲", "●"][i]
		orb.add_theme_font_size_override("font_size", randi_range(16, 28))
		orb.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4, 0.85))
		var start_pos := Vector2(effect_layer.size.x * 0.6, effect_layer.size.y * 0.4)
		var end_pos := Vector2(effect_layer.size.x * 0.2, effect_layer.size.y * (0.3 + randf() * 0.3))
		orb.position = start_pos
		effect_layer.add_child(orb)
		var tw2 := create_tween()
		tw2.tween_interval(i * 0.04)
		tw2.tween_property(orb, "position", end_pos, 0.18).set_ease(Tween.EASE_OUT)
		tw2.parallel().tween_property(orb, "scale", Vector2(1.5, 1.5), 0.18)
		tw2.tween_property(orb, "modulate:a", 0.0, 0.15)
		tw2.tween_callback(orb.queue_free)

# ==================== 标签切换 ====================
func _switch_tab(t: int) -> void:
	if current_tab == 0 and t != 0 and loot_dialog.visible:
		loot_dialog._on_continue()
	current_tab = t
	_highlight_tab()
	AudioManager.play_sfx("button")
	match t:
		0:
			battle_view.visible = true
			panel_view.visible = false
		1: _open_panel("角色", ["装备", "技能", "天赋", "宠物"], "装备")
		2: _open_panel("冒险", ["世界地图", "深渊塔"], "世界地图")
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
	if _equip_tooltip:
		_equip_tooltip.hide_tooltip()
	if _equip_compare and _equip_compare.visible:
		_equip_compare.dismiss()
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
	_reset_panel_list_layout()
	match sub_name:
		"装备": _build_equipment()
		"技能": _build_skills()
		"天赋": _build_talents()
		"宠物": _build_pets()
		"世界地图": _build_route_map()
		"深渊塔": _build_tower()
		"锻造": _build_craft()
		"强化": _build_enhance()
		"任务": _build_quests()
		"每日": _build_daily()
		"商店": _build_shop()
		"成就": _build_achievements()

# ==================== 战斗界面更新 ====================
func _update_battle(_delta: float) -> void:
	var combat: Dictionary = GameManager.game_data["combat"]
	player_hp_bar.max_value = combat["max_hp"]
	player_hp_bar.value = GameManager.player_hp
	player_hp_label.text = "%d/%d" % [GameManager.player_hp, combat["max_hp"]]
	overlay_level_label.text = "Lv.%d" % GameManager.game_data["player"]["level"]
	var p: Dictionary = GameManager.game_data["player"]
	var need: int = DataManager.exp_for_level(int(p["level"]))
	exp_bar.max_value = need
	exp_bar.value = int(p["exp"])
	exp_pct.text = "%.0f%%" % (float(p["exp"]) / float(maxi(1, need)) * 100.0)
	if GameManager.is_boss_fight and _boss_unit:
		_boss_unit.update_hp(GameManager.enemy_hp, GameManager.enemy_max_hp)
	if GameManager.enemy_hp < _prev_ehp and _prev_ehp > 0:
		var dmg: int = _prev_ehp - GameManager.enemy_hp
		_float_dmg(str(dmg), ThemeConfig.ACCENT_ORANGE if dmg > 50 else ThemeConfig.TXT_PRIMARY, true, dmg > 100)
	if GameManager.player_hp < _prev_php and _prev_php > 0:
		var dmg2: int = _prev_php - GameManager.player_hp
		_float_dmg(str(dmg2), ThemeConfig.ENEMY_RED, false, false)
	_prev_ehp = GameManager.enemy_hp
	_prev_php = GameManager.player_hp

func _float_dmg(text: String, color: Color, is_enemy: bool, big: bool) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22 if big else 15)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 伤害数字直接显示在角色身上(战斗区域内)
	var battle_rect: Rect2 = battle_arena.get_rect()
	if is_enemy:
		l.position = Vector2(battle_arena.size.x * 0.68 + randf_range(-20, 20), battle_arena.size.y * 0.52 + randf_range(-12, 12))
	else:
		l.position = Vector2(battle_arena.size.x * 0.16 + randf_range(-20, 20), battle_arena.size.y * 0.52 + randf_range(-12, 12))
	l.z_index = 10
	effect_layer.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	if big:
		tw.tween_property(l, "scale", Vector2(1.6, 1.6), 0.06)
		tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.06)
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


# ==================== 冒险世界地图 ====================
func _reset_panel_list_layout() -> void:
	var margin := item_list.get_parent() as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 12)
	var scroll := _get_panel_scroll()
	if scroll:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _set_map_panel_layout() -> void:
	var margin := item_list.get_parent() as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_left", 0)
		margin.add_theme_constant_override("margin_right", 0)
		margin.add_theme_constant_override("margin_top", 0)
		margin.add_theme_constant_override("margin_bottom", 0)
	var scroll := _get_panel_scroll()
	if scroll:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _get_panel_scroll() -> ScrollContainer:
	var n: Node = item_list
	while n:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null

func _build_route_map() -> void:
	_set_map_panel_layout()
	var d: Dictionary = GameManager.game_data
	var cur: int = int(d["zone"]["current"])
	var unl: int = int(d["zone"]["unlocked"])
	var map_view := AdventureMapView.new()
	map_view.setup(cur, unl)
	map_view.zone_selected.connect(_on_map_zone_selected)
	map_view.tower_requested.connect(func(): _on_sub("深渊塔"))
	item_list.add_child(map_view)
	map_view.call_deferred("scroll_to_zone", cur)

func _on_map_zone_selected(zone_idx: int) -> void:
	if zone_idx > int(GameManager.game_data["zone"]["unlocked"]):
		GameManager.toast_message.emit("击败区域 Boss 后解锁", ThemeConfig.TXT_DISABLED)
		return
	if zone_idx == int(GameManager.game_data["zone"]["current"]):
		return
	if GameManager.change_zone(zone_idx):
		AudioManager.play_sfx("button")
		_on_sub("世界地图")

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
	_build_equipment_hero_strip(d)
	_section_header("已装备")
	_hint_text("悬停查看属性 · 双击背包装备对比 · 双击已装备卸下")
	var equip_grid := GridContainer.new()
	equip_grid.columns = 3
	equip_grid.add_theme_constant_override("h_separation", 10)
	equip_grid.add_theme_constant_override("v_separation", 10)
	item_list.add_child(equip_grid)
	for sk in d["equipment"]:
		var si: int = int(sk)
		var item = d["equipment"][sk]
		var cell := _make_equip_slot_cell(si, item, true)
		equip_grid.add_child(cell)
	_section_header("背包 (%d/%d)" % [d["inventory"].size(), int(d["inventory_max"])])
	if d["inventory"].is_empty():
		_hint_text("击杀怪物获取装备掉落")
	else:
		var bag_grid := GridContainer.new()
		bag_grid.columns = 4
		bag_grid.add_theme_constant_override("h_separation", 8)
		bag_grid.add_theme_constant_override("v_separation", 8)
		item_list.add_child(bag_grid)
		for item in d["inventory"]:
			bag_grid.add_child(_make_equip_slot_cell(-1, item, false))

func _build_equipment_hero_strip(d: Dictionary) -> void:
	var combat: Dictionary = d["combat"]
	var player: Dictionary = d["player"]
	var card := _make_card(ThemeConfig.PRIMARY)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(56, 56)
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if player_visual:
		var tex: Texture2D = player_visual.get_avatar_texture()
		if tex:
			avatar.texture = tex
	row.add_child(avatar)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	var name_l := Label.new()
	name_l.text = "Lv.%d  暗影行者" % int(player["level"])
	name_l.add_theme_font_size_override("font_size", 14)
	name_l.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	info.add_child(name_l)
	var stats_l := Label.new()
	stats_l.text = "⚔%d  🛡%d  ❤%d  ✦%d%%" % [combat["atk"], combat["def"], combat["max_hp"], combat["crit"]]
	stats_l.add_theme_font_size_override("font_size", 10)
	stats_l.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(stats_l)
	row.add_child(info)
	item_list.add_child(card)

func _make_equip_slot_cell(slot_i: int, item, is_equipped_row: bool) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	var slot := EquipItemSlot.new()
	if is_equipped_row:
		if item == null:
			slot.setup_empty(slot_i, DataManager.SLOT_NAMES[slot_i as DataManager.SlotType])
		else:
			slot.setup_item(item, true)
			_wire_equip_slot(slot, true)
	else:
		slot.setup_item(item, false)
		_wire_equip_slot(slot, false)
	cell.add_child(slot)
	return cell

func _wire_equip_slot(slot: EquipItemSlot, is_equipped: bool) -> void:
	slot.slot_hovered.connect(func(it: Dictionary, pos: Vector2):
		if _equip_tooltip:
			_equip_tooltip.show_item(it, pos))
	slot.slot_unhovered.connect(func():
		if _equip_tooltip:
			_equip_tooltip.hide_tooltip())
	slot.slot_double_clicked.connect(func(it: Dictionary):
		_on_equip_slot_double_click(it, is_equipped))

func _on_equip_slot_double_click(item: Dictionary, is_equipped: bool) -> void:
	if item.is_empty():
		return
	if is_equipped:
		GameManager.unequip_item(int(item["slot"]))
		_on_sub("装备")
		return
	var slot_key := DataManager.item_slot_key(item)
	var current = GameManager.game_data["equipment"].get(slot_key)
	if _equip_compare:
		_equip_compare.open(item, current if current != null else {})
	if _equip_tooltip:
		_equip_tooltip.hide_tooltip()

func _on_equip_compare_confirm(item: Dictionary) -> void:
	GameManager.equip_item(item)
	_on_sub("装备")

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

func _make_list_icon(tex_path: String, border_color: Color, dimmed: bool = false) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(52, 52)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.10, 0.92)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(border_color.r, border_color.g, border_color.b, 0.35 if dimmed else 0.85)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	badge.add_theme_stylebox_override("panel", s)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(center)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(38, 38)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = AssetRegistry.load_texture(tex_path)
	if tex:
		icon.texture = tex
	icon.modulate = Color(1, 1, 1, 0.35 if dimmed else 1.0)
	center.add_child(icon)
	return badge

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
	var unlocked: bool = plv >= int(sk["unlock_lv"])
	var active: bool = lv > 0
	var equipped: bool = sid in eq
	var accent: Color = sk["color"] if active else ThemeConfig.TXT_DISABLED
	var card := _make_card(accent if active else ThemeConfig.TXT_DISABLED)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	hbox.add_child(_make_list_icon(AssetRegistry.get_skill_icon(sid), accent, not active))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s Lv.%d%s" % [sk["name"], lv, " · 已装备" if equipped else ""]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", accent)
	info.add_child(nl)
	var dl := Label.new()
	if unlocked:
		dl.text = "%s · CD:%.1fs" % [sk["type"], sk["cooldown"]]
	else:
		dl.text = "Lv.%d 解锁" % int(sk["unlock_lv"])
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
	var ri: Dictionary = DataManager.RARITY_INFO[int(pet["rarity"]) as DataManager.Rarity]
	var accent: Color = ri["color"] if active else ThemeConfig.TXT_DISABLED
	var card := _make_card(accent if active else ThemeConfig.TXT_DISABLED)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	hbox.add_child(_make_list_icon(AssetRegistry.get_pet_icon(pid), accent, not active))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := Label.new()
	nl.text = "%s Lv.%d%s" % [pet["name"], int(pd.get("level", 1)), " ★" if active else ""]
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", pet["color"])
	info.add_child(nl)
	var dl := Label.new()
	dl.text = "[%s] %s" % [ri["name"], pet["desc"]]
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", ThemeConfig.TXT_SECONDARY)
	info.add_child(dl)
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
	GameManager.current_enemy = {"name": GameManager.current_boss.get("name", "Boss")}
	_spawn_boss_unit()
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

# ==================== 波次战斗 UI ====================
func _on_wave_started(enemies: Array) -> void:
	_clear_enemy_units()
	_spawn_queue = enemies.duplicate(true)
	_spawn_delay = 0.0
	_prev_ehp = 0
	_prev_php = GameManager.player_hp
	if _wave_label:
		_wave_label.text = "× %d" % enemies.size()

func _process_spawn_queue(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	_spawn_delay -= delta
	if _spawn_delay > 0:
		return
	var enemy: Dictionary = _spawn_queue.pop_front()
	_spawn_enemy_unit(enemy)
	_spawn_delay = SPAWN_STAGGER if not _spawn_queue.is_empty() else 0.0

func _spawn_enemy_unit(enemy: Dictionary) -> void:
	var zone_idx: int = GameManager.game_data["zone"]["current"]
	var tex_path: String = AssetRegistry.get_enemy_texture(enemy["name"], zone_idx)
	var arena_size: Vector2 = _get_arena_size()
	var unit := BattleEnemyUnit.new()
	enemy_container.add_child(unit)
	var eid: int = int(enemy["id"])
	_enemy_units[eid] = unit
	unit.setup(enemy, tex_path, arena_size, false)
	unit.enter_finished.connect(func(): GameManager.battle_wave.activate_enemy(eid))
	unit.play_enter()

func _on_enemy_hp_changed(enemy_id: int, hp: int, max_hp: int) -> void:
	if _enemy_units.has(enemy_id):
		_enemy_units[enemy_id].update_hp(hp, max_hp)

func _on_enemy_unit_died(enemy_id: int, _enemy: Dictionary) -> void:
	if _enemy_units.has(enemy_id):
		var unit: BattleEnemyUnit = _enemy_units[enemy_id]
		_enemy_units.erase(enemy_id)
		unit.play_death()

func _clear_enemy_units() -> void:
	for eid in _enemy_units:
		var unit: BattleEnemyUnit = _enemy_units[eid]
		if is_instance_valid(unit):
			unit.queue_free()
	_enemy_units.clear()
	if _boss_unit and is_instance_valid(_boss_unit):
		_boss_unit.queue_free()
	_boss_unit = null

func _on_wave_cleared(rewards: Dictionary) -> void:
	if current_tab != 0:
		_auto_continue_wave()
		return
	var title: String = "Boss 击败!" if rewards.get("is_boss", false) else "战斗胜利"
	loot_dialog.show_rewards(rewards, title)

func _auto_continue_wave() -> void:
	_clear_enemy_units()
	_prev_ehp = 0
	_prev_php = GameManager.player_hp
	GameManager.continue_next_wave()

func _on_loot_closed() -> void:
	_clear_enemy_units()
	_prev_ehp = 0
	_prev_php = GameManager.player_hp
	_refresh_player_avatar()
	GameManager.continue_next_wave()

func _on_skill_cast(skill_id: String, color: Color, _target_pos: Vector2) -> void:
	if not battle_effects:
		return
	var arena_pos := Vector2(effect_layer.size.x * 0.65, effect_layer.size.y * 0.35)
	var eid := GameManager.current_target_id
	if _enemy_units.has(eid):
		var unit: BattleEnemyUnit = _enemy_units[eid]
		arena_pos = unit.position + Vector2(40, 45)
	elif _boss_unit:
		arena_pos = _boss_unit.position + Vector2(40, 45)
	match skill_id:
		"slash_storm", "execute", "whirlwind", "bleed":
			battle_effects.spawn_hit_particles(arena_pos, ThemeConfig.ACCENT_GOLD, 8)
			battle_effects.spawn_crit_effect(arena_pos)
		"shadow_bolt", "soul_drain", "dark_explosion", "void_rift":
			battle_effects.spawn_hit_particles(arena_pos, color, 10)
		"holy_shield":
			battle_effects.spawn_hit_particles(arena_pos, Color(0.3, 0.8, 1.0), 12)
		"divine_wrath", "resurrection":
			battle_effects.spawn_crit_effect(arena_pos)
		_:
			battle_effects.spawn_hit_particles(arena_pos, color, 6)
	var vfx_path: String = AssetRegistry.get_skill_vfx(skill_id)
	if ResourceLoader.exists(vfx_path):
		var spr := TextureRect.new()
		spr.texture = load(vfx_path)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.custom_minimum_size = Vector2(64, 64)
		spr.size = Vector2(64, 64)
		spr.position = arena_pos - Vector2(32, 32)
		spr.modulate = Color(color.r, color.g, color.b, 0.9)
		effect_layer.add_child(spr)
		var tw := create_tween()
		tw.tween_property(spr, "scale", Vector2(2.0, 2.0), 0.2)
		tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.5)
		tw.tween_callback(spr.queue_free)

func _spawn_boss_unit() -> void:
	_clear_enemy_units()
	var boss := GameManager.current_boss
	var fake_enemy := {
		"id": 9999,
		"name": boss["name"],
		"hp": GameManager.enemy_hp,
		"max_hp": GameManager.enemy_max_hp,
		"slot_index": 2,
	}
	var tex_path := "res://assets/generated/bosses/boss_forest_lord.png"
	if not ResourceLoader.exists(tex_path):
		tex_path = "res://assets/sprites/enemy_idle_2.png"
	var arena_size: Vector2 = _get_arena_size()
	var unit := BattleEnemyUnit.new()
	enemy_container.add_child(unit)
	unit.setup(fake_enemy, tex_path, arena_size, false, 1.18)
	_boss_unit = unit
	if _wave_label:
		_wave_label.text = "💀 BOSS"
	battle_effects.spawn_boss_entrance(unit.position + Vector2(40, 45))
	unit.play_enter()
	unit.enter_finished.connect(func(): pass)
