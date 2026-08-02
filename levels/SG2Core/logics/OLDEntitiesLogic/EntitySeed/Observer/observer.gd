@tool
extends Node
class_name Observer


#var entity_id : int
#var player_type : String # peer or reg
#var id : int
#var player_data : EntitySyncLogic.EntitiesPlayerData
#
#var current_chunk
#var loaded_chunks : Array
#var loaded_entities : PackedInt32Array
#var _chunks_to_delete : Array
#func _to_string() -> String:
	#return '[{0}, {1}, {2}]'.format([current_chunk, str(len(loaded_chunks)), len(loaded_entities)])
#
#var _SG2Core : SG2Core
#var _EntitySyncLogic : EntitySyncLogic
#var _MultiplayerLogic : MultiplayerLogic
#var _ChunksCalculator : ChunksCalculator
#var _ConnectionLogic : ConnectionLogic
	#
	#
#func prepare_properties():
	#var voxel_viewer = VoxelViewer.new()
	#get_parent().add_child(voxel_viewer)
	#var ESeed : EntitySeed = $'../EntitySeed'
	#var Entity = get_parent()
	#var player_type_sync = NoninterpolatedTracker.new()
	#player_type_sync.property_path = '$'+str(Entity.get_path_to(self))+'.player_type'
	#var id_sync = NoninterpolatedTracker.new()
	#id_sync.property_path = '$'+str(Entity.get_path_to(self))+'.id'
	#ESeed.tracked_properties.append_array([player_type_sync, id_sync])
	#
	#
#func presets():
	#_SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
	#_EntitySyncLogic = _SG2Core._EntitySyncLogic
	#_MultiplayerLogic = _SG2Core._MultiplayerLogic
	#_ChunksCalculator = _SG2Core._ChunksCalculator
	#_ConnectionLogic = _SG2Core._ConnectionLogic
	#
	#entity_id = int(get_parent().name.substr(1))
	#
	#host_update_player_data()
#
#
#func _get_configuration_warnings():
	#var warnings = []
	#var has_entity_seed = false
	#for child in get_parent().get_children():
		#if child is EntitySeed and child.name == 'EntitySeed':
			#has_entity_seed = true
	#if not has_entity_seed:
		#warnings.append('Observer must be child of Node with EntitySeed')
	#return warnings
	#
	#
#func is_player() -> bool:
	#if player_type == 'peer':
		#if _EntitySyncLogic.multiplayer.get_unique_id() == id:
			#return true
		#else:
			#return false
	#elif player_type == 'reg':
		#pass
	#return false
	#
	#
#func _process(delta: float) -> void:
	#if _EntitySyncLogic != null:
		#if _EntitySyncLogic.entities_can_start_work:
			#if _ConnectionLogic.peer_role == 'host':
				#if _EntitySyncLogic.current_update_frame == 1:
					#host_update_player_data()
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
