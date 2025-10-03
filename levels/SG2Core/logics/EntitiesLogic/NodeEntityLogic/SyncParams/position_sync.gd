@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name PositionSync


var Logic : EntityLogic
var param_data : Vector3
## Example: $SomeNode.value or value
@export var value_path : String
var value


func _ready():
	if '$' in value_path:
		if '.' in value_path:
			value = get_value_from_node(Logic.get_parent().get_node(value_path))
		else:
			value = Logic.get_parent().get_node(value_path.substr(1))
	else:
		value = get_value_from_node(Logic.get_parent().get(value_path))
		

func get_value_from_node(node):
	pass
		
		
func load_param_data(_param_data):
	param_data = _param_data
	

func _process():
	if Logic.ConnectionLogic.peer_role == 'host':
		give_data_to_entity_logic()
		
		
func give_data_to_entity_logic():
	pass
	
	
