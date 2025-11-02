@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name NoninterpolatedSync


var Logic : EntityLogic
var param_data : Vector3 # host and guest must have same param_data in entity param
## Example: $SomeNode.value or value or $SomeNode
@export var value_path : String

var SG2Core
var tracking_entities : Dictionary # {entity_id: {value_path: param_data, ...}, ...}
var EntitiesLogic
var ChunksCalculator
var entities_storage


func start():
	SG2Core = ExecManager.give_current_exec(self).giveo('level')
	EntitiesLogic = SG2Core.giveo('EntitiesLogic')
	ChunksCalculator = SG2Core.giveo('ChunksCalculator')
	entities_storage = SG2Core.giveo('entities_storage')
	
	
func start_tracking(entity_id, entity_node, _value_path, _param_data):
	if not tracking_entities.has(entity_id):
		tracking_entities[entity_id] = {}
	tracking_entities[entity_id] = {_value_path: [entity_node, _param_data, entities_storage.get_path_to(entity_node)]}
	
	
func load_entity(chunk, entity_id, entity_data):
	var entity = entities_storage.get_node('.' if not entity_data.has(2) else entity_data[2]).get_node('e'+str(entity_id))
	
	if entity_data[1] is Dictionary:
		for _value_path in entity_data[1]:
			Dispenser.set_resource(entity, _value_path, Dispenser.dupl(entity_data[1][value_path]))
	elif entity_data[1] is Array:
		var dict = {}
		for i in range(EntitiesLogic.entities_values_compressed_order[entity_data[0]].size()):
			dict[EntitiesLogic.entities_values_compressed_order[entity_data[0]][i]] = Dispenser.dupl(entity_data[1][i])
		entity_data[1] = dict.duplicate(true)
		load_entity(chunk, entity_id, entity_data)
	
	
func track_entities():
	for entity_id in tracking_entities:
		#if not EntitiesLogic.entities_chunks.has(entity_id): continue
		#if not EntitiesLogic.entities[EntitiesLogic.entities_chunks[entity_id]].has(entity_id): continue
		for value_path in tracking_entities[entity_id]:
			EntitiesLogic.entities[EntitiesLogic.entities_chunks[entity_id]][entity_id][1][value_path] = Dispenser.get_resource(entities_storage.get_node(EntitiesLogic.entities[EntitiesLogic.entities_chunks[entity_id]][entity_id][2]).get_node('e'+str(entity_id)), value_path)[0]
