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
	

func _process(delta: float) -> void:
	var camera : FPSCamera3D = $cam/FPSCamera3D
	if _ConnectionLogic.is_player(self):
		camera.make_current()
	
	
func _physics_process(delta: float) -> void:
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
		

var input_rotation = Vector2.ZERO
func _on_player_input_player_input(event: PlayerInputEvent) -> void:
	if not UIManager.has_active_ui():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		return
		
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
	var input_dir = event.get_vector2("move")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle mouse rotation
	var event_rotation = event.get_vector2('rotate')
	input_rotation.y -= event_rotation.x * ROTATION_SPEED
	input_rotation.x -= event_rotation.y * ROTATION_SPEED
	input_rotation.x = clampf(input_rotation.x, -1.4, 1.4)
	transform.basis = Basis(Vector3.UP, input_rotation.y)
	$cam.transform.basis = Basis(Vector3.RIGHT, input_rotation.x)
	
	#if event.is_action_pressed("break"):
		#pass
	#if event.is_action_just_pressed('place'):
		#pass
