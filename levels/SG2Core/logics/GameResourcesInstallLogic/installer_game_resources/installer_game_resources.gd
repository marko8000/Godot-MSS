extends HTTPRequest


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')
@onready var GameResourcesInstallLogic = SG2Core.giveo('GameResourcesInstallLogic')

@onready var DownloadedContent = File2ool.create_path([DirectoriesPathsDistributor.give_path('DownloadedContent')])


var game_resource_name : String
var game_resource : Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	install_game_resources()
	

func install_game_resources():
	if len(game_resource.actions) > 0:
		var _current_action = game_resource.actions[0]
		
		if typeof(_current_action) == TYPE_ARRAY:
			if _current_action[0] == 'change_extension':
				_change_source_file_extension(game_resource.source, _current_action[1])
				next_action()
		
		elif typeof(_current_action) == TYPE_STRING:
			if _current_action == 'http_download_file_from_body':
				# Create an HTTP request node and connect its completion signal.
				var http_request = HTTPRequest.new()
				add_child(http_request)
				http_request.request_completed.connect(_http_request_downloaded_file_body)
			
				http_request.request(game_resource.source)
			
			elif _current_action == 'unzip':
				unzip_game_resource()
	else:
		installation_complete()
	

func installation_complete():
	print(game_resource_name)
	GameResourcesInstallLogic._game_resource_installed(game_resource_name)
	queue_free()
	
	
func next_action():
	var _len_of_actions_array : int = len(game_resource.actions)
	if _len_of_actions_array > 0:
		game_resource.actions.pop_at(0)
		if _len_of_actions_array > 0:
			install_game_resources()
	else:
		installation_complete()
	

func _http_request_downloaded_file_body(result, response_code, headers, body):
	var _file_path = File2ool.create_path([DownloadedContent, game_resource_name + '.sg2downloaded'])
	var file = FileAccess.open(_file_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(body)
		file.close()
	
	game_resource.source = _file_path
	next_action()
	
		
func _change_source_file_extension(source, new_extension):
	var _file_extension = File2ool.get_file_extension(source)
	if not _file_extension == null and not 'sg2' in _file_extension:
		game_resource.source = File2ool.change_file_extension(source, new_extension)
	else:
		game_resource.source = File2ool.add_file_extension(source, new_extension)
		

func unzip_game_resource():
	ZipArchiver.unpack(game_resource.source, File2ool.create_path([DownloadedContent, game_resource_name]), Callable(self, '_unpacking_game_resource_result'))
	
	
func _unpacking_game_resource_result(result):
	if result.elements_iteration == len(result.list_of_archive_parts):
		game_resource.source = File2ool.create_path([DownloadedContent, game_resource_name])
		next_action()
