extends MSSLogic
class_name EntityStorageLogic


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityFactory := _MSSCore._EntityFactory
@export var _EntityInterest : EntityInterest
@export var _ChunkCalculator : ChunkCalculator
@onready var _InterpolationState := _MSSCore._InterpolationState
@onready var _RootEntityStorageLogic := _MSSCore._RootEntityStorageLogic

var _entities_can_start_working : bool = false
signal _entities_start_working
@export var main_tickrate : int = 20

@warning_ignore("unused_private_class_variable")
var _storage_logic_array : Array[EntityStorageLogic]

# Allocate
@onready var _data_sources := _EntityFactory._data_sources
var _entity_indices : PackedInt32Array
var _entity_ids : PackedInt64Array
var _entity_types : PackedInt32Array
var _nodes : Array[Node]
var _entity_free_slots : PackedInt32Array

# Activate
var _activation_queue : Array[ActivationBatch]
class ActivationBatch:
	var type_batches : Array[PackedInt32Array]
var _entity_parent : PackedInt32Array
var _entity_root : PackedInt32Array

# Local
var _root_chunk : PackedInt32Array
var _chunks : Array[PackedInt64Array]
var _chunk_free_slots : PackedInt32Array
var _chunk_idx_by_chunk : Dictionary[PackedInt64Array, int]
#var _move_queue : Array[PackedInt32Array]
#var _remove_queue : Array[PackedInt32Array]
var _entity_tree : Array[ChunkData]
class ChunkData:
	var entity_indices : PackedInt32Array
	var free_slots : PackedInt32Array
	# 0 - create flag
	# 1 - update flag
	# 2 - remove flag
	# 3 - moved to chunk (chunk_idx)
	# 4 - moved from chunk (chunk_idx)
	var flags : Array[PackedInt64Array]
	var path_from_parent_changed : PackedByteArray
	var path_from_parent : PackedStringArray
	var child_data : Array[TypeBatches]
var _entity_tree_indices : PackedInt32Array
	
class TypeBatches:
	var type_batches : Array[ChunkData]
	
var _chunk_buffers : Array[ChunkBuffer]
class ChunkBuffer:
	var spawn_buffer : Array[PackedByteArray]
	var update_buffer : Array[PackedByteArray]
	func clear() -> void:
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
	
	_RootEntityStorageLogic._storage_logic_array.append(self)
	
	_data_sources = _RootEntityStorageLogic._data_sources
	_entity_indices = _RootEntityStorageLogic._entity_indices
	_entity_ids = _RootEntityStorageLogic._entity_ids
	_entity_types = _RootEntityStorageLogic._entity_types
	_nodes = _RootEntityStorageLogic._nodes
	_entity_free_slots = _RootEntityStorageLogic._entity_free_slots
	
	_activation_queue = _RootEntityStorageLogic._activation_queue
	_entity_parent = _RootEntityStorageLogic._entity_parent
	_entity_root = _RootEntityStorageLogic._entity_root
	

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
		_chunk_buffers.resize(required_size)
		_EntityInterest._chunk_requested.resize(required_size)
		for i : int in range(old_size, required_size):
			var chunk_data := ChunkData.new()
			chunk_data.entity_indices.append(-1)
			chunk_data.child_data.append(TypeBatches.new())
			_entity_tree[i] = chunk_data
			_chunk_buffers[i] = ChunkBuffer.new()
			_EntityInterest._chunk_requested[i] = EntityInterest.ChunkStatus.NOT_REQUESTED
	
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
			_entity_tree_indices[idx] = -1
		else:
			idx = _entity_ids.size()
			_entity_indices.append(idx)
			_entity_ids.append(entity_id)
			_entity_types.append(entity_type)
			_nodes.append(node)
			_entity_parent.append(-1)
			_entity_root.append(-1)
			_root_chunk.append(0)
			_entity_tree_indices.append(-1)
		
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
	
	
var _current_frame : int = 1
var _frames_per_tick : int
var _update_budget : int
var _update_workers : Array[EntityWorker]
var mutex := Mutex.new()
@export var entities_per_worker : int = 500
var _worker_budget : int

func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		_frames_per_tick = _InterpolationState.server_FPS / main_tickrate
		if _current_frame == 1:
			_EntityInterest._request_chunks()
			_process_activation_queue()
			_process_move_queue()
			_process_remove_queue()
			_update_budget = ceili(float(_entity_indices.size()) / _InterpolationState.server_FPS)
			var needed := ceili(float(_entity_ids.size()) / entities_per_worker)
			for _i in range(_update_workers.size(), needed):
				var worker := EntityWorker.new()
				worker.task_type = EntityWorker.TaskType.UPDATE_HOST
				worker._EntityStorageLogic = self
				_update_workers.append(worker)
			_worker_budget = ceili(float(_update_budget) / _update_workers.size())
			
		_process_chunk_loading()
		_process_update()
		if _current_frame >= main_tickrate:
			_EntityInterest.send_chunks()
			_chunk_buffers.clear()
			_current_frame = 1
		else:
			_current_frame += 1
			
			
func _process_chunk_loading() -> void:
	for chunk_idx in _EntityInterest._chunks_to_load:
		_EntityFactory._load_chunk(chunk_idx, self)
	_EntityInterest._chunks_to_load.clear()

	
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
				var path_from_parent : NodePath
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
				
				if parent_idx == -1:
					path_from_parent = get_parent().get_path_to(entity_node.get_parent())
				
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
				var batches := chunk_data.child_data[-1].type_batches
				var parent_type : int
				for j : int in range(root_path.size() - 1, 0, -1):
					parent_type = _entity_types[root_path[j]]
					var parent_tree_idx := _entity_tree_indices[root_path[j]]
					if batches.size() < parent_type + 1:
						var old_size = batches.size()
						batches.resize(parent_type + 1)
						for _i : int in range(old_size, batches.size()):
							batches[_i] = ChunkData.new()
					chunk_data = batches[parent_type]
					if j == 1:
						if chunk_data.child_data.size() <= parent_tree_idx:
							chunk_data.child_data.resize(parent_tree_idx + 1)
						if chunk_data.child_data[parent_tree_idx] == null:
							chunk_data.child_data[parent_tree_idx] = TypeBatches.new()
					batches = chunk_data.child_data[parent_tree_idx].type_batches
				if batches.size() < type + 1:
					var old_size = batches.size()
					batches.resize(type + 1)
					for _i : int in range(old_size, batches.size()):
						batches[_i] = ChunkData.new()
				chunk_data = batches[type]
				var tree_idx : int
				if not chunk_data.free_slots.is_empty():
					tree_idx = chunk_data.free_slots[-1]
					chunk_data.free_slots.resize(chunk_data.free_slots.size()-1)
					
					chunk_data.entity_indices[tree_idx] = entity_idx
					chunk_data.flags[tree_idx] = PackedInt64Array()
					chunk_data.path_from_parent_changed[tree_idx] = 0
					chunk_data.path_from_parent[tree_idx] = path_from_parent
				else:
					tree_idx = chunk_data.entity_indices.size()
					chunk_data.entity_indices.append(entity_idx)
					chunk_data.flags.append(PackedInt64Array([0]))
					chunk_data.path_from_parent_changed.append(1)
					chunk_data.path_from_parent.append(path_from_parent)
				_entity_tree_indices[entity_idx] = tree_idx
	
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


var _update_chunk_idx : int
var _update_tasks : Array[UpdateTask]
class UpdateTask:
	var chunk_data : ChunkData
	var entity_type : int = -1
	var entity_i : int = -1
	
func _process_update():
	#for worker in _update_workers:
		#var budget := _worker_budget
		#if _update_tasks.is_empty():
			#_update_tasks.append(UpdateTask.new())
		#var task_idx := _update_tasks.size()-1
		#var task := _update_tasks[task_idx]
		#while budget > 0:
			#
			#if task.chunk_data == null:
				#var old_update_chunk_idx := _update_chunk_idx
				#_update_chunk_idx = (_update_chunk_idx+1)%_EntityInterest._chunk_requested.size()
				#if old_update_chunk_idx == _update_chunk_idx:
					#break
	pass
		
			
