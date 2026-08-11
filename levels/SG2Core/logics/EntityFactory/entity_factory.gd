extends SG2Logic
class_name EntityFactory


@onready var _PathRegistry := _SG2Core._PathRegistry
@onready var _EntityStorage := _SG2Core._EntityStorage
@onready var _EntitySync := _SG2Core._EntitySync
@onready var _ChunkCalculator := _SG2Core._ChunkCalculator

@onready var _entities_dir = _PathRegistry.path('entities_dir')
@onready var _entities_data_dir = _PathRegistry.path('entities_data_dir')
@onready var _entities_meta_file = _PathRegistry.path('entities_meta_file')

@onready var _entities_meta : Dictionary = _load_entities_meta()
@onready var _entity_type_shortcuts : Dictionary[String, int] = _get_entity_type_shortcuts()
@onready var _shortcuts_entity_type : PackedStringArray = _get_shortcuts_entity_type()
@onready var _last_used_entity_id : int = 0 if !_entities_meta.has('last_used_entity_id') else _entities_meta.last_used_entity_id
@onready var _entity_type_data : Array[EntityTypeData] = _load_entity_resources()
var _tracker_names : PackedStringArray
class EntityTypeData:
	var resource : PackedScene 
	var dimension : Dimension
	enum Dimension {GLOBAL, V2, V3}
	var tracker_indices : PackedInt32Array
	var cell_size : PackedInt32Array
	var property_paths : Array[PackedStringArray]
	var node_paths : Array[PackedStringArray]
	var update_mask_size : int = 0
	func _to_string() -> String:
		return str([resource, dimension, tracker_indices, cell_size, property_paths, node_paths, update_mask_size])


static func get_from(from : Node) -> EntityFactory: 
	return SG2Core.get_from(from)._EntityFactory


func _get_new_entity_id() -> int:
	_last_used_entity_id += 1
	return _last_used_entity_id
	

func _load_entities_meta():
	var file = FileAccess.open(_entities_meta_file, FileAccess.READ)
	if file != null:
		var _entities_data = JSON.parse_string(file.get_as_text())
		file.close()
		return _entities_data
	else:
		push_warning('entities_meta_file not found')
		return {}
		

func _get_entity_type_shortcuts():
	var _shortcuts : Dictionary[String, int]
	if _entities_meta.has('entity_type_shortcuts'):
		_shortcuts = _entities_meta.entity_type_shortcuts
	return _shortcuts
	
	
func _get_shortcuts_entity_type():
	var _shortcuts : Array
	if _entities_meta.has('entity_type_shortcuts'):
		for entity_type in _entities_meta.entity_type_shortcuts.keys():
			var shortcut = _entities_meta.entity_type_shortcuts[entity_type]
			_shortcuts_entity_type[shortcut] = entity_type
	return _shortcuts
		

# TODO: Static trackers support
func _load_entity_resources() -> Array[EntityTypeData]:
	var type_data : Array[EntityTypeData]
	var entities_file_excepted : PackedStringArray
	var entities_without_EntitySeed : PackedStringArray
	for entity_type in DirAccess.get_directories_at('res://entities/'):
		if not _entity_type_shortcuts.has(entity_type):
			_shortcuts_entity_type.append(entity_type)
			_entity_type_shortcuts[entity_type] = _shortcuts_entity_type.size()-1
		var shortcut := _entity_type_shortcuts[entity_type]
		type_data.append(EntityTypeData.new())
		var data := type_data[shortcut]
		var name_options : Array = [
			'res://entities/'+entity_type+'/'+entity_type.to_camel_case()+'.tscn',
			'res://entities/'+entity_type+'/'+entity_type.to_kebab_case()+'.tscn',
			'res://entities/'+entity_type+'/'+entity_type.to_snake_case()+'.tscn',
			'res://entities/'+entity_type+'/'+entity_type.to_pascal_case()+'.tscn',
			'res://entities/'+entity_type+'/'+entity_type+'.tscn'
		]
		var valid_path: String = ""
		var existing_files = name_options.filter(func(path): return FileAccess.file_exists(path))
		if not existing_files.is_empty():
			valid_path = existing_files[0]
		if FileAccess.file_exists(valid_path):
			data.resource = load(valid_path)
			var entity_instance = data.resource.duplicate(true).instantiate()
			if not entity_instance.has_node('EntitySeed'):
				entities_without_EntitySeed.append(entity_type)
				continue
			var ESeed : EntitySeed = entity_instance.get_node('EntitySeed')
			_EntityStorage._activation_queue.append([])
			
			for property_num in range(ESeed.trackers.size()):
				var tracker := ESeed.trackers[property_num]
				if tracker is AAutoSelectTracker:
					continue
				var tracker_name : String = tracker.get_script().get_global_name()
				if not _tracker_names.has(tracker_name):
					_tracker_names.append(tracker_name)
					_EntityStorage._trackers.append(tracker.duplicate())
				var tracker_idx = _tracker_names.find(tracker_name)
				var node_path : String = tracker.node_path
				if node_path == '':
					node_path = '.'
				var property_path : String
				if tracker is PropertyBaseTracker:
					property_path = tracker.property_path
				data.update_mask_size += tracker._update_mask_size
				if not tracker_idx in data.tracker_indices:
					data.tracker_indices.append(tracker_idx)
					data.cell_size.append(1)
					data.node_paths.append(PackedStringArray([node_path]))
					if property_path:
						data.property_paths.append(PackedStringArray([property_path]))
				else:
					var list_idx := data.tracker_indices.find(tracker_idx)
					data.cell_size[list_idx] += 1
					data.node_paths[list_idx].append(node_path)
					if property_path:
						data.property_paths[list_idx].append(property_path)
					
				
			if ESeed.is_global:
				data.dimension = EntityTypeData.Dimension.GLOBAL
			else:
				if entity_instance is Node2D:
					data.dimension = EntityTypeData.Dimension.V2
				elif entity_instance is Node3D:
					data.dimension = EntityTypeData.Dimension.V3
				else:
					data.dimension = EntityTypeData.Dimension.GLOBAL
				
		else:
			entities_file_excepted.append(entity_type)
	
	# Pushing and asserting errors
	assert(entities_without_EntitySeed.size() == 0, 'Some entities don\'t have EntitySeed as child: '+str(entities_without_EntitySeed))
	for entity_type in entities_file_excepted:
		push_error('File excepted to load entity "'+entity_type+'": '+'res://entities/'+entity_type+'/'+entity_type.to_snake_case()+'.tscn')
	
	return type_data


func _spawn_json(entity_type : String, data : Dictionary, where : Node = _EntityStorage, entity_id : int = _get_new_entity_id()) -> Node:
	if not _entity_type_shortcuts.has(entity_type):
		return
	var shortcut := _entity_type_shortcuts[entity_type]
	var tdata := _entity_type_data[shortcut]
	var entity_instance := tdata.resource.instantiate()
	for path in data:
		Dispenser.set_resource(entity_instance, path, data[path], [shortcut, path])
	where.add_child(entity_instance)
	return entity_instance
	

func spawn_and_load(entity_type : String, data : Dictionary, where : Node = _EntityStorage) -> Node:
	var type_data := _entity_type_data[_entity_type_shortcuts[entity_type]]
	var position
	if data.has('position'):
		position = data.position
	var chunk
	var preloader_scene_path : String
	match type_data.dimension:
		EntityTypeData.Dimension.V2:
			if not position:
				position = Vector2.ZERO
			chunk = _ChunkCalculator.position2d_to_chunk(position)
			preloader_scene_path = 'res://levels/SG2Core/logics/EntityFactory/ChunkLoaders/chunk_loader_2d.tscn'				
		EntityTypeData.Dimension.V3:
			if not position:
				position = Vector3.ZERO
			chunk = _ChunkCalculator.position3d_to_chunk(position)
			preloader_scene_path = 'res://levels/SG2Core/logics/EntityFactory/ChunkLoaders/chunk_loader_3d.tscn'
	while true:
		var wait_time := 5
		if not has_node(str(chunk)):
			var preloader_scene : PackedScene = load(preloader_scene_path)
			var preloader_instance = preloader_scene.instantiate()
			preloader_instance.name = str(chunk)
			if position:
				preloader_instance.position = position
			var timer_killer := TimerKiller.new()
			timer_killer.name = 'T'
			timer_killer.wait_time = wait_time
			preloader_instance.add_child(timer_killer)
			add_child(preloader_instance)
		else:
			var timer_killer : TimerKiller = get_node_or_null(str(chunk)+'/T')
			if timer_killer:
				timer_killer.start()
			if is_instance_valid(timer_killer):
				timer_killer.start()
				break
	# load_chunk(chunk)
	await get_node(str(chunk)+'/T').timeout
	return _spawn_json(entity_type, data)
	
	
## Simple entity spawn
func spawn(entity_type : String, data : Dictionary, where : Node = _EntityStorage) -> Node:
	return _spawn_json(entity_type, data, where)
