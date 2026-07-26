@tool
extends Control
class_name PulseControl


@export var min_scale : float = 0.99
@export var max_scale : float = 1
@export var start_cycle_state : CycleState = CycleState.DECREASE
@export_custom(PROPERTY_HINT_NONE, "suffix:seconds") var decrease_time : float = 1
@export_custom(PROPERTY_HINT_NONE, "suffix:seconds") var increase_time : float = 1
var current_cycle_state : CycleState = CycleState.DECREASE
enum CycleState {DECREASE, INCREASE}


func _ready() -> void:
	match start_cycle_state:
		CycleState.DECREASE:
			get_child(0).scale = Vector2.ONE * max_scale
		CycleState.INCREASE:
			get_child(0).scale = Vector2.ONE * min_scale
	current_cycle_state = start_cycle_state
	
	
func _process(delta: float) -> void:
	if get_child_count() == 0 or not get_child(0) is Control:
		return
		
	var child = get_child(0)
	child.pivot_offset = child.size / 2
	var term : float
	match current_cycle_state:
		CycleState.DECREASE:
			term = (max_scale-min_scale) * delta / decrease_time
			if (child.scale.x - term) < min_scale:
				child.scale = Vector2.ONE * min_scale
				current_cycle_state = CycleState.INCREASE
			else:
				child.scale -= Vector2.ONE * term
		CycleState.INCREASE:
			term = (max_scale-min_scale) * delta / increase_time
			if (child.scale.x + term) > max_scale:
				child.scale = Vector2.ONE * max_scale
				current_cycle_state = CycleState.DECREASE
			else:
				child.scale += Vector2.ONE * term
