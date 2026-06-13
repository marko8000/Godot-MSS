@tool
@icon('res://nodes/AdaptiveTabContainer/AdaptiveTabContainer.svg')
class_name AdaptiveTabContainer
extends BoxContainer


@export_tool_button("Add tab", "Add") var b_add_tab = add_tab
@export var tabs_visible : bool = true
@export_category('LandscapeTabs')
@export var landscape_tabs_alignment : LandscapeAdaptiveTabAlignment = LandscapeAdaptiveTabAlignment.TOP
enum LandscapeAdaptiveTabAlignment {TOP, CENTER, FILL, BOTTOM}
@export var landscape_tabs_position : LandscapeAdaptiveTabPosition = LandscapeAdaptiveTabPosition.LEFT
enum LandscapeAdaptiveTabPosition {LEFT, RIGHT}
@export var icon_alignment_landscape : HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
@export var vertical_icon_alignment_landscape : VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
@export_category('PortraitTabs')
@export var portrait_tabs_alignment : PortraitAdaptiveTabAlignment = PortraitAdaptiveTabAlignment.CENTER
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
@export_category('Nodes config')
@export var tab_buttons : BoxContainer
@export var page_container : PageContainer

enum UIOrientation {landscape, portrait}


func add_tab():
	var btn = Button.new()
	g.rename_unique(btn, tab_buttons, 'Button')
	btn.toggle_mode = true
	tab_buttons.add_child(btn)
	btn.owner = get_tree().edited_scene_root
	
	var page = page_container.add_page('Tab')
	page_container.page_link_button[btn] = page
	
	
func _ready() -> void:
	if not tab_buttons:
		var instance := BoxContainer.new()
		instance.name = 'TabButtons'
		add_child(instance)
		instance.owner = get_tree().edited_scene_root
		tab_buttons = instance
	if not page_container:
		var instance = PageContainer.new()
		instance.name = 'PageContainer'
		instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(instance)
		instance.owner = get_tree().edited_scene_root
		page_container = instance
		
		
func _process(delta: float) -> void:
	update()
	
	
func update():
	if not is_instance_valid(tab_buttons) or not is_instance_valid(page_container):
		return
	
	tab_buttons.visible = tabs_visible
			
	for btn : BaseButton in page_container.page_link_button:
		btn.button_pressed = page_container.page_link_button[btn] == page_container.current_page
			
	var ui_orientation : UIOrientation
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
			
	vertical = ui_orientation == UIOrientation.portrait
	tab_buttons.vertical = not ui_orientation == UIOrientation.portrait
	
	for button : Control in tab_buttons.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	match ui_orientation:
		UIOrientation.landscape:
			for btn : BaseButton in page_container.page_link_button:
				if is_instance_valid(btn) and btn is Button:
					btn.icon_alignment = icon_alignment_landscape
					btn.vertical_icon_alignment = vertical_icon_alignment_landscape
			match landscape_tabs_position:
				LandscapeAdaptiveTabPosition.LEFT:
					move_child(tab_buttons, 0)
				LandscapeAdaptiveTabPosition.RIGHT:
					move_child(tab_buttons, -1)
			tab_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			match landscape_tabs_alignment:
				LandscapeAdaptiveTabAlignment.TOP:
					tab_buttons.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				LandscapeAdaptiveTabAlignment.CENTER:
					tab_buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				LandscapeAdaptiveTabAlignment.FILL:
					tab_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
				LandscapeAdaptiveTabAlignment.BOTTOM:
					tab_buttons.size_flags_vertical = Control.SIZE_SHRINK_END
		UIOrientation.portrait:
			for btn : BaseButton in page_container.page_link_button:
				if is_instance_valid(btn) and btn is Button:
					btn.icon_alignment = icon_alignment_portrait
					btn.vertical_icon_alignment = vertical_icon_alignment_portrait
			match portrait_tabs_position:
				PortraitAdaptiveTabPosition.TOP:
					move_child(tab_buttons, 0)
				PortraitAdaptiveTabPosition.BOTTOM:
					move_child(tab_buttons, -1)
			tab_buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			match portrait_tabs_alignment:
				PortraitAdaptiveTabAlignment.LEFT:
					tab_buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				PortraitAdaptiveTabAlignment.CENTER:
					tab_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				PortraitAdaptiveTabAlignment.FILL:
					tab_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				PortraitAdaptiveTabAlignment.RIGHT:
					tab_buttons.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	
func _get_configuration_warnings():
	var warnings = []
	if not is_instance_valid(tab_buttons):
		warnings.append('Node config category: Tab Buttons not assigned')
	if not is_instance_valid(page_container):
		warnings.append('Node config category: Page Container not assigned')
	return warnings
