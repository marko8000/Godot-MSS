@tool
extends Window


func _process(delta: float) -> void:
	size = $PageContainer.current_page.get_child(0).get_combined_minimum_size()
	

func _on_close_requested() -> void:
	queue_free()


var entity_type : String
var _showed_entities := false
func _on_navigate_button_pressed() -> void:
	if not _showed_entities:
		File2ool.file_system_dock_navigate_to('res://entities/'+entity_type)
	else:
		File2ool.file_system_dock_navigate_to('res://entities')
	_showed_entities = !_showed_entities
