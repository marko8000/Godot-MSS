extends CharacterBody3D


@onready var _SG2Core : SG2Core = ExecManager.get_current_exec(self).get_current_level(self)
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic

var _PlayerActions : PlayerActions

const WALKING_SPEED = 1.5
const SLOW_SHIFT_SPEED = 3
const FAST_SHIFT_SPEED = 7
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 0.0001 * 10

var direction : Vector3
var current_speed : float


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		_PlayerActions = %PlayerInput.get_PlayerActions()
	

func _physics_process(delta: float) -> void:
	if %Observer.is_player():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_SG2Core.get_node('Node3D/Camera').target = self.get_node('cam')
	if _ConnectionLogic.peer_role == 'host':
		if _PlayerActions != null:
			if not _PlayerActions.input.is_connected(input):
				_PlayerActions.input.connect(input)
			if _PlayerActions.sleep:
				if %Observer.player_type == 'peer':
					queue_free()
		else:
			return
	else:
		return
	
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		
	# Interaction with RigidBody
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
		

var mouse_rotation = Vector2.ZERO
func input():
	if _ConnectionLogic.peer_role == 'host':
		# Handle jump.
		if _PlayerActions.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		# Handle movement speed
		if _PlayerActions.is_action_pressed('slow_shift'):
			current_speed = SLOW_SHIFT_SPEED
		elif _PlayerActions.is_action_pressed('fast_shift'):
			current_speed = FAST_SHIFT_SPEED
		else:
			current_speed = WALKING_SPEED
	
		# Handle mouse rotation
		if _PlayerActions.actions.has('mouse_relative'):
			var mouse_relative = _PlayerActions.actions.mouse_relative[0]
			mouse_rotation.y -= mouse_relative.x * ROTATION_SPEED
			mouse_rotation.x -= mouse_relative.y * ROTATION_SPEED
			if mouse_rotation.x < -1.2: mouse_rotation.x = -1.2
			elif mouse_rotation.x > 1.2: mouse_rotation.x = 1.2
			transform.basis = Basis(Vector3.UP, mouse_rotation.y)
			$cam.transform.basis = Basis(Vector3.RIGHT, mouse_rotation.x)
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = _PlayerActions.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
