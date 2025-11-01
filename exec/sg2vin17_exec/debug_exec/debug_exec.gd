extends MarginContainer


@onready var SG2Exec = ExecManager.give_current_exec(self)
@onready var current_level = SG2Exec.giveo('level')


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	current_level = SG2Exec.giveo('level')
	
	if visible:
		#exec and level debug
		var exec_and_level_debug = get_node('HBoxContainer/exec_and_level_debug')
		
		var current_exec_name_label = exec_and_level_debug.get_node('current_exec_name/Value')
		current_exec_name_label.set_text(str(ExecManager.current_exec_name))
		
		var current_exec_file_path_label = exec_and_level_debug.get_node('current_exec_dir_path/Value')
		current_exec_file_path_label.set_text(str(ExecManager.current_exec_file_path))
		
		var current_level_name_label = exec_and_level_debug.get_node('current_level_name/Value')
		if current_level != null:
			current_level_name_label.set_text(str(current_level.name))
		else:
			current_level_name_label.set_text(str(null))
			
		var current_peer_role_label = exec_and_level_debug.get_node('current_peer_role/Value')
		var label_text = null
		if current_level != null:
			if current_level.has_method('giveo'):
				if current_level.giveo('ConnectionLogic') != null:
					if 'peer_role' in current_level.giveo('ConnectionLogic'):
						label_text = current_level.giveo('ConnectionLogic').peer_role
		current_peer_role_label.set_text(str(label_text))
		
		#device and engine debug
		var device_and_engine_debug = get_node('HBoxContainer/device_and_engine_debug')
		
		var godot_version_label = device_and_engine_debug.get_node('godot_version/Value')
		var version = Engine.get_version_info().string
		godot_version_label.set_text(version)
		
		var os_name_label = device_and_engine_debug.get_node('current_os/Value')
		os_name_label.set_text(OS.get_name())
		
		var fps_counter_label = device_and_engine_debug.get_node('fps_counter/Value')
		fps_counter_label.set_text(str(Engine.get_frames_per_second()))
		
		var static_memory_usage_label = device_and_engine_debug.get_node('static_memory_usage/Value')
		var measure_label = device_and_engine_debug.get_node('static_memory_usage/Measure')
		var measures = {'B': 1, 'KiB': 1024, 'MiB': 1024**2, 'GiB': 1024**3, 'TiB': 1024**4, 'PiB': 1024**5, 'EiB': 1024**6, 'ZiB': 1024**7, 'YiB': 1024**8, 'RiB': 1024**9, 'QiB': 1024**10}
		static_memory_usage_label.set_text(str(OS.get_static_memory_usage() / measures[measure_label.text])+'/'+str(OS.get_static_memory_peak_usage() / measures[measure_label.text]))
		
		var processor_info_label = device_and_engine_debug.get_node('processor_info/Value')
		var info = str(OS.get_processor_count())+'x ' + str(OS.get_processor_name())
		processor_info_label.set_text(info)
		
		var videoadapter_info_label = device_and_engine_debug.get_node('videoadapter_info/Value')
		info = str(RenderingServer.get_video_adapter_name())
		videoadapter_info_label.set_text(info)
