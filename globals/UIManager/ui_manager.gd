extends Node


var default_mouse_mode : Input.MouseMode = Input.MOUSE_MODE_VISIBLE

var ui_stack : Array[Control]


func register(ui : Control) -> void:
	if ui in ui_stack:
		ui_stack.erase(ui)

	ui_stack.push_back(ui)

	if not ui.visibility_changed.is_connected(_on_ui_visibility_changed.bind(ui)):
		ui.visibility_changed.connect(_on_ui_visibility_changed.bind(ui))

	if not ui.tree_exited.is_connected(_on_ui_tree_exited.bind(ui)):
		ui.tree_exited.connect(_on_ui_tree_exited.bind(ui))
		
	_ui_stack_changed()


func unregister(ui : Control) -> void:
	ui_stack.erase(ui)
	_ui_stack_changed()
	
	
func toggle(ui : Control) -> void:
	if not ui_stack.has(ui):
		register(ui)
		ui.show()
	else:
		unregister(ui)
		ui.hide()


func _on_ui_visibility_changed(ui : Control) -> void:
	if not is_instance_valid(ui):
		unregister(ui)
		return

	if ui.visible:
		if ui not in ui_stack:
			register(ui)
	else:
		unregister(ui)
		


func _on_ui_tree_exited(ui : Control) -> void:
	unregister(ui)


func has_active_ui() -> bool:
	if not ui_stack.is_empty():
		Input.set_mouse_mode(default_mouse_mode)
	return not ui_stack.is_empty()


func get_top_ui() -> Control:
	if ui_stack.is_empty():
		return null

	return ui_stack.back()
	
	
func _ui_stack_changed() -> void:
	if not ui_stack.is_empty():
		Input.set_mouse_mode(default_mouse_mode)
