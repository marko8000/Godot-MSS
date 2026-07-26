@tool
extends Control


func _physics_process(delta: float) -> void:
	$SubViewport/Node3D/MeshInstance3D.rotate_y(delta * 1)
