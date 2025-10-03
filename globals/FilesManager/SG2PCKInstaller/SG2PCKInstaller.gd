extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func install_pck(pck_file_path, call_after_operation : Callable, mark = null):
	var is_success = ProjectSettings.load_resource_pack(pck_file_path)
	
	var result : Dictionary
	if is_success:
		result = {'is_success': true, 'mark': mark}
	else:
		result = {'is_success': false, 'mark': mark}
		
	call_after_operation.call(result)
	
