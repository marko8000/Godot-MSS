extends MarginContainer


@onready var _SG2Exec := ExecManager.get_current_exec(self)
@onready var _current_level

var debug_label_file = load('res://exec/sg2vin17_exec/debug_control/debug_label.tscn')

var exec_debug_labels : Dictionary[String, Array]
var static_exec_debug_labels : Array[String]
var engine_debug_labels : Dictionary[String, Array]
var static_engine_debug_labels : Array[String]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	manage_debug_labels()
	
	_current_level = _SG2Exec.get_current_level()
	
	if Input.is_action_just_pressed("debug"):
		visible = not visible
	
	exec_debug('current exec name', ExecManager.get_current_exec_name(self))
	exec_debug('current level name', null if _current_level == null else _current_level.name)
	engine_debug('Godot Engine', Engine.get_version_info().string)
	engine_debug('current OS', OS.get_name())
	engine_debug('CPU', str(OS.get_processor_count())+'x ' + str(OS.get_processor_name()))
	engine_debug('Video adapter', RenderingServer.get_video_adapter_name())
	engine_debug('FPS', Engine.get_frames_per_second())
	var measures = {'B': 1, 'KiB': 1024, 'MiB': 1024**2, 'GiB': 1024**3, 'TiB': 1024**4, 'PiB': 1024**5, 'EiB': 1024**6, 'ZiB': 1024**7, 'YiB': 1024**8, 'RiB': 1024**9, 'QiB': 1024**10}
	var current_measure = 'MiB'
	engine_debug('Static memory usage', str(OS.get_static_memory_usage() / measures[current_measure])+'/'+str(OS.get_static_memory_peak_usage() / measures[current_measure])+current_measure)


func manage_debug_labels():
	var _debug_labels_storages : Dictionary[Control, Array] = {
		%exec_and_level_debug: [exec_debug_labels, static_exec_debug_labels],
		%device_and_engine_debug: [engine_debug_labels, static_engine_debug_labels]
	}
	
	for _debug_labels_storage in _debug_labels_storages:
		for _debug_label_name in _debug_labels_storages[_debug_labels_storage][0]:
			if not _debug_labels_storage.has_node(_debug_label_name):
				var debug_label_instance = debug_label_file.instantiate()
				debug_label_instance.name = _debug_label_name
				_debug_labels_storage.add_child(debug_label_instance)
			_debug_labels_storage.get_node(_debug_label_name).set_value(_debug_labels_storages[_debug_labels_storage][0][_debug_label_name][0])
		for child in _debug_labels_storage.get_children():
			if not child.name in _debug_labels_storages[_debug_labels_storage][0]:
				continue
			if (float(str(Time.get_unix_time_from_system())) - _debug_labels_storages[_debug_labels_storage][0][child.name][1]) > 0.2:
				if not child.name in _debug_labels_storages[_debug_labels_storage][1]:
					child.queue_free()
		
	
func exec_debug(debug_label_name, value, is_static: bool = false):
	exec_debug_labels[debug_label_name] = [value, Time.get_unix_time_from_system()]
	if is_static:
		static_exec_debug_labels.append(debug_label_name)
		
		
func engine_debug(debug_label_name, value, is_static: bool = false):
	engine_debug_labels[debug_label_name] = [value, Time.get_unix_time_from_system()]
	if is_static:
		static_engine_debug_labels.append(debug_label_name)
