@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
@tool
extends Node
## EntitySeed is start point for entity properties tracking
class_name EntitySeed


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
@onready var _EntitySync := _SG2Core._EntitySync
@onready var _EntityFactory := _SG2Core._EntityFactory
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
var _ESL : EntityStorageLogic

@export var tracked_properties : Array[DynamicTracker]
@export var guest_presets : Dictionary[String, Variant]
@export var global : bool = false


func _ready():
	entity_prepare()
	
	
func entity_prepare():
	get_parent().add_to_group('e')
	if not _EntitySync._entities_can_start_working:
		await _EntitySync._entities_start_working
	
	if _ConnectionLogic.peer_role == 'guest':
		get_parent().queue_free()
	elif _ConnectionLogic.peer_role == 'host':
		var entity_id = _EntityFactory._get_new_entity_id()
		var entity_type = _EntityFactory._entity_type_shortcuts[get_parent().get_scene_file_path().get_slice('/', 3)]
		_ESL = _EntityFactory._get_ESL(get_parent(), entity_type)
		_prepare_properties()
		_presets()
		print('name ', _ESL.name)
		_ESL._start_tracking(entity_id, entity_type, get_parent())
			


	
	
func _get_configuration_warnings():
	var warnings = []
	var parent_warning := false
	if get_parent() != null:
		if get_parent().scene_file_path != 'res://entities/'+get_parent().name+'/'+get_parent().name+'.tscn':
			parent_warning = true
	else:
		parent_warning = true
	if parent_warning:
		warnings.append('EntitySeed must be child of entity scene that saved in res://entities/{entity_type}/{entity_type}.tscn')
	return warnings
	
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		if get_parent() != null:
			if get_parent().name != get_parent().scene_file_path.get_slice('/', 3):
				_entity_node_renamed()
			
			
func _entity_node_renamed():
	if get_parent() != get_tree().edited_scene_root:
		return
	get_parent().name = get_parent().scene_file_path.get_slice('/', 3)
	var base_control = EditorInterface.get_base_control()
	
	var warning_window = load('res://levels/SG2Core/logics/EntitiesLogic/EntitySeed/popup.tscn').instantiate()
	warning_window.entity_type = get_parent().name
	warning_window.page('NodeRename')
	
	base_control.add_child(warning_window)
	

func _prepare_properties():
	for child in get_parent().get_children():
		if child.has_method('prepare_properties') and child != self:
			child.prepare_properties()
		
		
func _presets():
	for child in get_parent().get_children():
		if child.has_method('presets') and child != self:
			child.presets()
	if not is_instance_valid(_ConnectionLogic):
		return
	if _ConnectionLogic.peer_role == 'guest':
		_apply_guest_presets()
	
	
func _apply_guest_presets():
	for property_path in guest_presets:
		Dispenser.set_resource(get_parent(), property_path, guest_presets[property_path])
