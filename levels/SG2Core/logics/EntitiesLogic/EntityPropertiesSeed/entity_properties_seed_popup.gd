@tool
extends Window


func _process(delta: float) -> void:
	for _page in $Pages.get_children():
		if _page.visible:
			size = _page.size
	
	
func page(page_name):
	for _page in $Pages.get_children():
		_page.hide()
	$Pages.get_node(page_name).show()
	

func _on_close_requested() -> void:
	queue_free()


var entity_type : String
var _showed_entities := false
func _on_navigate_button_pressed() -> void:
	if not _showed_entities:
		FilesManager.file_system_dock_navigate_to('res://entities/'+entity_type)
	else:
		FilesManager.file_system_dock_navigate_to('res://entities')
	_showed_entities = !_showed_entities
