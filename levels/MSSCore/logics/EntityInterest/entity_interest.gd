@tool
extends MSSLogic
class_name EntityInterest


var _PlayerLifecycle : PlayerLifecycle
var _ChunkCalculator : ChunkCalculator
var _EntityStorage : EntityStorage
var _EntityFactory : EntityFactory

var _chunk_requested : PackedByteArray
var _player_data : Array[PlayerData]
			

func _ready() -> void:
	if not Engine.is_editor_hint():
		_PlayerLifecycle = _MSSCore._PlayerLifeCycle
		_ChunkCalculator = _MSSCore._ChunkCalculator
		_EntityStorage = _MSSCore._EntityStorage
		_EntityFactory = _MSSCore._EntityFactory
		_PlayerLifecycle.player_state_changed.connect(_player_state_changed)
	
	
func _player_state_changed(peer_idx : int, player_state : PlayerLifecycle.PlayerState):
	match player_state:
		PlayerLifecycle.PlayerState.preparing:
			var _player_data_size := _player_data.size()
			if _player_data_size < peer_idx+1:
				for _i in range(_player_data_size, peer_idx+1):
					var p_data := PlayerData.new()
					p_data.new_chunks.append(0)
					_player_data.append(p_data)
	

var _chunk_cache : Array[ChunkCache]
class ChunkCache:
	var lod_levels : Array[PackedInt32Array]
var _chunks_to_load_count : int
var _pending_chunk_cache : Array[ChunkCache]
func _request_chunks() -> void:
	var size := _chunk_requested.size()
	_chunk_requested.clear()
	_chunk_requested.resize(size)
	
	if not _pending_chunk_cache.is_empty():
		for chunk_idx in range(_pending_chunk_cache.size()):
			var pcache := _pending_chunk_cache[chunk_idx]
			if not pcache:
				continue
			for ring_num in range(pcache.rings.size()):
				_chunk_cache[chunk_idx].rings[ring_num].append_array(pcache.rings[ring_num])
				
	for peer_idx : int in range(_player_data.size()):
		var p_data := _player_data[peer_idx]
		for i in range(p_data.player_entities.size()):
			var entity_idx := p_data.player_entities[i]
			var chunk_idx := _EntityStorage._root_chunk[entity_idx]
			p_data.p_last_chunk_indices[i] = chunk_idx
			if _chunk_cache.size() < chunk_idx+1:
				_chunk_cache.resize(
					max(_chunk_cache.size(), chunk_idx+1)
				)
				_pending_chunk_cache.resize(
					max(_chunk_cache.size(), chunk_idx+1)
				)
			var cache := _chunk_cache[chunk_idx]
			var pcache := _pending_chunk_cache[chunk_idx]
				
			if cache == null:
				cache = ChunkCache.new()
				_chunk_cache[chunk_idx] = cache
			
				if pcache == null:
					pcache = ChunkCache.new()
					_pending_chunk_cache[chunk_idx] = pcache
					
				if cache.lod_levels.size() < p_draw_distance_level+1:
					for _i in range(cache.rings.size(), p_draw_distance_level+1):
						cache.rings.append(PackedInt32Array())
						pcache.rings.append(PackedInt32Array())
						
				var chunks := _ChunkCalculator.get_chunks_around(
					_EntityStorage._chunks[chunk_idx], draw_distance_levels[p_data.player_draw_distance_level]
					)
					
				for chunk in chunks:
					var idx : int
					if not _EntityStorage._chunk_idx_by_chunk.has(chunk):
						idx = _EntityStorage._allocate_chunk(chunk)
						_chunks_to_load_count += 1
						pcache.rings[p_draw_distance_level].append(idx)
					else:
						idx = _EntityStorage._chunk_idx_by_chunk[chunk]
						p_data.new_chunks.append(idx)
						cache.rings[p_draw_distance_level].append(_EntityStorage._chunk_idx_by_chunk[chunk])
						_chunk_requested[idx] = 1
			else:
				cache = _chunk_cache[chunk_idx]
				if chunk_idx == p_data.p_last_chunk_indices[i] and pcache != null:
					p_data.new_chunks.append_array(
						pcache.rings[p_draw_distance_level]
						)
					_chunk_requested[chunk_idx] = 2
				else:
					pass
					
		for chunk_idx in range(_chunk_requested.size()):
			if _chunk_requested[chunk_idx] == 2:
				_pending_chunk_cache[chunk_idx] = null
		
		
func send_chunks():
	pass
		
	
var _observer_sparse_array : PackedInt32Array
var _observer_entity_data : Array[ObservedEntityData] = [ObservedEntityData.new()]
var _observer_free_slots : PackedInt32Array

var _player_sparse_array : PackedInt32Array
var _player_entity_data : Array[ObservedEntityData] = [ObservedEntityData.new()]
var _player_free_slots : PackedInt32Array

class PlayerData:
	var new_chunks : PackedInt32Array
	var loaded_chunks : PackedInt32Array
	var player_entities : PackedInt32Array
	var p_last_chunk_indices : PackedInt32Array
	var observer_entities : PackedInt32Array
	var o_last_chunk_indices : PackedInt32Array

class ObservedEntityData:
	var peer_indices : PackedInt32Array
	var free_slots : PackedInt32Array


func register_observer(entity_idx : int, peer_idx : int) -> void:
	_observer_sparse_array.resize(max(entity_idx+1, _observer_sparse_array.size()))
	var oe_data : ObservedEntityData
	if not _observer_sparse_array[entity_idx]:
		var observer_data_index : int
		oe_data = ObservedEntityData.new()
		if not _observer_free_slots.is_empty():
			observer_data_index = _observer_free_slots[-1]
			_observer_free_slots.resize(_observer_free_slots.size()-1)
			_observer_entity_data[observer_data_index] = oe_data
		else:
			observer_data_index = _observer_entity_data.size()
			_observer_entity_data.append(oe_data)
		_observer_sparse_array[entity_idx] = observer_data_index
	else:
		oe_data = _observer_entity_data[_observer_sparse_array[entity_idx]]
	
	if not oe_data.free_slots.is_empty():
		oe_data.peer_indices[oe_data.free_slots[-1]] = peer_idx
		oe_data.free_slots.resize(oe_data.free_slots.size()-1)
	else:
		oe_data.peer_indices.append(peer_idx)
	
	var p_data := _player_data[peer_idx]
	if not p_data.observer_entities.has(entity_idx):
		p_data.observer_entities.append(entity_idx)
		p_data.o_last_chunk_indices.append(-2)
	
	
func register_player(entity_idx : int, peer_idx : int) -> void:
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
	
	var p_data := _player_data[peer_idx]
	if not p_data.player_entities.has(entity_idx):
		p_data.player_entities.append(entity_idx)
		p_data.p_last_chunk_indices.append(-2)
