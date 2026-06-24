extends Control
class_name EquipSellConfirm
## 出售确认 — 稀有及以上装备二次确认

signal confirmed(item: Dictionary)
signal cancelled

var _item: Dictionary = {}

var _overlay: ColorRect
var _panel: PanelContainer
var _body: Label
var _ok_btn: Button
var _cancel_btn: Button

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_ok_btn.pressed.connect(_on_ok)
	_cancel_btn.pressed.connect(_on_cancel)

func open(item: Dictionary) -> void:
	_item = DataManager.normalize_item(item)
	if _item.is_empty():
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rarity: int = int(_item.get("rarity", 0))
	var ri: Dictionary = DataManager.RARITY_INFO[rarity as DataManager.Rarity]
	var gold: int = InventoryUtils.sell_price(_item)
	_body.text = "确定出售「%s」？\n将获得 %d 金币" % [_item.get("name", ""), gold]

func dismiss() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item = {}

func _on_ok() -> void:
	if not _item.is_empty():
		confirmed.emit(_item)
	dismiss()

func _on_cancel() -> void:
	cancelled.emit()
	dismiss()

func _build_ui() -> void:
	if _panel != null:
		return
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_on_cancel())
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(260, 0)
	center.add_child(_panel)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.12, 0.98)
	ps.corner_radius_top_left = 12
	ps.corner_radius_top_right = 12
	ps.corner_radius_bottom_left = 12
	ps.corner_radius_bottom_right = 12
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.7, 0.45, 0.35, 0.8)
	ps.content_margin_left = 16.0
	ps.content_margin_right = 16.0
	ps.content_margin_top = 14.0
	ps.content_margin_bottom = 14.0
	_panel.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)
	var title := Label.new()
	title.text = "出售确认"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.65))
	vbox.add_child(title)
	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 11)
	_body.add_theme_color_override("font_color", ThemeConfig.TXT_PRIMARY)
	vbox.add_child(_body)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)
	_cancel_btn = Button.new()
	_cancel_btn.text = "取消"
	_cancel_btn.custom_minimum_size = Vector2(80, 32)
	footer.add_child(_cancel_btn)
	_ok_btn = Button.new()
	_ok_btn.text = "确认出售"
	_ok_btn.custom_minimum_size = Vector2(100, 32)
	footer.add_child(_ok_btn)
