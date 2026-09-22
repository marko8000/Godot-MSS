extends MSSLogic
class_name EntityInterest


var _PlayerLifecycle : PlayerLifecycle
var _ChunkCalculator : ChunkCalculator
var _EntityStorage : EntityStorage
var _EntityFactory : EntityFactory

var _chunk_requested : PackedByteArray
var _player_data : Array[PlayerData]
var _chunk_cache : Array[ChunkCache]
class ChunkCache:
	var chunk_indices : PackedInt32Array
var _pending_chunk_cache : Array[ChunkCache]
			

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
				for _i : int in range(_player_data_size, peer_idx+1):
					var p_data := PlayerData.new()
					_player_data.append(p_data)
	
	
func _request_chunks() -> void:
	for chunk_idx : int in range(_chunk_requested.size()):
		_chunk_requested[chunk_idx] = false
		var required_size := chunk_idx+1
		var old_size := _chunk_cache.size()
		if old_size < required_size:
			_chunk_cache.resize(required_size)
			_pending_chunk_cache.resize(required_size)
			for i : int in range(old_size, required_size):
				_chunk_cache[i] = ChunkCache.new()
				_pending_chunk_cache[i] = ChunkCache.new()
		var pcache := _pending_chunk_cache[chunk_idx]
		_chunk_cache[chunk_idx].chunk_indices.append_array(pcache.chunk_indices)
				
	for peer_idx : int in range(_player_data.size()):
		var p_data := _player_data[peer_idx]
		for i : int in range(p_data.observer_entities.size()):
			var entity_idx := p_data.observer_entities[i]
			var chunk_idx := _EntityStorage._root_chunk[entity_idx]
			
			var cache := _chunk_cache[chunk_idx]
			var pcache := _pending_chunk_cache[chunk_idx]
			
			if p_data.chunk_indices[i] != chunk_idx:
				if cache.chunk_indices.is_empty():
					pass
				elif not pcache.chunk_indices.is_empty():
					pass
				p_data.chunk_indices[i] = chunk_idx
				#
			#if cache == null:
				#cache = ChunkCache.new()
				#_chunk_cache[chunk_idx] = cache
			#
				#if pcache == null:
					#pcache = ChunkCache.new()
					#_pending_chunk_cache[chunk_idx] = pcache
					#
				#if cache.lod_levels.size() < p_draw_distance_level+1:
					#for _i in range(cache.rings.size(), p_draw_distance_level+1):
						#cache.rings.append(PackedInt32Array())
						#pcache.rings.append(PackedInt32Array())
						#
				#var chunks := _ChunkCalculator.get_chunks_around(
					#_EntityStorage._chunks[chunk_idx], draw_distance_levels[p_data.player_draw_distance_level]
					#)
					#
				#for chunk in chunks:
					#var idx : int
					#if not _EntityStorage._chunk_idx_by_chunk.has(chunk):
						#idx = _EntityStorage._allocate_chunk(chunk)
						#_chunks_to_load_count += 1
						#pcache.rings[p_draw_distance_level].append(idx)
					#else:
						#idx = _EntityStorage._chunk_idx_by_chunk[chunk]
						#p_data.new_chunks.append(idx)
						#cache.rings[p_draw_distance_level].append(_EntityStorage._chunk_idx_by_chunk[chunk])
						#_chunk_requested[idx] = 1
			#else:
				#cache = _chunk_cache[chunk_idx]
				#if chunk_idx == p_data.p_last_chunk_indices[i] and pcache != null:
					#p_data.new_chunks.append_array(
						#pcache.rings[p_draw_distance_level]
						#)
					#_chunk_requested[chunk_idx] = 2
				#else:
					#pass
		
		
func send_chunks():
	pass
		
	
var _player_sparse_array : PackedInt32Array
var _player_entity_data : Array[ObservedEntityData] = [ObservedEntityData.new()]
var _player_free_slots : PackedInt32Array

class PlayerData:
	var observer_entities : PackedInt32Array
	var player_entities : PackedByteArray
	var chunk_indices : PackedInt32Array

class ObservedEntityData:
	var peer_indices : PackedInt32Array
	var free_slots : PackedInt32Array


func register_observer(entity_idx : int, peer_idx : int) -> void:
	var p_data := _player_data[peer_idx]
	if not p_data.observer_entities.has(entity_idx):
		p_data.observer_entities.append(entity_idx)
		p_data.player_entities.append(false)
		p_data.chunk_indices.append(-1)
	
	
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
	
	
	
