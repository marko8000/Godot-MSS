extends MSSLogic
class_name EntityFactory


@onready var _PathRegistry := _MSSCore._PathRegistry
@onready var _EntityStorage := _MSSCore._EntityStorage
@onready var _EntityInterest := _MSSCore._EntityInterest
@onready var _ChunkCalculator := _MSSCore._ChunkCalculator

@onready var _entities_dir = _PathRegistry.path('entities_dir')
@onready var _entities_data_dir = _PathRegistry.path('entities_data_dir')
@onready var _entities_meta_file = _PathRegistry.path('entities_meta_file')

@onready var _entities_meta : Dictionary = _load_entities_meta()
@onready var _entity_type_shortcuts : Dictionary[String, int] = _get_entity_type_shortcuts()
@onready var _shortcuts_entity_type : PackedStringArray = _get_shortcuts_entity_type()
@onready var _last_used_entity_id : int = -1 if !_entities_meta.has('last_used_entity_id') else _entities_meta.last_used_entity_id
@onready var _entity_type_data : Array[EntityTypeData] = _load_entity_resources()
var _source_names : PackedStringArray
class EntityTypeData:
	var resource : PackedScene 
	var dimension : ChunkCalculator.Dimension
	var source_indices : PackedInt32Array
	var cell_size : PackedInt32Array
	var property_paths : Array[PackedStringArray]
	var node_paths : Array[PackedStringArray]
	var update_mask_size : int = 0
	var root_scale_level_idx : int
	var root_lod : int
	func _to_string() -> String:
		return str([resource, dimension, source_indices, cell_size, property_paths, node_paths, update_mask_size])


static func get_from(from : Node) -> EntityFactory: 
	return MSSCore.get_from(from)._EntityFactory


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
			
			data.root_lod = ESeed.root_lod
			data.root_scale_level_idx = _ChunkCalculator._scale_levels_by_size.find(
				ESeed.root_scale_level)
			
			var data_sources : Array[EntityDataSource]
			data_sources.append_array(ESeed.trackers)
			data_sources.append_array(ESeed.components)
			for property_num in range(ESeed.trackers.size()):
				var source := data_sources[property_num]
				if source is AAutoSelectTracker:
					continue
				var source_name : String = source.get_script().get_global_name()
				if not _source_names.has(source_name):
					_source_names.append(source_name)
					source._EntityStorage = _EntityStorage
					_EntityStorage._data_sources.append(source)
				var source_idx = _source_names.find(source_name)
				
				var node_path : String 
				if source is NodeTracker:
					node_path = source.node_path
				if node_path == '':
					node_path = '.'
				elif node_path == '..':
					node_path = '.'
				else:
					node_path = node_path.replace('../', '')
				var property_path : String
				if source is PropertyTracker:
					property_path = source.property_path
				data.update_mask_size += source._update_mask_size
				if not source_idx in data.source_indices:
					data.source_indices.append(source_idx)
					data.cell_size.append(1)
					data.node_paths.append(PackedStringArray([node_path]))
					if property_path:
						data.property_paths.append(PackedStringArray([property_path]))
				else:
					var list_idx := data.source_indices.find(source_idx)
					data.cell_size[list_idx] += 1
					data.node_paths[list_idx].append(node_path)
					if property_path:
						data.property_paths[list_idx].append(property_path)
					
			data.dimension = _ChunkCalculator.get_dim_from(entity_instance)
			if not data.dimension:
				@warning_ignore("assert_always_true")
				assert(true, 'Unsupported entity node type')
				
		else:
			entities_file_excepted.append(entity_type)
	
	# Pushing and asserting errors
	assert(entities_without_EntitySeed.size() == 0, 'Some entities don\'t have EntitySeed as child: '+str(entities_without_EntitySeed))
	for entity_type in entities_file_excepted:
		push_error('File excepted to load entity "'+entity_type+'": '+'res://entities/'+entity_type+'/'+entity_type.to_snake_case()+'.tscn')
	
	return type_data


func spawn(entity_type : String, data : Dictionary, where : Node = _EntityStorage) -> Node:
	if not _entity_type_shortcuts.has(entity_type):
		return
	var shortcut := _entity_type_shortcuts[entity_type]
	var tdata := _entity_type_data[shortcut]
	var entity_instance := tdata.resource.instantiate()
	if where == _EntityStorage:
		where = _ChunkCalculator.dim_data[tdata.dimension].storage
	for path in data:
		Dispenser.set_resource(entity_instance, path, data[path], [shortcut, path])
	where.add_child(entity_instance)
	return entity_instance
	

func spawn_and_load(entity_type : String, data : Dictionary) -> Node:
	var type_data := _entity_type_data[_entity_type_shortcuts[entity_type]]
	var position
	if data.has('position'):
		position = data.position
	var chunk_array : Array[Variant]
	var preloader_scene_path : String
	var estorage := _ChunkCalculator.dim_data[type_data.dimension].storage
	if not position:
		position = _ChunkCalculator.get_zero(type_data.dimension)
	for scale_level_idx in range(type_data.root_scale_level_idx):
		chunk_array.append(
			_ChunkCalculator.position_to_chunk(
				position, 
				_ChunkCalculator._scale_levels_by_size[scale_level_idx],
				type_data.dimension),
				)
	preloader_scene_path = _ChunkCalculator.dim_data[type_data.dimension].chunk_loader_file
	for chunk in chunk_array:
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
				if is_instance_valid(timer_killer):
					timer_killer.start()
					break
		if not _EntityStorage._chunk_idx_by_chunk.has(chunk):
			var chunk_idx := _EntityStorage._allocate_chunk(chunk)
			_load_chunk(chunk_idx)
		await get_node(str(chunk)+'/T').timeout
	return spawn(entity_type, data, estorage)
		
	
func _load_chunk(chunk_idx : int) -> void:
	var required_size: int = chunk_idx + 1
	if _EntityStorage._entity_tree.size() < required_size:
		var old_size: int = _EntityStorage._entity_tree.size()
		_EntityStorage._entity_tree.resize(required_size)
		for _i in range(old_size, required_size):
			_EntityStorage._entity_tree[_i] = _EntityStorage.ChunkData.new()
	_EntityInterest._chunk_requested.resize(max(chunk_idx+1, _EntityInterest._chunk_requested.size()))
	_EntityInterest._chunk_requested[chunk_idx] = 0
