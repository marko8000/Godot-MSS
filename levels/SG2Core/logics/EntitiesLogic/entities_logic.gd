@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@onready var SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var MultiplayerLogic = SG2Core.giveo('MultiplayerLogic')
@onready var InterpolationLogic = SG2Core.giveo('InterpolationLogic')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')
@onready var entities_storage = SG2Core.giveo('entities_storage')
@onready var ChunksCalculator = SG2Core.giveo('ChunksCalculator')

@onready var general_entities_dir = DirectoriesPathsDistributor.give_path('general_entities_dir')
@onready var entities_data_file = DirectoriesPathsDistributor.give_path('entities_data_file')
@onready var shortcuts_entities_types : Dictionary[int, String] = load_shortcuts_entities_types()
@onready var entities_types_shortcuts : Dictionary[String, int] = load_entities_types_shortcuts()
@onready var entities_resources : Dictionary[int, Resource] = load_entities_resources()

var entities_can_start_work : bool = false
signal _entities_start_work
var updates_per_frame : int = 30
var entities_spawn_data : Dictionary[int, Array] # Array = [entity_type : int, values_array : Array, path_from_entities_storage_to_parent : String = '.']
var entities_update_data : Dictionary[int, Array] # Array = [values_array : Array, path_from_entities_storage_to_parent : String = '.']
var entities_file_data : Dictionary[int, Array] # Array = [entity_type : int, values_dict : Dictionary, path_from_entities_storage_to_parent : String = '.']
var entities_chunks : Dictionary[int, Variant]
var chunks_entities : Dictionary[Variant, PackedInt32Array]
var entities_value_path_value_array_num : Dictionary[int, Dictionary] # {entity_type: {value_path: values_array_num}}
var entities_value_array_num_value_path : Dictionary[int, Array] # {entity_type: [value_path, ...]}
var entities_empty_values_array : Dictionary[int, Array]
var trackers : Array[AbstractSync]
var last_used_entity_id : int = 0
var current_update_frame : int = 1
var current_update_range_size : int
var current_frames_per_update : int
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
		for i in range(100):
			file_entity_summon(EntityFileData('BallRigidBody3D', {'position': Vector3(R.ri(-10, 10), 20, R.ri(-10, 10))}))
	

var some_sum = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ConnectionLogic.peer_role == 'host':
		await get_tree().process_frame
		track_entities()
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
	rpc_id(peer_id, 'guest_spawn_entities', Dispenser.dupl(entities_spawn_data))
	
	
func _peer_disconnected(peer_id):
	players_drawing_settings.erase(peer_id)
	

func EntityFileData(_type, _values_dict : Dictionary, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_type if _type is int else entities_types_shortcuts[_type], _values_dict, _path_from_entities_storage_to_parent]
	
	
func EntitySpawnData(_type : int, _values_array : Array, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_type, _values_array, _path_from_entities_storage_to_parent]
	
	
func EntityUpdateData(_values_array, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_values_array, _path_from_entities_storage_to_parent]
	
	
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
			if not entities_value_path_value_array_num.has(entities_types_shortcuts[entity_type]):
				entities_value_path_value_array_num[entities_types_shortcuts[entity_type]] = {}
				entities_value_array_num_value_path[entities_types_shortcuts[entity_type]] = []
				entities_empty_values_array[entities_types_shortcuts[entity_type]] = []
				for param_num in range(len(entity_instance.get_node('EntityLogic').params)):
					entities_value_path_value_array_num[entities_types_shortcuts[entity_type]][entity_instance.get_node('EntityLogic').params[param_num].value_path] = param_num
					entities_value_array_num_value_path[entities_types_shortcuts[entity_type]].append(entity_instance.get_node('EntityLogic').params[param_num].value_path)
					entities_empty_values_array[entities_types_shortcuts[entity_type]].append(null)
	assert(entities_without_EntityLogic.size() == 0, 'Some entities don\'t have EntityLogic as child: '+str(entities_without_EntityLogic))
	return resources
	
	
func save_entities_data():
	pass
		
		
func get_parent_entity(node):
	var current_node = node
	while current_node != entities_storage:
		current_node = current_node.get_parent()
		if len(current_node.name) >= 2 and str(current_node.name[0]) == 'e' and get_parent().name.substr(1).is_valid_int():
			break
	return current_node
		

func load_entities_data():
	var file = FileAccess.open(entities_data_file, FileAccess.READ)
	if file != null:
		var entities_data = JSON.parse_string(file.get_as_text())
		last_used_entity_id = entities_data.last_used_entity_id
		entities_data.erase('last_used_entity_id')
		#load_entities(entities_data.duplicate(true))
		
		
func load_entities(_entities_file_data : Dictionary[int, Array], _chunks_entities : Dictionary[Variant, PackedInt32Array]):
	for chunk in _chunks_entities:
		for entity_id in _entities_file_data:
			file_entity_summon(_entities_file_data[entity_id], entity_id, chunk)
			

func file_entity_summon(file_data : Array, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var array : Array
	for i in range(len(entities_value_array_num_value_path[file_data[0]])):
		if file_data[1].has(entities_value_array_num_value_path[file_data[0]][i]):
			array.append(file_data[1][entities_value_array_num_value_path[file_data[0]][i]])
	spawn_entity(EntitySpawnData(file_data[0], array, file_data[2]), chunk, entity_id)
	
	
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
	entities_spawn_data[entity_id] = EntitySpawnData(entity_type, entities_empty_values_array[entity_type], entities_storage.get_path_to(entity_node.get_parent()))
	entities_update_data[entity_id] = EntityUpdateData(entities_empty_values_array[entity_type], entities_storage.get_path_to(entity_node.get_parent()))
	for res_num in range(len(params)):
		if not params[res_num].get_script().get_global_name() in already_used_tracker_types:
			params[res_num].start()
			trackers.append(params[res_num])
		trackers[res_num].start_tracking(entity_id, entity_node, params[res_num].value_path, params[res_num].param_data)
	

func track_entities():
	var entities_range : PackedInt32Array
	if current_update_frame == 1:
		current_frames_per_update = InterpolationLogic.server_FPS / updates_per_frame
		current_update_range_size = len(entities_update_data) / current_frames_per_update
	if not current_update_frame == current_frames_per_update:
		entities_range = entities_update_data.keys().slice(current_update_range_size*(current_update_frame-1), current_update_range_size*current_update_frame)
		current_update_frame += 1
	else:
		some_sum += 1
		entities_range = entities_update_data.keys().slice(current_update_range_size*(current_update_frame-1))
		current_update_frame = 1
	for entity_id in entities_range:
		var new_chunk = ChunksCalculator.position_to_chunk(entities_storage.get_node(entities_spawn_data[entity_id][2]).get_node('e'+str(entity_id)).global_position)
		if new_chunk != entities_chunks[entity_id]:
			if not chunks_entities.has(new_chunk):
				chunks_entities[new_chunk] = PackedInt32Array()
			chunks_entities[entities_chunks[entity_id]].erase(entity_id)
			chunks_entities[new_chunk].append(entity_id)
			entities_chunks[entity_id] = new_chunk
		entities_spawn_data[entity_id][1] = entities_empty_values_array[entities_spawn_data[entity_id][0]].duplicate(true)
		entities_update_data[entity_id][0] = entities_empty_values_array[entities_spawn_data[entity_id][0]].duplicate(true)
		for tracker in trackers:
			tracker.track_entity(entity_id)
			
	
func spawn_entity(spawn_data : Array, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var entity_type = spawn_data[0]
	if not entity_type in entities_resources:
		return
	var entity_instance = entities_resources[entity_type].instantiate()
	entity_instance.name = 'e'+str(entity_id)
	var entity_parent_node = entities_storage.get_node(spawn_data[2])
	entity_parent_node.add_child(entity_instance)
	if typeof(chunk) == typeof(FROM_E_POS):
		if entities_value_path_value_array_num[entity_type].has('position'):
			chunk = ChunksCalculator.position_to_chunk(spawn_data[1][entities_value_path_value_array_num[entity_type]['position']])
		else:
			chunk = FROM_E_POS
	entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').nonchunk = chunk==null
	if ConnectionLogic.peer_role == 'guest':
		entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').apply_guest_presets()
	start_tracking(entity_id, entity_parent_node.get_node('e'+str(entity_id)), entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').params, chunk)
	update_entity(chunk, entity_id, EntityUpdateData(spawn_data[1], spawn_data[2]))


func update_entity(chunk, entity_id : int, update_data : Array):
	# TODO: path_from_parent changes
	for tracker:AbstractSync in trackers:
		tracker.update_entity(chunk, entity_id, update_data)		


func send_entities_to_guests():
	for peer_id in MultiplayerLogic.players_info:
		rpc_id(peer_id, 'guest_update_entities', Dispenser.dupl(entities_update_data))
		
		
@rpc("authority")
func guest_spawn_entities(entities):
	for entity_id in entities:
		spawn_entity(entities[entity_id])
		
	
@rpc("authority")
func guest_update_entities(entities):
	for entity_id in entities:
		update_entity(FROM_E_POS, entity_id, entities[entity_id])
