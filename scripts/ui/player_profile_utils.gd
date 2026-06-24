extends RefCounted
class_name PlayerProfileUtils
## 角色档案 — 性别、名称校验与展示

const DEFAULT_NAME := "暗影行者"
const NAME_MIN_LEN := 2
const NAME_MAX_LEN := 12
const MOTTO_MAX_LEN := 20

const GENDERS: Array = [
	{"id": "male", "label": "男", "icon": "♂"},
	{"id": "female", "label": "女", "icon": "♀"},
	{"id": "secret", "label": "保密", "icon": "？"},
]

static func normalize_gender(gender_id: String) -> String:
	for g in GENDERS:
		if g["id"] == gender_id:
			return gender_id
	return "secret"

static func gender_label(gender_id: String) -> String:
	for g in GENDERS:
		if g["id"] == gender_id:
			return g["label"]
	return "保密"

static func gender_icon(gender_id: String) -> String:
	for g in GENDERS:
		if g["id"] == gender_id:
			return g["icon"]
	return "？"

static func display_name(player: Dictionary) -> String:
	var name: String = str(player.get("name", DEFAULT_NAME)).strip_edges()
	if name.is_empty():
		return DEFAULT_NAME
	return name

static func profile_subtitle(player: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append("%s %s" % [gender_icon(str(player.get("gender", "secret"))), gender_label(str(player.get("gender", "secret")))])
	var motto: String = str(player.get("motto", "")).strip_edges()
	if not motto.is_empty():
		parts.append("「%s」" % motto)
	return " · ".join(parts)

static func sanitize_name(raw: String) -> String:
	var name: String = raw.strip_edges()
	if name.length() > NAME_MAX_LEN:
		name = name.substr(0, NAME_MAX_LEN)
	return name

static func sanitize_motto(raw: String) -> String:
	var motto: String = raw.strip_edges()
	if motto.length() > MOTTO_MAX_LEN:
		motto = motto.substr(0, MOTTO_MAX_LEN)
	return motto

static func validate_name(name: String) -> String:
	name = sanitize_name(name)
	if name.length() < NAME_MIN_LEN:
		return "名字至少 %d 个字" % NAME_MIN_LEN
	return ""

static func gender_index(gender_id: String) -> int:
	for i in range(GENDERS.size()):
		if GENDERS[i]["id"] == gender_id:
			return i
	return GENDERS.size() - 1
