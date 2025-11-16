@icon('res://levels/SG2Core/x_res/x_images/level_icon.png')
extends Node
class_name SG2Core


# Strongly recomended to use one game instance for one server.


var is_level

@export var _ConnectionLogic : ConnectionLogic
@export var _AuthLogic : AuthLogic
@export var _MultiplayerLogic : MultiplayerLogic
@export var _DirectoriesPathsDistributor : DirectoriesPathsDistributor
@export var _EntitiesLogic : EntitiesLogic
@export var _entities_storage : Node
@export var _ChunksCalculator : ChunksCalculator
@export var _PlayersActionsLogic : PlayersActionsLogic
@export var _InterpolationLogic : InterpolationLogic

signal stop


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
