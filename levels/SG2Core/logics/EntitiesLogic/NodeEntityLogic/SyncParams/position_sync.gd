@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name PositionSync


var Logic : EntityLogic
var param_data : Vector3
## Example: $SomeNode.value or value
@export var value_path : String

var SG2Core
var tracking_entities : Dictionary # {chunk: {entity_id: {value_path: param_data, ...}, ...}, ...}
var ChunksCalculator


func track(entity_id, entity_node, _value_path, _param_data):
	ChunksCalculator = SG2Core.giveo('ChunksCalculator')
	if not tracking_entities.has(ChunksCalculator.position_to_chunk(entity_node.position)):
		tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)] = {}
	if not tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)].has(entity_id):
		tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)][entity_id] = {}
	tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)][entity_id] = {_value_path: _param_data}
	
	
func get_entities_params():
	pass
	
	
func load_entities_params():
	pass
