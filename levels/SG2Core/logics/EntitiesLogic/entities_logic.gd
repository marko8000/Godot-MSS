extends SG2Logic
## EntitiesLogic saves/loads entities state, transfers entities data between host and guests.
## chunk = null is used for nonchunk entities
class_name EntitiesLogic


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _MultiplayerLogic := _SG2Core._MultiplayerLogic
@onready var _InterpolationLogic := _SG2Core._InterpolationLogic
@onready var _PathRegistry := _SG2Core._PathRegistry
@onready var _entities_storage := _SG2Core._entities_storage
@onready var _ChunksCalculator := _SG2Core._ChunksCalculator

@onready var entities_dir = _PathRegistry.path('entities_dir')
@onready var entities_data_dir = _PathRegistry.path('entities_data_dir')
@onready var entities_global_file = _PathRegistry.path('entities_global_file')

@onready var entities_global = load_entities_global()
@onready var entities_types_shortcuts : Dictionary[String, int] = get_entities_types_shortcuts()
@onready var shortcuts_entities_types : Dictionary[int, String] = get_shortcuts_entities_types()
@onready var last_used_entity_id : int = 0 if !entities_global.has('last_used_entity_id') else entities_global.last_used_entity_id
@onready var entities_resources : Dictionary[int, Resource] = load_entities_resources()

var entities_can_start_work : bool = false
signal _entities_start_work
var trackers : Array[AbstractTracker]
var updates_per_second : int = 30
var entities : Dictionary[int, EntityData]
var entities_list : PackedInt32Array ## = [entity_id, ...]
var chunks_entities : Dictionary[Variant, PackedInt32Array] ## = {chunk: [entity_id, ...], ...}
var nodes_entities : Dictionary[Node, int]
var chunks_users_num : Dictionary[Variant, int] ## if number of users is equal to or less than zero, chunk will be unloaded
var entities_property_path_property_array_num : Dictionary[int, Dictionary] ## {entity_type: {property_path: property_array_num}}
var entities_property_array_num_property_path : Dictionary[int, Array] ## {entity_type: [property_path, ...]}
var entities_empty_properties_array : Dictionary[int, Array] ## {entity_type: [null, null, ...]}
var current_update_frame : int = 1
var current_update_range_size : int
var current_frames_per_update : int
var deleted_entities : PackedInt32Array
var reparenting_buffer : Dictionary[int, Array] ## = {entity_id: [entity_node, new_parent, path_to_parent], ...}
var FROM_E_POS = 'f' ## if chunk == FROM_E_POS: the chunk will be calculated from entity global_position
var NONCHUNK = null
class EntityData:
	var type : int # entity_type_shortcut
	var spawn_data : Array = [-1, [], '.']# [entity_type : int, values_array : Array, path_from_entities_storage_to_parent : String = '.']
	var update_data : Array = [[], '.'] # [values_array : Array, path_from_entities_storage_to_parent : String = '.']
	var chunk
	var hierarchy_value : int
	var update_check : bool # if nothing is changed: false
	var parent_link : int # root_parent_entity_id
	var node : Node
	
	

@export_category('Drawing Settings')
@export var drawing_distance : int = 1 # host's parameter is max for guest. drawing distance 1 is minimum
var players : Dictionary[int, EntitiesPlayerData]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


func start():
	_entities_start_work.emit()
	entities_can_start_work = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	Debug.dstate('Entities / chunks', str(entities_list.size())+'e / '+str(chunks_entities.size())+'ch', self)
	if _ConnectionLogic.peer_role in ['host', 'guest']:
		process_reparenting_buffer()
		await get_tree().process_frame
		track_entities()
		if _ConnectionLogic.peer_role == 'host':
			if current_update_frame == 1:
				host_manage_chunks_users()
				send_entities_to_guests()
				clear_deleted_entities()
			if Input.is_action_just_pressed('ui_accept'):
				var chunks = _ChunksCalculator.get_chunks_around(Vector3i(0, 0, 0), 2)
				for chunk in chunks:
					file_entity_summon(EntityFileData('BallRigidBody3D', {'position': Vector3(chunk.x, 30, chunk.z)}))
		elif _ConnectionLogic.peer_role == 'guest':
			if current_update_frame == 1:
				pass
	manage_debug_keybindings()
		
		
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
	var entities_without_EntitySeed : PackedStringArray
	for entity_type in DirAccess.get_directories_at('res://entities/'):
		if not entities_types_shortcuts.has(entity_type):
			shortcuts_entities_types[len(shortcuts_entities_types)] = entity_type
			entities_types_shortcuts[entity_type] = len(shortcuts_entities_types)-1
		if FileAccess.file_exists('res://entities/'+entity_type+'/'+entity_type+'.tscn'):
			resources[entities_types_shortcuts[entity_type]] = load("res://entities/"+entity_type+"/"+entity_type+'.tscn')
			var entity_instance = resources[entities_types_shortcuts[entity_type]].duplicate(true).instantiate()
			if not entity_instance.has_node('EntitySeed'):
				entities_without_EntitySeed.append(entity_type)
				continue
			var ESeed : EntitySeed = entity_instance.get_node('EntitySeed')
			ESeed.prepare_properties()
			if not entities_property_path_property_array_num.has(entities_types_shortcuts[entity_type]):
				entities_property_path_property_array_num[entities_types_shortcuts[entity_type]] = {}
				entities_property_array_num_property_path[entities_types_shortcuts[entity_type]] = []
				entities_empty_properties_array[entities_types_shortcuts[entity_type]] = []
				for property_num in range(len(ESeed.tracked_properties)):
					entities_property_path_property_array_num[entities_types_shortcuts[entity_type]][ESeed.tracked_properties[property_num].property_path] = property_num
					entities_property_array_num_property_path[entities_types_shortcuts[entity_type]].append(ESeed.tracked_properties[property_num].property_path)
					entities_empty_properties_array[entities_types_shortcuts[entity_type]].append(null)
		else:
			entities_file_excepted.append(entity_type)
			
	# Pushing and asserting errors
	assert(entities_without_EntitySeed.size() == 0, 'Some entities don\'t have EntitySeed as child: '+str(entities_without_EntitySeed))
	for entity_type in entities_file_excepted:
		push_error('File excepted to load entity "'+entity_type+'": '+'res://entities/'+entity_type+'/'+entity_type+'.tscn')
	
	return resources
	
	
func save_entities_data():
	var _eglobal_file = FileAccess.open(entities_global_file, FileAccess.WRITE)
	#update_entities_global()
	_eglobal_file.store_var(entities_global)
	_eglobal_file.close()
	for chunk in chunks_entities:
		save_chunk(chunk)
				
		
func load_entities(_entities_file_data : Dictionary[int, Array], _chunks_entities : Dictionary[Variant, PackedInt32Array]):
	for chunk in _chunks_entities:
		for entity_id in _entities_file_data:
			file_entity_summon(_entities_file_data[entity_id], entity_id, chunk)
			

## EntityFileData version of [method host_spawn_entity]
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
	
	
func prepare_trackers(entity_id, tracked_properties : Array[AbstractTracker]):
	var already_used_tracker_types = []
	for res_num in range(len(tracked_properties)):
		for tracker in trackers:
			already_used_tracker_types.append(tracker.get_script().get_global_name())
		if not already_used_tracker_types.has(tracked_properties[res_num].get_script().get_global_name()):
			tracked_properties[res_num]._SG2Core = _SG2Core
			tracked_properties[res_num].start()
			trackers.append(tracked_properties[res_num])
		trackers[already_used_tracker_types.find(tracked_properties[res_num].get_script().get_global_name())].start_tracking(entity_id, tracked_properties[res_num].property_path, tracked_properties[res_num])
	
	
func register_entity(entity_id : int, entity_node : Node):
	entities[entity_id] = EntityData.new()
	entities[entity_id].node = entity_node
	nodes_entities[entity_node] = entity_id
	entities[entity_id].type = entities_types_shortcuts[entity_node.get_scene_file_path().get_slice('/', 3)]
	
	
func start_tracking(entity_id : int, entity_node : Node, chunk=FROM_E_POS):
	entity_node.get_node('EntitySeed').queue_free()
	var entity_type : int = entities[entity_id].type
	var path_to_parent : NodePath = _entities_storage.get_path_to(entity_node.get_parent())
	var chunk_node = establish_entity_parenthood(entity_node, entity_id, path_to_parent)
	if typeof(chunk) == typeof(FROM_E_POS):
		chunk = _ChunksCalculator.position_to_chunk(null if not 'global_position' in chunk_node else chunk_node.global_position)
	if not chunks_entities.has(chunk):
		chunks_entities[chunk] = PackedInt32Array()
	if not chunks_users_num.has(chunk):
		load_chunk(chunk)
	entities[entity_id].type = entity_type
	chunks_entities[chunk].append(entity_id)
	entities[entity_id].chunk = chunk
	entities[entity_id].spawn_data = EntitySpawnData(entity_type, entities_empty_properties_array[entity_type], path_to_parent)
	entities[entity_id].update_data = EntityUpdateData(entities_empty_properties_array[entity_type], path_to_parent)
	
	entities_list.append(entity_id)
	

func track_entities():
	var _from : int
	var _to : int
	if current_update_frame == 1:
		var FPS : float = {'host': _InterpolationLogic.server_FPS, 'guest': _InterpolationLogic.guest_FPS}[_ConnectionLogic.peer_role]
		current_frames_per_update = ceil(FPS / float(updates_per_second))
		current_update_range_size = len(entities_list) / current_frames_per_update
	if not current_update_frame == current_frames_per_update:
		_from = current_update_range_size*(current_update_frame-1)
		_to = current_update_range_size*current_update_frame
		current_update_frame += 1
	else:
		_from = current_update_range_size*(current_update_frame-1)
		_to = len(entities_list)
		current_update_frame = 1
	for i in range(_from, _to):
		if len(entities_list)-1 < i:
			continue
		var entity_id = entities_list[i]
		if not is_instance_valid(entities[entity_id].node):
			entities_list.erase(entity_id)
			deleted_entities.append(entity_id)
			chunks_entities[entities[entity_id].chunk].erase(entity_id)
			entities.erase(entity_id)
			for tracker in trackers:
				tracker.stop_tracking(entity_id)
			continue
		if entities[entity_id].chunk != null:
			var new_chunk = _ChunksCalculator.position_to_chunk(entities[entities[entity_id].parent_link].node.global_position)
			if new_chunk != entities[entity_id].chunk:
				if not chunks_entities.has(new_chunk):
					chunks_entities[new_chunk] = PackedInt32Array()
				if not chunks_users_num.has(new_chunk):
					load_chunk(new_chunk)
				chunks_entities[entities[entity_id].chunk].erase(entity_id)
				chunks_entities[new_chunk].append(entity_id)
				entities[entity_id].chunk = new_chunk
		var old_data = entities[entity_id].update_data.duplicate(true)
		entities[entity_id].spawn_data[1] = entities_empty_properties_array[entities[entity_id].spawn_data[0]].duplicate(false)
		entities[entity_id].update_data[0] = entities_empty_properties_array[entities[entity_id].spawn_data[0]].duplicate(false)
		for tracker in trackers:
			tracker.track_entity(entity_id)
		if old_data != entities[entity_id].update_data:
			entities[entity_id].update_check = true
	if nodes_entities.has(null):
		nodes_entities.erase(null)
	for chunk in chunks_entities:
		if chunks_entities[chunk].is_empty():
			chunks_entities.erase(chunk)
			
		
func spawn_entity(spawn_data : Array, chunk=FROM_E_POS, entity_id : int = get_new_entity_id()):
	var entity_type : int = spawn_data[0]
	if not entities_resources.has(entity_type):
		return
	var entity_instance = entities_resources[entity_type].instantiate()
	entity_instance.name = 'e'+str(entity_id)
	var entity_parent_node = _entities_storage.get_node(spawn_data[2])
	var ESeed : EntitySeed = entity_instance.get_node('EntitySeed')
	ESeed.nonchunk = chunk==NONCHUNK
	
	register_entity(entity_id, entity_instance)
	ESeed.prepare_properties()
	prepare_trackers(entity_id, ESeed.tracked_properties)
	update_entity(entity_id, EntityUpdateData(spawn_data[1], spawn_data[2]))
	ESeed.presets()
	entity_parent_node.add_child(entity_instance)
	start_tracking(entity_id, entity_instance, chunk)
	
	
func update_entity(entity_id : int, update_data : Array):
	# TODO: test path_from_parent changes
	if entities[entity_id].spawn_data[2] != update_data[1]:
		reparent_entity(entities[entity_id].node, update_data[1])
	for tracker:AbstractTracker in trackers:
		tracker.update_entity(entity_id, update_data)


## Establishes entity parenthood and returns chunk_node
func establish_entity_parenthood(entity_node : Node, entity_id : int, path_to_parent : NodePath) -> Node:
	var chunk_node : Node = entity_node
	var _chunk_node_path = ''
	entities[entity_id].parent_link = entity_id
	for node_name in str(path_to_parent).split('/'):
		_chunk_node_path += node_name + '/'
		if node_name[0] == 'e' and node_name.substr(1).is_valid_int():
			entities[entity_id].parent_link = int(node_name.substr(1))
			chunk_node = _entities_storage.get_node(_chunk_node_path)
			break
	entities[entity_id].hierarchy_value = path_to_parent.get_name_count()
	return chunk_node
	

func reparent_entity(entity_node : Node, new_parent : Node, immediately : bool = false):
	var entity_id = int(entity_node.name.substr(1))
	var path_to_parent : NodePath = _entities_storage.get_path_to(entity_node.get_parent())
	if not immediately:
		if str(entity_node.name)[0] == 'e' and entity_node.name.substr(1).is_valid_int():
			reparenting_buffer[entity_id] = [entity_node, new_parent]
	else:
		entity_node.reparent(new_parent, false)
		establish_entity_parenthood(entity_node, entity_id, path_to_parent)
	
	
func process_reparenting_buffer():
	for entity_id in reparenting_buffer:
		reparent_entity(reparenting_buffer[entity_id][0], reparenting_buffer[entity_id][1], true)
		reparenting_buffer.erase(entity_id)
	

func host_manage_chunks_users():
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
		var entity = _entities_storage.get_node(entities[entity_id].spawn_data[2]+'/e'+str(entity_id))
		if entity:
			entity.queue_free()
	
	
func send_entities_to_guests():
	var _checked_entities : Array[int]
	for peer_id in players:
		var player_data := players[peer_id]
		player_data.observers = player_data.observers.filter(func(_o): return _o != null)
		var _entities_to_delete : PackedInt32Array
		var _entities_to_update : Dictionary[int, Array]
		var _entities_to_spawn : Dictionary[int, Array]
		for observer : Observer in player_data.observers:
			for chunk in observer._chunks_to_delete:
				if not chunks_entities.has(chunk):
					continue
				for entity_id in chunks_entities[chunk]:
					observer.loaded_entities.erase(entity_id)
					_entities_to_delete.append(entity_id)
			for entity_id in observer.loaded_entities:
				if deleted_entities.has(entity_id) or entities[entity_id].chunk not in observer.loaded_chunks:
					observer.loaded_entities.erase(entity_id)
					_entities_to_delete.append(entity_id)
				elif entities[entity_id].update_check:
					_checked_entities.append(entity_id)
					_entities_to_update[entity_id] = entities[entity_id].update_data
			for chunk in observer.loaded_chunks:
				if not chunks_entities.has(chunk): continue
				for entity_id in chunks_entities[chunk]:
					if not entities_list.has(entity_id): continue
					if not observer.loaded_entities.has(entity_id):
						observer.loaded_entities.append(entity_id)
						_entities_to_spawn[entity_id] = entities[entity_id].spawn_data
		rpc_id(peer_id, 'guest_sync_entities', _entities_to_delete, _entities_to_spawn, _entities_to_update)
	for entity_id in _checked_entities:
		entities[entity_id].update_check = false



func clear_deleted_entities():
	deleted_entities.clear()
		

@rpc("authority", 'call_local')
func guest_sync_entities(_delete_entities : PackedInt32Array, _spawn_entities : Dictionary[int, Array], _update_entities : Dictionary[int, Array]):
	if _ConnectionLogic.peer_role != 'guest': return
	
	for entity_id in _delete_entities:
		entities[entity_id].node.queue_free()
		
	for entity_id in _spawn_entities:
		spawn_entity(_spawn_entities[entity_id], FROM_E_POS, entity_id)
		
	for entity_id in _update_entities:
		update_entity(entity_id, _update_entities[entity_id])


func manage_debug_keybindings():
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("change_visibility"):
		_SG2Core.get_node('Logics/VoxelTerrain/TransvoxelTerrain').visible = not _SG2Core.get_node('Logics/VoxelTerrain/TransvoxelTerrain').visible
