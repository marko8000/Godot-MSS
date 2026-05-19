@icon('res://levels/SG2Core/x_res/x_images/Grid.svg')
extends AbstractTracker
class_name NoninterpolatedTracker
	
	
func start_tracking(entity_id : int, _property_path : String, _property_config : AbstractTracker):
	var e_type = _EntitiesLogic.entities[entity_id].type
	if not tracked_entities.has(entity_id):
		tracked_entities[entity_id] = TrackedEntity.new()
		tracked_entities[entity_id].entity_node = _EntitiesLogic.entities[entity_id].node
		tracked_entities[entity_id].entity_type = e_type
		if not entity_type_data.has(e_type):
			entity_type_data[e_type] = EntityTypeData.new()
			entity_type_data[e_type].properties_path_config = {}
			entity_type_data[e_type].entities_property_path_property_array_num = _EntitiesLogic.entities_property_path_property_array_num[e_type]
			entity_type_data[e_type].entities_property_array_num_property_path = _EntitiesLogic.entities_property_array_num_property_path[e_type]
	if len(entity_type_data[e_type].properties_path_config) != len(entity_type_data[e_type].entities_property_array_num_property_path):
		entity_type_data[e_type].properties_path_config[_property_path] = _property_config.duplicate(true)
	
	
func track_entity(entity_id : int):
	if not tracked_entities.has(entity_id): return
	var entity : TrackedEntity = tracked_entities[entity_id]
	var type_data : EntityTypeData = entity_type_data[entity.entity_type]
	for _property_path in type_data.properties_path_config:
		var value = Dispenser.get_resource(entity.entity_node, _property_path, [entity.entity_type, _property_path],)[0]
		_EntitiesLogic.entities[entity_id].spawn_data[1][type_data.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		_EntitiesLogic.entities[entity_id].update_data[0][type_data.entities_property_path_property_array_num[_property_path]] = Dispenser.dupl(value)
		

func update_entity(entity_id : int, update_data : Array):
	var entity : TrackedEntity = tracked_entities[entity_id]
	var type_data : EntityTypeData = entity_type_data[entity.entity_type]
	if update_data[0] != null and is_instance_valid(entity.entity_node):
		for i in range(len(update_data[0])):
			Dispenser.set_resource(entity.entity_node, type_data.entities_property_array_num_property_path[i], update_data[0][i], [entity.entity_type, i])
		
		
func stop_tracking(entity_id : int):
	tracked_entities.erase(entity_id)
