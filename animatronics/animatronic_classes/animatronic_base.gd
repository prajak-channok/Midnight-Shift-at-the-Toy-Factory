extends Node3D
class_name AnimatronicBase
## Base class for all animatronics that have an AI level.
##
## Night only talks to animatronics through this class: it sets [member ai_level], calls
## [method start_ai] / [method stop_ai], and reacts to [signal reached_office].

signal reached_office ## Emitted when the animatronic got into the office and the night is lost.

const MAX_AI_LEVEL := 20

@export var id: StringName ## Key used by NightDifficulty to look up this animatronic's AI profile.
@export var jumpscare: AnimatronicJumpscare ## Played when this animatronic reaches the office.

var ai_level := 0


func start_ai() -> void:
	pass


func stop_ai() -> void:
	pass
