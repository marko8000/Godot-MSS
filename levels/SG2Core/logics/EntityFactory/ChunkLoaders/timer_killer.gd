extends Timer
class_name TimerKiller


func _init() -> void:
	timeout.connect(_on_timeout)
	

func _on_timeout():
	get_parent().queue_free()
	
