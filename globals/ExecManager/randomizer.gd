extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func ri(from : int, to : int):
	return randi_range(from, to)
	
	
func rfloat(from : float, to : float):
	return randi_range(from, to)


func rbool():
	return bool(randi_range(0, 1))
