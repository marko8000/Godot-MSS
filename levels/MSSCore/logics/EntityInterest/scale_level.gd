extends RefCounted
class_name ScaleLevel


@export var chunk_size : int :
	set(value):
		chunk_size = max(value, 1)

func _init(_chunk_size : int) -> void:
	chunk_size = _chunk_size
