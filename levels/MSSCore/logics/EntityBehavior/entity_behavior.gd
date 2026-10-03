@icon('res://levels/MSSCore/images/entity_icon.png')
@tool
extends Node
class_name EntityBehavior


var _EntityStorageLogic : EntityStorageLogic

var entity_indices : PackedInt32Array


func _entity_ready(entity : Node) -> void:
	pass
	
	
func _process(delta: float) -> void:
	pass
	
	
func _physics_process(delta: float) -> void:
	pass


func _get_configuration_warnings():
	var warnings = []
	
	var parent_warning := false
	if is_instance_valid(get_parent()) and get_parent() == get_tree().edited_scene_root:
		if get_parent().name != get_parent().scene_file_path.get_slice('/', 3):
			get_parent().name = get_parent().scene_file_path.get_slice('/', 3)
		var name_options : PackedStringArray = [
			'res://entities/'+get_parent().name+'/'+get_parent().name.to_camel_case()+'.tscn',
			'res://entities/'+get_parent().name+'/'+get_parent().name.to_kebab_case()+'.tscn',
			'res://entities/'+get_parent().name+'/'+get_parent().name.to_snake_case()+'.tscn',
			'res://entities/'+get_parent().name+'/'+get_parent().name.to_pascal_case()+'.tscn',
			'res://entities/'+get_parent().name+'/'+get_parent().name+'.tscn'
		]
		if not get_parent().scene_file_path in name_options:
			parent_warning = true
	else:
		parent_warning = true
	if parent_warning:
		warnings.append('EntitySeed must be child of entity scene that saved in res://entities/{0}/{1}.tscn'.format([get_parent().name, get_parent().name.to_snake_case()]))
	
	return warnings
