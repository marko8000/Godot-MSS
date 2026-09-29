extends MSSLogic
class_name EntityStorageLogic


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityFactory := _MSSCore._EntityFactory
@export var _EntityInterest : EntityInterest
@export var _ChunkCalculator : ChunkCalculator
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
var _chunks : Array[PackedInt64Array]
var _chunk_free_slots : PackedInt32Array
var _chunk_idx_by_chunk : Dictionary[PackedInt64Array, int]
#var _move_queue : Array[PackedInt32Array]
#var _remove_queue : Array[PackedInt32Array]
var _entity_tree : Array[ChunkData]
class ChunkData:
	var type_batches : Array[TypeBatch]
class TypeBatch:
	extends ChunkData
	var entity_indices : PackedInt32Array
	# 0 - create flag
	# 1 - update flag
	# 2 - remove flag
	# 3 - moved to chunk (chunk_data)
	# 4 - moved from chunk (chunk_data)
	var flags : PackedInt32Array
	var tickrate_data : Vector2i
	func _to_string() -> String:
		return str(entity_indices, type_batches, flags)

var _chunk_buffers : Array[ChunkBuffer]
class ChunkBuffer:
	var cursor : PackedInt32Array
	var spawn_buffer : PackedByteArray
	var update_buffer : PackedByteArray
	func clear() -> void:
		cursor.clear()
		spawn_buffer.clear()
		update_buffer.clear()
	
	
static func get_from(from : Node) -> EntityStorageLogic:
	var parent := from
	while true:
		if parent.get_child_count() > 0 and parent.get_child(0) is EntityStorageLogic:
			return parent.get_child(0)
		elif parent is MSSCore:
			break
		elif parent is Viewport:
			break
		parent = parent.get_parent()
	return


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
		

func _allocate_chunk(chunk : PackedInt64Array) -> int:
	var chunk_idx : int
	if not _chunk_free_slots.is_empty():
		chunk_idx = _chunk_free_slots[-1]
		_chunk_free_slots.resize(_chunk_free_slots.size()-1)
		_chunks[chunk_idx] = chunk
	else:
		chunk_idx = _chunks.size()
		_chunks.append(chunk)
	_chunk_idx_by_chunk[chunk] = chunk_idx
	
	var required_size: int = chunk_idx + 1
	if _entity_tree.size() < required_size:
		var old_size: int = _entity_tree.size()
		_entity_tree.resize(required_size)
		_EntityInterest._chunk_status.resize(required_size)
		for i : int in range(old_size, required_size):
			_entity_tree[i] = ChunkData.new()
			_EntityInterest._chunk_status[i] = EntityInterest.ChunkStatus.NOT_REQUESTED
	
	return chunk_idx
	
	
func _allocate_batch(entity_type : int, nodes : Array[Node]) -> PackedInt32Array:
	var entity_indices : PackedInt32Array
	var type_data := _EntityFactory._entity_type_data[entity_type]
	var last_parent : Node
	var last_depth : int
	for node : Node in nodes:
		var entity_id := _EntityFactory._get_new_entity_id()
		var idx : int
		@warning_ignore("unassigned_variable")
		if node.get_parent() != last_parent:
			last_parent = node.get_parent()
			last_depth = 0
			var current_parent := node.get_parent()
			while true:
				if current_parent == _MSSCore:
					last_depth = -1
					break
				elif current_parent == get_parent():
					break
				last_depth += 1
				current_parent = current_parent.get_parent()
		if last_depth == -1:
			continue
		_entity_indices.append(idx)
		if not _entity_free_slots.is_empty():
			idx = _entity_free_slots[-1]
			_entity_free_slots.resize(_entity_free_slots.size()-1)
			_entity_indices[entity_id] = idx
			_entity_ids[idx] = entity_id
			_entity_types[idx] = entity_type
			_nodes[idx] = node
		else:
			idx = _entity_ids.size()
			_entity_indices.append(idx)
			_entity_ids.append(entity_id)
			_entity_types.append(entity_type)
			_nodes.append(node)
			_entity_parent.append(-1)
			_entity_root.append(-1)
			_root_chunk.append(0)
		
		node.name = str(idx)
		entity_indices.append(idx)
		node.get_node('EntitySeed').queue_free()
		
		if _activation_queue.size() < last_depth+1:
			for _i : int in range(_activation_queue.size(), last_depth+1):
				_activation_queue.append(ActivationBatch.new())
		var ld_tb := _activation_queue[last_depth].type_batches
		if ld_tb.size() < entity_type+1:
			for _i : int in range(ld_tb.size(), entity_type+1):
				ld_tb.append(PackedInt32Array())
		ld_tb[entity_type].append(idx)
				
	for source_idx : int in range(_data_sources.size()):
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
			_EntityInterest._request_chunks()
			_process_activation_queue()
			_process_move_queue()
			_process_remove_queue()
			var worker_count := ceili(float(_entity_ids.size()) / worker_entity_limit)
			if worker_count > workers.size():
				for _i : int in worker_count-workers.size():
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
	for s : int in range(_activation_queue.size()):
		var invalid_entities_i : Array[PackedInt32Array]
		for type : int in range(_activation_queue[s].type_batches.size()):
			var eindices := _activation_queue[s].type_batches[type]
			if invalid_entities_i.size() < type+1:
				for __ in range(invalid_entities_i.size(), type+1):
					invalid_entities_i.append(PackedInt32Array())
			for i : int in range(eindices.size()):
				var entity_idx := eindices[i]
				
				var entity_node := _nodes[entity_idx]
				var current_entity_idx := -1
				var parent_node := entity_node.get_parent()
				var parent_idx := -1
				var root_idx := -1
				var chunk_node := entity_node
				var root_path := PackedInt32Array([entity_idx])
				while true:
					if str(parent_node.name).is_valid_int():
						current_entity_idx = int(parent_node.name)
						if parent_idx == -1:
							parent_idx = current_entity_idx
						root_idx = current_entity_idx
						chunk_node = parent_node
						root_path.append(current_entity_idx)
					if parent_node == get_parent():
						break
					parent_node = parent_node.get_parent()
				
				_entity_root[entity_idx] = root_idx
				_entity_parent[entity_idx] = parent_idx
				
				var chunk_node_type := _entity_types[root_idx]
				var chunk_node_type_data := _EntityFactory._entity_type_data[chunk_node_type]
				var chunk = _ChunkCalculator.position_to_chunk(
					_ChunkCalculator.node_to_position(chunk_node, chunk_node_type_data.dimension),
					chunk_node_type_data.dimension)
				var chunk_idx : int
				if not _chunk_idx_by_chunk.has(chunk):
					invalid_entities_i[type].append(i)
					continue
				else:
					chunk_idx = _chunk_idx_by_chunk[chunk]
				_root_chunk[root_idx] = chunk_idx
				var chunk_data := _entity_tree[chunk_idx]
				var batches : Array[TypeBatch]
				var parent_type : int
				for j : int in range(root_path.size() - 1, -1, -1):
					batches = chunk_data.type_batches
					parent_type = _entity_types[root_path[j]]
					if batches.size() < parent_type + 1:
						var old_size = batches.size()
						batches.resize(parent_type + 1)
						for _i : int in range(old_size, batches.size()):
							batches[_i] = TypeBatch.new()
					chunk_data = batches[parent_type]
				var type_batch : TypeBatch = chunk_data
				type_batch.entity_indices.append(entity_idx)
				type_batch.flags.append(0)
	
		# remove invalid entities
		for type : int in range(invalid_entities_i.size()):
			var remove_indices : PackedInt32Array
			for i : int in invalid_entities_i[type]:
				var entity_idx := _activation_queue[s].type_batches[type][i]
				_entity_indices[_entity_ids[entity_idx]] = -1
				_entity_ids[entity_idx] = -1
				_nodes[entity_idx].queue_free()
				_entity_free_slots.append(entity_idx)
				remove_indices.append(entity_idx)
			var type_data := _EntityFactory._entity_type_data[type]
			for source_idx : int in range(_data_sources.size()):
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
	for chunk_idx : int in _EntityInterest._chunk_status:
		pass
	
