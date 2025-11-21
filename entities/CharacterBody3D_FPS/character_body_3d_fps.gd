extends CharacterBody3D


@onready var _SG2Core : SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _EntitiesLogic := _SG2Core._EntitiesLogic

var _PlayerActions : PlayerActions

var direction : Vector3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 0.0001 * 10

var mouse_rotation = Vector2.ZERO


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
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
		

func input():
	if _ConnectionLogic.peer_role == 'host':
		# Handle jump.
		if _PlayerActions.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
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
