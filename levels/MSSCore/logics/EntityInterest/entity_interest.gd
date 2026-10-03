extends MSSLogic
class_name EntityInterest


@onready var _PlayerLifecycle := _MSSCore._PlayerLifeCycle
var _EntityStorageLogic : EntityStorageLogic
var _ChunkCalculator : ChunkCalculator

var _chunk_requested : PackedByteArray
var _chunks_to_load : PackedInt32Array
var _player_data : Array[PlayerData]
var _chunk_cache : Array[ChunkCache]
class ChunkCache:
	var chunk_indices : PackedInt32Array
			

func _ready() -> void:
	if not Engine.is_editor_hint():
		_PlayerLifecycle = _MSSCore._PlayerLifeCycle
		_EntityStorageLogic = get_parent()
		_ChunkCalculator = _EntityStorageLogic._ChunkCalculator
		_PlayerLifecycle.player_state_changed.connect(_player_state_changed)
	
	
func _player_state_changed(peer_idx : int, player_state : PlayerLifecycle.PlayerState):
	match player_state:
		PlayerLifecycle.PlayerState.preparing:
			var _player_data_size := _player_data.size()
			if _player_data_size < peer_idx+1:
				for _i : int in range(_player_data_size, peer_idx+1):
					var p_data := PlayerData.new()
					_player_data.append(p_data)
	

func _request_chunks() -> void:
	for chunk_idx : int in range(_chunk_requested.size()):
		_chunk_requested[chunk_idx] = false
	var required_size := _chunk_requested.size()
	var old_size := _chunk_cache.size()

	if old_size < required_size:
		_chunk_cache.resize(required_size)
		for i : int in range(old_size, required_size):
			_chunk_cache[i] = ChunkCache.new()
	_chunk_requested.fill(false)
				
	for peer_idx : int in range(_player_data.size()):
		var p_data := _player_data[peer_idx]
		
		for i : int in range(p_data.observer_entities.size()):
			var entity_idx := p_data.observer_entities[i]
			var entity_chunk_idx := _EntityStorageLogic._root_chunk[entity_idx]
			
			var cache := _chunk_cache[entity_chunk_idx]
			
			if p_data.entity_chunk_indices[i] != entity_chunk_idx:
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
						_chunk_requested[chunk_idx] = true
						cache.chunk_indices.append(chunk_idx)
						p_data.required_chunks.append(chunk_idx)
				else:
					for chunk_idx : int in cache.chunk_indices:
						p_data.required_chunks.append(chunk_idx)
						_chunk_requested[chunk_idx] = true
				p_data.entity_chunk_indices[i] = entity_chunk_idx
			else:
				for chunk_idx in cache.chunk_indices:
					_chunk_requested[chunk_idx] = true
		
		
func send_chunks():
	pass
		
	
var _player_sparse_array : PackedInt32Array
var _player_entity_data : Array[ObservedEntityData] = [ObservedEntityData.new()]
var _player_free_slots : PackedInt32Array

class PlayerData:
	var observer_entities : PackedInt32Array
	var player_entities : PackedByteArray
	var entity_chunk_indices : PackedInt32Array
	var required_chunks : PackedInt32Array
	var loaded_chunk_indices : PackedInt32Array
	

class ObservedEntityData:
	var peer_indices : PackedInt32Array
	var free_slots : PackedInt32Array


func register_observer(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	if not p_data.observer_entities.has(entity_idx):
		p_data.observer_entities.append(entity_idx)
		p_data.player_entities.append(false)
		p_data.entity_chunk_indices.append(-1)
	
	
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
	
	
	
