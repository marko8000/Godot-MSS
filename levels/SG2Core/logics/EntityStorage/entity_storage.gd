@icon('res://levels/SG2Core/x_res/x_images/Groups.svg')
extends SG2Logic
class_name EntityStorage


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _EntityFactory := _SG2Core._EntityFactory
@onready var _EntityInterest := _SG2Core._EntityInterest
@onready var _ChunkCalculator := _SG2Core._ChunkCalculator
@onready var _InterpolationState := _SG2Core._InterpolationState

var _entities_can_start_working : bool = false
signal _entities_start_working
var main_tickrate : int = 30

# Allocate
var _data_sources : Array[EntityDataSource]
var _entities : PackedInt64Array
var _entity_types : PackedInt32Array
var _nodes : Array[Node]
var _entities_free_slots : PackedInt32Array

# Activate
var _activation_queue : Array[PackedInt32Array]
var _entity_parent : PackedInt32Array # -1 for root storage
var _entity_root : PackedInt32Array # -1 for root storage
var _root_chunk : Array[Variant]
var _move_queue : Array[PackedInt32Array]
var _remove_queue : Array[PackedInt32Array]
var _entity_tree : Dictionary[Variant, ChunkData]
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

var _chunks_buffer := ChunksBuffer.new()
class ChunksBuffer:
	var spawn_byte_data : Dictionary[Variant, PackedByteArray]
	var update_byte_data : Dictionary[Variant, PackedByteArray]
	
	func clear():
		spawn_byte_data.clear()
		update_byte_data.clear()
		
	
static func get_from(from : Node) -> EntityStorage:
	return SG2Core.get_from(from)._EntityStorage
	

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
		var free_size := _entities_free_slots.size()
		var idx : int
			
		if free_size > 0:
			idx = _entities_free_slots[-1]
			_entities_free_slots.resize(free_size-1)
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
	

var current_tick : int = 1
var budget : int
func _process(delta: float) -> void:
	if current_tick == 1:
		_process_activation_queue()
		_process_move_queue()
		_process_remove_queue()
		budget = ceil(float(_entities.size()) / _InterpolationState.server_FPS)
	_process_update()
	if current_tick >= main_tickrate:
		#send_chunks()
		_chunks_buffer.clear()
		current_tick = 1
	else:
		current_tick += 1
	
	
func _process_activation_queue():
	var root_path_type_batches_i : Dictionary[PackedInt32Array, Array]
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
				root_path_type_batches_i[root_path].resize(type+1)
				root_path_type_batches_i[root_path][type] = PackedInt32Array()
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
				if not _entity_tree.has(chunk):
					_entity_tree[chunk] = ChunkData.new()
				var chunk_data := _entity_tree[chunk].type_batches
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
	if root_path_type_batches_i.has(PackedInt32Array()):
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
	
