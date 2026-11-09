class_name LoadingOverlay
extends CanvasLayer

const RING_RADIUS := 36.0
const RING_WIDTH := 5.0
const ARC_LENGTH := TAU * 0.25
const SPIN_SPEED := TAU * 0.9

const TITLE_TEXT := "Loading..."
const HINT_TEXT := "The first load may take longer than usual."
const GROUP := &"loading_overlay"

var _dim: ColorRect


static func dismiss(tree: SceneTree) -> void:
	for overlay in tree.get_nodes_in_group(GROUP):
		overlay.queue_free()


## บังฉากที่ยังโหลดไม่เสร็จเพื่อไม่ให้เห็นการจัดวางโหนด (Hide unfinished loading scene so setup happens unseen)
func make_opaque() -> void:
	_dim.color.a = 1.0


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS # หมุนแสดงผลต่อไปได้แม้คืนจะถูก pause (Keeps spinning while game is paused)
	add_to_group(GROUP)

	var dim := ColorRect.new()
	_dim = dim
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP # ดักคลิกเมาส์เพื่อไม่ให้กดโดนปุ่มหรือสิ่งของด้านหลัง (Block mouse clicks from interacting underneath)
	add_child(dim)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	dim.add_child(column)

	var ring := _Ring.new()
	ring.custom_minimum_size = Vector2.ONE * (RING_RADIUS + RING_WIDTH) * 2.0
	column.add_child(ring)

	column.add_child(_make_label(TITLE_TEXT, 24, Color.WHITE))
	column.add_child(_make_label(HINT_TEXT, 16, Color(1, 1, 1, 0.65)))


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


class _Ring extends Control:
	var _angle := 0.0

	func _process(delta: float) -> void:
		_angle = fmod(_angle + SPIN_SPEED * delta, TAU)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_arc(center, RING_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.18), RING_WIDTH, true)
		draw_arc(center, RING_RADIUS, _angle, _angle + ARC_LENGTH, 32, Color.WHITE, RING_WIDTH, true)
