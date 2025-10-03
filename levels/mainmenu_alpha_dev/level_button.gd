extends HBoxContainer


var level_name : String
var developer : String


func _ready() -> void:
	$Icon.texture_normal = load('res://levels/SG2Core/x_res/x_images/sg_logo_icon.svg')
	$VBoxContainer/LevelNameLabel.text = level_name
	$VBoxContainer2/DeveloperLabel.text = developer
	

func load_level():
	$'../../../'.load_level(level_name)


func _on_icon_pressed() -> void:
	load_level()


func _on_texture_button_pressed() -> void:
	load_level()
