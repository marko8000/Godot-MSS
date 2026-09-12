extends Node
class_name ExecManager


var sessions : Array[Session]
class Session:
	var sv_container : SubViewportContainer
	var sub_viewport : SubViewport


func _ready() -> void:
	create_session()
	

func create_session() -> Session:
	var session := Session.new()
	
	session.sv_container = SubViewportContainer.new()
	session.sv_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	session.sv_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	session.sv_container.stretch = true
	session.sub_viewport = SubViewport.new()
	session.sv_container.add_child(session.sub_viewport)
	%GridContainer.add_child(session.sv_container)
	sessions.append(session)
	
	var node := Exec.new()
	session.sub_viewport.add_child(node)
	change_exec_to('mss_start_exec', node)
	
	return session
	
func set_splitscreen_columns(column_count : int) -> void:
	%GridContainer.columns = column_count
	
func set_splitscreen_grid_separation(h : int, v : int):
	%GridContainer.add_theme_constant_override('h_separation', h)
	%GridContainer.add_theme_constant_override('v_separation', v)
	
	
static func change_exec_to(exec_name : StringName, caller : Object) -> Exec:
	var exec := get_current_exec(caller)
	var viewport : SubViewport = exec.get_parent()
	for child in viewport.get_children():
		child.queue_free()
		
	var exec_dir := File2ool.path(['res://exec', exec_name])
	var exec_scene : PackedScene = load(
		File2ool.path([exec_dir, exec_name+'.tscn']))
	var exec_instance : Exec = exec_scene.instantiate()
	viewport.add_child(exec_instance)
	Debug.dprint('Exec successfully changed to ' + exec_name)
	return exec_instance


static func get_current_exec(caller : Node) -> Exec:
	var viewport : Node = caller
	while true:
		if not viewport.get_parent().get_viewport() is SubViewport:
			break
		else:
			viewport = viewport.get_parent().get_viewport()
	return viewport.get_child(-1)
	

func get_current_level(caller : Object):
	return get_current_exec(self).get_current_level(self)
	

func get_available_execs():
	var _available_execs = DirAccess.get_directories_at('res://exec')
	
	return _available_execs


static func get_current_exec_name(caller : Object):
	return get_current_exec(caller).scene_file_path.get_slice('/', 3)
