extends Node3D


var is_block
@export var HP := 100


# recommended impact_parametres keys: guaranteed_damage, sharp, temperature
func destroy(impact_parametres : Dictionary):
	var damage : float
	if 'guaranteed_damage' in impact_parametres:
		damage += impact_parametres.guaranteed_damage
	if 'sharp' in impact_parametres:
		pass
	if 'temperature' in impact_parametres:
		pass
		
	HP -= damage
	if HP <= 0:
		queue_free()
	get_EntityLogic().processing()


func get_EntityLogic():
	return $EntityLogic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


@onready var old_position = global_position
@onready var old_rotation = global_rotation
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if old_position != global_position or old_rotation != global_rotation:
		get_EntityLogic().processing()
	old_position = global_position
	old_rotation = global_rotation
	
