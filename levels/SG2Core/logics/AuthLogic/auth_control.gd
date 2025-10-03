extends Control


var current_page : String
var last_page : String
	
	
func load_page(page_name):
	last_page = current_page
	current_page = page_name
	if $Panel/VBoxContainer.has_node(last_page):
		$Panel/VBoxContainer.get_node(last_page).hide()
	$Panel/VBoxContainer.get_node(current_page).show()
	if $Panel/VBoxContainer.get_node(current_page).has_method('refresh'):
		$Panel/VBoxContainer.get_node(current_page).refresh()


func get_page(page_name):
	return $Panel/VBoxContainer.get_node(page_name)
