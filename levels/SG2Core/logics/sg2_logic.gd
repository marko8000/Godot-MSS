@icon('res://levels/SG2Core/x_res/x_images/sg_logo_light.svg')
class_name SG2Logic
extends Node


@warning_ignore("unused_private_class_variable")
@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
