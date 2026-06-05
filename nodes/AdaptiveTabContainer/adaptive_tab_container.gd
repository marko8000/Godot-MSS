@tool
extends HBoxContainer


@export var current_tab : int = 0
@export var tabs_visible : bool = true
@export_category('HorisontalTabs')
@export var horisontal_tab_alignment : HorizontalAdaptiveTabAlignment = HorizontalAdaptiveTabAlignment.CENTER
enum HorizontalAdaptiveTabAlignment {LEFT, CENTER, RIGHT}
@export var horisontal_tabs_position : HorizontalAdaptiveTabPosition = HorizontalAdaptiveTabPosition.BOTTOM
enum HorizontalAdaptiveTabPosition {TOP, BOTTOM}
@export_category('VerticalTabs')
@export var vertical_tabs_alignment : VerticalAdaptiveTabAlignment = VerticalAdaptiveTabAlignment.TOP
enum VerticalAdaptiveTabAlignment {TOP, CENTER, BOTTOM}
@export var vertical_tabs_position : VerticalAdaptiveTabPosition = VerticalAdaptiveTabPosition.LEFT
enum VerticalAdaptiveTabPosition {LEFT, RIGHT}
@export_category('Adaptation')
@export var adaptation_mode : AdaptationMode = AdaptationMode.AUTO
enum AdaptationMode {
	AUTO,
	FORCE_HORIZONTAL,
	FORCE_VERTICAL
}


func _on_child_entered_tree(node: Node) -> void:
	if not str(node.name) in 'TabsLeft VBoxContainer TabsRight'.split(' '):
		print(node.name)
