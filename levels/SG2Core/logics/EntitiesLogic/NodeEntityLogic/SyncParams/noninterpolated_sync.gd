@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name NoninterpolatedSync


var ChunksCalculator
var entities_storage

var tracking_entities : Dictionary[int, Array] # {entity_id: [entity_node, {value_path: param_data, ...}], ...}


func start():
	SG2Core = ExecManager.give_current_exec(self).giveo('level')
	EntitiesLogic = SG2Core.giveo('EntitiesLogic')
	ChunksCalculator = SG2Core.giveo('ChunksCalculator')
	entities_storage = SG2Core.giveo('entities_storage')
	
	
func start_tracking(entity_id : int, entity_node : Node, _value_path : String, _param_data):
	if not tracking_entities.has(entity_id):
		tracking_entities[entity_id] = [entity_node, {}]
	tracking_entities[entity_id][1][_value_path] = _param_data
	
	
func load_entity(chunk, entity_id : int, entity_data):
	if entity_data.values_dict.size() > 0:
		for _value_path in entity_data.values_dict:
			Dispenser.set_resource(tracking_entities[entity_id][0], _value_path, Dispenser.dupl(entity_data.values_dict[_value_path]))
	elif entity_data.values_array.size > 0:
		for i in range(len(entity_data.values_array)):
			Dispenser.set_resource(tracking_entities[entity_id][0], EntitiesLogic.entities_values_compressed_order[i], entity_data.values_array[i])
	
	
func track_entity(entity_id : int):
	for _value_path in tracking_entities[entity_id][1]:
		EntitiesLogic.entities[entity_id].values_dict[_value_path] = Dispenser.get_resource(tracking_entities[entity_id][0], _value_path)[0]
