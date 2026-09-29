extends MSSLogic
class_name PlayerInput


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityInterest := EntityStorageLogic.get_from(self)._EntityInterest
@onready var _MultiplayerInput := _MSSCore._MultiplayerInput

var peer_indices : PackedInt32Array
func _process(delta: float) -> void:
	if get_parent().name.is_valid_int:
		var entity_idx := int(get_parent().name)
		if _EntityInterest._player_sparse_array[entity_idx]:
			var new_peer_indices := _EntityInterest._player_entity_data[_EntityInterest._player_sparse_array[entity_idx]].peer_indices
			for peer_idx : int in peer_indices:
				if not new_peer_indices.has(peer_idx):
					_MultiplayerInput.disconnect_from(_on_peer_input, peer_idx)
			for peer_idx : int in new_peer_indices:
				if not peer_indices.has(peer_idx):
					peer_indices.append(peer_idx)
					_MultiplayerInput.connect_to(_on_peer_input, peer_idx)
	
	
signal player_input(event : PlayerInputEvent)
		
func _on_peer_input(event : PlayerInputEvent):
	player_input.emit(event)
