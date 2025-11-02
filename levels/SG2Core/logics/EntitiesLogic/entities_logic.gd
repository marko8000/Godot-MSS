@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@onready var SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')
@onready var entities_storage = SG2Core.giveo('entities_storage')
@onready var ChunksCalculator = SG2Core.giveo('ChunksCalculator')

@onready var general_entities_dir = DirectoriesPathsDistributor.give_path('general_entities_dir')
@onready var entities_data_file = DirectoriesPathsDistributor.give_path('entities_data_file')
@onready var entities_resources : Dictionary = load_entities_resources()
@onready var shortcuts : Dictionary


var entities_can_start_work : bool = false
signal _entities_start_work
## From this variable player gets entity for first time, guest values will be compressed to Array
## Host use this dictionary to load and save data
var entities : Dictionary # {chunk: {entity_id: [typeCONST, {value_path: value, ...}, path_from_entities_storage_to_parent],...,...},...}
var entities_chunks : Dictionary # {entity_id: chunk, ...}
## From this parameter player gets small changes from entities, unchanged params will be filled with null
var entities_changes : Dictionary # {entity_id: [value, value, ...], ...}
var entities_values_compressed_order : Dictionary # {entity_type: [value_path, value_path, ...], ...}
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
			summon_entity(['BallRigidBody3D', {'position': Vector3(R.ri(-10, 10), 10, R.ri(-10, 10))}])
	

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
	
	
func _peer_disconnected(peer_id):
	players_drawing_settings.erase(peer_id)
	

func get_new_entity_id():
	last_used_entity_id += 1
	return last_used_entity_id - 1
	
	
func load_entities_resources():
	var resources : Dictionary
	for entity_name in DirAccess.get_directories_at('res://entities'):
		if FilesManager.give_value_from_file_readlines('res://entities/'+entity_name+'/entity_info.txt', 'entity_scene_file') != null:
			resources[entity_name] = load("res://entities/"+entity_name+"/"+str(FilesManager.give_value_from_file_readlines('res://entities/'+entity_name+'/entity_info.txt', 'entity_scene_file')))
	return resources
	
	
func load_entities_data():
	var file = FileAccess.open(entities_data_file, FileAccess.READ)
	if file != null:
		var entities_data = JSON.parse_string(file.get_as_text())
		last_used_entity_id = entities_data.last_used_entity_id
		entities_data.erase('last_used_entity_id')
		load_entities(entities_data.duplicate(true))
	
	
func save_entities_data():
	pass
	

func start_tracking(entity_id, entity_node, params, chunk=FROM_E_POS):
	entity_node.get_node('EntityLogic').queue_free()
	var already_used_tracker_types = []
	for tracker in trackers:
		already_used_tracker_types.append(tracker.get_script().get_global_name())
	var entity_type = entity_node.get_scene_file_path().get_slice('/', 3)
	if typeof(chunk) == typeof(FROM_E_POS):
		chunk = ChunksCalculator.position_to_chunk(entity_node.global_position)
	entities_chunks[entity_id] = chunk
	if not entities.has(chunk):
		entities[chunk] = {}
	entities[chunk][entity_id] = [entity_type, {}, entities_storage.get_path_to(entity_node.get_parent())]
	for res_num in range(len(params)):
		if not params[res_num].get_script().get_global_name() in already_used_tracker_types:
			params[res_num].start()
			trackers.append(params[res_num])
		trackers[res_num].start_tracking(entity_id, entity_node, params[res_num].value_path, params[res_num].param_data)
				
				
func track_entities():
	for _n in entities:
		for entity_id in entities[_n]:
			var new_chunk = ChunksCalculator.position_to_chunk(entities_storage.get_node(entities[entities_chunks[entity_id]][entity_id][2]).get_node('e'+str(entity_id)).global_position)
			if new_chunk != _n:
				if not entities.has(new_chunk):
					entities[new_chunk] = {}
				entities[new_chunk][entity_id] = Dispenser.dupl(entities[_n][entity_id])
				entities[_n].erase(entity_id)
				entities_chunks[entity_id] = new_chunk
		if entities[_n].size() == 0:
			entities.erase(_n)

	for tracker in trackers:
		tracker.track_entities()
	
		
func send_entities_to_guests():
	pass
		
		
func get_parent_entity(node):
	var current_node = node
	while current_node != entities_storage:
		current_node = current_node.get_parent()
		if len(current_node.name) >= 2 and str(current_node.name[0]) == 'e' and get_parent().name.substr(1).is_valid_int():
			break
	return current_node
			
			
func summon_entity(entity_data : Array = [], chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var entity_type = entity_data[0]
	var entity_instance = entities_resources[entity_type].instantiate()
	if not entities_values_compressed_order.has(entity_type):
		entities_values_compressed_order[entity_type] = []
		for param in entity_instance.get_node('EntityLogic').params:
			entities_values_compressed_order[entity_type].append(param.value_path)
	entity_instance.name = 'e'+str(entity_id)
	var entity_parent_node = entities_storage.get_node('.' if not entity_data.has(2) else entity_data[2])
	entity_parent_node.add_child(entity_instance)
	if typeof(chunk) == typeof(FROM_E_POS):
		chunk = null
		if entity_data[1].has('position'):
			chunk = ChunksCalculator.position_to_chunk(entity_data[1]['position'])
		else:
			chunk = FROM_E_POS
	entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').nonchunk = chunk==null
	start_tracking(entity_id, entity_parent_node.get_node('e'+str(entity_id)), entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityLogic').params, chunk)
	load_entity(chunk, entity_id, entity_data)
	
	
func load_entities(entities_data):
	for chunk in entities_data:
		for entity_id in chunk:
			load_entity(chunk, entity_id, entities_data[chunk][entity_id])
	
	
func load_entity(chunk, entity_id : int, entity_data : Array):
	if not entities_chunks.has(entity_id):
		print('summon')
		summon_entity(entity_data, chunk, entity_id)
	for tracker in trackers:
		tracker.load_entity(chunk, entity_id, entity_data)
		
