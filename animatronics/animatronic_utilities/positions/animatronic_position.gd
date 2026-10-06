@tool
extends Marker3D
class_name AnimatronicPosition
## Position that an animatronic can go to.
##
## This node represents a transform and an animation that an animatronic can apply to itself.

@export var animation_to_play : String = "" ## The animation that the animatronic can play when here.
