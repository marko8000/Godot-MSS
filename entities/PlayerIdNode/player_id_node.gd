@tool
@icon('res://levels/MSSCore/x_res/x_images/sg_logo_light.svg')
extends Node
class_name PlayerIdNode


var _MSSCore : MSSCore
var _EntityInterest : EntityInterest
var _ConnectionLogic : ConnectionLogic

signal peer_id_changed(peer_id)
var uid : int
var peer_id : int :
	set(value):
		if _ConnectionLogic and _ConnectionLogic.peer_role == 'host':
			_player_data = _EntityInterest._players[value]
		peer_id = value
		peer_id_changed.emit(value)
var _player_data : EntityInterest.EntitiesPlayerData

var _current_chunk
var _loaded_chunks : Array
func _to_string() -> String:
	return 'Observer:[{0}, {1}]'.format([_current_chunk, str(len(_loaded_chunks))])


func _ready() -> void:
	if not Engine.is_editor_hint():
		_MSSCore = MSSCore.get_from(self)
		_EntityInterest = _MSSCore._EntityInterest
		_ConnectionLogic = _MSSCore._ConnectionLogic
	
	
func is_player() -> bool:
	if _EntityInterest.multiplayer.multiplayer_peer.get_unique_id() == peer_id:
		return true
	return false
	
	
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		%ChunkLoader3D.global_position = get_parent().global_position
	
	
	#
	#
#func host_update_player_data():
	#if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		#return
	#if _ConnectionLogic.peer_role != 'host':
		#return
	#if player_type == 'peer':
		#if _EntitySyncLogic.players.has(id):
			#player_data = _EntitySyncLogic.players[id]
		#else:
			#get_parent().queue_free()
	#elif player_type == 'reg':
		#player_data = _EntitySyncLogic.players[_MultiplayerLogic.reg_id_to_peer_id(id)]
	#if player_data == null:
		#return
	#if not player_data.observers.has(self):
		#player_data.observers.append(self)
		#
	#current_chunk = _ChunksCalculator.position_to_chunk(get_parent().global_position)
	#delete_chunks()
	#load_chunks()
	#
		#
#func delete_chunks():
	#_chunks_to_delete = loaded_chunks.filter(func (chunk): return _ChunksCalculator.dist(chunk, current_chunk) > _ChunksCalculator.max_dist(current_chunk, player_data.drawing_distance))
	#for chunk in _chunks_to_delete:
		#_ChunksCalculator.hide_chunk(chunk)
		#_EntitySyncLogic.chunks_users_num[chunk] -= 1
		#loaded_chunks.erase(chunk)
	#
	#
#func load_chunks():
	#var chunks : Array = _ChunksCalculator.get_chunks_around(
		#current_chunk, 
		#player_data.drawing_distance
	#)
	#chunks.append(EntityStorageLogic.NONCHUNK)
	#for chunk in chunks:
		#_ChunksCalculator.visualize_chunk(chunk)
		#if not _EntitySyncLogic.chunks_users_num.has(chunk):
			#_EntitySyncLogic.chunks_users_num[chunk] = 0
		#if not loaded_chunks.has(chunk):
			#loaded_chunks.append(chunk)
			#_EntitySyncLogic.chunks_users_num[chunk] += 1
	#
