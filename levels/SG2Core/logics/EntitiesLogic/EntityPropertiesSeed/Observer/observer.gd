@tool
extends Node
class_name Observer


var entity_id : int
var player_type : String # peer or reg
var id : int
var player_data : EntitiesLogic.EntitiesPlayerData

var current_chunk
var loaded_chunks : Array
var loaded_entities : PackedInt32Array
func _to_string() -> String:
	return '[{0}, {1}, {2}]'.format([current_chunk, str(len(loaded_chunks)), len(loaded_entities)])

var _SG2Core : SG2Core
var _EntitiesLogic : EntitiesLogic
var _MultiplayerLogic : MultiplayerLogic
var _ChunksCalculator : ChunksCalculator
var _ConnectionLogic : ConnectionLogic
	
	
func presets():
	_SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
	_EntitiesLogic = _SG2Core._EntitiesLogic
	_MultiplayerLogic = _SG2Core._MultiplayerLogic
	_ChunksCalculator = _SG2Core._ChunksCalculator
	_ConnectionLogic = _SG2Core._ConnectionLogic
	
	if not get_parent().has_node('EntityPropertiesSeed'):
		return
	get_parent().add_child(VoxelViewer.new())
	var EPropertiesSeed : EntityPropertiesSeed = $'../EntityPropertiesSeed'
	var Entity = get_parent()
	var player_type_sync = NoninterpolatedSync.new()
	player_type_sync.property_path = '$'+str(Entity.get_path_to(self))+'.player_type'
	var id_sync = NoninterpolatedSync.new()
	id_sync.property_path = '$'+str(Entity.get_path_to(self))+'.id'
	EPropertiesSeed.tracked_properties.append_array([player_type_sync, id_sync])


func _get_configuration_warnings():
	var warnings = []
	var has_entity_logic = false
	for child in get_parent().get_children():
		if child is EntityPropertiesSeed:
			has_entity_logic = true
	if not has_entity_logic:
		warnings.append('Observer must be child of Node with EntityLogic')
	return warnings
	
	
func is_player() -> bool:
	if player_type == 'peer':
		if _EntitiesLogic.multiplayer.get_unique_id() == id:
			return true
		else:
			return false
	elif player_type == 'reg':
		pass
	return false
	
	
func _process(delta: float) -> void:
	if _EntitiesLogic != null:
		if _EntitiesLogic.entities_can_start_work:
			update_player_data()
	
	
func update_player_data():
	if _EntitiesLogic.current_update_frame != 1: return
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		return
	if _ConnectionLogic.peer_role != 'host':
		return
	entity_id = int(get_parent().name.substr(1))
	if player_type == 'peer':
		if _EntitiesLogic.players.has(id):
			player_data = _EntitiesLogic.players[id]
		else:
			get_parent().queue_free()
	elif player_type == 'reg':
		player_data = _EntitiesLogic.players[_MultiplayerLogic.reg_id_to_peer_id(id)]
	if not player_data.observers.has(self):
		player_data.observers.append(self)
		
	current_chunk = _ChunksCalculator.position_to_chunk(get_parent().global_position)
	delete_chunks()
	load_chunks()
	
		
func delete_chunks():
	var _chunks_to_delete = loaded_chunks.filter(func (chunk): return _ChunksCalculator.dist(chunk, current_chunk) > _ChunksCalculator.max_dist(current_chunk, player_data.drawing_distance))
	for chunk in _chunks_to_delete:
		_ChunksCalculator.hide_chunk(chunk)
		_EntitiesLogic.chunks_users_num[chunk] -= 1
		loaded_chunks.erase(chunk)
	
	
func load_chunks():
	var chunks : Array = _ChunksCalculator.get_chunks_around(
		current_chunk, 
		player_data.drawing_distance
	)
	chunks.append(null)
	for chunk in chunks:
		_ChunksCalculator.visualize_chunk(chunk)
		if not _EntitiesLogic.chunks_users_num.has(chunk):
			_EntitiesLogic.chunks_users_num[chunk] = 0
		if not loaded_chunks.has(chunk):
			loaded_chunks.append(chunk)
			_EntitiesLogic.chunks_users_num[chunk] += 1
	
