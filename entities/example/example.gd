extends Node3D


func get_EntityLogic():
	return $EntityLogic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


var trans_vector = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed('ui_accept'):
		translate(trans_vector * delta)
		rotate_x(10)
