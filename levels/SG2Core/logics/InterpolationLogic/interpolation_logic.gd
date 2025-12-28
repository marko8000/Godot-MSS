@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
class_name InterpolationLogic


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic


@export_category('Interpolation Settings')
## Interpolation is used to make smooth movements in guest side if server rarely sends states updates
var server_FPS : int = 1
var guest_FPS : int = 1

func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		if Engine.get_frames_per_second() > server_FPS:
			server_FPS = Engine.get_frames_per_second()
	elif _ConnectionLogic.peer_role == 'guest':
		if Engine.get_frames_per_second() > guest_FPS:
			guest_FPS = Engine.get_frames_per_second()
