@icon('res://levels/MSSCore/godot_icons/Groups.svg')
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
var _entities : PackedInt64Array
var _entity_types : PackedInt32Array
var _nodes : Array[Node]
var _entity_free_slots : PackedInt32Array

# Activate
var _activation_queue : Array[PackedInt32Array]
var _entity_parent : PackedInt32Array # -1 for root storage
var _entity_root : PackedInt32Array # -1 for root storage
var _root_chunk : PackedInt32Array
var _chunks : Array[Variant]
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
	_entities_start_working.emit()
	_entities_can_start_working = true
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
		

func _allocate_batch(entity_type : int, nodes : Array[Node]) -> PackedInt32Array:
	var entity_indices : PackedInt32Array
	var type_data := _EntityFactory._entity_type_data[entity_type]
	for node in nodes:
		var entity_id := _EntityFactory._get_new_entity_id()
		var idx : int
			
		if not _entity_free_slots.is_empty():
			idx = _entity_free_slots[-1]
			_entity_free_slots.resize(_entity_free_slots.size()-1)
			_entities[idx] = entity_id
			_entity_types[idx] = entity_type
			_nodes[idx] = node
		else:
			idx = _entities.size()
			_entities.append(entity_id)
			_entity_types.append(entity_type)
			_nodes.append(node)
			_entity_parent.append(-2)
			_entity_root.append(-2)
			_root_chunk.append(0)
		entity_indices.append(idx)
	for source_idx in range(_data_sources.size()):
		var source_list_idx = type_data.source_indices.find(source_idx)
		var source = _data_sources[source_idx]
		source._sparse_array.resize(_entities.size())
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
			var worker_count := ceili(float(_entities.size()) / worker_entity_limit)
			if worker_count > workers.size():
				for _i in worker_count-workers.size():
					workers.append(EntityWorker.new())
			worker_budget = ceili(float(worker_entity_limit) / _InterpolationState.server_FPS)
		_process_update()
		if current_frame >= main_tickrate:
			#send_chunks()
			_chunk_buffers.clear()
			current_frame = 1
		else:
			current_frame += 1
	
	
func _process_activation_queue():
	var root_path_type_batches_i : Dictionary[PackedInt32Array, Array] = {PackedInt32Array(): []}
	var activation_queue_path_from_parent : Array[PackedStringArray]
	for type in range(_activation_queue.size()):
		activation_queue_path_from_parent.resize(type+1)
		var entity_indices := _activation_queue[type]
		for i in range(entity_indices.size()):
			var entity_idx := entity_indices[i]
			var parent_node := _nodes[entity_indices[i]].get_parent()
			var parent_idx : int = -2
			var current_entity_idx : int = -2
			var root_path := PackedInt32Array([entity_idx])
			while true:
				if str(parent_node.name).is_valid_int():
					current_entity_idx = int(parent_node.name)
					root_path.append(current_entity_idx)
				if parent_idx == -2 and bool(current_entity_idx+2):
					parent_idx = current_entity_idx
					_entity_parent[entity_idx] = parent_idx
					activation_queue_path_from_parent[type].append(parent_node.get_path_to(_nodes[entity_idx].get_parent()))
				if parent_node == self:
					_entity_root[entity_idx] = current_entity_idx
					root_path.append(-1)
					break
					
				if parent_node == get_tree().root:
					break
				parent_node = parent_node.get_parent()
			if not root_path_type_batches_i.has(root_path):
				root_path_type_batches_i[root_path] = []
			if root_path_type_batches_i[root_path].size() < type+1:
				for _t in range(root_path_type_batches_i[root_path].size(), type+1):
					root_path_type_batches_i[root_path].append(PackedInt32Array())
			root_path_type_batches_i[root_path][type].append(i)
	var sorted_root_paths : Array[PackedInt32Array] = root_path_type_batches_i.keys()
	sorted_root_paths.sort_custom(func(a, b): return a.size() < b.size())
	for root_path in sorted_root_paths:
		if root_path.size() == 1:
			continue
		for type in range(root_path_type_batches_i[root_path].size()):
			if root_path_type_batches_i[root_path][type] == null:
				continue
			for i in root_path_type_batches_i[root_path][type]:
				var entity_idx : int = _activation_queue[type][i]
				var chunk_node := _nodes[entity_idx]
				var chunk_node_type := _entity_types[entity_idx]
				if root_path.size() >= 2:
					chunk_node = _nodes[root_path[-2]]
					chunk_node_type = _entity_types[root_path[-2]]
				var chunk_node_type_data := _EntityFactory._entity_type_data[chunk_node_type]
				var chunk
				match chunk_node_type_data.dimension:
					EntityFactory.EntityTypeData.Dimension.GLOBAL:
						chunk = null
					EntityFactory.EntityTypeData.Dimension.V2:
						chunk = _ChunkCalculator.position2d_to_chunk(chunk_node.global_position)
					EntityFactory.EntityTypeData.Dimension.V3:
						chunk = _ChunkCalculator.position3d_to_chunk(chunk_node.global_position)
				var chunk_idx : int
				if _chunk_idx_by_chunk.has(chunk):
					chunk_idx = _chunk_idx_by_chunk[chunk]
				else:
					if root_path_type_batches_i[PackedInt32Array()].size() < type+1:
						for _t in range(root_path_type_batches_i[PackedInt32Array()].size(), type+1):
							print(_t)
							root_path_type_batches_i[PackedInt32Array()].append(PackedInt32Array())
					root_path_type_batches_i[PackedInt32Array()][type].append(i)
					continue
				var chunk_data := _entity_tree[chunk_idx].type_batches
				var index : int
				var type_batch : ChunkData.TypeBatch
				for j in range(root_path.size() - 2, -1, -1):
					var parent_type := _entity_types[root_path[j]]
					if chunk_data.size() < parent_type+1:
						chunk_data.resize(parent_type+1)
						for k in range(parent_type+1):
							if chunk_data[k] == null:
								chunk_data[k] = ChunkData.TypeBatch.new()
					index = chunk_data[parent_type].entity_indices.find(root_path[j])
					if index == -1:
						type_batch = chunk_data[parent_type]
						break
					chunk_data = chunk_data[parent_type].children
				type_batch.entity_indices.append(entity_idx)
				type_batch.children.append(ChunkData.TypeBatch.new())
				type_batch.flags.append(0)
	
	# remove invalid entities
	for type in range(root_path_type_batches_i[PackedInt32Array()].size()):
		var remove_indices : PackedInt32Array
		for i in root_path_type_batches_i[PackedInt32Array()][type]:
			var entity_idx := _activation_queue[type][i]
			_nodes[entity_idx].queue_free()
			remove_indices.append(entity_idx)
		var type_data := _EntityFactory._entity_type_data[type]
		for source_idx in range(_data_sources.size()):
			var source_list_idx = type_data.source_indices.find(source_idx)
			var source = _data_sources[source_idx]
			if not source_list_idx == -1:
				source._remove_batch(remove_indices, type_data, source_list_idx)
				
	for type in range(_activation_queue.size()):
		_activation_queue[type].clear()


func _process_move_queue():
	pass


func _process_remove_queue():
	pass



func _process_update():
	for chunk in _EntityInterest._chunk_user_counts:
		pass
	
