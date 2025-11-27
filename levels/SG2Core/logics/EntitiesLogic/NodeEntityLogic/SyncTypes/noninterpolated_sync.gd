@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractSync
class_name NoninterpolatedSync


var _ChunksCalculator
var _entities_storage

var tracked_entities : Dictionary[int, Array] # {entity_id: [entity_node, {property_path: property_config, ...}, entity_type], ...}
	

func start():
	_SG2Core = ExecManager.give_current_exec(self).giveo('level')
	_EntitiesLogic = _SG2Core._EntitiesLogic
	_ChunksCalculator = _SG2Core._ChunksCalculator
	_entities_storage = _SG2Core._entities_storage
	
	
func start_tracking(entity_id : int, entity_node : Node, _property_path : String, _property_config):
	if not tracked_entities.has(entity_id):
		tracked_entities[entity_id] = [entity_node, {}, _EntitiesLogic.entities_spawn_data[entity_id][0], _EntitiesLogic.entities_property_path_property_array_num[_EntitiesLogic.entities_spawn_data[entity_id][0]], _EntitiesLogic.entities_property_array_num_property_path[_EntitiesLogic.entities_spawn_data[entity_id][0]]]
	tracked_entities[entity_id][1][_property_path] = _property_config
	
	
func track_entity(entity_id : int):
	if not tracked_entities.has(entity_id): return
	for _property_path in tracked_entities[entity_id][1]:
		var value = Dispenser.get_resource(tracked_entities[entity_id][0], _property_path, [tracked_entities[entity_id][2], _property_path])[0]
		_EntitiesLogic.entities_spawn_data[entity_id][1][tracked_entities[entity_id][3][_property_path]] = Dispenser.dupl(value)
		_EntitiesLogic.entities_update_data[entity_id][0][tracked_entities[entity_id][3][_property_path]] = Dispenser.dupl(value)
		

func update_entity(chunk, entity_id : int, update_data : Array):
	if not tracked_entities.has(entity_id): return
	for i in range(len(update_data[0])):
		if update_data[0] != null:
			Dispenser.set_resource(tracked_entities[entity_id][0], tracked_entities[entity_id][4][i], update_data[0][i])
		
		
func stop_tracking(entity_id):
	tracked_entities.erase(entity_id)
