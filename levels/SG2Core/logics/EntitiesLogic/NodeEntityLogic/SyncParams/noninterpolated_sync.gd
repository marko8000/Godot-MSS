@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name NoninterpolatedSync


var ChunksCalculator
var entities_storage

var tracking_entities : Dictionary[int, Array] # {entity_id: [entity_node, {value_path: param_data, ...}, entity_type], ...}
	

func start():
	SG2Core = ExecManager.give_current_exec(self).giveo('level')
	EntitiesLogic = SG2Core.giveo('EntitiesLogic')
	ChunksCalculator = SG2Core.giveo('ChunksCalculator')
	entities_storage = SG2Core.giveo('entities_storage')
	
	
func start_tracking(entity_id : int, entity_node : Node, _value_path : String, _param_data):
	if not tracking_entities.has(entity_id):
		tracking_entities[entity_id] = [entity_node, {}, EntitiesLogic.entities_spawn_data[entity_id][0], EntitiesLogic.entities_value_path_value_array_num[EntitiesLogic.entities_spawn_data[entity_id][0]], EntitiesLogic.entities_value_array_num_value_path[EntitiesLogic.entities_spawn_data[entity_id][0]]]
	tracking_entities[entity_id][1][_value_path] = _param_data
	
	
func track_entity(entity_id : int):
	if not tracking_entities.has(entity_id): return
	for _value_path in tracking_entities[entity_id][1]:
		var value = Dispenser.get_resource(tracking_entities[entity_id][0], _value_path, [tracking_entities[entity_id][2], _value_path])[0]
		EntitiesLogic.entities_spawn_data[entity_id][1][tracking_entities[entity_id][3][_value_path]] = Dispenser.dupl(value)
		EntitiesLogic.entities_update_data[entity_id][0][tracking_entities[entity_id][3][_value_path]] = Dispenser.dupl(value)
		
		
func update_entity(chunk, entity_id : int, update_data : Array):
	if not tracking_entities.has(entity_id): return
	for i in range(len(update_data[0])):
		if update_data[0] != null:
			Dispenser.set_resource(tracking_entities[entity_id][0], tracking_entities[entity_id][4][i], update_data[0][i])
		
		
func save_entities():
	pass
