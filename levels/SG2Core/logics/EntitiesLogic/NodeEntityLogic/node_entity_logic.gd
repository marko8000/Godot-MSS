@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
extends Node
class_name EntityLogic


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var EntitiesLogic = SG2Core.giveo('EntitiesLogic')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var InterpolationLogic = SG2Core.giveo('InterpolationLogic')

@export var params : Array[AbstractSync]

var entity_data : Array = [{}, {}]# [{name, params...}, {subentity_id: [], ...}]


func _ready():	
	if not EntitiesLogic.entities_can_start_work:
		await EntitiesLogic._entities_start_work
				
	for param in params:
		if 'Logic' in param:
			param.Logic = self
	
	if not str(get_parent().name)[0] == 'e' and not get_parent().name.substr(1).is_valid_int():
		if ConnectionLogic.peer_role == 'guest':
			get_parent().queue_free()
		elif ConnectionLogic.peer_role == 'host':
			get_parent().name = 'e'+str(EntitiesLogic.get_new_entity_id())
			
			
func load_entity_data(_entity_data):
	var entity_params = _entity_data[0]
	if entity_params is Dictionary:
		entity_data[0] = {'name': entity_params.name}
		entity_params.erase('name')
		for param in params:
			if not 'Logic' in param: continue
			for _key in entity_params:
				if param.value_path == _key:
					param.load_param_data(entity_params[_key])
	elif entity_params is Array:
		entity_data[0] = {'name': entity_params[0]}
		entity_data.pop_at(0)
		for param_num in len(range(params)):
			if not 'Logic' in params[param_num]: continue
			if entity_params.has(param_num):
				params[param_num].load_param_data(entity_params[param_num])
		
