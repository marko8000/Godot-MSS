extends Panel


func _process(delta: float) -> void:
	if has_node('Control'):
		$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
func _on_back_pressed() -> void:
	get_node('Control').queue_free()
	$'../'.change_page('GameContentPage')
