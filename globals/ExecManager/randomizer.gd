extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func give_random_int_in_range(from : int, to : int):
	return randi_range(from, to)
	
	
func give_random_float_in_range(from : float, to : float):
	return randi_range(from, to)


func give_random_bool():
	return bool(randi_range(0, 1))
