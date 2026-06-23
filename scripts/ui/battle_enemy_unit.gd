extends Control
class_name BattleEnemyUnit
## 战斗敌人单元 - 从右侧走入战场

signal enter_finished

var sprite: TextureRect
var shadow: ColorRect
var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label

var enemy_id := -1
var _home_pos := Vector2.ZERO
var _walk_start_x := 0.0
var _walk_elapsed := 0.0
var _walk_duration := 0.85
var _is_walking_in := false
var _skip_enter := false
var _sprite_scale_mult := 1.0
var _is_attacking := false
var _arena_h := 360.0

const UNIT_W := 96.0
const UNIT_H := 108.0

const SLOT_X: Array = [0.52, 0.64, 0.76, 0.58, 0.70]

func setup(enemy: Dictionary, tex_path: String, arena_size: Vector2, skip_enter: bool = false, sprite_scale_mult: float = 1.0) -> void:
	_ensure_nodes()
	_skip_enter = skip_enter
	_sprite_scale_mult = sprite_scale_mult
	enemy_id = int(enemy["id"])
	name_label.text = enemy["name"]
	hp_bar.max_value = int(enemy["max_hp"])
	hp_bar.value = int(enemy["hp"])
	hp_label.text = "%d/%d" % [int(enemy["hp"]), int(enemy["max_hp"])]

	if arena_size.x < 80.0:
		arena_size = Vector2(680, 360)
	_arena_h = arena_size.y
	var slot: int = clampi(int(enemy.get("slot_index", 0)), 0, SLOT_X.size() - 1)
	var ground_y: float = arena_size.y * BattleLayout.GROUND_Y_RATIO
	var unit_h: float = maxf(108.0, _arena_h * BattleLayout.ENEMY_HEIGHT_RATIO * _sprite_scale_mult + 30.0)
	custom_minimum_size = Vector2(UNIT_W, unit_h)
	size = Vector2(UNIT_W, unit_h)
	scale = Vector2.ONE
	z_index = 2 + slot
	pivot_offset = Vector2(UNIT_W * 0.5, unit_h)

	var tex: Texture2D = AssetRegistry.load_texture(tex_path)
	if tex:
		sprite.texture = tex
		_layout_sprite(tex, unit_h)
		if AssetRegistry.uses_chroma_key(tex_path):
			_apply_chroma_key(sprite)
	else:
		var fb: Texture2D = load("res://assets/sprites/enemy_idle_1.png")
		if fb:
			sprite.texture = fb
			_layout_sprite(fb, unit_h)
			_apply_chroma_key(sprite)

	_home_pos = Vector2(arena_size.x * SLOT_X[slot] - UNIT_W * 0.5, ground_y - unit_h)

	if skip_enter:
		position = _home_pos
		modulate.a = 1.0
	else:
		_walk_start_x = arena_size.x + 12.0
		position = Vector2(_walk_start_x, _home_pos.y)
		modulate.a = 1.0

func play_enter() -> void:
	if _skip_enter:
		enter_finished.emit()
		return
	_is_walking_in = true
	_walk_elapsed = 0.0
	set_process(true)

func _process(delta: float) -> void:
	if not _is_walking_in or _is_attacking:
		return
	_walk_elapsed += delta
	var t: float = clampf(_walk_elapsed / _walk_duration, 0.0, 1.0)
	var ease_t: float = t * t * (3.0 - 2.0 * t)
	position.x = lerpf(_walk_start_x, _home_pos.x, ease_t)
	var step: float = _walk_elapsed * 10.0
	position.y = _home_pos.y + abs(sin(step)) * -3.0
	var squash: float = 1.0 + sin(step) * 0.04
	sprite.scale = Vector2(1.0, squash)
	sprite.rotation = sin(step * 0.5) * 0.03
	if t >= 1.0:
		position = _home_pos
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0
		_is_walking_in = false
		set_process(false)
		enter_finished.emit()

func update_hp(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = maxi(0, hp)
	hp_label.text = "%d/%d" % [maxi(0, hp), max_hp]

func play_hit() -> void:
	if not sprite:
		return
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.03)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)

func play_death(on_done: Callable = Callable()) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_property(self, "position:y", position.y + 18, 0.35)
	tw.set_parallel(false)
	tw.tween_callback(func():
		if on_done.is_valid():
			on_done.call()
		queue_free())

func play_attack_toward(_target_x: float) -> void:
	if not sprite or _is_attacking:
		return
	_is_attacking = true
	var orig_x: float = position.x
	var tw := create_tween()
	# 蓄力后扑向玩家
	tw.tween_property(sprite, "rotation", 0.06, 0.04)
	tw.tween_property(sprite, "scale", Vector2(0.94, 1.06), 0.04)
	tw.tween_property(self, "position:x", orig_x - 30, 0.07).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", -0.14, 0.07)
	tw.parallel().tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.07)
	tw.tween_callback(func():
		sprite.modulate = Color(1.5, 0.65, 0.55, 1.0))
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	tw.tween_property(self, "position:x", orig_x, 0.14).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.12)
	tw.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.12)
	tw.tween_callback(func(): _is_attacking = false)

func _layout_sprite(tex: Texture2D, unit_h: float) -> void:
	var tex_w: float = maxf(1.0, float(tex.get_width()))
	var tex_h: float = maxf(1.0, float(tex.get_height()))
	var display_h: float = _arena_h * BattleLayout.ENEMY_HEIGHT_RATIO * _sprite_scale_mult
	var display_w: float = display_h * (tex_w / tex_h)
	sprite.custom_minimum_size = Vector2(display_w, display_h)
	sprite.size = Vector2(display_w, display_h)
	sprite.position = Vector2((UNIT_W - display_w) * 0.5, unit_h - display_h - BattleLayout.SPRITE_FOOT_INSET)
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	# v2 素材本身朝左（面向玩家），不翻转
	sprite.flip_h = false
	sprite.pivot_offset = Vector2(display_w * 0.5, display_h * 0.9)
	if shadow:
		var sw: float = display_w * 0.62
		shadow.size = Vector2(sw, 8)
		shadow.position = Vector2((UNIT_W - sw) * 0.5, unit_h - 12)

func _apply_chroma_key(rect: TextureRect) -> void:
	var shader: Shader = load("res://shaders/chroma_key.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("threshold", 0.42)
		mat.set_shader_parameter("smoothing", 0.14)
		rect.material = mat

func _ensure_nodes() -> void:
	if shadow == null:
		shadow = ColorRect.new()
		shadow.name = "Shadow"
		shadow.color = Color(0, 0, 0, 0.28)
		shadow.custom_minimum_size = Vector2(48, 8)
		shadow.size = Vector2(48, 8)
		add_child(shadow)
	if sprite == null:
		sprite = TextureRect.new()
		sprite.name = "Sprite"
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.custom_minimum_size = Vector2(58, 58)
		sprite.size = Vector2(58, 58)
		add_child(sprite)
	if name_label == null:
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.78))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-2, 0)
		name_label.custom_minimum_size = Vector2(UNIT_W + 4, 12)
		add_child(name_label)
	if hp_bar == null:
		hp_bar = ProgressBar.new()
		hp_bar.name = "HPBar"
		hp_bar.custom_minimum_size = Vector2(80, 6)
		hp_bar.position = Vector2(6, 10)
		hp_bar.show_percentage = false
		add_child(hp_bar)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.06, 0.05, 0.08, 0.92)
		bg.corner_radius_top_left = 3
		bg.corner_radius_top_right = 3
		bg.corner_radius_bottom_left = 3
		bg.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("background", bg)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.92, 0.28, 0.28, 1.0)
		fill.corner_radius_top_left = 3
		fill.corner_radius_top_right = 3
		fill.corner_radius_bottom_left = 3
		fill.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("fill", fill)
	if hp_label == null:
		hp_label = Label.new()
		hp_label.name = "HPLabel"
		hp_label.add_theme_font_size_override("font_size", 6)
		hp_label.add_theme_color_override("font_color", Color(1, 0.92, 0.92))
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.position = Vector2(6, 10)
		hp_label.custom_minimum_size = Vector2(80, 6)
		add_child(hp_label)
