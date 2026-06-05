extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 10
const ROTATION_SPEED = 0.003


@onready var voxel_lod_terrain = $"../VoxelLodTerrain"
@onready var voxel_tool = voxel_lod_terrain.get_voxel_tool()
@onready var ray_cast = $'Camera3D/RayCast3D'


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	var target_pos = ray_cast.get_collision_point()
	if not ray_cast.is_colliding():
		target_pos = ray_cast.global_position-ray_cast.global_basis.z*5
	if Input.is_action_pressed("break"):
		voxel_tool.mode = VoxelTool.MODE_REMOVE
		voxel_tool.grow_sphere(target_pos, 2, .2)
	if Input.is_action_pressed("place"):
		voxel_tool.mode = VoxelTool.MODE_ADD
		voxel_tool.grow_sphere(target_pos, 2, .2)
		
		voxel_tool.mode = VoxelTool.MODE_TEXTURE_PAINT
		voxel_tool.do_sphere(target_pos, 2.5)
	if Input.is_action_just_pressed('ui_right'):
		voxel_tool.texture_index = posmod(voxel_tool.texture_index+1,3)
		


var rot = Vector2.ZERO
func _input(e) -> void:
	if e is InputEventMouseMotion:
		rot.y -= e.relative.x * ROTATION_SPEED
		rot.x -= e.relative.y * ROTATION_SPEED
		if rot.x < -1.2: rot.x = -1.2
		elif rot.x > 1.2: rot.x = 1.2
		transform.basis = Basis(Vector3.UP, rot.y)
		$Camera3D.transform.basis = Basis(Vector3.RIGHT, rot.x)
