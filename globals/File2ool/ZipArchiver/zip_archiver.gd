@icon('res://globals/FilesManager/ZipArchiver/zip_icon.svg')
extends Node


var operations_per_frame : int = 3
var operations = {} # {id: {operation_type: unpack, zip_reader: reader, extract_dir: string, list_of_archive_parts: [], elements_iteration: 0, call_after_operation : Callable, mark: any}}
var last_busy_operation_id = -1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(operations_per_frame):
		for id in operations:
			var _operation_type = operations[id].operation_type
			
			if _operation_type == 'unpack':
				var _res = operations[id].zip_reader.read_file(operations[id].list_of_archive_parts[operations[id].elements_iteration])
				if len(_res) > 0: # is file
					File2ool.make_dir(File2ool.get_dir_without_last_element(File2ool.create_path([operations[id].extract_dir, operations[id].list_of_archive_parts[operations[id].elements_iteration]])))
					var _file = FileAccess.open(File2ool.create_path([operations[id].extract_dir, operations[id].list_of_archive_parts[operations[id].elements_iteration]]), FileAccess.WRITE)
					_file.store_buffer(_res)
					_file.close()
				else: # is dir
					File2ool.make_dir(File2ool.create_path([operations[id].extract_dir, operations[id].list_of_archive_parts[operations[id].elements_iteration]]))
				send_result_to_callable(operations[id].call_after_operation, build_result_of_unpacking(operations[id]))
				operations[id].elements_iteration += 1
				
				
				if operations[id].elements_iteration == len(operations[id].list_of_archive_parts):
					operations[id].zip_reader.close()
					send_result_to_callable(operations[id].call_after_operation, build_result_of_unpacking(operations[id]))
					operations.erase(id)
				
			elif _operation_type == 'pack':
				pass
				
		
func create_new_operation(operation_type):
	last_busy_operation_id += 1
	operations[last_busy_operation_id] = {'operation_type': operation_type}
	return last_busy_operation_id


func unpack(zip_file_path, extract_dir, call_after_operation : Callable, mark = null):
	var id = create_new_operation('unpack')
	
	operations[id].zip_reader = ZIPReader.new()
	operations[id].zip_reader.open(zip_file_path)
	
	operations[id].extract_dir = extract_dir
	File2ool.make_dir(extract_dir)
	
	operations[id].list_of_archive_parts = operations[id].zip_reader.get_files()
	operations[id].elements_iteration = 0
	
	operations[id].call_after_operation = call_after_operation
	operations[id].mark = mark
	

func build_result_of_unpacking(operation_dict : Dictionary):
	var _result = operation_dict.duplicate()
	_result.erase('zip_reader')
	return _result
	

func send_result_to_callable(callable_method : Callable, result):
	callable_method.call(result)
