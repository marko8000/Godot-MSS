@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@export_category('Interpolation Settings')
## Interpolation is used to make smooth movements in guest side if server FPS is lower than guest FPS
@export var interpolation : bool = false
## Guest need time to automatically count server FPS, this parameter allow smooth movements from start
@export var server_FPS : int = 0
var supposed_server_FPS : int = 0 # guest
