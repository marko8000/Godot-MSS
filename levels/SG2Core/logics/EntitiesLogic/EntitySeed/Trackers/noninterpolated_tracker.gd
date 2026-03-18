@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractTracker
class_name NoninterpolatedTracker


var _ChunksCalculator
var _entities_storage

var tracked_entities : Dictionary[int, TrackedEntity]
var entity_type_cache : Dictionary[int, EntityTypeCache]


class TrackedEntity:
	var entity_node : Node
	var entity_type : int
	

class EntityTypeCache:
	var properties_path_config : Dictionary[String, Variant]
	var entities_property_path_property_array_num : Dictionary
	var entities_property_array_num_property_path : Array
	
	
func start():
	_SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
	_EntitiesLogic = _SG2Core._EntitiesLogic
	_ChunksCalculator = _SG2Core._ChunksCalculator
	_entities_storage = _SG2Core._entities_storage
	
	
func start_tracking(entity_id : int, _property_path : String, _property_config):
	var e_type = _EntitiesLogic.entities[entity_id].type
	if not tracked_entities.has(entity_id):
		tracked_entities[entity_id] = TrackedEntity.new()
		tracked_entities[entity_id].entity_node = _EntitiesLogic.entities[entity_id].node
		tracked_entities[entity_id].entity_type = e_type
		if not entity_type_cache.has(e_type):
			entity_type_cache[e_type] = EntityTypeCache.new()
			entity_type_cache[e_type].properties_path_config = {}
			entity_type_cache[e_type].entities_property_path_property_array_num = _EntitiesLogic.entities_property_path_property_array_num[e_type]
			entity_type_cache[e_type].entities_property_array_num_property_path = _EntitiesLogic.entities_property_array_num_property_path[e_type]
	if len(entity_type_cache[e_type].properties_path_config) != len(entity_type_cache[e_type].entities_property_array_num_property_path):
		entity_type_cache[e_type].properties_path_config[_property_path] = _property_config
	
	
func track_entity(entity_id : int):
	if not tracked_entities.has(entity_id): return
	var entity : TrackedEntity = tracked_entities[entity_id]
	var type_cache : EntityTypeCache = entity_type_cache[entity.entity_type]
	for _property_path in type_cache.properties_path_config:
		var value = Dispenser.get_resource(entity.entity_node, _property_path, [entity.entity_type, _property_path],)[0]
		_EntitiesLogic.entities[entity_id].spawn_data[1][type_cache.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		_EntitiesLogic.entities[entity_id].update_data[0][type_cache.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		

func update_entity(entity_id : int, update_data : Array):
	var entity : TrackedEntity = tracked_entities[entity_id]
	var type_cache : EntityTypeCache = entity_type_cache[entity.entity_type]
	if update_data[0] != null and is_instance_valid(entity.entity_node):
		for i in range(len(update_data[0])):
			Dispenser.set_resource(entity.entity_node, type_cache.entities_property_array_num_property_path[i], update_data[0][i], [entity.entity_type, i])
		
		
func stop_tracking(entity_id):
	tracked_entities.erase(entity_id)
