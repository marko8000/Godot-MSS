@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name PositionSync


var Logic : EntityLogic
var param_data : Vector3
## Example: $SomeNode.value or value or $SomeNode
@export var value_path : String

var SG2Core
var tracking_entities : Dictionary # {chunk: {entity_id: {value_path: param_data, ...}, ...}, ...}
var ChunksCalculator
var entities_storage


func start():
	SG2Core = ExecManager.give_current_exec().giveo('level')
	ChunksCalculator = SG2Core.giveo('ChunksCalculator')
	entities_storage = SG2Core.giveo('entities_storage')
	
	
func track(entity_id, entity_node, _value_path, _param_data):
	if not tracking_entities.has(ChunksCalculator.position_to_chunk(entity_node.position)):
		tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)] = {}
	if not tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)].has(entity_id):
		tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)][entity_id] = {}
	tracking_entities[ChunksCalculator.position_to_chunk(entity_node.position)][entity_id] = {_value_path: [entity_node, _param_data, entities_storage.get_path_to(entity_node)]}
	
	
func load_entity(chunk, entity_id, entity_data):
	pass
