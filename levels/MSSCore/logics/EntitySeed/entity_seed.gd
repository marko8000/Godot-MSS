@icon('res://levels/MSSCore/images/entity_icon.png')
@tool
extends Node
## EntitySeed is start point for entity properties tracking
class_name EntitySeed


var _MSSCore : MSSCore
var _EntityStorage : EntityStorage
var _EntityFactory : EntityFactory
var _ConnectionLogic : ConnectionLogic

@export var trackers : Array[NodeTracker]
@export var components : Array[Component]
@export_group('Advanced settings')
@export var scale_level : int = 0 :
	set(value):
		scale_level = max(value, 0)
@export var root_lod_level : int = 0 : 
	set(value):
		root_lod_level = max(value, 0)
@export var is_global : bool = false
@export var tickrate : int = 0
@export var setup_on_ready : bool = false

var entity_type : int
	
	
func _ready():
	if not Engine.is_editor_hint() and setup_on_ready:
		entity_prepare()
	else:
		if get_parent() != null:
			get_parent().renamed.connect(_entity_node_renamed)
		if get_parent() == get_tree().edited_scene_root:
			setup_on_ready = true
	
	
func entity_prepare():
	_MSSCore = MSSCore.get_from(self)
	_EntityFactory = _MSSCore._EntityFactory
	_EntityStorage = _MSSCore._EntityStorage
	_ConnectionLogic = _MSSCore._ConnectionLogic

	if not _EntityStorage._entities_can_start_working:
		await _EntityStorage._entities_start_working
	
	if _ConnectionLogic.peer_role == 'guest':
		get_parent().queue_free()
	elif _ConnectionLogic.peer_role == 'host':
		if not entity_type:
			entity_type = _EntityFactory._entity_type_shortcuts[get_parent().get_scene_file_path().get_slice('/', 3)]
		_presets()
		var indices = _EntityStorage._allocate_batch(entity_type, Array([get_parent()], TYPE_OBJECT, "Node", null))
		_EntityStorage._activation_queue[entity_type].append_array(indices)
		get_parent().name = str(indices[0])
		
		
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
	
	var entity_behavior_warning := false
	if is_instance_valid(get_parent()) and get_parent() == get_tree().edited_scene_root:
		if is_instance_valid(get_parent().get_script()):
			entity_behavior_warning = true
	if entity_behavior_warning:
		warnings.append('''Consider using EntityBehavior
This entity contains behavior that can be processed independently for each instance.
If many instances of this entity are active, centralized processing through EntityBehavior may provide better performance.
Create a new EntityBehavior node and extend the script to create centralized logic.''')
	
	return warnings
	
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
			
			
func _entity_node_renamed():
	get_parent().renamed.disconnect(_entity_node_renamed)
	if get_parent() != get_tree().edited_scene_root:
		return
	get_parent().renamed.connect(_entity_node_renamed)
	if get_parent().name == get_parent().scene_file_path.get_slice('/', 3):
		return
	get_parent().name = get_parent().scene_file_path.get_slice('/', 3)

	var base_control = EditorInterface.get_base_control()
	
	var warning_window = load('res://levels/MSSCore/logics/EntitySeed/popup.tscn').instantiate()
	warning_window.entity_type = get_parent().name
	warning_window.get_node('PageContainer').change_page('NodeRenamed')
	
	base_control.add_child(warning_window)
		
		
func _presets():
	for child in get_parent().get_children():
		if child.has_method('presets') and child != self:
			child.presets()
	if not is_instance_valid(_ConnectionLogic):
		return
