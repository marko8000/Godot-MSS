@abstract
extends Resource
class_name MultiplayerAction


var _update_mask_size : int
var _is_update : bool
var _is_zero : bool

func _ready() -> void:
	pass
	
func _local_ready() -> void:
	pass
	
func _not_update() -> void:
	pass
	
func _write_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	pass

func _read_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int) -> void:
	pass
	
func _copy() -> MultiplayerAction:
	return
	
func _input(event : InputEvent):
	pass
