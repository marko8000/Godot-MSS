@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
@tool
extends Node
## EntityLogic is start point for entity properties tracking, the node is deleted after the function EntitiesLogic.start_tracking is called
class_name EntityPropertiesSeed


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level()
@onready var _EntitiesLogic := _SG2Core._EntitiesLogic
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic

@export var tracked_properties : Array[AbstractSync]
@export var guest_presets : Dictionary[String, Variant]
## nonchunk entitites are visible everywhere
@export var nonchunk : bool = false


func _ready():
	entity_prepare()
	
	
func entity_prepare():
	if _EntitiesLogic == null:
		return
		
	if not _EntitiesLogic.entities_can_start_work:
		await _EntitiesLogic._entities_start_work
	
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		if _ConnectionLogic.peer_role == 'guest':
			get_parent().queue_free()
		elif _ConnectionLogic.peer_role == 'host':
			var entity_id = _EntitiesLogic.get_new_entity_id()
			get_parent().name = 'e'+str(entity_id)
			presets()
			start_tracking(entity_id)
					

func _get_configuration_warnings():
	var warnings = []
	var parent_warning := false
	if get_parent() != null:
		if get_parent().scene_file_path != 'res://entities/'+get_parent().name+'/'+get_parent().name+'.tscn':
			parent_warning = true
	else:
		parent_warning = true
	if parent_warning:
		warnings.append('EntityPropertiesSeed must be child of entity scene saved in res://entities/{entity_type}/{entity_type}.tscn')
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
	
	var warning_window = load('res://levels/SG2Core/logics/EntitiesLogic/EntityPropertiesSeed/popup.tscn').instantiate()
	warning_window.entity_type = get_parent().name
	warning_window.page('NodeRename')
	
	base_control.add_child(warning_window)
	

func presets():
	for child in get_parent().get_children():
		if child.has_method('presets') and child != self:
			child.presets()
	if _ConnectionLogic == null:
		return
	if _ConnectionLogic.peer_role == 'guest':
		apply_guest_presets()
	
	
func apply_guest_presets():
	for property_path in guest_presets:
		Dispenser.set_resource(get_parent(), property_path, guest_presets[property_path])
	
	
func start_tracking(entity_id):
	@warning_ignore("incompatible_ternary")
	_EntitiesLogic.start_tracking(entity_id, get_parent(), tracked_properties, null if nonchunk else _EntitiesLogic.FROM_E_POS)
