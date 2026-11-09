@tool
extends Button

signal cam_button_pressed(cam_node_name:String)

@export var camera_node_name : String ## ชื่อโหนดของ Camera3D ที่เชื่อมกับปุ่มนี้ (Name of related Camera3D node)

@export var accent_color : Color = Color(0.35, 0.6, 1.0): ## สีธีมของปุ่มกล้อง (Theme color of the button)
	set(value):
		accent_color = value
		if is_node_ready():
			_apply_style()


var selected := false: ## สวิตช์บอกสถานะว่าปุ่มกล้องนี้กำลังถูกดูอยู่หรือไม่ (True while this button's camera is being watched)
	set(value):
		selected = value
		if is_node_ready():
			_apply_style()


func _ready():
	_apply_style()
	if Engine.is_editor_hint():
		return
	focus_mode = Control.FOCUS_NONE # ปิดโฟกัสเพื่อป้องกันไม่ให้ปุ่มทำงานเมื่อกดปุ่ม Space (Prevent button from triggering on Space bar)
	if camera_node_name.is_empty():
		camera_node_name = text


func _pressed():
	emit_signal("cam_button_pressed", camera_node_name)


func _apply_style():
	var base := accent_color.darkened(0.35)
	var bright := base.lightened(0.3)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_theme_constant_override("outline_size", 4)
	if selected:
		# แสดงผลแบบปุ่มสว่างเด่นชัดเมื่อกำลังถูกเลือกดู (Bright highlighted style for currently selected camera button)
		var rim := accent_color.lightened(0.7)
		var fill := accent_color.darkened(0.1)
		add_theme_stylebox_override("normal", _make_box(fill, 0.95, rim, 1.0, 0.55, 3, 8))
		add_theme_stylebox_override("hover", _make_box(fill.lightened(0.1), 0.98, rim, 1.0, 0.65, 3, 9))
		add_theme_stylebox_override("pressed", _make_box(fill.darkened(0.15), 1.0, rim, 1.0, 0.7, 3, 9))
		add_theme_color_override("font_color", Color.WHITE)
		add_theme_color_override("font_hover_color", Color.WHITE)
		add_theme_color_override("font_pressed_color", Color.WHITE)
		return
	add_theme_stylebox_override("normal", _make_box(base.darkened(0.8), 0.55, base, 0.7, 0.06))
	add_theme_stylebox_override("hover", _make_box(base.darkened(0.65), 0.65, bright, 0.85, 0.18))
	add_theme_stylebox_override("pressed", _make_box(base.darkened(0.45), 0.8, bright, 0.9, 0.28))
	add_theme_color_override("font_color", bright)
	add_theme_color_override("font_hover_color", base.lightened(0.55))
	add_theme_color_override("font_pressed_color", base.lightened(0.55))


func _make_box(bg: Color, bg_alpha: float, border: Color, border_alpha: float, glow_alpha: float, border_width := 2, glow_size := 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(bg, bg_alpha)
	box.set_border_width_all(border_width)
	box.border_color = Color(border, border_alpha)
	box.corner_radius_top_left = 9
	box.corner_radius_bottom_right = 9
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.shadow_color = Color(border, glow_alpha)
	box.shadow_size = glow_size
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box
