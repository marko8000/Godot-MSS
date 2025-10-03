@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node



@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var MultiplayerLogic = SG2Core.giveo('MultiplayerLogic')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')


@onready var DownloadedContent = DirectoriesPathsDistributor.give_path("DownloadedContent")

@onready var GameResourcesInstallLogic_dir = FilesManager.create_path([DirectoriesPathsDistributor.give_path('SavesLogics_dir'), 'GameResourcesInstallLogic'])
@onready var installer_game_resources_scene_path = FilesManager.create_path([GameResourcesInstallLogic_dir, 'installer_game_resources/installer_game_resources.tscn'])


@onready var game_resources : Dictionary = {'test_game_resource': {'source': 'https://png.pngtree.com/png-vector/20221217/ourmid/pngtree-example-sample-grungy-stamp-vector-png-image_15560590.png', 'actions': ['http_download_file_from_body', ['change_extension', 'png']]},
											'test_game_resource1': {'source': 'user://ServersDataSaves/SG2CoreServer/DownloadedContent/test_game_resource1.zip', 'actions': ['unzip']}}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)		


func install_game_resources():
	for game_resource in game_resources:
		game_resources[game_resource].installed = false
		install_game_resource(game_resource, game_resources[game_resource])
		

func install_game_resource(game_resource_name, game_resource):
	var installer_game_resources_file = load(installer_game_resources_scene_path)
	
	var installer_game_resources_instance = installer_game_resources_file.instantiate()
	installer_game_resources_instance.game_resource_name = game_resource_name
	installer_game_resources_instance.game_resource = game_resource.duplicate()
	installer_game_resources_instance.game_resource.erase('installed')
	
	add_child(installer_game_resources_instance)


func _game_resource_installed(game_resource_name):
	game_resources[game_resource_name].installed = true
	for game_resource in game_resources:
		if not game_resources[game_resource].installed:
			return
	rpc_id(1, '_all_game_resources_installed')


@rpc("any_peer")
func _all_game_resources_installed():
	var _player_id = multiplayer.get_remote_sender_id()
	MultiplayerLogic._player_installed_game_resources(_player_id)


func send_game_resources_to_player(player_id):
	rpc_id(player_id, 'give_game_resources', game_resources)
	

@rpc("authority")
func give_game_resources(given_game_resources):
	game_resources = given_game_resources
	install_game_resources()
