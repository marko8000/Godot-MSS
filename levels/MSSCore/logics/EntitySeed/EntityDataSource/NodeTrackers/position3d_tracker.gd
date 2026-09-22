@icon('res://levels/MSSCore/images/ToolMove3D.svg')
extends NodeTracker
class_name Position3DTracker


var _nodes : Array[Node3D]
var _values : PackedVector3Array


func _allocate_batch(entity_indices : PackedInt32Array, type_data : EntityFactory.EntityTypeData, tracker_list_idx : int = -1):
	var cell_size : int = type_data.cell_size[tracker_list_idx]
	if _free_cells.size() <= cell_size:
		_free_cells.resize(cell_size+1)
	for entity_idx : int in entity_indices:
		var cell_idx : int
		if not _free_cells[cell_size].is_empty():
			cell_idx = _free_cells[cell_size][-1]
			_free_cells[cell_size].resize(_free_cells[cell_size].size()-1)
			for j : int in range(cell_size):
				_nodes[cell_idx+j] = _EntityStorage._nodes[entity_idx].get_node(type_data.node_paths[tracker_list_idx][j])
		else:
			cell_idx = _values.size()
			for j : int in range(cell_size):
				_values.append(Vector3.ZERO)
				_nodes.append(_EntityStorage._nodes[entity_idx].get_node(type_data.node_paths[tracker_list_idx][j]))
		_sparse_array[entity_idx] = cell_idx
	
	
func _remove_batch(entity_indices : PackedInt32Array, type_data : EntityFactory.EntityTypeData, tracker_list_idx : int):
	var cell_size : int = type_data.cell_size[tracker_list_idx]
	for entity_idx : int in entity_indices:
		_free_cells[cell_size].append(_sparse_array[entity_idx])
		
		
func _update_batch(entity_indices : PackedInt32Array, entity_type_data : EntityFactory.EntityTypeData, chunk):
	pass
