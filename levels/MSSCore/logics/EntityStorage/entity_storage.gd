extends MSSLogic
class_name EntityStorage


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityFactory := _MSSCore._EntityFactory
@onready var _EntityInterest := _MSSCore._EntityInterest
@onready var _ChunkCalculator := _MSSCore._ChunkCalculator
@onready var _InterpolationState := _MSSCore._InterpolationState

var _entities_can_start_working : bool = false
signal _entities_start_working
var main_tickrate : int = 30

# Allocate
var _data_sources : Array[EntityDataSource]
var _entity_indices : PackedInt32Array
var _entity_ids : PackedInt64Array
var _entity_types : PackedInt32Array
var _nodes : Array[Node]
var _entity_free_slots : PackedInt32Array

# Activate
var _activation_queue : Array[ActivationBatch]
class ActivationBatch:
	var type_batches : Array[PackedInt32Array]
var _entity_parent : PackedInt32Array # -1 for root storage
var _entity_root : PackedInt32Array # -1 for root storage
var _root_chunk : PackedInt32Array
var _entity_scale_level_idx : PackedByteArray
var _entity_lod : PackedByteArray
var _chunks : Array[Variant]
var _chunk_scale_level : PackedByteArray
var _chunk_free_slots : PackedInt32Array
var _chunk_idx_by_chunk : Dictionary[Variant, int]
var _move_queue : Array[PackedInt32Array]
var _remove_queue : Array[PackedInt32Array]
var _entity_tree : Array[ChunkData]
class ChunkData:
	var type_batches : Array[TypeBatch]
	class TypeBatch:
		var entity_indices : PackedInt32Array
		var children : Array[TypeBatch]
		## 0 - create flag [br]
		## 1 - update flag [br]
		## 2 - remove flag [br]
		## 3 - moved to chunk (lod_level, chunk_type, chunk_data) [br]
		## 4 - moved from chunk (lod_level, chunk_type, chunk_data) [br]
		var flags : PackedInt32Array
		var tickrate_data : Vector2i
		func _to_string() -> String:
			return str(entity_indices, children, flags)

var _chunk_buffers : Array[ChunkBuffer]
class ChunkBuffer:
	var cursor : PackedInt32Array
	var spawn_buffer : PackedByteArray
	var update_buffer : PackedByteArray
	func clear() -> void:
		cursor.clear()
		spawn_buffer.clear()
		update_buffer.clear()
	
	
static func get_from(from : Node) -> EntityStorage:
	return MSSCore.get_from(from)._EntityStorage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	

func _connection_peer_changed(new_peer):
	if not _entities_can_start_working:
		_entities_start_working.emit()
		_entities_can_start_working = true
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection peer setted', self.name)
		

func _allocate_chunk(chunk : Variant) -> int:
	var chunk_idx : int
	if not _chunk_free_slots.is_empty():
		chunk_idx = _chunk_free_slots[-1]
		_chunk_free_slots.resize(_chunk_free_slots.size()-1)
		_chunks[chunk_idx] = chunk
		_chunk_scale_level[chunk_idx] = chunk[-1]
	else:
		chunk_idx = _chunks.size()
		_chunks.append(chunk)
		_chunk_scale_level.append(chunk[-1])
	_chunk_idx_by_chunk[chunk] = chunk_idx
	return chunk_idx
	
	
func _allocate_batch(entity_type : int, nodes : Array[Node]) -> PackedInt32Array:
	var entity_indices : PackedInt32Array
	var type_data := _EntityFactory._entity_type_data[entity_type]
	var last_parent : Node
	var last_depth : int
	var storage := _ChunkCalculator.dim_data[type_data.dimension].storage
	for node in nodes:
		var entity_id := _EntityFactory._get_new_entity_id()
		var idx : int
		@warning_ignore("unassigned_variable")
		if node.get_parent() != last_parent:
			last_parent = node.get_parent()
			last_depth = 0
			var current_parent := node.get_parent()
			while current_parent != self:
				print(node, current_parent)
				if current_parent == _MSSCore:
					last_depth = -1
					break
				elif current_parent == storage:
					break
				last_depth += 1
				current_parent = current_parent.get_parent()
		if last_depth == -1:
			continue
		if not _entity_free_slots.is_empty():
			idx = _entity_free_slots[-1]
			_entity_free_slots.resize(_entity_free_slots.size()-1)
			_entity_ids[idx] = entity_id
			_entity_types[idx] = entity_type
			_nodes[idx] = node
			_entity_scale_level_idx[idx] = -1
			_entity_lod[idx] = -1
		else:
			idx = _entity_ids.size()
			_entity_ids.append(entity_id)
			_entity_types.append(entity_type)
			_nodes.append(node)
			_entity_parent.append(-1)
			_entity_root.append(-1)
			_root_chunk.append(0)
			_entity_scale_level_idx.append(-1)
			_entity_lod.append(-1)
		
		node.name = str(idx)
		print(node.name)
		entity_indices.append(idx)
		node.get_node('EntitySeed').queue_free()
		
		if _activation_queue.size() < last_depth+1:
			for _i in range(_activation_queue.size(), last_depth+1):
				_activation_queue.append(ActivationBatch.new())
		var ld_tb := _activation_queue[last_depth].type_batches
		if ld_tb.size() < entity_type+1:
			for _i in range(ld_tb.size(), entity_type+1):
				ld_tb.append(PackedInt32Array())
		ld_tb[entity_type].append(idx)
				
	for source_idx in range(_data_sources.size()):
		var source_list_idx = type_data.source_indices.find(source_idx)
		var source = _data_sources[source_idx]
		source._sparse_array.resize(_entity_ids.size())
		if not source_list_idx == -1:
			source._allocate_batch(entity_indices, type_data, source_list_idx)
	return entity_indices
	
	
var current_frame : int = 1
var frames_per_tick : int
var workers : Array[EntityWorker]
var worker_entity_limit : int = 500
var worker_budget : int
func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		frames_per_tick = _InterpolationState.server_FPS / main_tickrate
		if current_frame == 1:
			#_EntityInterest._request_chunks()
			_process_activation_queue()
			_process_move_queue()
			_process_remove_queue()
			var worker_count := ceili(float(_entity_ids.size()) / worker_entity_limit)
			if worker_count > workers.size():
				for _i in worker_count-workers.size():
					workers.append(EntityWorker.new())
			worker_budget = ceili(float(worker_entity_limit) / _InterpolationState.server_FPS)
		_process_update()
		if current_frame >= main_tickrate:
			_EntityInterest.send_chunks()
			_chunk_buffers.clear()
			current_frame = 1
		else:
			current_frame += 1
	
	
func _process_activation_queue():
	for s in range(_activation_queue.size()):
		var invalid_entities_i : Array[PackedInt32Array]
		for type in range(_activation_queue[s].type_batches.size()):
			var eindices := _activation_queue[s].type_batches[type]
			var type_data := _EntityFactory._entity_type_data[type]
			var storage := _ChunkCalculator.dim_data[type_data.dimension].storage
			if invalid_entities_i.size() < type+1:
				for __ in range(invalid_entities_i.size(), type+1):
					invalid_entities_i.append(PackedInt32Array())
			for i in range(eindices.size()):
				var entity_idx := eindices[i]
				
				var entity_node := _nodes[entity_idx]
				var current_entity_idx := -1
				var parent_node := entity_node.get_parent()
				var parent_idx := -1
				var root_idx := -1
				var chunk_node := entity_node
				var root_path := PackedInt32Array([entity_idx])
				var scale_level_idx := type_data.root_scale_level_idx
				var lod := 0
				while true:
					if str(parent_node.name).is_valid_int():
						current_entity_idx = int(parent_node.name)
						if scale_level_idx == _entity_scale_level_idx[
							current_entity_idx]:
							root_idx = current_entity_idx
							chunk_node = parent_node
						if not parent_idx+1:
							parent_idx = current_entity_idx
							lod = maxi(
								0,
								_entity_lod[current_entity_idx]-1)
						root_path.append(current_entity_idx)
					if parent_node == storage:
						break
					parent_node = parent_node.get_parent()
				_entity_root[entity_idx] = root_idx
				_entity_parent[entity_idx] = parent_idx
				if lod == 0:
					lod = type_data.root_lod
				_entity_scale_level_idx[entity_idx] = scale_level_idx
				_entity_lod[entity_idx] = lod
					
				var chunk_node_type := _entity_types[root_idx]
				var chunk_node_type_data := _EntityFactory._entity_type_data[chunk_node_type]
				var chunk = _ChunkCalculator.position_to_chunk(chunk_node.position, 
				scale_level_idx, chunk_node_type_data.dimension)
				var chunk_idx : int
				if _chunk_idx_by_chunk.has(chunk):
					invalid_entities_i[type].append(entity_idx)
					chunk_idx = _chunk_idx_by_chunk[chunk]
				else:
					continue
				_root_chunk[entity_idx] = chunk_idx
				var batches := _entity_tree[chunk_idx].type_batches
				var parent_type : int
				for j in range(root_path.size() - 1, -1, -1):
					parent_type = _entity_types[root_path[j]]
					if batches.size() < parent_type+1:
						batches.resize(parent_type+1)
						for _i in range(batches.size(), parent_type+1):
							batches.append(ChunkData.TypeBatch.new())
					batches = batches[parent_type].children
				var type_batch := batches[parent_type]
				type_batch.entity_indices.append(entity_idx)
				type_batch.children.append(ChunkData.TypeBatch.new())
				type_batch.flags.append(0)
	
		# remove invalid entities
		for type in range(invalid_entities_i.size()):
			var remove_indices : PackedInt32Array
			for i in invalid_entities_i[type]:
				var entity_idx := _activation_queue[s].type_batches[type][i]
				_nodes[entity_idx].queue_free()
				_entity_free_slots.append(entity_idx)
				remove_indices.append(entity_idx)
			var type_data := _EntityFactory._entity_type_data[type]
			for source_idx in range(_data_sources.size()):
				var source_list_idx = type_data.source_indices.find(source_idx)
				var source = _data_sources[source_idx]
				if not source_list_idx == -1:
					source._remove_batch(remove_indices, 
					type_data, source_list_idx)
					
			_activation_queue[s].type_batches[type].clear()


func _process_move_queue():
	pass


func _process_remove_queue():
	pass



func _process_update():
	for chunk in _EntityInterest._chunk_requested:
		pass
	
