extends Control
class_name HeroIdlePreview
## 装备页角色预览 — 正面半身立绘铺满 + 呼吸动效

signal preview_clicked

const CHROMA_SHADER := "res://shaders/chroma_key.gdshader"
const BREATH_SCALE := 0.018
const BOB_PX := 1.8

var _sprite: TextureRect
var _texture: Texture2D
var _phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "点击查看角色档案"
	_build_nodes()
	_load_texture()
	_apply_chroma()
	call_deferred("_layout_sprite")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_sprite")

func _process(delta: float) -> void:
	if _sprite == null or size.x < 4.0:
		return
	_phase += delta * 2.0
	var breath: float = 1.0 + sin(_phase * 1.25) * BREATH_SCALE
	var bob: float = sin(_phase) * BOB_PX
	_sprite.pivot_offset = size * 0.5
	_sprite.scale = Vector2(breath, breath)
	_sprite.position = Vector2(0.0, bob)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			preview_clicked.emit()
			accept_event()

func _layout_sprite() -> void:
	if not _sprite or _texture == null or size.x < 4.0:
		return
	_sprite.texture = _texture
	_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sprite.offset_left = 0
	_sprite.offset_top = 0
	_sprite.offset_right = 0
	_sprite.offset_bottom = 0
	_sprite.size = size
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sprite.pivot_offset = size * 0.5
	_sprite.scale = Vector2.ONE
	_sprite.position = Vector2.ZERO

func _load_texture() -> void:
	_texture = AssetRegistry.get_hero_portrait_texture()
	if _texture == null:
		_texture = AssetRegistry.load_texture(AssetRegistry.HERO_BATTLE_IDLE)

func _apply_chroma() -> void:
	if not _sprite:
		return
	var shader: Shader = load(CHROMA_SHADER)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("threshold", 0.40)
		mat.set_shader_parameter("smoothing", 0.15)
		_sprite.material = mat

func _build_nodes() -> void:
	if _sprite != null:
		return
	_sprite = TextureRect.new()
	_sprite.name = "Body"
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
