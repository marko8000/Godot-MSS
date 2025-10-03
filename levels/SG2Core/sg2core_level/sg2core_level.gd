@icon('res://levels/SG2Core/x_res/x_images/level_icon.png')
extends Node


# Strongly recomended to use one game instance for one server.


var is_level

signal stop


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func giveo(object_name):
	if object_name == 'ConnectionLogic':
		return $Logics/ConnectionLogic
	elif object_name == 'AuthLogic':
		return $Logics/AuthLogic
	elif object_name == 'MultiplayerLogic':
		return $Logics/MultiplayerLogic
	elif object_name == 'DirectoriesPathsDistributor':
		return $Logics/DirectoriesPathsDistributor
	elif object_name == 'GameResourcesInstallLogic':
		return $Logics/GameResourcesInstallLogic
	elif object_name == 'EntitiesLogic':
		return $Logics/EntitiesLogic
	elif object_name == 'entities_storage':
		return $entities_storage
	elif object_name == 'ChunksCalculator':
		return $Logics/ChunksCalculator
	elif object_name == 'PlayersActionsLogic':
		return $Logics/PlayersActionsLogic
	elif object_name == 'InterpolationLogic':
		return $Logics/InterpolationLogic
	else:
		Debug.dprint('Failed to find object:' + object_name, self.name)
