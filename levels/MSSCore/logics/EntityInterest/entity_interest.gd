extends MSSLogic
class_name EntityInterest


@onready var _PlayerLifecycle := _MSSCore._PlayerLifeCycle

var _chunk_requested : PackedByteArray
var _player_data : Array[PlayerData]

@export_category('Drawing Settings')
const MIN_DRAW_DISTANCE : int = 1
const MAX_DRAW_DISTANCE : int = 16
@export_range(MIN_DRAW_DISTANCE, MAX_DRAW_DISTANCE, 1, "prefer_slider")\
var base_draw_distance : int = 2

@export_range(MIN_DRAW_DISTANCE, MAX_DRAW_DISTANCE, 1, "prefer_slider")\
var OBSERVER_DRAW_DISTANCE : int = MIN_DRAW_DISTANCE
			

func _ready() -> void:
	_PlayerLifecycle.player_state_changed.connect(_player_state_changed)
	
	
func _player_state_changed(peer_idx : int, player_state : PlayerLifecycle.PlayerState):
	match player_state:
		PlayerLifecycle.PlayerState.preparing:
			_player_data.resize(max(peer_idx+1, _player_data.size()))
			var player_data := PlayerData.new()
			_player_data.append(player_data)
	
	
func _request_chunks() -> void:
	var size := _chunk_requested.size()
	_chunk_requested.clear()
	_chunk_requested.resize(size)
	
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
	var player_draw_distances : PackedInt32Array
	var observer_entities : PackedInt32Array
	
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
