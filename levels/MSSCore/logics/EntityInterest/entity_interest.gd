extends MSSLogic
class_name EntityInterest


@onready var _PlayerLifecycle := _MSSCore._PlayerLifeCycle
@onready var _RootEntityStorageLogic := _MSSCore._RootEntityStorageLogic
@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityFactory := _MSSCore._EntityFactory
var _EntityStorageLogic : EntityStorageLogic
var _ChunkCalculator : ChunkCalculator

var _player_data : Array[PlayerData]

var _player_sparse_array : PackedInt32Array
var _player_entity_data : Array[ObservedEntityData] = [ObservedEntityData.new()]
var _player_free_slots : PackedInt32Array

# Local
var _local_player_data : Array[LocalPlayerData]
enum ChunkStatus {NOT_REQUESTED, REQUESTED, NOT_LOADED}
var _chunk_requested : PackedByteArray
var _chunks_to_load : PackedInt32Array
var _chunk_cache : Array[ChunkCache]
class ChunkCache:
	var chunk_indices : PackedInt32Array
			

func _ready() -> void:
	if not Engine.is_editor_hint():
		_PlayerLifecycle = _MSSCore._PlayerLifeCycle
		_EntityStorageLogic = EntityStorageLogic.get_from(self)
		_ChunkCalculator = _EntityStorageLogic._ChunkCalculator
		_PlayerLifecycle.player_state_changed.connect(_player_state_changed)
		
		_player_data = _RootEntityStorageLogic._EntityInterest._player_data
		
		_player_sparse_array = _RootEntityStorageLogic._EntityInterest._player_sparse_array
		_player_entity_data = _RootEntityStorageLogic._EntityInterest._player_entity_data
		_player_free_slots = _RootEntityStorageLogic._EntityInterest._player_free_slots
	
	
func _player_state_changed(peer_idx : int, player_state : PlayerLifecycle.PlayerState):
	match player_state:
		PlayerLifecycle.PlayerState.preparing:
			var _player_data_size := _player_data.size()
			if _player_data_size < peer_idx+1:
				for _i : int in range(_player_data_size, peer_idx+1):
					var p_data := PlayerData.new()
					_player_data.append(p_data)
		PlayerLifecycle.PlayerState.disconnected:
			var p_data := _player_data[peer_idx]
			for entity_idx in p_data.observer_entities:
				unregister_observer(entity_idx, peer_idx)
	

func _request_chunks() -> void:
	for chunk_idx : int in range(_chunk_requested.size()):
		if _chunk_requested[chunk_idx] == ChunkStatus.REQUESTED:
			_chunk_requested[chunk_idx] = ChunkStatus.NOT_REQUESTED
	var required_size := _chunk_requested.size()
	var old_size := _chunk_cache.size()

	if old_size < required_size:
		_chunk_cache.resize(required_size)
		for i : int in range(old_size, required_size):
			_chunk_cache[i] = ChunkCache.new()
				
	for peer_idx : int in range(_local_player_data.size()):
		if not _ConnectionLogic._is_connected(peer_idx):
			continue
			
		var p_data := _player_data[peer_idx]
		var local_p_data := _local_player_data[peer_idx]
		
		for i : int in range(p_data.observer_entities.size()):
			var entity_idx := p_data.observer_entities[i]
			var entity_chunk_idx := _EntityStorageLogic._root_chunk[entity_idx]
			var entity_type_data := _EntityFactory._entity_type_data[
				_RootEntityStorageLogic._entity_types[entity_idx]]
			var dimension := entity_type_data.dimension
			var current_chunk := _ChunkCalculator.position_to_chunk(
				_ChunkCalculator.node_to_position(_EntityStorageLogic._nodes[entity_idx], dimension),
				dimension)
			
			var cache := _chunk_cache[entity_chunk_idx]
			if local_p_data.entity_chunks[i] != current_chunk:
				if cache.chunk_indices.is_empty():
					var chunks := _ChunkCalculator.get_chunks_around(
						_EntityStorageLogic._chunks[entity_chunk_idx]
					)
					for chunk : PackedInt64Array in chunks:
						var chunk_idx : int
						if not _EntityStorageLogic._chunk_idx_by_chunk.has(chunk):
							chunk_idx = _EntityStorageLogic._allocate_chunk(chunk)
							_chunks_to_load.append(chunk_idx)
						else:
							chunk_idx = _EntityStorageLogic._chunk_idx_by_chunk[chunk]
						_chunk_requested[chunk_idx] = ChunkStatus.REQUESTED
						cache.chunk_indices.append(chunk_idx)
						local_p_data.required_chunks.append(chunk_idx)
				else:
					for chunk_idx : int in cache.chunk_indices:
						local_p_data.required_chunks.append(chunk_idx)
						_chunk_requested[chunk_idx] = ChunkStatus.REQUESTED
				local_p_data.entity_chunks[i] = current_chunk
			else:
				for chunk_idx in cache.chunk_indices:
					_chunk_requested[chunk_idx] = ChunkStatus.REQUESTED
		
		
func send_chunks():
	pass


class PlayerData:
	var observer_entities : PackedInt32Array
	var player_entities : PackedByteArray
	

class ObservedEntityData:
	var peer_indices : PackedInt32Array
	var free_slots : PackedInt32Array
	
class LocalPlayerData:
	var entity_chunks : Array[PackedInt64Array]
	var required_chunks : PackedInt32Array
	var loaded_chunk_indices : PackedInt32Array


func register_observer(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	if not p_data.observer_entities.has(entity_idx):
		p_data.observer_entities.append(entity_idx)
		p_data.player_entities.append(false)
	for storage_logic : EntityStorageLogic in _RootEntityStorageLogic._storage_logic_array:
		if not storage_logic:
			continue
		if _player_data.size() > storage_logic._EntityInterest._local_player_data.size():
			var old_size := storage_logic._EntityInterest._local_player_data.size()
			storage_logic._EntityInterest._local_player_data.resize(_player_data.size())
			for i in range(old_size, _player_data.size()):
				var local_p_data = LocalPlayerData.new()
				local_p_data.entity_chunks.append([])
				storage_logic._EntityInterest._local_player_data[i] = local_p_data
		
	
	
func register_player(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	register_observer(entity_idx, peer_idx)
	p_data.player_entities[-1] = true
	_player_sparse_array.resize(max(entity_idx+1, _player_sparse_array.size()))
	var oe_data : ObservedEntityData
	if not _player_sparse_array[entity_idx]:
		var player_data_index : int
		oe_data = ObservedEntityData.new()
		if not _player_free_slots.is_empty():
			player_data_index = _player_free_slots[-1]
			_player_free_slots.resize(_player_free_slots.size()-1)
			_player_entity_data[player_data_index] = oe_data
		else:
			player_data_index = _player_entity_data.size()
			_player_entity_data.append(oe_data)
		_player_sparse_array[entity_idx] = player_data_index
	else:
		oe_data = _player_entity_data[_player_sparse_array[entity_idx]]
	
	if not oe_data.free_slots.is_empty():
		oe_data.peer_indices[oe_data.free_slots[-1]] = peer_idx
		oe_data.free_slots.resize(oe_data.free_slots.size()-1)
	else:
		oe_data.peer_indices.append(peer_idx)
		

func unregister_player(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	p_data.player_entities[p_data.observer_entities.find(entity_idx)] = false
	var oe_data := _player_entity_data[_player_sparse_array[entity_idx]]
	oe_data.free_slots.append(oe_data.peer_indices.find(peer_idx))
	if oe_data.free_slots.size() == oe_data.peer_indices.size():
		_player_entity_data[_player_sparse_array[entity_idx]] = null
		_player_sparse_array[entity_idx] = 0
	
	
func unregister_observer(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	unregister_player(entity_idx, peer_idx)
	p_data.observer_entities.erase(entity_idx)
	
	
	
	
