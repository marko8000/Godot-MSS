@abstract
extends SG2Logic
class_name EntityStorageLogic


func _ready() -> void:
	get_parent().add_to_group('s')
	print(get_parent().name)
	
	
func _start_tracking(entity_id : int, entity_type : int, entity_node : Node, chunk=null, chunk_from_pos : bool=true):
	pass
	
