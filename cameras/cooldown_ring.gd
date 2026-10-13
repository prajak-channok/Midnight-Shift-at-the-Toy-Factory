extends Control
class_name CooldownRing
## A circular ring without any number that empties clockwise as [member ratio] goes from 1 to 0.
## It turns [member urgent_color] while [member urgent] is true.

@export var ring_width := 7.0
@export var track_color := Color(0.2, 0.2, 0.22, 1.0)
@export var fill_color := Color(0.62, 0.63, 0.66, 1.0)
@export var urgent_color := Color(0.95, 0.12, 0.1, 1.0)

var ratio := 1.0:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if value != ratio:
			ratio = value
			queue_redraw()

var urgent := false:
	set(value):
		if value != urgent:
			urgent = value
			queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var outer := minf(size.x, size.y) / 2.0
	var radius := outer - ring_width / 2.0 - 1.0
	draw_arc(center, radius, 0.0, TAU, 64, track_color, ring_width, true)
	if ratio > 0.0:
		var start := -PI / 2.0
		draw_arc(center, radius, start, start + TAU * ratio, 64, urgent_color if urgent else fill_color, ring_width, true)
