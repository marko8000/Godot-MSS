@tool
class_name PageContainer
extends Control


@export_tool_button('Add page', "Add") var b_add_page = add_page
@export var current_page : Control :
	set(page):
		if page == current_page:
			return
		if page and page.get_parent() == self:
			for child in get_children():
				if child == page:
					continue
				child.hide()
			page.show()
			current_page = page
@export var page_link_button : Dictionary[BaseButton, Control]		
var _backup_links_buttons : Dictionary[NodePath, BaseButton]
var _backup_links_connections : Dictionary[NodePath, NodePath]
var _backup_links_pages : Dictionary[NodePath, Control]


func add_page(base_name : String = 'Page') -> Control:
	var _page = ScrollContainer.new()
	g.rename_unique(_page, self, base_name)
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	_page.owner = get_tree().edited_scene_root
	return _page
	
	
func change_page(page_name : String):
	if has_node(page_name):
		current_page = get_node(page_name)
		
		
func _ready():
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
		_backup_links()
		connect_page_link_button()
	else:
		connect_page_link_button()
		
		
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_backup_links()
		_process_backup_links()
		_process_deletion()
	
	
func connect_page_link_button():
	for button in page_link_button.keys():
		if button and button is BaseButton:
			if button.pressed.is_connected(_on_any_button_pressed):
				button.pressed.disconnect(_on_any_button_pressed)
			var target_page = page_link_button[button]
			button.pressed.connect(_on_any_button_pressed.bind(target_page))


func _on_selection_changed():
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if not selected.is_empty():
		var select = selected[0]
		if select.get_parent() == self:
			current_page = select
		elif select is BaseButton:
			if select in page_link_button:
				if is_instance_valid(page_link_button[select]):
					current_page = page_link_button[select]
		
		
func _on_any_button_pressed(target_page : Control):
	current_page = target_page


func _backup_links():
	for btn : BaseButton in page_link_button:
		var btn_path : NodePath
		if not is_instance_valid(btn) or not is_instance_valid(btn.owner):
			continue
		else:
			btn_path = get_path_to(btn)
			_backup_links_buttons[btn_path] = btn
		var page := page_link_button[btn]
		var page_path : NodePath
		if not is_instance_valid(page) or not is_instance_valid(page.owner):
			continue
		else:
			page_path = get_path_to(page)
			_backup_links_pages[page_path] = page
		_backup_links_connections[btn_path] = page_path
	
	
func _process_backup_links():
	for path : NodePath in _backup_links_buttons.keys():
		
		if not has_node(path):
			_backup_links_buttons.erase(path)
			_backup_links_connections.erase(path)
		elif get_node(path) != _backup_links_buttons[path]:
			_backup_links_buttons[path] = get_node(path)
			page_link_button[_backup_links_buttons[path]] = _backup_links_pages[_backup_links_connections[path]]
			connect_page_link_button()
				


func _process_deletion():
	for btn in page_link_button:
		if not is_instance_valid(btn) or not is_instance_valid(btn.owner):
			page_link_button.erase(btn)
	page_link_button.erase(null)
	_backup_links_buttons.erase('')
	_backup_links_connections.erase('')
	_backup_links_pages.erase('')
	for page_path in _backup_links_pages:
		if not has_node(page_path):
			_backup_links_pages.erase(page_path)
