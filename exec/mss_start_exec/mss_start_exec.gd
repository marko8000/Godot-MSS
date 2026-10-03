extends Exec


var delay_at_start : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('https://github.com/marko8000/Godot-MSS')
	print('Godot MSS\n')
	if delay_at_start == true:
		var delay = 0
		while delay < 10 ** 7.5:
			delay += 1
	ExecManager.change_exec_to('mss_exec', self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
