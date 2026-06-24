extends Node
## 万界裂隙 — 世界观/章节叙事管理器

signal realm_entered(zone_index: int, realm: Dictionary)
signal realm_unlocked(zone_index: int, realm: Dictionary)

var _data: Dictionary = {}
var _realms_by_zone: Dictionary = {}
var _dimension_types: Dictionary = {}

func _ready() -> void:
	_load_lore()

func _load_lore() -> void:
	var path := "res://data/multiverse_lore.json"
	if not FileAccess.file_exists(path):
		push_error("LoreManager: missing %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("LoreManager: invalid lore JSON")
		return
	_data = parsed
	_dimension_types = _data.get("dimension_types", {})
	_realms_by_zone.clear()
	for realm in _data.get("realms", []):
		var zi: int = int(realm.get("zone_index", -1))
		if zi >= 0:
			_realms_by_zone[zi] = realm

func is_ready() -> bool:
	return not _data.is_empty()

func get_title() -> String:
	return str(_data.get("title", "万界裂隙"))

func get_subtitle() -> String:
	return str(_data.get("subtitle", ""))

func get_premise() -> Dictionary:
	return _data.get("premise", {})

func get_realm(zone_index: int) -> Dictionary:
	return _realms_by_zone.get(zone_index, {})

func get_zone_display_name(zone_index: int) -> String:
	var realm: Dictionary = get_realm(zone_index)
	if not realm.is_empty():
		return str(realm.get("display_name", ""))
	if zone_index >= 0 and zone_index < DataManager.ZONES.size():
		return str(DataManager.ZONES[zone_index]["name"])
	return "未知界域"

func get_zone_tagline(zone_index: int) -> String:
	return str(get_realm(zone_index).get("tagline", ""))

func get_dimension_type(type_id: String) -> Dictionary:
	return _dimension_types.get(type_id, {})

func get_dimension_badge(zone_index: int) -> String:
	var realm: Dictionary = get_realm(zone_index)
	var dim: Dictionary = get_dimension_type(str(realm.get("dimension_type", "")))
	var icon: String = str(dim.get("icon", "🌀"))
	var name: String = str(dim.get("name", "异界"))
	return "%s %s" % [icon, name]

func get_travel_text(zone_index: int) -> String:
	return str(get_realm(zone_index).get("travel_text", "裂隙震颤，你坠入了新的世界……"))

func get_intro(zone_index: int) -> String:
	return str(get_realm(zone_index).get("intro", ""))

func get_boss_lore(zone_index: int) -> String:
	return str(get_realm(zone_index).get("boss_lore", ""))

func get_era(zone_index: int) -> String:
	return str(get_realm(zone_index).get("era", ""))

func ensure_lore_save(game_data: Dictionary) -> void:
	if not game_data.has("lore"):
		game_data["lore"] = {
			"visited_realms": [],
			"seen_first_game": false,
		}

func on_first_game(game_data: Dictionary) -> void:
	if not is_ready():
		return
	ensure_lore_save(game_data)
	var lore: Dictionary = game_data["lore"]
	if lore.get("seen_first_game", false):
		return
	lore["seen_first_game"] = true
	for ev in _data.get("rift_events", []):
		if str(ev.get("trigger", "")) == "first_game":
			GameManager.battle_log.emit(str(ev.get("text", "")), Color(0.7, 0.85, 1.0))
			GameManager.toast_message.emit(str(ev.get("text", "")), Color(0.7, 0.85, 1.0))
			break

func on_zone_enter(game_data: Dictionary, zone_index: int) -> void:
	if not is_ready():
		return
	ensure_lore_save(game_data)
	var lore: Dictionary = game_data["lore"]
	var visited: Array = lore.get("visited_realms", [])
	var first_visit := zone_index not in visited
	if first_visit:
		visited.append(zone_index)
		lore["visited_realms"] = visited
	var realm: Dictionary = get_realm(zone_index)
	if realm.is_empty():
		return
	realm_entered.emit(zone_index, realm)
	if first_visit:
		var travel: String = get_travel_text(zone_index)
		GameManager.battle_log.emit("▸ %s" % travel, Color(0.85, 0.75, 1.0))
		GameManager.toast_message.emit(travel, Color(0.85, 0.75, 1.0))
		var intro: String = get_intro(zone_index)
		if not intro.is_empty():
			var timer := GameManager.get_tree().create_timer(0.8)
			timer.timeout.connect(func():
				GameManager.battle_log.emit(intro, Color(0.75, 0.82, 0.95))
			, CONNECT_ONE_SHOT)

func on_realm_unlocked(game_data: Dictionary, zone_index: int) -> void:
	if not is_ready() or zone_index < 0:
		return
	var realm: Dictionary = get_realm(zone_index)
	if realm.is_empty():
		return
	realm_unlocked.emit(zone_index, realm)
	for ev in _data.get("rift_events", []):
		if str(ev.get("trigger", "")) == "realm_unlock":
			GameManager.battle_log.emit(str(ev.get("text", "")), Color(1.0, 0.85, 0.4))
			break
	var name: String = get_zone_display_name(zone_index)
	var era: String = get_era(zone_index)
	var badge: String = get_dimension_badge(zone_index)
	GameManager.toast_message.emit(
		"新界域: %s\n%s | %s" % [name, badge, era],
		Color(1.0, 0.82, 0.35)
	)

func get_stage_info_lines(zone_index: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	var realm: Dictionary = get_realm(zone_index)
	if realm.is_empty():
		return lines
	lines.append(get_dimension_badge(zone_index))
	lines.append(str(realm.get("era", "")))
	if not str(realm.get("tagline", "")).is_empty():
		lines.append(str(realm.get("tagline", "")))
	return lines

func get_all_realms() -> Array:
	return _data.get("realms", [])
