@tool
extends Node
class_name PlayerInput


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level()
@onready var _PlayersActionsLogic := _SG2Core._PlayersActionsLogic
@onready var _Observer : Observer = $'../Observer'


func _get_configuration_warnings():
	var warnings = []
	var has_observer = false
	for child in get_parent().get_children():
		if child is Observer:
			has_observer = true
	if not has_observer:
		warnings.append('PlayerInput must be child of Node with Observer')
	return warnings


func get_PlayerActions():
	return _PlayersActionsLogic.get_PlayerActions(_Observer.player_type, _Observer.id)
	
	
	
