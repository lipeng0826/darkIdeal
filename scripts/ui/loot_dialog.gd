extends Control
class_name LootDialog
## 波次战利品模态弹框

signal closed

var _countdown := 3.0
var _auto_close := true

@onready var _overlay: ColorRect = $Overlay
@onready var _center: CenterContainer = $Center
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _gold_line: Label = $Center/Panel/Margin/VBox/GoldLine
@onready var _items_box: VBoxContainer = $Center/Panel/Margin/VBox/ItemsBox
@onready var _footer: HBoxContainer = $Center/Panel/Margin/VBox/Footer
@onready var _continue_btn: Button = $Center/Panel/Margin/VBox/Footer/ContinueBtn
@onready var _countdown_label: Label = $Center/Panel/Margin/VBox/Footer/CountdownLabel

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_style()
	if _continue_btn:
		_continue_btn.pressed.connect(_on_continue)

func _apply_style() -> void:
	if _overlay:
		_overlay.color = Color(0.02, 0.02, 0.05, 0.62)
	if _panel:
		_panel.custom_minimum_size = Vector2(280, 0)
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.10, 0.08, 0.14, 0.97)
		s.corner_radius_top_left = 14
		s.corner_radius_top_right = 14
		s.corner_radius_bottom_left = 14
		s.corner_radius_bottom_right = 14
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = Color(0.72, 0.58, 0.32, 0.85)
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 8
		s.shadow_offset = Vector2(0, 3)
		s.content_margin_left = 18.0
		s.content_margin_right = 18.0
		s.content_margin_top = 16.0
		s.content_margin_bottom = 14.0
		_panel.add_theme_stylebox_override("panel", s)
	if _title:
		_title.add_theme_font_size_override("font_size", 15)
		_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62))
	if _gold_line:
		_gold_line.add_theme_font_size_override("font_size", 11)
		_gold_line.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	if _countdown_label:
		_countdown_label.add_theme_font_size_override("font_size", 9)
		_countdown_label.add_theme_color_override("font_color", Color(0.55, 0.52, 0.62))
	_style_continue_btn()

func _style_continue_btn() -> void:
	if not _continue_btn:
		return
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.55, 0.38, 0.62)
	n.corner_radius_top_left = 14
	n.corner_radius_top_right = 14
	n.corner_radius_bottom_left = 14
	n.corner_radius_bottom_right = 14
	n.content_margin_left = 20.0
	n.content_margin_right = 20.0
	n.content_margin_top = 8.0
	n.content_margin_bottom = 8.0
	_continue_btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(0.65, 0.46, 0.72)
	_continue_btn.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(0.42, 0.28, 0.48)
	_continue_btn.add_theme_stylebox_override("pressed", p)
	_continue_btn.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
	_continue_btn.custom_minimum_size = Vector2(120, 32)

func show_rewards(rewards: Dictionary, title_text: String = "战斗胜利") -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_countdown = 3.0
	_auto_close = true
	if _title:
		_title.text = title_text
	if _gold_line:
		_gold_line.text = "💰 +%s    ✨ +%s EXP" % [_fmt(int(rewards.get("gold", 0))), _fmt(int(rewards.get("exp", 0)))]
	_clear_items()
	if rewards.has("materials"):
		for mat_id in rewards["materials"]:
			var mat_name: String = DataManager.MATERIALS.get(mat_id, {}).get("name", mat_id)
			_add_item_line("🔮 %s ×%d" % [mat_name, int(rewards["materials"][mat_id])], Color(0.62, 0.86, 0.98))
	elif rewards.has("material"):
		var mat_name2: String = DataManager.MATERIALS.get(rewards["material"], {}).get("name", rewards["material"])
		_add_item_line("🔮 %s ×1" % mat_name2, Color(0.62, 0.86, 0.98))
	if rewards.has("items"):
		for item in rewards["items"]:
			_add_equip_row(item)
	elif rewards.has("item"):
		_add_equip_row(rewards["item"])
	_update_countdown_label()

func _add_item_line(text: String, color: Color) -> void:
	if not _items_box:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	_items_box.add_child(l)

func _add_equip_row(item: Dictionary) -> void:
	if not _items_box:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var rarity_colors: Array = [Color.WHITE, Color(0.3, 0.9, 0.3), Color(0.3, 0.6, 1.0), Color(0.8, 0.3, 1.0), Color(1.0, 0.8, 0.2)]
	var rc: Color = rarity_colors[mini(int(item["rarity"]), 4)]
	var name_l := Label.new()
	name_l.text = "⚔ %s" % item["name"]
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.add_theme_font_size_override("font_size", 10)
	name_l.add_theme_color_override("font_color", rc)
	row.add_child(name_l)
	var slot_key := DataManager.item_slot_key(item)
	var equipped = GameManager.game_data["equipment"].get(slot_key)
	var already: bool = equipped != null and str(equipped.get("uid", "")) == str(item.get("uid", ""))
	if already:
		var tag := Label.new()
		tag.text = "已装备"
		tag.add_theme_font_size_override("font_size", 9)
		tag.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
		row.add_child(tag)
	else:
		var btn := Button.new()
		btn.text = "装备"
		btn.add_theme_font_size_override("font_size", 9)
		btn.custom_minimum_size = Vector2(52, 24)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.22, 0.20, 0.28)
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		bs.border_width_left = 1
		bs.border_width_right = 1
		bs.border_width_top = 1
		bs.border_width_bottom = 1
		bs.border_color = Color(0.55, 0.48, 0.65)
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_color_override("font_color", Color(0.88, 0.84, 0.95))
		btn.pressed.connect(func(): _equip_item(item, btn))
		row.add_child(btn)
	_items_box.add_child(row)

func _equip_item(item: Dictionary, btn: Button) -> void:
	for i in range(GameManager.game_data["inventory"].size()):
		if GameManager.game_data["inventory"][i].get("uid", "") == item.get("uid", ""):
			GameManager.equip_item(item)
			btn.text = "已装备"
			btn.disabled = true
			return

func _clear_items() -> void:
	if not _items_box:
		return
	for c in _items_box.get_children():
		c.queue_free()

func _process(delta: float) -> void:
	if not visible or not _auto_close:
		return
	_countdown -= delta
	_update_countdown_label()
	if _countdown <= 0:
		_on_continue()

func _update_countdown_label() -> void:
	if _countdown_label:
		_countdown_label.text = "%.0fs 后自动继续" % maxf(0, ceil(_countdown))

func _on_continue() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
