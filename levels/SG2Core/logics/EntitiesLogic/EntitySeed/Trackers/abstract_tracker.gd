@abstract
extends Resource
class_name AbstractTracker


var _SG2Core : SG2Core
var _EntitiesLogic : EntitiesLogic

## Example: $SomeNode.value or value or $SomeNode
@export var property_path : String

var tracked_entities : Dictionary[int, TrackedEntity]
var entity_type_data : Dictionary[int, EntityTypeData]


class TrackedEntity:
	var entity_node : Node
	var entity_type : int
	

class EntityTypeData:
	var properties_config : Dictionary[String, AbstractTracker]
	var entities_property_path_property_array_num : Dictionary
	var entities_property_array_num_property_path : Array

	
func start():
	_EntitiesLogic = _SG2Core._EntitiesLogic
	
	
func start_tracking(entity_id : int, _property_path : String, _property_config : AbstractTracker):
	pass
	
	
func update_entity(entity_id : int, update_data : Array):
	pass
	
	
func track_entity(entity_id : int):
	pass
	
	
func stop_tracking(entity_id : int):
	pass
