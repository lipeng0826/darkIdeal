extends Control
class_name PlayerVisual
## 横版战斗主角精灵 - 跑步 / 待机 / 攻击 / 受击

enum MotionState { IDLE, RUN, ATTACK, HIT }

var body_sprite: TextureRect

var _idle_textures: Array[Texture2D] = []
var _is_attacking := false
var _is_hit_reacting := false
var _motion_state := MotionState.IDLE
var _foot_y := 0.0
var _sprite_w := 0.0
var _sprite_h := 0.0
var _anchor_x := 0.0
var _ref_aspect := 1.0
var _mo := Vector2.ZERO
var _motion_scale := Vector2.ONE

var motion_offset: Vector2:
	get:
		return _mo
	set(value):
		_mo = value
		_apply_sprite_transform()

var motion_scale: Vector2:
	get:
		return _motion_scale
	set(value):
		_motion_scale = value
		_apply_sprite_transform()

const HERO_TEXTURE := "res://assets/sprites/hero_iterations/hero_iter_08.png"
const FALLBACK_IDLE := "res://assets/sprites/player_idle_1.png"
const CHROMA_SHADER := "res://shaders/chroma_key.gdshader"
const HERO_VERTICAL_OFFSET := 10.0  # 主角脚底额外下沉，修正与敌人不在同一水平线

func _ready() -> void:
	_ensure_nodes()
	_load_frames()
	_apply_chroma(body_sprite)
	call_deferred("_fit_hero")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_fit_hero")

func _fit_hero() -> void:
	if not body_sprite or not body_sprite.texture or size.y < 20.0:
		return
	var preserve_mo: Vector2 = _mo
	var preserve_scale: Vector2 = _motion_scale
	var arena_h: float = _get_arena_height()
	var arena_w: float = _get_arena_width()
	var anchor: Dictionary = BattleLayout.get_player_anchor(Vector2(arena_w, arena_h))
	_foot_y = float(anchor["ground_y"]) - BattleLayout.SPRITE_FOOT_INSET + HERO_VERTICAL_OFFSET
	_sprite_h = arena_h * BattleLayout.HERO_HEIGHT_RATIO * float(anchor["scale"])
	_sprite_w = _sprite_h * _ref_aspect
	_anchor_x = float(anchor.get("screen_x", size.x * BattleLayout.PLAYER_SCREEN_X_RATIO))
	z_index = int(anchor["z"])
	if not (_is_attacking or _is_hit_reacting):
		_mo = Vector2.ZERO
		_motion_scale = Vector2.ONE
	else:
		_mo = preserve_mo
		_motion_scale = preserve_scale
	body_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	body_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_apply_sprite_transform()
	_layout_ground_shadow(_sprite_w, _foot_y, BattleLayout.PLAYER_DEPTH)

func _apply_sprite_transform() -> void:
	if not body_sprite or _sprite_h < 1.0:
		return
	var w: float = _sprite_w * _motion_scale.x
	var h: float = _sprite_h * _motion_scale.y
	var foot: float = _foot_y + _mo.y
	var left: float = _anchor_x - w * 0.5 + _mo.x
	body_sprite.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	body_sprite.offset_left = left
	body_sprite.offset_top = foot - h
	body_sprite.offset_right = left + w
	body_sprite.offset_bottom = foot
	body_sprite.pivot_offset = Vector2(w * 0.5, h)

func _layout_ground_shadow(sprite_w: float, foot_y: float, depth: float = 0.06) -> void:
	if not has_node("GroundShadow"):
		return
	var sh: ColorRect = $GroundShadow
	var sw: float = sprite_w * lerpf(0.62, 0.48, depth)
	var sh_h: float = lerpf(11.0, 7.0, depth)
	sh.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sh.offset_left = _anchor_x - sw * 0.5
	sh.offset_top = foot_y - sh_h * 0.35
	sh.offset_right = sh.offset_left + sw
	sh.offset_bottom = foot_y + sh_h * 0.45
	sh.color = Color(0, 0, 0, lerpf(0.28, 0.16, depth))

func _get_arena_width() -> float:
	var node: Node = get_parent()
	while node:
		if node.name == "BattleArena" and node is Control:
			var w: float = (node as Control).size.x
			if w > 20.0:
				return w
		node = node.get_parent()
	return size.x

func _get_arena_height() -> float:
	var node: Node = get_parent()
	while node:
		if node.name == "BattleArena" and node is Control:
			var h: float = (node as Control).size.y
			if h > 20.0:
				return h
		node = node.get_parent()
	return size.y

func _load_frames() -> void:
	_idle_textures.clear()
	var hero_tex: Texture2D = AssetRegistry.load_texture(HERO_TEXTURE)
	if hero_tex == null:
		hero_tex = load(HERO_TEXTURE) as Texture2D
	if hero_tex == null:
		hero_tex = load(FALLBACK_IDLE) as Texture2D
	if hero_tex:
		_idle_textures.append(hero_tex)
		_ref_aspect = float(hero_tex.get_width()) / float(maxi(hero_tex.get_height(), 1))
	if _idle_textures.size() > 0 and body_sprite:
		body_sprite.texture = _idle_textures[0]

var _action_tween: Tween
var _pending_finish: Callable = Callable()

func set_motion_state(state: MotionState) -> void:
	_motion_state = state

func apply_idle_motion(phase: float) -> void:
	if _is_attacking or _is_hit_reacting:
		return
	var bob: float = sin(phase) * 2.0
	var breath: float = 1.0 + sin(phase * 1.5) * 0.008
	motion_offset = Vector2(0.0, bob)
	motion_scale = Vector2(breath, breath)
	if body_sprite:
		body_sprite.rotation = 0.0

func apply_run_motion(phase: float) -> void:
	if _is_attacking or _is_hit_reacting:
		return
	var stride: float = sin(phase * 2.4)
	var bob: float = absf(sin(phase * 2.4)) * -5.0
	var lean: float = 0.04 + sin(phase * 1.2) * 0.012
	motion_offset = Vector2(stride * 3.0, bob)
	motion_scale = Vector2(1.0 + lean * 0.5, 1.0 - lean * 0.35)
	if body_sprite:
		body_sprite.rotation = -lean

func reset_motion() -> void:
	motion_offset = Vector2.ZERO
	motion_scale = Vector2.ONE

func set_idle_frame(_idx: int) -> void:
	pass

func play_attack_sequence(on_strike: Callable = Callable(), on_finished: Callable = Callable()) -> void:
	_kill_action_tween(true)
	_is_attacking = true
	_is_hit_reacting = false
	_motion_state = MotionState.ATTACK
	_pending_finish = on_finished
	_restore_hero_texture()
	var orig_mo: Vector2 = _mo
	var ps: TextureRect = body_sprite
	_action_tween = create_tween()
	# 蓄力：后拉+压扁+剑身发光
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(-26, 5), 0.10).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2(0.84, 1.12), 0.10)
	if ps:
		_action_tween.parallel().tween_property(ps, "rotation", -0.18, 0.10)
		_action_tween.parallel().tween_property(ps, "modulate", Color(1.25, 1.25, 1.4), 0.08)
	# 冲刺出刀
	_action_tween.tween_callback(func():
		if on_strike.is_valid():
			on_strike.call())
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(82, -12), 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2(1.22, 0.84), 0.05)
	if ps:
		_action_tween.parallel().tween_property(ps, "rotation", 0.22, 0.05)
		_action_tween.parallel().tween_property(ps, "modulate", Color(1.6, 1.6, 1.75), 0.03)
	# 命中后短暂白光
	if ps:
		_action_tween.tween_property(ps, "modulate", Color.WHITE, 0.06)
	# 收招（弹性回弹）
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(44, -3), 0.07)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2(1.04, 0.96), 0.07)
	if ps:
		_action_tween.parallel().tween_property(ps, "rotation", 0.06, 0.07)
	_action_tween.tween_property(self, "motion_offset", orig_mo, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2.ONE, 0.15)
	if ps:
		_action_tween.parallel().tween_property(ps, "rotation", 0.0, 0.12)
	_action_tween.tween_callback(func():
		_finish_attack_sequence())

func play_skill_cast_sequence(on_strike: Callable = Callable()) -> void:
	_kill_action_tween(false)
	_is_attacking = true
	_is_hit_reacting = false
	_restore_hero_texture()
	var orig_mo: Vector2 = _mo
	var ps: TextureRect = body_sprite
	_action_tween = create_tween()
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(-8, 2), 0.05)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2(0.94, 1.04), 0.05)
	_action_tween.tween_callback(func():
		motion_offset = orig_mo + Vector2(30, -3)
		if on_strike.is_valid():
			on_strike.call())
	_action_tween.tween_property(self, "motion_offset", orig_mo, 0.11).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2.ONE, 0.11)
	if ps:
		_action_tween.parallel().tween_property(ps, "rotation", 0.0, 0.09)
	_action_tween.tween_callback(func():
		_is_attacking = false
		restore_idle_frame())

func _finish_attack_sequence() -> void:
	_is_attacking = false
	restore_idle_frame()
	var cb := _pending_finish
	_pending_finish = Callable()
	if cb.is_valid():
		cb.call()

func play_hit_reaction() -> void:
	if _is_attacking:
		return
	_kill_action_tween(true)
	_is_hit_reacting = true
	var orig_mo: Vector2 = _mo
	var ps: TextureRect = body_sprite
	_action_tween = create_tween()
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(-16, -5), 0.05)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2(0.90, 1.08), 0.05)
	if ps:
		_action_tween.parallel().tween_property(ps, "modulate", Color(1.45, 1.2, 1.15), 0.04)
		_action_tween.parallel().tween_property(ps, "rotation", -0.10, 0.05)
	_action_tween.tween_property(self, "motion_offset", orig_mo + Vector2(-8, 3), 0.08)
	_action_tween.tween_property(self, "motion_offset", orig_mo, 0.12).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(self, "motion_scale", Vector2.ONE, 0.12)
	if ps:
		_action_tween.parallel().tween_property(ps, "modulate", Color.WHITE, 0.12)
		_action_tween.parallel().tween_property(ps, "rotation", 0.0, 0.12)
	_action_tween.tween_callback(func(): _is_hit_reacting = false)

func _restore_hero_texture() -> void:
	if _idle_textures.size() > 0 and body_sprite:
		body_sprite.texture = _idle_textures[0]

func _kill_action_tween(invoke_finish: bool = false) -> void:
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = null
	if invoke_finish and _pending_finish.is_valid():
		var cb := _pending_finish
		_pending_finish = Callable()
		_is_attacking = false
		cb.call()
	else:
		_is_attacking = false

func play_attack_frame() -> void:
	play_attack_sequence()

func restore_idle_frame() -> void:
	_is_attacking = false
	_restore_hero_texture()
	if body_sprite:
		body_sprite.rotation = 0.0

func get_body_sprite() -> TextureRect:
	return body_sprite

func get_foot_global_position() -> Vector2:
	return get_global_transform() * Vector2(_anchor_x, _foot_y)

func get_body_center_global() -> Vector2:
	return get_global_transform() * Vector2(_anchor_x, _foot_y - _sprite_h * 0.55)

func get_avatar_texture() -> Texture2D:
	if _idle_textures.size() > 0:
		return _idle_textures[0]
	return null

func get_anchor_x() -> float:
	return _anchor_x

func _apply_chroma(rect: TextureRect) -> void:
	if not rect:
		return
	var shader: Shader = load(CHROMA_SHADER)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("threshold", 0.55)
		mat.set_shader_parameter("smoothing", 0.08)
		rect.material = mat

func _ensure_nodes() -> void:
	if not has_node("GroundShadow"):
		var sh := ColorRect.new()
		sh.name = "GroundShadow"
		sh.color = Color(0, 0, 0, 0.2)
		sh.custom_minimum_size = Vector2(64, 12)
		sh.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		sh.anchor_left = 0.15
		sh.anchor_right = 0.85
		sh.anchor_top = 0.88
		sh.anchor_bottom = 0.94
		sh.offset_left = 0
		sh.offset_top = 0
		sh.offset_right = 0
		sh.offset_bottom = 0
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sh)
		move_child(sh, 0)
	if not has_node("BodySprite"):
		var b := TextureRect.new()
		b.name = "BodySprite"
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.offset_left = 0
		b.offset_top = 0
		b.offset_right = 0
		b.offset_bottom = 0
		b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(b)
		body_sprite = b
	else:
		body_sprite = $BodySprite
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
