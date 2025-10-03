@icon('res://levels/SG2Core/x_res/x_images/entity_icon.png')
extends Node 


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var entities_storage = SG2Core.giveo('entities_storage')
@onready var EntitiesLogic = SG2Core.giveo('EntitiesLogic')
@onready var MultiplayerLogic = SG2Core.giveo('MultiplayerLogic')
@onready var Entity = give_Entity() 

@onready var entity_id : int
var entity_parametres : Dictionary = {'entity_type': 'example', 'subentities': {}, 'path_from_parent': null}
var current_chunk = 'hasnotchunk'
@export var unchunkable : bool = false

var interpolating_entity_parametres : Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# START
	if not EntitiesLogic.entities_can_start_work:
		await EntitiesLogic._entities_start_work
	entity_id = give_new_entity_id()
	
	if not is_in_entities_storage():
		if is_subentity():
			update_entity_parametres()
			give_entity_parametres_to_parent()
		else:
			update_entity_parametres()
			await get_tree().process_frame
			parent_move_to_entities_storage()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_in_entities_storage():
		if 'interpolating_frame' in interpolating_entity_parametres:
			load_entity_parametres(entity_id, interpolating_entity_parametres)
		
		if is_subentity():
			update_entity_parametres()
			give_entity_parametres_to_parent()
		else:
			update_entity_parametres()
			parent_give_entity_parametres_to_EntitiesLogic()


func give_new_entity_id():
	if not is_in_entities_storage() or not 'notloaded' in Entity.name:
		return EntitiesLogic.give_new_entity_id(Entity)
	else:
		return -1
		

func give_Entity():
	var _checking_parent = get_parent()
	while _checking_parent != SG2Core:
		if _checking_parent.has_method('get_EntityLogic'):
			return _checking_parent
		_checking_parent = _checking_parent.get_parent()
	

func is_in_entities_storage():
	var _checking_parent = Entity.get_parent()
	while _checking_parent != SG2Core:
		if _checking_parent == entities_storage:
			return true
		_checking_parent = _checking_parent.get_parent()
	return false
	
	
func is_subentity():
	var _checking_parent = Entity.get_parent()
	while _checking_parent != SG2Core:
		if _checking_parent.has_method('get_EntityLogic'):
			return true
		_checking_parent = _checking_parent.get_parent()
	return false
	
	
func give_parent_entity():
	var _checking_parent = Entity.get_parent()
	while _checking_parent != SG2Core:
		if _checking_parent.has_method('get_EntityLogic'):
			return _checking_parent
		_checking_parent = _checking_parent.get_parent()


func update_entity_parametres():
	entity_parametres.global_position = Entity.global_position
	entity_parametres.global_rotation = Entity.global_rotation
	
	if is_subentity():
		var _path_from_parent = give_parent_entity().get_path_to(Entity).slice(0, -1)
		entity_parametres.path_from_parent = _path_from_parent if str(_path_from_parent) != '' else null
	
	if is_in_entities_storage():
		for subentity_id in entity_parametres.subentities:
			var _path_from_Entity_to_subentity_parent_node = entity_parametres.subentities[subentity_id].path_from_parent
			var _parent_node_of_subentity = Entity.get_node(_path_from_Entity_to_subentity_parent_node) if _path_from_Entity_to_subentity_parent_node != null else Entity
			if not _parent_node_of_subentity.has_node(str(subentity_id)):
				EntitiesLogic.deleted_entities.append(subentity_id)
				entity_parametres.subentities.erase(subentity_id)
			else:
				if subentity_id in EntitiesLogic.deleted_entities:
					_parent_node_of_subentity.get_node(str(subentity_id)).queue_free()
					EntitiesLogic.deleted_entities.erase(subentity_id)
	
	
func load_entity_parametres(_entity_id, _new_entity_parametres):
	entity_id = _entity_id
	Entity.set_name(str(_entity_id))
	
	# setting interpolation settings
	if not 'interpolating_frame' in _new_entity_parametres:
		interpolating_entity_parametres = _new_entity_parametres
		interpolating_entity_parametres.interpolating_frame = 0
		load_entity_parametres(_entity_id, interpolating_entity_parametres)
		return
	elif 'interpolating_frame' in interpolating_entity_parametres:
		interpolating_entity_parametres.interpolating_frame += 1
		if interpolating_entity_parametres.interpolating_frame > MultiplayerLogic.guest_interpolation_scale:
			interpolating_entity_parametres = {}
			return
	
	var _guest_interpolation_scale = MultiplayerLogic.guest_interpolation_scale
	var i_frame = interpolating_entity_parametres.interpolating_frame
	
	# loading parametres to Entity from _new_entity_parametres
	# condition for not interpolatable values
	if i_frame == 1:
		#loading subentities
		for subentity_id in _new_entity_parametres.subentities:
			var _entity_scene_file = load(EntitiesLogic.entities_summon_settings[_new_entity_parametres.subentities[subentity_id].entity_type].scene_path)
			var _entity_instance = _entity_scene_file.instantiate()
			_entity_instance.name = str(subentity_id)
			var _path_from_Entity_to_subentity_parent_node = _new_entity_parametres.subentities[subentity_id].path_from_parent
			var _parent_node_of_subentity = Entity.get_node(_path_from_Entity_to_subentity_parent_node) if _path_from_Entity_to_subentity_parent_node != null else Entity
			EntitiesLogic.summon_entity(subentity_id, _new_entity_parametres.subentities[subentity_id].duplicate(true), _parent_node_of_subentity)
	# this condition execute for interpolating values
	if i_frame >= 1:
		#loading global_position
		var old_global_position = Entity.global_position
		var _vector_from_old_global_position_to_new = (_new_entity_parametres.global_position - old_global_position) / _guest_interpolation_scale * i_frame
		Entity.translate(_vector_from_old_global_position_to_new)
		Entity.global_position = old_global_position + _vector_from_old_global_position_to_new
		
		#loading global_rotation
		var old_global_rotation = Entity.global_rotation
		var _vector_from_old_global_rotation_to_new = (_new_entity_parametres.global_rotation - old_global_rotation) / _guest_interpolation_scale * i_frame
		Entity.global_rotation = old_global_rotation + _vector_from_old_global_rotation_to_new
	
	
func parent_move_to_entities_storage():
	EntitiesLogic.summon_entity(entity_id, entity_parametres.duplicate(true))
	Entity.queue_free()
	

func give_entity_parametres_to_parent():
	var _parent_entity = give_parent_entity()
	var _parent_entity_EntityLogic = _parent_entity.get_EntityLogic()
	_parent_entity_EntityLogic.entity_parametres.subentities[entity_id] = entity_parametres.duplicate(true)
	if _parent_entity_EntityLogic.is_subentity():
		_parent_entity_EntityLogic.give_entity_parametres_to_parent()
	else:
		if is_in_entities_storage():
			_parent_entity_EntityLogic.parent_give_entity_parametres_to_EntitiesLogic()
	
	
func parent_give_entity_parametres_to_EntitiesLogic():
	current_chunk = EntitiesLogic.chunk_entity(Entity.global_position, entity_id, entity_parametres.duplicate(true), current_chunk)
	
