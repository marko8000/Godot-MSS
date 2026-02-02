@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractTracker
class_name NoninterpolatedTracker


var _ChunksCalculator
var _entities_storage

## cache of tracked entities
var tracked_entities : Dictionary[int, TrackedEntityCache]


class TrackedEntityCache:
	var entity_node : Node
	var properties_path_config : Dictionary[String, Variant]
	var entity_type : int
	var entities_property_path_property_array_num : Dictionary
	var entities_property_array_num_property_path : Array
	
	
func start():
	_SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
	_EntitiesLogic = _SG2Core._EntitiesLogic
	_ChunksCalculator = _SG2Core._ChunksCalculator
	_entities_storage = _SG2Core._entities_storage
	
	
func start_tracking(entity_id : int, _property_path : String, _property_config):
	if not tracked_entities.has(entity_id):
		tracked_entities[entity_id] = TrackedEntityCache.new()
		tracked_entities[entity_id].entity_node = _EntitiesLogic.entities_nodes[entity_id]
		tracked_entities[entity_id].properties_path_config = {}
		tracked_entities[entity_id].entity_type = _EntitiesLogic.entities_types[entity_id]
		tracked_entities[entity_id].entities_property_path_property_array_num = _EntitiesLogic.entities_property_path_property_array_num[_EntitiesLogic.entities_types[entity_id]]
		tracked_entities[entity_id].entities_property_array_num_property_path = _EntitiesLogic.entities_property_array_num_property_path[_EntitiesLogic.entities_types[entity_id]]
	tracked_entities[entity_id].properties_path_config[_property_path] = _property_config
	
	
func track_entity(entity_id : int):
	if not tracked_entities.has(entity_id): return
	var cache : TrackedEntityCache = tracked_entities[entity_id]
	for _property_path in cache.properties_path_config:
		var value = Dispenser.get_resource(cache.entity_node, _property_path, [cache.entity_type, _property_path],)[0]
		_EntitiesLogic.entities_spawn_data[entity_id][1][cache.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		_EntitiesLogic.entities_update_data[entity_id][0][cache.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		

func update_entity(entity_id : int, update_data : Array):
	var cache : TrackedEntityCache = tracked_entities[entity_id]
	if update_data[0] != null and is_instance_valid(cache.entity_node):
		for i in range(len(update_data[0])):
			Dispenser.set_resource(cache.entity_node, cache.entities_property_array_num_property_path[i], update_data[0][i], [cache.entity_type, i])
		
		
func stop_tracking(entity_id):
	tracked_entities.erase(entity_id)
