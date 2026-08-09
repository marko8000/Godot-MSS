@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
@tool
extends Node
## EntitySeed is start point for entity properties tracking
class_name EntitySeed


var _SG2Core : SG2Core
var _EntitySync : EntitySync
var _EntityFactory : EntityFactory
var _EntityStorage : EntityStorage
var _ConnectionLogic : ConnectionLogic

@export var trackers : Array[BaseTracker] :
	set(value):
		trackers = value
@export_group('Advanced settings')
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
	_SG2Core = SG2Core.get_from(self)
	_EntitySync = _SG2Core._EntitySync
	_EntityFactory = _SG2Core._EntityFactory
	_EntityStorage = _SG2Core._EntityStorage
	_ConnectionLogic = _SG2Core._ConnectionLogic

	if not _EntitySync._entities_can_start_working:
		await _EntitySync._entities_start_working
	
	if _ConnectionLogic.peer_role == 'guest':
		get_parent().queue_free()
	elif _ConnectionLogic.peer_role == 'host':
		if not entity_type:
			entity_type = _EntityFactory._entity_type_shortcuts[get_parent().get_scene_file_path().get_slice('/', 3)]
		_presets()
		var indices = _EntityStorage._allocate_batch(entity_type, Array([get_parent()], TYPE_OBJECT, "Node", null))
		_EntityStorage._activation_queue[entity_type] = indices
		get_parent().set_meta('x', indices[0])
		
		
func _get_configuration_warnings():
	var warnings = []
	var parent_warning := false
	if get_parent() != null:
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
	
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
			
			
func _entity_node_renamed():
	get_parent().renamed.disconnect(_entity_node_renamed)
	if get_parent() != get_tree().edited_scene_root:
		return
	get_parent().name = get_parent().scene_file_path.get_slice('/', 3)
	get_parent().renamed.connect(_entity_node_renamed)
	var base_control = EditorInterface.get_base_control()
	
	var warning_window = load('res://levels/SG2Core/logics/EntitySeed/popup.tscn').instantiate()
	warning_window.entity_type = get_parent().name
	warning_window.get_node('PageContainer').change_page('NodeRenamed')
	
	base_control.add_child(warning_window)
		
		
func _presets():
	for child in get_parent().get_children():
		if child.has_method('presets') and child != self:
			child.presets()
	if not is_instance_valid(_ConnectionLogic):
		return
