@tool
extends Marker3D
class_name AnimatronicPosition
## Position that an animatronic can go to.
##
## This node represents a transform and an animation that an animatronic can apply to itself.

@export var animation_to_play : String = "" ## The animation that the animatronic can play when here.


## Returns the AnimatronicPosition above this one in the scene hierarchy. Or null if we are the first one.
func get_previous_position() -> AnimatronicPosition:
	var siblings := get_parent().get_children()
	for i in range(get_index() - 1, -1, -1):
		if siblings[i] is AnimatronicPosition:
			return siblings[i]
	return null


## Returns the AnimatronicPosition below this one in the scene hierarchy. Or null if we are the last one.
func get_next_position() -> AnimatronicPosition:
	var siblings := get_parent().get_children()
	for i in range(get_index() + 1, siblings.size()):
		if siblings[i] is AnimatronicPosition:
			return siblings[i]
	return null
