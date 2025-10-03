extends Node


var delay_at_start : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Vin17\'s Games')
	print('SurvGos 2\n')
	if delay_at_start == true:
		var delay = 0
		while delay < 10 ** 7.5:
			delay += 1
	ExecManager.change_exec_to('sg2vin17_exec')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
