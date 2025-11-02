@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@onready var SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')
@onready var entities_storage = SG2Core.giveo('entities_storage')
@onready var ChunksCalculator = SG2Core.giveo('ChunksCalculator')

@onready var general_entities_dir = DirectoriesPathsDistributor.give_path('general_entities_dir')
@onready var entities_data_file = DirectoriesPathsDistributor.give_path('entities_data_file')
@onready var shortcuts_entities_types : Dictionary[int, String] = load_shortcuts_entities_types()
@onready var entities_types_shortcuts : Dictionary[String, int] = load_entities_types_shortcuts()
@onready var entities_resources : Dictionary[int, Resource] = load_entities_resources()
var nonexistent_entities_types : PackedInt32Array


var entities_can_start_work : bool = false
signal _entities_start_work
var entities : Dictionary[int, EntityData] # {entity_id: EntityData, ...}
var entities_chunks : Dictionary[int, Variant] # {entity_id: chunk, ...}
var chunks_entities : Dictionary[Variant, PackedInt32Array] # {chunk: IdsArray}
var entities_changes : Dictionary[int, Array] # {entity_id: [value, value, ...], ...}
var entities_values_compressed_order : Dictionary[int, Array] # {entity_type: [value_path, value_path, ...], ...}
var trackers : Array[AbstractSync]
var last_used_entity_id : int = 0
const FROM_E_POS = 'f' # that means that chunk will be found from entity_position

@export_category('Drawing Settings')
@export var drawing_distance : int = 16 # host's parameter is max for guest. 0 is 1 chunk
@export var chunks_per_second : int = 3 # host's parameter is max for guest
var players_drawing_settings : Dictionary # {peer_id: [drawing_distance, chunks_per_second], ...}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


func start():
	emit_signal('_entities_start_work')
	entities_can_start_work = true
	if ConnectionLogic.peer_role == 'host':
		load_entities_data()
		for i in range(1000):
			summon_entity(EntityData.new('BallRigidBody3D', '.', {'position': Vector3(R.ri(-10, 10), 10, R.ri(-10, 10))}))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ConnectionLogic.peer_role == 'host':
		await get_tree().process_frame
		track_entities()
		for entity_id in entities:
			if entity_id == 23:
				print(entity_id, ': ', entities[entity_id].values_dict)
		send_entities_to_guests()
		
		
func _connection_peer_changed(new_peer):
	start()
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		
		
func _peer_connected(peer_id):
	players_drawing_settings[peer_id] = [drawing_distance, chunks_per_second]
	
	
func _peer_disconnected(peer_id):
	players_drawing_settings.erase(peer_id)
	

class EntityData:
	var type : int
	var path_from_entities_storage_to_parent : String = '.'
	var values_dict : Dictionary[String, Variant]
	var values_array : Array
	func _init(_type : Variant, _path_from_entities_storage_to_parent : String, _values_dict : Dictionary[String, Variant] = {}, _values_array : Array = []) -> void:
		type = _type if _type is int else ExecManager.give_current_exec(self).giveo('level').giveo('EntitiesLogic').entities_types_shortcuts[_type]
		path_from_entities_storage_to_parent = _path_from_entities_storage_to_parent
		values_dict = _values_dict
		values_array = _values_array
	
	
func get_new_entity_id():
	last_used_entity_id += 1
	return last_used_entity_id - 1
	

func load_shortcuts_entities_types():
	var dict : Dictionary[int, String]
	return dict
	
	
func load_entities_types_shortcuts():
	var dict : Dictionary[String, int]
	return dict
	
	
func load_entities_resources():
	var resources : Dictionary[int, Resource]
	var entities_without_EntityLogic : PackedStringArray
	for entity_type in DirAccess.get_directories_at('res://entities/'):
		if not entities_types_shortcuts.has(entity_type):
			shortcuts_entities_types[len(shortcuts_entities_types)] = entity_type
			entities_types_shortcuts[entity_type] = len(shortcuts_entities_types)-1
		if FilesManager.give_value_from_file_readlines('res://entities/'+entity_type+'/entity_info.txt', 'entity_scene_file') != null:
			resources[entities_types_shortcuts[entity_type]] = load("res://entities/"+entity_type+"/"+str(FilesManager.give_value_from_file_readlines('res://entities/'+entity_type+'/entity_info.txt', 'entity_scene_file')))
			var entity_instance = resources[entities_types_shortcuts[entity_type]].duplicate(true).instantiate()
			if not entity_instance.has_node('EntityLogic'):
				entities_without_EntityLogic.append(entity_type)
				continue
			if not entities_values_compressed_order.has(entities_types_shortcuts[entity_type]):
				entities_values_compressed_order[entities_types_shortcuts[entity_type]] = []
				for param in entity_instance.get_node('EntityLogic').params:
					entities_values_compressed_order[entities_types_shortcuts[entity_type]].append(param.value_path)
	assert(entities_without_EntityLogic.size() == 0, 'Some entities don\'t have EntityLogic as child: '+str(entities_without_EntityLogic))
	return resources
	
	
func load_entities_data():
	var file = FileAccess.open(entities_data_file, FileAccess.READ)
	if file != null:
		var entities_data = JSON.parse_string(file.get_as_text())
		last_used_entity_id = entities_data.last_used_entity_id
		entities_data.erase('last_used_entity_id')
		#load_entities(entities_data.duplicate(true))
	
	
func save_entities_data():
	pass
	

func start_tracking(entity_id : int, entity_node : Node, params : Array[AbstractSync], chunk=FROM_E_POS):
	entity_node.get_node('EntityLogic').queue_free()
	var already_used_tracker_types = []
	for tracker in trackers:
		already_used_tracker_types.append(tracker.get_script().get_global_name())
	var entity_type = entities_types_shortcuts[entity_node.get_scene_file_path().get_slice('/', 3)]
	if typeof(chunk) == typeof(FROM_E_POS):
		chunk = ChunksCalculator.position_to_chunk(entity_node.global_position)
	if not chunks_entities.has(chunk):
		chunks_entities[chunk] = PackedInt32Array()
	chunks_entities[chunk].append(entity_id)
	entities_chunks[entity_id] = chunk
	entities[entity_id] = EntityData.new(entity_type, entities_storage.get_path_to(entity_node.get_parent())) #[entity_type, {}, entities_storage.get_path_to(entity_node.get_parent())]
	for res_num in range(len(params)):
		if not params[res_num].get_script().get_global_name() in already_used_tracker_types:
			params[res_num].start()
			trackers.append(params[res_num])
		trackers[res_num].start_tracking(entity_id, entity_node, params[res_num].value_path, params[res_num].param_data)
				
				
func track_entities():
	for entity_id in entities:
		var new_chunk = ChunksCalculator.position_to_chunk(entities_storage.get_node(entities[entity_id].path_from_entities_storage_to_parent).get_node('e'+str(entity_id)).global_position)
		if new_chunk != entities_chunks[entity_id]:
			if not chunks_entities.has(new_chunk):
				chunks_entities[new_chunk] = PackedInt32Array()
			chunks_entities[entities_chunks[entity_id]].erase(entity_id)
			chunks_entities[new_chunk].append(entity_id)
			entities_chunks[entity_id] = new_chunk

		for tracker in trackers:
			tracker.track_entity(entity_id)
	
		
func send_entities_to_guests():
	pass
		
		
func get_parent_entity(node):
	var current_node = node
	while current_node != entities_storage:
		current_node = current_node.get_parent()
		if len(current_node.name) >= 2 and str(current_node.name[0]) == 'e' and get_parent().name.substr(1).is_valid_int():
			break
	return current_node
			
			
func summon_entity(entity_data : EntityData, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var entity_type = entity_data.type
	if entity_type in nonexistent_entities_types:
		return
	var entity_instance = entities_resources[entity_type].instantiate()
	entity_instance.name = 'e'+str(entity_id)
	var entity_parent_node = entities_storage.get_node(entity_data.path_from_entities_storage_to_parent)
	entity_parent_node.add_child(entity_instance)
	if typeof(chunk) == typeof(FROM_E_POS):
		if entity_data.values_dict.has('position'):
			chunk = ChunksCalculator.position_to_chunk(entity_data.values_dict['position'])
		else:
			chunk = FROM_E_POS
	entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').nonchunk = chunk==null
	start_tracking(entity_id, entity_parent_node.get_node('e'+str(entity_id)), entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').params, chunk)
	load_entity(chunk, entity_id, entity_data)
	
	
func load_entities(_entities : Dictionary[int, EntityData], _chunks_entities : Dictionary[Variant, PackedInt32Array]):
	for chunk in _chunks_entities:
		for entity_id in _entities:
			load_entity(chunk, entity_id, _entities[entity_id])
	
	
func load_entity(chunk, entity_id : int, entity_data : EntityData):
	if not entities_chunks.has(entity_id):
		summon_entity(entity_data, chunk, entity_id)
	for tracker:AbstractSync in trackers:
		tracker.load_entity(chunk, entity_id, entity_data)
		
