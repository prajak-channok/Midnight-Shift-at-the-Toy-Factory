extends Resource
class_name AnimatronicGraph
## Movement graph + timing of one animatronic.
##
## The destination "Office" is reserved: it has no marker and means "attack the office"
## (what that means is up to the animatronic, see [method FnafAnimatronic._on_reach_office]).

const OFFICE := &"Office"

@export var start_position: StringName ## Where the animatronic starts.
@export var return_position: StringName ## Where the animatronic retreats to after being blocked. Empty = [member start_position].
@export_group("Timing")
@export var decision_time_min: float = 5.0 ## Seconds between movement opportunities (random between min and max).
@export var decision_time_max: float = 7.0
@export var blocked_retreat_delay_min: float = 2.0 ## Seconds a closed door must hold before the animatronic retreats.
@export var blocked_retreat_delay_max: float = 4.0
@export_group("Graph")
@export var nodes: Array[AnimatronicGraphNode] = []


## Picks a destination from [param from] by weight. Returns an empty name if there is none.
func pick_destination(from: StringName) -> StringName:
	for node in nodes:
		if node.position_name != from:
			continue
		var total := 0.0
		for weight: float in node.destinations.values():
			total += weight
		if total <= 0.0:
			return &""
		var roll := randf() * total
		for destination: StringName in node.destinations:
			roll -= node.destinations[destination]
			if roll < 0.0:
				return destination
	return &""


func get_return_position() -> StringName:
	return return_position if return_position != &"" else start_position


## Every position name the graph refers to (without the reserved Office).
func get_all_position_names() -> Array[StringName]:
	var names: Array[StringName] = [start_position, get_return_position()]
	for node in nodes:
		names.append(node.position_name)
		for destination: StringName in node.destinations:
			names.append(destination)
	var unique: Array[StringName] = []
	for pos_name in names:
		if pos_name != OFFICE and pos_name not in unique:
			unique.append(pos_name)
	return unique
