extends Resource
class_name AnimatronicGraphNode
## One position of an AnimatronicGraph and the positions it can move to from there.

@export var position_name: StringName ## Must match the name of an AnimatronicPosition marker.
@export var destinations: Dictionary[StringName, float] = {} ## Destination position name -> relative weight (60 vs 40 means 60% vs 40%).
