@abstract
extends Resource
class_name DynamicTracker


@warning_ignore("unused_private_class_variable")
var _SG2Core : SG2Core
@warning_ignore("unused_private_class_variable")
var _ESL : EntityStorageLogic

## Example: $SomeNode.value or value or $SomeNode
@export var property_path : String

var tracked_global_entities : Array[TrackedEntity]
var global_active_mask : Array[PackedByteArray]
var global_index_map : PackedInt32Array

var entity_type_data : Dictionary[int, EntityTypeData]


class TrackedEntity:
	var entity_node : Node
	var entity_type : int
	

class EntityTypeData:
	var properties_config : Dictionary[String, DynamicTracker]
	var entities_property_path_property_array_num : Dictionary
	var entities_property_array_num_property_path : Array
	
	
func start_tracking(entity_id : int, _property_path : String, _property_config : DynamicTracker):
	pass
	
	
func update_entity(entity_id : int, update_data : Array):
	pass
	
	
func track_entity(entity_id : int):
	pass
	
	
func stop_tracking(entity_id : int):
	pass
