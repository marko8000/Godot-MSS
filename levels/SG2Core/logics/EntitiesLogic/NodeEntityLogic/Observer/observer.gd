@tool
extends Node
class_name Observer


var player_type : String = 'dsfdsf'# peer or reg
var id : int

var SG2Core
var EntitiesLogic


func presets():
	SG2Core = ExecManager.give_current_exec(self).giveo('level')
	EntitiesLogic = SG2Core.giveo('EntitiesLogic')
	
	if not get_parent().has_node('EntityLogic'):
		return
	var ELogic : EntityLogic = $'../EntityLogic'
	var Entity = get_parent()
	var player_type_sync = NoninterpolatedSync.new()
	player_type_sync.value_path = '$'+str(Entity.get_path_to(self))+'.player_type'
	var id_sync = NoninterpolatedSync.new()
	id_sync.value_path = '$'+str(Entity.get_path_to(self))+'.id'
	ELogic.params.append_array([player_type_sync, id_sync])


func _get_configuration_warnings():
	var warnings = []
	var has_entity_logic = false
	for child in get_parent().get_children():
		if child is EntityLogic:
			has_entity_logic = true
	if not has_entity_logic:
		warnings.append('Observer must be child of Node with EntityLogic')
	return warnings
	
	
func is_player():
	if player_type == 'peer':
		if EntitiesLogic.multiplayer.get_unique_id() == id:
			return true
		else:
			return false
	elif player_type == 'reg':
		pass
