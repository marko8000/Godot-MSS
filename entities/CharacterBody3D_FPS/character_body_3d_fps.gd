extends CharacterBody3D


@onready var _ConnectionLogic := ConnectionLogic.get_from(self)
@onready var _EntityStorage := EntityStorage.get_from(self)

const WALKING_SPEED = 1.5
const SLOW_SHIFT_SPEED = 3
const FAST_SHIFT_SPEED = 7
const JUMP_VELOCITY = 6
const ROTATION_SPEED = 0.0006
var sensitivity := 0

var direction : Vector3
var current_speed : float
	

func _physics_process(delta: float) -> void:
	var camera : FPSCamera3D = _EntityStorage.get_node('FPSCamera3D')
	if _ConnectionLogic.is_player(self):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		camera.target = get_node('cam')
		camera.make_current()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		camera.target = null
	
	if _ConnectionLogic.peer_role == 'guest':
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	_process_raycast()
	

@onready var raycast : RayCast3D = $cam/RayCast3D
var raycast_body : Node
func _process_raycast() -> void:
	raycast_body = raycast.get_collider()
		

var mouse_rotation = Vector2.ZERO
func _on_player_input_peer_input(event: PlayerInputEvent) -> void:
	if is_on_floor() and event.is_action_just_pressed("jump"):
		velocity.y += JUMP_VELOCITY
			
	# Handle movement speed
	if event.is_action_pressed('slow_shift'):
		current_speed = SLOW_SHIFT_SPEED
	elif event.is_action_pressed('fast_shift'):
		current_speed = FAST_SHIFT_SPEED
	else:
		current_speed = WALKING_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = event.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle mouse rotation
	if event.actions.has('mouse_relative'):
		var mouse_relative = event.actions.mouse_relative[0]
		mouse_rotation.y -= mouse_relative.x * ROTATION_SPEED
		mouse_rotation.x -= mouse_relative.y * ROTATION_SPEED
		if mouse_rotation.x < -1.4: mouse_rotation.x = -1.4
		elif mouse_rotation.x > 1.4: mouse_rotation.x = 1.4
		transform.basis = Basis(Vector3.UP, mouse_rotation.y)
		$cam.transform.basis = Basis(Vector3.RIGHT, mouse_rotation.x)
		
	if event.is_action_pressed("break"):
		pass
	if event.is_action_just_pressed('place'):
		pass 
