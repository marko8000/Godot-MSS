extends Camera3D
class_name FPSCamera3D


@export var target : Node3D

	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	global_position = target.global_position
	global_rotation = target.global_rotation
