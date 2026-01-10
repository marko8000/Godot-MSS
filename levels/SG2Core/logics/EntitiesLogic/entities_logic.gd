@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## EntitiesLogic saves/loads entities state, transfers entities data between host and guests
class_name EntitiesLogic


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _MultiplayerLogic := _SG2Core._MultiplayerLogic
@onready var _InterpolationLogic := _SG2Core._InterpolationLogic
@onready var _DirectoriesPathsDistributor := _SG2Core._DirectoriesPathsDistributor
@onready var _entities_storage := _SG2Core._entities_storage
@onready var _ChunksCalculator := _SG2Core._ChunksCalculator

@onready var entities_dir = _DirectoriesPathsDistributor.path('entities_dir')
@onready var entities_data_dir = _DirectoriesPathsDistributor.path('entities_data_dir')
@onready var entities_global_file = _DirectoriesPathsDistributor.path('entities_global_file')

@onready var entities_global = load_entities_global()
@onready var entities_types_shortcuts : Dictionary[String, int] = get_entities_types_shortcuts()
@onready var shortcuts_entities_types : Dictionary[int, String] = get_shortcuts_entities_types()
@onready var last_used_entity_id : int = 0 if !entities_global.has('last_used_entity_id') else entities_global.last_used_entity_id
@onready var entities_resources : Dictionary[int, Resource] = load_entities_resources()

var entities_can_start_work : bool = false
signal _entities_start_work
var trackers : Array[AbstractSync]
var updates_per_frame : int = 30
var entities_spawn_data : Dictionary[int, Array] # Array = [entity_type : int, values_array : Array, path_from_entities_storage_to_parent : String = '.']
var entities_update_data : Dictionary[int, Array] # Array = [values_array : Array, path_from_entities_storage_to_parent : String = '.']
var entities_file_data : Dictionary[int, Array] # Array = [entity_type : int, values_dict : Dictionary, path_from_entities_storage_to_parent : String = '.']
var entities_chunks : Dictionary[int, Variant] # = {entity_id: chunk}
var chunks_entities : Dictionary[Variant, PackedInt32Array] # = {chunk: [entity_id, ...], ...}
var update_check : Dictionary[int, bool] # {entity_id: bool} if nothing is changed: false
var chunks_users_num : Dictionary[Variant, int] # if number of users is equal to or less than zero, chunk will be unloaded
var entities_property_path_property_array_num : Dictionary[int, Dictionary] # {entity_type: {value_path: values_array_num}}
var entities_property_array_num_property_path : Dictionary[int, Array] # {entity_type: [value_path, ...]}
var entities_empty_properties_array : Dictionary[int, Array]
var current_update_frame : int = 1
var current_update_range_size : int
var current_frames_per_update : int
var deleted_entities : PackedInt32Array
enum {
	FROM_E_POS # that means that chunk will be found from entity_position
}

@export_category('Drawing Settings')
@export var drawing_distance : int = 1 # host's parameter is max for guest. 0 is 1 chunk
var players : Dictionary[int, EntitiesPlayerData]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


func start():
	emit_signal('_entities_start_work')
	entities_can_start_work = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	Debug.dstate('Entities / chunks', str(entities_chunks.size())+'e / '+str(chunks_entities.size())+'ch')
	if _ConnectionLogic.peer_role == 'host':
		await get_tree().process_frame
		track_entities()
		host_manage_chunks_users()
		send_entities_to_guests()
		clear_deleted_entities()
		if Input.is_action_just_pressed('ui_accept'):
			var chunks = _ChunksCalculator.get_chunks_around(Vector3i(0, 0, 0), 2)
			for chunk in chunks:
				file_entity_summon(EntityFileData('BallRigidBody3D', {'position': Vector3(chunk.x, 10, chunk.y)}))
	elif _ConnectionLogic.peer_role == 'guest':
		track_entities()
		
		
func _connection_peer_changed(new_peer):
	start()
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if _ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		
		
func _peer_connected(peer_id):
	spawn_player('peer', peer_id)
	
	
## player_type = "peer" or "reg"
## use "peer" if player entity will be deleted after player disconnect
## use "reg" if player will play on same entity after reconnect
func spawn_player(player_type : String, id):
	if player_type == 'peer':
		players[id] = EntitiesPlayerData.new(drawing_distance)
		file_entity_summon(EntityFileData('CharacterBody3D_FPS', {'position': Vector3(0, 50, 0), '$Observer.player_type': player_type, '$Observer.id': id}))
		rpc_id(id, 'guest_spawn_entities', Dispenser.dupl(entities_spawn_data))
	elif player_type == 'reg':
		pass
	
	
func _peer_disconnected(peer_id):
	for observer : Observer in players[peer_id].observers:
		if observer.current_chunk in chunks_users_num:
			chunks_users_num[observer.current_chunk] -= 1
	players.erase(peer_id)
	

func EntityFileData(_type, _values_dict : Dictionary, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_type if _type is int else entities_types_shortcuts[_type], _values_dict, _path_from_entities_storage_to_parent]
	
	
func EntitySpawnData(_type : int, _values_array : Array, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_type, _values_array, _path_from_entities_storage_to_parent]
	
	
func EntityUpdateData(_values_array, _path_from_entities_storage_to_parent : String = '.') -> Array:
	return [_values_array, _path_from_entities_storage_to_parent]
	
	
class EntitiesPlayerData:
	var drawing_distance : int
	var observers : Array[Observer]
	func _init(_drawing_distance :  int) -> void:
		drawing_distance = _drawing_distance
	func _to_string() -> String:
		return '{drawing_distance: {dd}, observers: {od}}'.format({'dd': drawing_distance, 'od': observers})
	
	
func get_new_entity_id():
	last_used_entity_id += 1
	return last_used_entity_id - 1
	

func load_entities_global():
	var file = FileAccess.open(entities_global_file, FileAccess.READ)
	if file != null:
		var _entities_data = JSON.parse_string(file.get_as_text())
		file.close()
		return _entities_data
	else:
		push_warning('entities_global_file not found')
		return {}
		

func get_entities_types_shortcuts():
	var _shortcuts : Dictionary[String, int]
	if entities_global.has('entities_types_shortcuts'):
		_shortcuts = entities_global.entities_types_shortcuts
	return _shortcuts
	
	
func get_shortcuts_entities_types():
	var _shortcuts : Dictionary[int, String]
	if entities_global.has('entities_types_shortcuts'):
		for entity_type in entities_global.entities_types_shortcuts.keys():
			var shortcut = entities_global.entities_types_shortcuts[entity_type]
			shortcuts_entities_types[shortcut] = entity_type
	return _shortcuts
		
		
func load_entities_resources():
	var resources : Dictionary[int, Resource]
	var entities_file_excepted : PackedStringArray
	var entities_without_EntityPropertiesSeed : PackedStringArray
	for entity_type in DirAccess.get_directories_at('res://entities/'):
		if not entities_types_shortcuts.has(entity_type):
			shortcuts_entities_types[len(shortcuts_entities_types)] = entity_type
			entities_types_shortcuts[entity_type] = len(shortcuts_entities_types)-1
		if FileAccess.file_exists('res://entities/'+entity_type+'/'+entity_type+'.tscn'):
			resources[entities_types_shortcuts[entity_type]] = load("res://entities/"+entity_type+"/"+entity_type+'.tscn')
			var entity_instance = resources[entities_types_shortcuts[entity_type]].duplicate(true).instantiate()
			if not entity_instance.has_node('EntityPropertiesSeed'):
				entities_without_EntityPropertiesSeed.append(entity_type)
				continue
			entity_instance.get_node('EntityPropertiesSeed').presets()
			if not entities_property_path_property_array_num.has(entities_types_shortcuts[entity_type]):
				entities_property_path_property_array_num[entities_types_shortcuts[entity_type]] = {}
				entities_property_array_num_property_path[entities_types_shortcuts[entity_type]] = []
				entities_empty_properties_array[entities_types_shortcuts[entity_type]] = []
				for property_num in range(len(entity_instance.get_node('EntityPropertiesSeed').tracked_properties)):
					entities_property_path_property_array_num[entities_types_shortcuts[entity_type]][entity_instance.get_node('EntityPropertiesSeed').tracked_properties[property_num].property_path] = property_num
					entities_property_array_num_property_path[entities_types_shortcuts[entity_type]].append(entity_instance.get_node('EntityPropertiesSeed').tracked_properties[property_num].property_path)
					entities_empty_properties_array[entities_types_shortcuts[entity_type]].append(null)
		else:
			entities_file_excepted.append(entity_type)
			
	# Pushing and asserting errors
	assert(entities_without_EntityPropertiesSeed.size() == 0, 'Some entities don\'t have EntityPropertiesSeed as child: '+str(entities_without_EntityPropertiesSeed))
	for entity_type in entities_file_excepted:
		push_error('File excepted to load entity "'+entity_type+'": '+'res://entities/'+entity_type+'/'+entity_type+'.tscn')
	
	return resources
	
	
func save_entities_data():
	var _eglobal_file = FileAccess.open(entities_global_file, FileAccess.WRITE)
	_eglobal_file.store_var(entities_global)
	_eglobal_file.close()
	for chunk in chunks_entities:
		save_chunk(chunk)
		
		
func get_parent_entity(node):
	var current_node = node
	while current_node != _entities_storage:
		current_node = current_node.get_parent()
		if len(current_node.name) >= 2 and str(current_node.name[0]) == 'e' and get_parent().name.substr(1).is_valid_int():
			break
	return current_node
				
		
func load_entities(_entities_file_data : Dictionary[int, Array], _chunks_entities : Dictionary[Variant, PackedInt32Array]):
	for chunk in _chunks_entities:
		for entity_id in _entities_file_data:
			file_entity_summon(_entities_file_data[entity_id], entity_id, chunk)
			

func file_entity_summon(file_data : Array, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var array : Array
	if not entities_property_array_num_property_path.has(file_data[0]):
		return
	for i in range(len(entities_property_array_num_property_path[file_data[0]])):
		if file_data[1].has(entities_property_array_num_property_path[file_data[0]][i]):
			array.append(file_data[1][entities_property_array_num_property_path[file_data[0]][i]])
		else:
			array.append(null)
	spawn_entity(EntitySpawnData(file_data[0], array, file_data[2]), chunk, entity_id)
	
	
func start_tracking(entity_id : int, entity_node : Node, tracked_properties : Array[AbstractSync], chunk=FROM_E_POS):
	entity_node.get_node('EntityPropertiesSeed').queue_free()
	var entity_type = entities_types_shortcuts[entity_node.get_scene_file_path().get_slice('/', 3)]
	if typeof(chunk) == typeof(FROM_E_POS):
		chunk = _ChunksCalculator.position_to_chunk(entity_node.global_position)
	if not chunks_entities.has(chunk):
		chunks_entities[chunk] = PackedInt32Array()
	if not chunks_users_num.has(chunk):
		load_chunk(chunk)
	chunks_entities[chunk].append(entity_id)
	entities_chunks[entity_id] = chunk
	entities_spawn_data[entity_id] = EntitySpawnData(entity_type, entities_empty_properties_array[entity_type], _entities_storage.get_path_to(entity_node.get_parent()))
	entities_update_data[entity_id] = EntityUpdateData(entities_empty_properties_array[entity_type], _entities_storage.get_path_to(entity_node.get_parent()))
	var already_used_tracker_types = []
	for res_num in range(len(tracked_properties)):
		for tracker in trackers:
			already_used_tracker_types.append(tracker.get_script().get_global_name())
		if not already_used_tracker_types.has(tracked_properties[res_num].get_script().get_global_name()):
			tracked_properties[res_num].start()
			trackers.append(tracked_properties[res_num])
		trackers[already_used_tracker_types.find(tracked_properties[res_num].get_script().get_global_name())].start_tracking(entity_id, entity_node, tracked_properties[res_num].property_path, tracked_properties[res_num].property_config)
	

func track_entities():
	var entities_range : PackedInt32Array
	if current_update_frame == 1:
		current_frames_per_update = _InterpolationLogic.server_FPS / updates_per_frame
		current_update_range_size = len(entities_update_data) / current_frames_per_update
	if not current_update_frame == current_frames_per_update:
		entities_range = entities_update_data.keys().slice(current_update_range_size*(current_update_frame-1), current_update_range_size*current_update_frame)
		current_update_frame += 1
	else:
		entities_range = entities_update_data.keys().slice(current_update_range_size*(current_update_frame-1))
		current_update_frame = 1
	for entity_id in entities_range:
		if not _entities_storage.has_node(entities_spawn_data[entity_id][2] + '/e'+str(entity_id)):
			deleted_entities.append(entity_id)
			entities_spawn_data.erase(entity_id)
			entities_update_data.erase(entity_id)
			chunks_entities[entities_chunks[entity_id]].erase(entity_id)
			entities_chunks.erase(entity_id)
			for tracker in trackers:
				tracker.stop_tracking(entity_id)
			continue
		if entities_chunks[entity_id] != null:
			var new_chunk = _ChunksCalculator.position_to_chunk(_entities_storage.get_node(entities_spawn_data[entity_id][2]).get_node('e'+str(entity_id)).global_position)
			if new_chunk != entities_chunks[entity_id]:
				if not chunks_entities.has(new_chunk):
					chunks_entities[new_chunk] = PackedInt32Array()
				if not chunks_users_num.has(new_chunk):
					load_chunk(new_chunk)
				chunks_entities[entities_chunks[entity_id]].erase(entity_id)
				chunks_entities[new_chunk].append(entity_id)
				entities_chunks[entity_id] = new_chunk
		var old_data = entities_update_data[entity_id].duplicate(true)
		entities_spawn_data[entity_id][1] = entities_empty_properties_array[entities_spawn_data[entity_id][0]].duplicate(true)
		entities_update_data[entity_id][0] = entities_empty_properties_array[entities_spawn_data[entity_id][0]].duplicate(true)
		for tracker in trackers:
			tracker.track_entity(entity_id)
		if old_data != entities_update_data[entity_id]:
			update_check[entity_id] = true
	for empty_chunk in chunks_entities.keys().filter(func(chunk): return chunks_entities[chunk] == PackedInt32Array()):
		chunks_entities.erase(empty_chunk)
	
	
func spawn_entity(spawn_data : Array, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var entity_type = spawn_data[0]
	if not entities_resources.has(entity_type):
		return
	var entity_instance = entities_resources[entity_type].instantiate()
	entity_instance.name = 'e'+str(entity_id)
	var entity_parent_node = _entities_storage.get_node(spawn_data[2])
	entity_parent_node.add_child(entity_instance)
	if typeof(chunk) == typeof(FROM_E_POS):
		if entities_property_path_property_array_num[entity_type].has('position'):
			chunk = _ChunksCalculator.position_to_chunk(spawn_data[1][entities_property_path_property_array_num[entity_type]['position']])
		else:
			chunk = FROM_E_POS
	entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityPropertiesSeed').nonchunk = chunk==null
	entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityPropertiesSeed').presets()
	start_tracking(entity_id, entity_parent_node.get_node('e'+str(entity_id)), entity_parent_node.get_node('e'+str(entity_id)).get_node('EntityPropertiesSeed').tracked_properties, chunk)
	update_entity(chunk, entity_id, EntityUpdateData(spawn_data[1], spawn_data[2]))


func update_entity(chunk, entity_id : int, update_data : Array):
	# TODO: path_from_parent changes
	for tracker:AbstractSync in trackers:
		tracker.update_entity(chunk, entity_id, update_data)		


func host_manage_chunks_users():
	if current_update_frame == 1:
		for chunk in chunks_users_num:
			if chunks_users_num[chunk] <= 0:
				save_chunk(chunk)
				unload_chunk(chunk)
		
		
func save_chunk(chunk):
	pass
	
	
func load_chunk(chunk):
	
	if not chunks_users_num.has(chunk):
		chunks_users_num[chunk] = 0
	
	
func unload_chunk(chunk):
	chunks_users_num.erase(chunk)
	if not chunks_entities.has(chunk):
		return
	for entity_id in chunks_entities[chunk]:
		var entity = _entities_storage.get_node(entities_spawn_data[entity_id][2]+'/e'+str(entity_id))
		if entity:
			entity.queue_free()
	
	
func send_entities_to_guests():
	if current_update_frame == 1:
		for peer_id in players:
			var player_data := players[peer_id]
			print('p', player_data)
			player_data.observers = player_data.observers.filter(func(_o): return _o != null)
			var _entities_to_delete : PackedInt32Array
			var _entities_to_update : Dictionary[int, Array]
			var _entities_to_spawn : Dictionary[int, Array]
			for observer : Observer in player_data.observers:
				for entity_id in observer.loaded_entities:
					if deleted_entities.has(entity_id):
						observer.loaded_entities.erase(entity_id)
						_entities_to_delete.append(entity_id)
					elif update_check[entity_id]:
						update_check[entity_id] = false
						_entities_to_update[entity_id] = entities_update_data[entity_id]
				for chunk in observer.loaded_chunks:
					if not chunks_entities.has(chunk): continue
					for entity_id in chunks_entities[chunk]:
						if not observer.loaded_entities.has(entity_id):
							observer.loaded_entities.append(entity_id)
							_entities_to_spawn[entity_id] = entities_spawn_data[entity_id]
			
			rpc_id(peer_id, 'guest_delete_entities', _entities_to_delete)
			rpc_id(peer_id, 'guest_update_entities', _entities_to_update)
			rpc_id(peer_id, 'guest_spawn_entities', _entities_to_spawn)


func clear_deleted_entities():
	if current_update_frame == 1:
		deleted_entities.clear()
		

@rpc("authority", 'call_local')
func guest_delete_entities(entities : PackedInt32Array):
	if _ConnectionLogic.peer_role != 'guest': return
	for entity_id in entities:
		_entities_storage.get_node(entities_spawn_data[entity_id][2]+'/e'+str(entity_id))
	
	
@rpc("authority", 'call_local')
func guest_spawn_entities(entities : Dictionary[int, Array]):
	if _ConnectionLogic.peer_role != 'guest': return
	for entity_id in entities:
		spawn_entity(entities[entity_id])
		

@rpc("authority", 'call_local')
func guest_update_entities(entities : Dictionary[int, Array]):
	if _ConnectionLogic.peer_role != 'guest': return
	for entity_id in entities:
		update_entity(FROM_E_POS, entity_id, entities[entity_id])
