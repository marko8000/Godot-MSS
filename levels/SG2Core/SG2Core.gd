@icon('res://levels/SG2Core/x_res/x_images/level_icon.png')
@tool
extends Node
class_name SG2Core


@export var server_name : String = 'SG2CoreServer'

@export_category('Components')
@warning_ignore("unused_private_class_variable")
@export var _ConnectionLogic : ConnectionLogic
@warning_ignore("unused_private_class_variable")
@export var _AuthLogic : AuthLogic
@warning_ignore("unused_private_class_variable")
@export var _MultiplayerLogic : MultiplayerLogic
@warning_ignore("unused_private_class_variable")
@export var _PathRegistry : PathRegistry
@warning_ignore("unused_private_class_variable")
@export var _EntitiesLogic : EntitiesLogic
@warning_ignore("unused_private_class_variable")
@export var _entities_storage : Node
@warning_ignore("unused_private_class_variable")
@export var _ChunksCalculator : ChunksCalculator
@warning_ignore("unused_private_class_variable")
@export var _PlayersActionsLogic : PlayersActionsLogic
@warning_ignore("unused_private_class_variable")
@export var _InterpolationLogic : InterpolationLogic
@warning_ignore("unused_private_class_variable")
@export var _VoxelEditor : VoxelEditor
	

func _process(delta: float) -> void:
	for symbol in '.:@/\"%':
		if server_name.find(symbol) != -1:
			server_name = server_name.erase(server_name.find(symbol))
