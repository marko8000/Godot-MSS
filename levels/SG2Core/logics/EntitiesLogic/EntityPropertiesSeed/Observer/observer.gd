@tool
extends Node
class_name Observer


var entity_id : int
var player_type : String # peer or reg
var id : int

var _SG2Core : SG2Core
var _EntitiesLogic : EntitiesLogic
var _MultiplayerLogic : MultiplayerLogic
var _ChunksCalculator : ChunksCalculator
var _ConnectionLogic : ConnectionLogic
	
	
func presets():
	_SG2Core = ExecManager.get_current_exec(self).get_current_level()
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
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		return
	if _ConnectionLogic.peer_role != 'host':
		return
	entity_id = int(get_parent().name.substr(1))
	var _player_data : EntitiesLogic.EntitiesPlayerData
	if player_type == 'peer':
		if _EntitiesLogic.players.has(id):
			_player_data = _EntitiesLogic.players[id]
		else:
			get_parent().queue_free()
	elif player_type == 'reg':
		_player_data = _EntitiesLogic.players[_MultiplayerLogic.reg_id_to_peer_id(id)]
	if not _player_data.observers_data.has(entity_id):
		_player_data.observers_data[entity_id] = EntitiesLogic.EntitiesPlayerData.ObserverData.new()
	var _observer_data : EntitiesLogic.EntitiesPlayerData.ObserverData = _player_data.observers_data[entity_id]
	var _current_chunk = _ChunksCalculator.position_to_chunk(get_parent().global_position)
	var _direction = _ChunksCalculator.rotation_to_direction(get_parent().global_rotation)
	var _old_chunk = _observer_data.current_chunk
	if _old_chunk == null:
		_old_chunk = _current_chunk
	var _old_direction = _observer_data.direction
	if _old_direction == null:
		_old_direction = _direction
	
	_observer_data.observer_entity_id = entity_id
	_observer_data.current_chunk = _current_chunk
	_observer_data.direction = _direction
	if _current_chunk != _old_chunk:
		_observer_data.old_chunk = _old_chunk
	if _direction != _old_direction:
		_observer_data.old_direction = _old_direction
	
	
	
