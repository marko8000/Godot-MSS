@tool
extends Node
class_name Observer


var player_type : String # peer or reg
var id : int

var _SG2Core : SG2Core
var _EntitiesLogic : EntitiesLogic


func _ready() -> void:
	add_child(VoxelViewer.new())
	
	
func presets():
	_SG2Core = ExecManager.give_current_exec(self).giveo('level')
	_EntitiesLogic = _SG2Core._EntitiesLogic
	
	if not get_parent().has_node('EntityPropertiesSeed'):
		return
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
