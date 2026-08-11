@tool
extends SG2Logic
class_name PlayerInput


var _PlayerActionsLogic : PlayerActionsLogic

var player_id_node : PlayerIdNode

signal peer_input(event : PlayerInputEvent)


func _ready() -> void:
	_PlayerActionsLogic = _SG2Core._PlayerActionsLogic
	get_parent().child_entered_tree.connect(_on_child_entered_tree)
	for child in get_parent().get_children():
		_on_child_entered_tree(child)
	

func _on_child_entered_tree(node : Node):
	if node is PlayerIdNode:
		node.peer_id_changed.connect(_on_player_peer_id_changed)
		_on_player_peer_id_changed(node.peer_id)
	
	
var player_input_event : PlayerInputEvent
func _on_player_peer_id_changed(peer_id: Variant) -> void:
	var new_player_input_event := _PlayerActionsLogic.get_PlayerActions(peer_id)
	if player_input_event and player_input_event.peer_input.is_connected(_on_peer_input):
		player_input_event.peer_input.disconnect(_on_peer_input)
	player_input_event = new_player_input_event
	player_input_event.peer_input.connect(_on_peer_input)
		
		
func _on_peer_input(event : PlayerInputEvent):
	peer_input.emit(event)
