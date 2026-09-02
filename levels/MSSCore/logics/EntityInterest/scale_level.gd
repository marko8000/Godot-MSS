extends RefCounted
class_name ScaleLevel


@export var chunk_size : int :
	set(value):
		chunk_size = max(value, 1)
@export var lod_draw_distances : PackedInt32Array

func _init(_chunk_size : int, _lod_draw_distances : PackedInt32Array) -> void:
	chunk_size = _chunk_size
	lod_draw_distances = _lod_draw_distances
