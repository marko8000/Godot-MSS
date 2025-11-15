extends Resource
class_name AbstractSync


var SG2Core
var EntitiesLogic

## Example: $SomeNode.value or value or $SomeNode
@export var value_path : String
var param_data # host and guest must have same param_data in entity param
	
	
func start():
	SG2Core = ExecManager.give_current_exec(self).giveo('level')
	EntitiesLogic = SG2Core.giveo('EntitiesLogic')
	
	
func start_tracking(entity_id : int, entity_node : Node, _value_path : String, _param_data):
	pass
	
	
func update_entity(chunk, entity_id : int, entity_data):
	pass
	
	
func track_entity(entity_id : int):
	pass
	
	
func save_entities():
	pass
