extends RefCounted
class_name HeroSpriteFrames
## 从横向精灵表切分战斗帧（主角待机 / 跑步 / 攻击）

const IDLE_SHEET := "res://assets/sprites/hero_battle/hero_idle_sheet.png"
const RUN_SHEET := "res://assets/sprites/hero_battle/hero_run_sheet.png"
const ATTACK_SHEET := "res://assets/sprites/hero_battle/hero_attack_sheet.png"

const IDLE_FRAME_COUNT := 6
const RUN_FRAME_COUNT := 8
const ATTACK_FRAME_COUNT := 8

static func load_strip(path: String, frame_count: int) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if frame_count <= 0:
		return result
	var tex: Texture2D = AssetRegistry.load_texture(path)
	if tex == null:
		tex = load(path) as Texture2D
	if tex == null:
		return result
	var sheet_w: int = int(tex.get_width())
	var sheet_h: int = int(tex.get_height())
	var frame_w: int = sheet_w / frame_count
	if frame_w <= 0:
		return result
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2i(i * frame_w, 0, frame_w, sheet_h)
		atlas.filter_clip = true
		result.append(atlas)
	return result

static func first_frame(path: String, frame_count: int) -> Texture2D:
	var frames := load_strip(path, frame_count)
	if frames.is_empty():
		return null
	return frames[0]
