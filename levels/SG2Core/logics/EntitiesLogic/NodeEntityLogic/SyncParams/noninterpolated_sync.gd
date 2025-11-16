@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name NoninterpolatedSync


var _ChunksCalculator
var _entities_storage

var tracking_entities : Dictionary[int, Array] # {entity_id: [entity_node, {value_path: param_data, ...}, entity_type], ...}
	

func start():
	_SG2Core = ExecManager.give_current_exec(self).giveo('level')
	_EntitiesLogic = _SG2Core._EntitiesLogic
	_ChunksCalculator = _SG2Core._ChunksCalculator
	_entities_storage = _SG2Core._entities_storage
	
	
func start_tracking(entity_id : int, entity_node : Node, _value_path : String, _param_data):
	if not tracking_entities.has(entity_id):
		tracking_entities[entity_id] = [entity_node, {}, _EntitiesLogic.entities_spawn_data[entity_id][0], _EntitiesLogic.entities_value_path_value_array_num[_EntitiesLogic.entities_spawn_data[entity_id][0]], _EntitiesLogic.entities_value_array_num_value_path[_EntitiesLogic.entities_spawn_data[entity_id][0]]]
	tracking_entities[entity_id][1][_value_path] = _param_data
	
	
func track_entity(entity_id : int):
	if not tracking_entities.has(entity_id): return
	for _value_path in tracking_entities[entity_id][1]:
		var value = Dispenser.get_resource(tracking_entities[entity_id][0], _value_path, [tracking_entities[entity_id][2], _value_path])[0]
		_EntitiesLogic.entities_spawn_data[entity_id][1][tracking_entities[entity_id][3][_value_path]] = Dispenser.dupl(value)
		_EntitiesLogic.entities_update_data[entity_id][0][tracking_entities[entity_id][3][_value_path]] = Dispenser.dupl(value)
		
		
func update_entity(chunk, entity_id : int, update_data : Array):
	if not tracking_entities.has(entity_id): return
	for i in range(len(update_data[0])):
		if update_data[0] != null:
			Dispenser.set_resource(tracking_entities[entity_id][0], tracking_entities[entity_id][4][i], update_data[0][i])
		
		
func save_entities():
	pass
