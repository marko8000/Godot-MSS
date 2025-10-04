extends Node


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var EntitiesLogic = SG2Core.giveo('EntitiesLogic')


var actions : Dictionary
var player_info : Dictionary
var sleep : bool = false
signal input
var old_actions : Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EntitiesLogic.summon_entity(Vector2i(0, 0), [{'name': 'CharacterBody3D_FPS', 'player_actions_info': player_info.duplicate()}])


func _process(delta: float) -> void:
	if actions != old_actions:
		old_actions = actions
		input.emit()
	
	
func is_action_just_pressed(action : String):
	if action in actions:
		if 'just_pressed' in actions[action]:
			return true
	return false
	
	
func is_action_pressed(action : String):
	if action in actions:
		if 'pressed' in actions[action]:
			return true
	return false
	
	
func is_action_just_released(action : String):
	if action in actions:
		if 'just_released' in actions[action]:
			return true
	return false
	
	
func get_vector(negative_x: String, positive_x: String, negative_y: String, positive_y: String):
	var _vector : Vector2
	if is_action_pressed(negative_x):
		_vector.x -= 1
	if is_action_pressed(positive_x):
		_vector.x += 1
	if is_action_pressed(negative_y):
		_vector.y -= 1
	if is_action_pressed(positive_y):
		_vector.y += 1
	return _vector
