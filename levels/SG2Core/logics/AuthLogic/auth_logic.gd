@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## AuthLogic is used verify player identification
class_name AuthLogic


#TODO
@onready var _SG2Core : SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _DirectoriesPathsDistributor := _SG2Core._DirectoriesPathsDistributor
@onready var AuthControl = $AuthControl

@onready var auth_token_file = _DirectoriesPathsDistributor.give_path('auth_token_file')
@onready var users_auth_database = _DirectoriesPathsDistributor.give_path('users_auth_database_file')
@onready var player_info_file = _DirectoriesPathsDistributor.give_path('player_info_file')

@onready var db = get_parent()

var token_length : int = 16
var token_symbols : String = 'QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm'

## Parameter online_mode allows to connect to game Store to verify player's id.
@export var online_mode : bool = false


# NOT DONE


func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	
	
#func start():
	#db.path = users_auth_database
	#db.verbosity_level = SQLite.VerbosityLevel.NORMAL
	#db.open_db()
	#var table_name: String = "users_auth"
	#var table_dict: Dictionary = {
	#"reg_id": {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
	#"player_name": {"data_type":"text", "not_null": true},
	#"password": {"data_type":"text", "not_null": true},
	#"token": {"data_type":"text", "not_null": true},
	#}
	#db.create_table(table_name, table_dict)
	#
	#
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	#start()
#
#
#func manage_loggining_in(peer_id):
	##rpc_id(peer_id, 'ask_token')
	#pass
	#
	#
#@rpc("authority")
#func ask_token(last_token_is_invalid=false):
	#if not last_token_is_invalid and FileAccess.file_exists(auth_token_file):
		#var token = FileAccess.open(auth_token_file, FileAccess.READ).get_as_text()
		#rpc_id(1, 'get_token', FilesManager.give_value_from_file_readlines(player_info_file, 'player_name'), token)
	#else:
		#rpc_id(1, 'create_token')
	#
	#
#@rpc("any_peer")
#func get_token(player_name, token : String):
	#var _player_id = multiplayer.get_remote_sender_id()
	#
	#var query = "SELECT token FROM users_auth WHERE player_name = ?;"
	#var args = [player_name]
	#var actual_token
	#if db.query_with_args(query, args) == OK:
		#if db.query_result.size() > 0:
			#actual_token = db.query_result[0]
		#else:
			#rpc_id(_player_id, 'ask_token', true)
	#else:
			#rpc_id(_player_id, 'ask_token', true)
	#if actual_token == token:
		#var new_token = generate_token()
		#query = 'UPDATE users_auth SET token = ? WHERE reg_id = ?'
		#args = [new_token, player_name]
		#db.query_with_args(query, args)
	#else:
		#rpc_id(_player_id, 'ask_token', true)
		#
#
#@rpc("any_peer")
#func create_token():
	#var _player_id = multiplayer.get_remote_sender_id()
	#rpc_id(_player_id, 'request_password')
	#
#
#@rpc('authority')
#func request_password():
	#AuthControl.show()
	#AuthControl.load_page('PasswordPage')
	#AuthControl.get_page('PasswordPage').get_node('continue').pressed.connect(_password_entered)
	#
	#
#func _password_entered():
	#rpc_id(1, 'create_token_with_password', FilesManager.give_value_from_file_readlines(player_info_file, 'player_name'), AuthControl.get_page('PasswordPage').password)
	#
	#
#@rpc('any_peer')
#func create_token_with_password(player_name, password):
	#var _player_id = multiplayer.get_remote_sender_id()
	#if len(password) > 32:
		#rpc_id(_player_id, 'ask_token', true)
	#var query = "SELECT reg_id FROM users_auth WHERE password = ?;"
	#var args = [password]
	#db.query_with_bindings(query, args)
	#var new_token = generate_token()
	#if db.query_result == []:
		#query = 'INSERT INTO users_auth (player_name, password, token)
				#VALUES (?, ?, ?);'
		#args = [player_name, password, new_token]
		#db.query_with_bindings(query, args)
	#else:
		#query = 'UPDATE users_auth SET token = ? WHERE reg_id = ?;'
		#args = [new_token, db.query_result[0]]
		#db.query_with_bindings(query, args)
	#rpc_id(_player_id, 'give_new_token', new_token)
	#
	#
#@rpc('authority')
#func give_new_token(new_token):
	#var file = FileAccess.open(auth_token_file, FileAccess.WRITE_READ)
	#file.store_string(new_token)
	#ask_token()
#
#
#func generate_token():
	#var token : String
	#for i in range(token_length):
		#token += token_symbols[randi_range(0, len(token_symbols)-1)]
	#return token
