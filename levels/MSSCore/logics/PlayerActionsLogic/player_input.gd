extends MSSLogic
class_name PlayerInput


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _ObserverSystem := _MSSCore._ObserverSystem
@onready var _PlayerActionsLogic := _MSSCore._PlayerActionsLogic

var peer_indices : PackedInt32Array
func _process(delta: float) -> void:
	if get_parent().name.is_valid_int:
		var entity_idx := int(get_parent().name)
		var current_peer_idx := _ConnectionLogic.current_peer_idx
		if _ObserverSystem._player_sparse_array[entity_idx]:
			var new_peer_indices := _ObserverSystem._player_entity_data[_ObserverSystem._player_sparse_array[entity_idx]].peer_indices
			for peer_idx in peer_indices:
				if not new_peer_indices.has(peer_idx):
					_PlayerActionsLogic.get_PlayerInputEvent(peer_idx).peer_input.disconnect(_on_peer_input)
			for peer_idx in new_peer_indices:
				if not peer_indices.has(peer_idx):
					peer_indices.append(peer_idx)
					_PlayerActionsLogic.get_PlayerInputEvent(peer_idx).peer_input.connect(_on_peer_input)
	
	
signal peer_input(event : PlayerInputEvent)
		
func _on_peer_input(event : PlayerInputEvent):
	peer_input.emit(event)
