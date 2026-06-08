@tool
@icon('res://nodes/AdaptiveTabContainer/AdaptiveTabContainer.svg')
extends HBoxContainer


@export var current_tab: int = -1
@export var tabs_visible : bool = true
@export_category('LandscapeTabs')
@export var landscape_tabs_alignment : LandscapeAdaptiveTabAlignment = LandscapeAdaptiveTabAlignment.TOP
enum LandscapeAdaptiveTabAlignment {TOP, CENTER, FILL, BOTTOM}
@export var landscape_tabs_position : LandscapeAdaptiveTabPosition = LandscapeAdaptiveTabPosition.LEFT
enum LandscapeAdaptiveTabPosition {LEFT, RIGHT}
@export var icon_alignment_landscape : HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
@export var vertical_icon_alignment_landscape : VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
@export_category('PortraitTabs')
@export var portrait_tab_alignment : PortraitAdaptiveTabAlignment = PortraitAdaptiveTabAlignment.CENTER
enum PortraitAdaptiveTabAlignment {LEFT, CENTER, FILL, RIGHT}
@export var portrait_tabs_position : PortraitAdaptiveTabPosition = PortraitAdaptiveTabPosition.TOP
enum PortraitAdaptiveTabPosition {TOP, BOTTOM}
@export var icon_alignment_portrait : HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
@export var vertical_icon_alignment_portrait : VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
@export_category('Adaptation')
@export var adaptation_mode : AdaptationMode = AdaptationMode.AUTO
enum AdaptationMode {
	AUTO,
	FORCE_LANDSCAPE,
	FORCE_PORTRAIT
}
@export_range(0.01, 10, 0.1, "suffix:s") var tab_update_interval : float = 0.1 :
	set(value):
		tab_update_interval = value
		if $Timer:
			$Timer.wait_time = value
enum UIOrientation {landscape, portrait}
var _blacklist : PackedStringArray = 'TabsLeft VBoxContainer TabsRight Timer'.split(' ')

var _tabs : Dictionary[int, BaseButton]
var _visible_tabs : Dictionary[int, BaseButton]
var _pages : Dictionary[int, Control]


func _ready() -> void:
	$Timer.start()
	reset_tabs()
	_update()
	
	
func _on_child_entered_tree(node: Node) -> void:
	if not str(node.name) in _blacklist:
		if node is BaseButton:
			node.hide()
			node.toggle_mode = true
			_tabs[node.get_instance_id()] = node
		else:
			node.queue_free()
	

func _on_timer_timeout() -> void:
	if Engine.is_editor_hint():
		reset_tabs()
	_update()


func reset_tabs():
	for container : BoxContainer in [$TabsLeft, $TabsRight, $VBoxContainer/TabsBottom, $VBoxContainer/TabsTop]:
		for child : Node in container.get_children():
			child.queue_free()
	for page in $VBoxContainer/Panel.get_children():
		page.queue_free()
			

var _container : BoxContainer
func _update():
	var ui_orientation : UIOrientation
	if size.x > size.y:
		ui_orientation = UIOrientation.landscape
	else:
		ui_orientation = UIOrientation.portrait
	match adaptation_mode:
		AdaptationMode.AUTO:
			if size.x > size.y:
				ui_orientation = UIOrientation.landscape
			else:
				ui_orientation = UIOrientation.portrait
		AdaptationMode.FORCE_LANDSCAPE:
			ui_orientation = UIOrientation.landscape
		AdaptationMode.FORCE_PORTRAIT:
			ui_orientation = UIOrientation.portrait
	
	var _pos = {UIOrientation.landscape: landscape_tabs_position, 
	UIOrientation.portrait: portrait_tabs_position
	}[ui_orientation]
	var _container_cfg : Dictionary[Vector2i, BoxContainer] = {
		Vector2i(UIOrientation.landscape, LandscapeAdaptiveTabPosition.LEFT): $TabsLeft,
		Vector2i(UIOrientation.landscape, LandscapeAdaptiveTabPosition.RIGHT): $TabsRight,
		Vector2i(UIOrientation.portrait, PortraitAdaptiveTabPosition.TOP): $VBoxContainer/TabsTop,
		Vector2i(UIOrientation.portrait, PortraitAdaptiveTabPosition.BOTTOM): $VBoxContainer/TabsBottom
	}
	_container = _container_cfg[Vector2i(ui_orientation, _pos)]
	var _dir : Orientation = HORIZONTAL if _container in [$VBoxContainer/TabsTop, $VBoxContainer/TabsBottom] else VERTICAL
	var _h_flags_cfg : Dictionary[PortraitAdaptiveTabAlignment, SizeFlags] = {
		PortraitAdaptiveTabAlignment.LEFT: SizeFlags.SIZE_SHRINK_BEGIN,
		PortraitAdaptiveTabAlignment.CENTER: SizeFlags.SIZE_SHRINK_CENTER,
		PortraitAdaptiveTabAlignment.FILL: SizeFlags.SIZE_FILL,
		PortraitAdaptiveTabAlignment.RIGHT: SizeFlags.SIZE_SHRINK_END
	}
	var _v_flags_cfg : Dictionary[LandscapeAdaptiveTabAlignment, SizeFlags] = {
		LandscapeAdaptiveTabAlignment.TOP: SizeFlags.SIZE_SHRINK_BEGIN,
		LandscapeAdaptiveTabAlignment.CENTER: SizeFlags.SIZE_SHRINK_CENTER,
		LandscapeAdaptiveTabAlignment.FILL: SizeFlags.SIZE_FILL,
		LandscapeAdaptiveTabAlignment.BOTTOM: SizeFlags.SIZE_SHRINK_END
	}
	var _flag : SizeFlags= {HORIZONTAL: _h_flags_cfg[portrait_tab_alignment], VERTICAL: _v_flags_cfg[landscape_tabs_alignment]}[_dir]
	
	match _dir:
		HORIZONTAL:
			_container.size_flags_horizontal = _flag
		VERTICAL:
			_container.size_flags_vertical = _flag
	
	_container.visible = tabs_visible
	for id : int in _tabs.keys():
		if not is_instance_valid(_tabs[id]):
			_visible_tabs[id].queue_free()
			_tabs.erase(id)
			_visible_tabs.erase(id)
			_pages.erase(id)
			current_tab -= 1
			continue
		var tab := _tabs[id]
		if Engine.is_editor_hint() or (not Engine.is_editor_hint() and not _visible_tabs.has(id)):
			var _dupl : BaseButton = tab.duplicate(
				Node.DUPLICATE_SIGNALS |
				Node.DUPLICATE_GROUPS |
				Node.DUPLICATE_SCRIPTS |
				Node.DUPLICATE_USE_INSTANTIATION
			)
			for child in _dupl.get_children():
				_dupl.remove_child(child)
				child.queue_free()
			_dupl.pressed.connect(_on_tab_pressed.bind(_dupl))
			_dupl.show()
			_container.add_child(_dupl)
			_visible_tabs[id] = _dupl
			
			var tab_page = Control.new()
			tab_page.set_anchors_preset(Control.PRESET_FULL_RECT)
			tab_page.name = tab.name
			tab_page.hide()
			for child in tab.get_children():
				var _child_dupl := child.duplicate(
					Node.DUPLICATE_SIGNALS |
					Node.DUPLICATE_GROUPS |
					Node.DUPLICATE_SCRIPTS |
					Node.DUPLICATE_USE_INSTANTIATION
				)
				tab_page.add_child(_child_dupl)
			$VBoxContainer/Panel.add_child(tab_page)
			_pages[id] = tab_page
		else:
			_visible_tabs[id].reparent(_container)
		var visible_tab := _visible_tabs[id]
		if visible_tab is Button:
			match ui_orientation:
				UIOrientation.landscape:
					visible_tab.icon_alignment = icon_alignment_landscape
					visible_tab.vertical_icon_alignment = vertical_icon_alignment_landscape
				UIOrientation.portrait:
					visible_tab.icon_alignment = icon_alignment_portrait
					visible_tab.vertical_icon_alignment = vertical_icon_alignment_portrait
		var page := _pages[id]
		if current_tab < 0:
			tab.button_pressed = false
			page.hide()
			visible_tab.button_pressed = false
		else:
			tab.button_pressed = (tab.get_index()-len(_blacklist) == current_tab)
			visible_tab.button_pressed = (tab.get_index()-len(_blacklist) == current_tab)
			page.visible = (tab.get_index()-len(_blacklist) == current_tab)
		

func _on_tab_pressed(button: BaseButton) -> void:
	current_tab = button.get_index()
