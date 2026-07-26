@tool
class_name AdaptiveBoxContainer
extends BoxContainer

@export var adaptation_mode : AdaptationMode = AdaptationMode.x
enum AdaptationMode { x, y }


func _process(delta: float) -> void:
	_update()

func _update() -> void:
	var parent := get_parent()
	if not parent is Control:
		return
	
	var _psize = size - Vector2(get_theme_constant("separation"), get_theme_constant("separation"))
	var _min := Vector2.ZERO  
	  
	for child in get_children():
		_min += child.get_combined_minimum_size()
  
	var new_vertical: bool
	
	match adaptation_mode:  
		AdaptationMode.x:  
			new_vertical = _min.x >= _psize.x  
		AdaptationMode.y:  
			new_vertical = _min.y >= _psize.y  
	
	if new_vertical != vertical:  
		vertical = new_vertical
		
		
func _get_configuration_warnings() -> PackedStringArray:
	var _warnings : PackedStringArray
	
	for child in get_children():
		var warning = 'Child node "{0}" has combined minimum size {1}'.format([child.name, child.get_combined_minimum_size()])
		if child.get_combined_minimum_size()[child.get_combined_minimum_size().min_axis_index()] == 0:
			_warnings.append(warning)
	return _warnings
