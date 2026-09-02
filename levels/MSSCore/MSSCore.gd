@tool
@icon('res://levels/MSSCore/images/mss_icon_light.svg')
extends Node
class_name MSSCore


static func get_from(from : Node) -> MSSCore:
	return ExecManager.get_current_exec(from).get_current_level(from)
	
@export var server_name : String = 'GMSSServer':
	set(value):
		if value.is_valid_filename():
			server_name = value
		else:
			push_warning("Invalid folder name: '%s'. Change rejected." % value)


@export_group('Logics')
@warning_ignore("unused_private_class_variable")
@export var _ConnectionLogic : ConnectionLogic
@warning_ignore("unused_private_class_variable")
@export var _PlayerLifeCycle : PlayerLifecycle
@warning_ignore("unused_private_class_variable")
@export var _PathRegistry : PathRegistry
@warning_ignore("unused_private_class_variable")
@export var _EntityFactory : EntityFactory
@warning_ignore("unused_private_class_variable")
@export var _EntityStorage : EntityStorage
@warning_ignore("unused_private_class_variable")
@export var _EStorageGlobal : Node
@warning_ignore("unused_private_class_variable")
@export var _EntityInterest : EntityInterest
@warning_ignore("unused_private_class_variable")
@export var _ChunkCalculator : ChunkCalculator
@warning_ignore("unused_private_class_variable")
@export var _MultiplayerInput : MultiplayerInput
@warning_ignore("unused_private_class_variable")
@export var _InterpolationState : InterpolationState
@warning_ignore("unused_private_class_variable")
@export var _VoxelEditor : VoxelEditor
