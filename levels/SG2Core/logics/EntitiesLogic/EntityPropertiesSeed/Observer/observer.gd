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
	_SG2Core = ExecManager.give_current_exec(self).giveo('level')
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
	update_player_data()
	
	
func update_player_data():
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		return
	if _ConnectionLogic.peer_role != 'host':
		return
	entity_id = int(get_parent().name.substr(1))
	var _player_data : EntitiesLogic.PlayerData
	if  player_type == 'peer':
		_player_data = _EntitiesLogic.players[id]
	elif player_type == 'reg':
		_player_data = _EntitiesLogic.players[_MultiplayerLogic.reg_id_to_peer_id(id)]
	var _current_chunk = _ChunksCalculator.position_to_chunk(get_parent().position)
	var _direction = _ChunksCalculator.rotation_to_direction(get_parent().rotation)
	_player_data.observers_data[entity_id] = EntitiesLogic.PlayerData.ObserverData.new(_current_chunk, _direction)
