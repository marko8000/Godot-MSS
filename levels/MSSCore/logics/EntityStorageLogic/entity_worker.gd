extends RefCounted
class_name EntityWorker


var thread := Thread.new()
var running := true


func start() -> void:
	thread.start(_run)
	
	
func _run() -> void:
	while running:
		_process()
		
		
func stop() -> void:
	running = false
	
	if thread.is_started():
		thread.wait_to_finish()
		

func _process() -> void:
	pass
