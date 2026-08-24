@tool
extends Resource
class_name ScaleLevel


@export var chunk_size : int :
	set(value):
		chunk_size = max(value, 1)
@export var lod_level_draw_distances : PackedInt32Array
