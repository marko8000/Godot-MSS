@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
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
## From this parameter player gets entity for first time, guest's params will be compressed to Array. This variable must be saved to entities_data_file.
var entities : Dictionary # {chunk: {entity_id: [{params}, {entity_id: ..., entity_id: ...}], entity_id: [{params}, {}]}}
## From this parameter player gets small changes from entities, unchanged params will be filled with null
var entities_changes : Dictionary # {chunk: entity_id: [[null, 0, null, 0], {...}], ...}
var deleted_entities : Array # [entity_id, entity_id]
var last_used_entity_id : int = 0

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
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ConnectionLogic.peer_role == 'host':
		pass
		
		
func _connection_peer_changed(new_peer):
	start()
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	#elif ConnectionLogic.peer_role == 'guest':
		#multiplayer.connected_to_server.connect(_connected_to_server)
		
		
func _peer_connected(peer_id):
	players_drawing_settings[peer_id] = [drawing_distance, chunks_per_second]
	
	
func _peer_disconnected(peer_id):
	players_drawing_settings.erase(peer_id)
	

func get_new_entity_id():
	return last_used_entity_id
	last_used_entity_id += 1
	
	
func load_entities_resources():
	var resources : Dictionary
	for entity_name in DirAccess.get_directories_at('res://entities'):
		if FilesManager.give_value_from_file_readlines('res://entities/'+entity_name, 'entity_scene_file') != null:
			resources[entity_name] = str(FilesManager.give_value_from_file_readlines('res://entities/'+entity_name, 'entity_scene_file'))
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
	
	
func load_entities(entities_data: Dictionary):
	for chunk in entities_data:
		for entity_id in chunk:
			load_entity(chunk, entity_id, entities_data[chunk][entity_id])
			
			
func load_entity(chunk, entity_id : int, entity_data):
	if not entities_storage.has_node('e'+str(entity_id)):
		var entity_name = entity_data[0]['name'] if entity_data is Dictionary else entity_data[0][0]
		var entity_instance = entities_resources[entity_name].instantiate()
		entity_instance.name = 'e'+str(entity_id)
		entities_storage.add_child(entity_instance)
		entities_storage.get_node('e'+str(entity_id)).get_node('EntityLogic').load_entity_data(entity_data.duplicate(true))
	else:
		entities_storage.get_node('e'+str(entity_id)).get_node('EntityLogic').load_entity_data(entity_data.duplicate(true))
		
	
func summon(chunk, entity_data : Array):
	load_entity(chunk, get_new_entity_id(), entity_data)
