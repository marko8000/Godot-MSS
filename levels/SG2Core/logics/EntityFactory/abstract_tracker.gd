@abstract
extends Resource
class_name Tracker


@warning_ignore("unused_private_class_variable")
var _update_mask_size : int = 1
@warning_ignore("unused_private_class_variable")
var _sparse_array : PackedInt32Array
@warning_ignore("unused_private_class_variable")
var _free_cells : Array[PackedInt32Array] = [[], ]
@warning_ignore("unused_private_class_variable")
var _nodes : Array[Node]


func _allocate_batch(entity_indices : PackedInt32Array, nodes : Array[Node], type_data : EntityFactory.EntityTypeData, tracker_list_idx : int):
	pass


func _remove_batch(entity_indices : PackedInt32Array, type_data : EntityFactory.EntityTypeData, tracker_list_idx : int):
	pass
	
	
func _update_batch(entity_indices : PackedInt32Array, entity_type_data : EntityFactory.EntityTypeData, chunk):
	pass
