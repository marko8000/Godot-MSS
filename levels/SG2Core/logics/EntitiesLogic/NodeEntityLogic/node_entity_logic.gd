@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
extends Node
class_name EntityLogic


@onready var SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var EntitiesLogic = SG2Core.giveo('EntitiesLogic')
@onready var ChunksCalculator = SG2Core.giveo('ChunksCalculator')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var InterpolationLogic = SG2Core.giveo('InterpolationLogic')

@export var params : Array[AbstractSync]
@export var guest_presets : Dictionary[String, Variant]
## nonchunk entitites are visible everywhere
@export var nonchunk : bool = false


func _ready():
	if not EntitiesLogic.entities_can_start_work:
		await EntitiesLogic._entities_start_work
	
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		if ConnectionLogic.peer_role == 'guest':
			get_parent().queue_free()
		elif ConnectionLogic.peer_role == 'host':
			var entity_id = EntitiesLogic.get_new_entity_id()
			get_parent().name = 'e'+str(entity_id)
			presets()
			start_tracking(entity_id)
			

func presets():
	for child in get_parent().get_children():
		if child.has_method('presets') and child != self:
			child.presets()
	if ConnectionLogic == null:
		return
	if ConnectionLogic.peer_role == 'guest':
		apply_guest_presets()
	
	
func apply_guest_presets():
	for value_path in guest_presets:
		Dispenser.set_resource(get_parent(), value_path, guest_presets[value_path])
	
	
func start_tracking(entity_id):
	EntitiesLogic.start_tracking(entity_id, get_parent(), params, null if nonchunk else EntitiesLogic.FROM_E_POS)
