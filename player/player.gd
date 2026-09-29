extends Node3D
class_name Player

@export_group("Links")
@export var gui_node: Control
@export var cam_manager: CameraManager

@export_group("Panning Settings")
@export var panning_curve: Curve = preload("res://panning_curve_presets/smooth.tres")
@export var max_panning_speed: float = 70.0

# ระยะจากขอบจอที่จะเริ่มแพน
# 0.05 = 5% ของความกว้างหน้าจอ
@export_range(0.0, 0.5) var edge_threshold: float = 0.05

@export_range(0.0, 180.0) var left_rotation_limit: float = 50.0
@export_range(-180.0, 0.0) var right_rotation_limit: float = -50.0
@export var allow_360: bool = false

@onready var cam: Camera3D = $Camera3D
@onready var monitor = $%Monitor


func _ready():
	cam.current = true


func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_width = get_viewport().get_visible_rect().size.x

	if viewport_width <= 0:
		return

	var mouse_x = mouse_pos.x / viewport_width

	panning_edge(delta, mouse_x)


func panning_edge(delta: float, mouse_x: float):
	var speed_multiplier := 0.0

	# เมาส์อยู่ด้านซ้ายของจอ
	if mouse_x <= edge_threshold:
		var strength = (edge_threshold - mouse_x) / edge_threshold
		strength = clampf(strength, 0.0, 1.0)

		speed_multiplier = panning_curve.sample(strength)

	# เมาส์อยู่ด้านขวาของจอ
	elif mouse_x >= 1.0 - edge_threshold:
		var strength = (mouse_x - (1.0 - edge_threshold)) / edge_threshold
		strength = clampf(strength, 0.0, 1.0)

		speed_multiplier = -panning_curve.sample(strength)

	# ถ้าไม่อยู่บริเวณขอบ → speed = 0
	cam.rotation_degrees.y += delta * max_panning_speed * speed_multiplier

	if not allow_360:
		cam.rotation_degrees.y = clampf(
			cam.rotation_degrees.y,
			right_rotation_limit,
			left_rotation_limit
		)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			toggle_monitor()


func toggle_monitor():
	if monitor.monitor_on:
		await monitor.turn_off()
		cam_manager.disable_camera_display()
		cam.current = true
	else:
		await monitor.turn_on()
		cam.current = false
		cam_manager.enable_camera_display()


func force_monitor_down():
	if monitor.monitor_on:
		await monitor.turn_off()
		cam_manager.disable_camera_display()
		cam.current = true


func is_monitor_on() -> bool:
	return monitor.monitor_on
