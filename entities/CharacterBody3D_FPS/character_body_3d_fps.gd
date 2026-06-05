extends CharacterBody3D


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic

var Actions : PlayerActions

const WALKING_SPEED = 1.5
const SLOW_SHIFT_SPEED = 3
const FAST_SHIFT_SPEED = 7
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 0.0001 * 10

var direction : Vector3
var current_speed : float


func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		Actions = %PlayerInput.get_PlayerActions()
	

func _physics_process(delta: float) -> void:
	if %Observer.is_player():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_SG2Core.get_node('Node3D/Camera').target = self.get_node('cam')
	if _ConnectionLogic.peer_role == 'host':
		if Actions != null:
			if not Actions.input.is_connected(input):
				Actions.input.connect(input)
			if Actions.sleep:
				if %Observer.player_type == 'peer':
					queue_free()
		else:
			return
	else:
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
func input():
	if _ConnectionLogic.peer_role == 'host':
		# Handle jump.
		if Actions.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		# Handle movement speed
		if Actions.is_action_pressed('slow_shift'):
			current_speed = SLOW_SHIFT_SPEED
		elif Actions.is_action_pressed('fast_shift'):
			current_speed = FAST_SHIFT_SPEED
		else:
			current_speed = WALKING_SPEED
	
		# Handle mouse rotation
		if Actions.actions.has('mouse_relative'):
			var mouse_relative = Actions.actions.mouse_relative[0]
			mouse_rotation.y -= mouse_relative.x * ROTATION_SPEED
			mouse_rotation.x -= mouse_relative.y * ROTATION_SPEED
			if mouse_rotation.x < -1.2: mouse_rotation.x = -1.2
			elif mouse_rotation.x > 1.2: mouse_rotation.x = 1.2
			transform.basis = Basis(Vector3.UP, mouse_rotation.y)
			$cam.transform.basis = Basis(Vector3.RIGHT, mouse_rotation.x)
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Actions.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if Actions.is_action_pressed("break"):
			pass
		if Actions.is_action_just_pressed('place'):
			pass 
