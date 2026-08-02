extends SG2Logic
class_name EntityFactory


@onready var _PathRegistry := _SG2Core._PathRegistry

@onready var _entities_dir = _PathRegistry.path('entities_dir')
@onready var _entities_data_dir = _PathRegistry.path('entities_data_dir')
@onready var _entities_meta_file = _PathRegistry.path('entities_meta_file')

@onready var _entities_meta : Dictionary = _load_entities_meta()
@onready var _entity_type_shortcuts : Dictionary[String, int] = _get_entity_type_shortcuts()
@onready var _shortcuts_entity_type : Dictionary[int, String] = _get_shortcuts_entity_type()
@onready var _last_used_entity_id : int = 0 if !_entities_meta.has('last_used_entity_id') else _entities_meta.last_used_entity_id
@onready var _entity_type_data : Dictionary[int, EntityTypeData] = _load_entity_resources()
class EntityTypeData:
	var resource : PackedScene 
	var property_path_property_array_num : Dictionary[StringName, int] ## {property_path: property_array_num}
	var property_array_num_property_path : Array[StringName] ## {entity_type: [property_path, ...]}
	var empty_property_array : Array ## {entity_type: [null, null, ...]}
	var dimension : Dimension
	enum Dimension {GLOBAL, V2, V3}
	

func _get_new_entity_id():
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
	var _shortcuts : Dictionary[int, String]
	if _entities_meta.has('entity_type_shortcuts'):
		for entity_type in _entities_meta.entity_type_shortcuts.keys():
			var shortcut = _entities_meta.entity_type_shortcuts[entity_type]
			_shortcuts_entity_type[shortcut] = entity_type
	return _shortcuts
		
		
func _load_entity_resources() -> Dictionary[int, EntityTypeData]:
	var type_data : Dictionary[int, EntityTypeData]
	var entities_file_excepted : PackedStringArray
	var entities_without_EntitySeed : PackedStringArray
	for entity_type in DirAccess.get_directories_at('res://entities/'):
		if not _entity_type_shortcuts.has(entity_type):
			_shortcuts_entity_type[_shortcuts_entity_type.size()] = entity_type
			_entity_type_shortcuts[entity_type] = _shortcuts_entity_type.size()-1
		var shortcut := _entity_type_shortcuts[entity_type]
		type_data[shortcut] = EntityTypeData.new()
		var data := type_data[shortcut]
		if FileAccess.file_exists('res://entities/'+entity_type+'/'+entity_type+'.tscn'):
			data.resource = load("res://entities/"+entity_type+"/"+entity_type+'.tscn')
			var entity_instance = data.resource.duplicate(true).instantiate()
			if not entity_instance.has_node('EntitySeed'):
				entities_without_EntitySeed.append(entity_type)
				continue
			var ESeed : EntitySeed = entity_instance.get_node('EntitySeed')
			ESeed._prepare_properties()
			for property_num in range(len(ESeed.tracked_properties)):
				data.property_path_property_array_num[ESeed.tracked_properties[property_num].property_path] = property_num
				data.property_array_num_property_path.append(ESeed.tracked_properties[property_num].property_path)
				data.empty_property_array.append(null)
			if ESeed.global:
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
		push_error('File excepted to load entity "'+entity_type+'": '+'res://entities/'+entity_type+'/'+entity_type+'.tscn')
	
	return type_data


func spawn(entity_type : String, data : Dictionary, chunk = null, chunk_from_pos : bool = true, entity_id : int = _get_new_entity_id()):
	var array : Array
	if not _entity_type_shortcuts.has(entity_type):
		return
	var type_shortcut := _entity_type_shortcuts[entity_type]
	var tdata := _entity_type_data[type_shortcut]
	for i in range(len(tdata.property_array_num_property_path)):
		if data.has(tdata.property_array_num_property_path[i]):
			array.append(data[tdata.property_array_num_property_path[i]])
		else:
			array.append(null)
	if tdata.dimension == EntityTypeData.Dimension.GLOBAL:
		_spawn_entity_global(type_shortcut, array, chunk, entity_id)
	elif tdata.dimension == EntityTypeData.Dimension.V2:
		pass
	elif tdata.dimension == EntityTypeData.Dimension.V3:
		pass
	

func _get_ESL(entity_node : Node, entity_type : int) -> EntityStorageLogic:
	var _ESL : EntityStorageLogic
	var parent := entity_node.get_parent()
	var storage_entity : Node
	while true:
		if parent.is_in_group('s') or parent.is_in_group('e'):
			storage_entity = parent
			break
		if parent == _SG2Core:
			return
		parent = parent.get_parent()
	var logic_instance : EntityStorageLogic
	var logic_name : String
	match _entity_type_data[entity_type].dimension:
		EntityTypeData.Dimension.GLOBAL:
			logic_instance = EntityStorageLogicGlobal.new()
			logic_name = 'ESLGlobal'
		EntityTypeData.Dimension.V2:
			#logic_instance = EntityStorageLogic2D.new()
			logic_name = 'ESL2D'
		EntityTypeData.Dimension.V3:
			#logic_instance = EntityStorageLogic3D.new()
			logic_name = 'ESL3D'
	if storage_entity.has_node(logic_name):
		return storage_entity.get_node(logic_name)
	else:
		logic_instance.name = logic_name
		storage_entity.add_child(logic_instance)
		return storage_entity.get_node(logic_name)
	
	
func _spawn_entity_global(entity_type : int, data : Array, chunk : Variant, entity_id : int = _get_new_entity_id()):
	pass
