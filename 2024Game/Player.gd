extends CharacterBody3D

@onready var SPEED = 15
@onready var ON_WALL = false
const SIDE_SPEED = 15
const TURN_DAMPING = 5
const ACCELERATION = 5
const FRICTION = 0.9
const JUMP_VELOCITY = 6
const DOUBLE_JUMP_VELOCITY = 5
const WALL_JUMP_VELOCITY = 8
@onready var JUMP_COUNTER = 2
@onready var WALL_JUMP_COUNTER = 1
@onready var wall_sliding = false
@onready var Camera_Cast = $Neck/Camera3D/camera_cast
@onready var grapple_line = $Neck/Camera3D/GrappleLine
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var camera_cast = $Neck/Camera3D/camera_cast

# Variables for grappling hook
var grappling = false
var target_point = Vector3()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(70))
			
func _physics_process(delta):
	var space_state = get_world_3d().direct_space_state

	# Add the gravity if not grappling
	if not is_on_floor() and !is_on_wall() and !grappling:
		velocity.y -= gravity * delta

	# Handle jump and double jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and JUMP_COUNTER == 2:
		velocity.y = JUMP_VELOCITY
		JUMP_COUNTER = 1
	if JUMP_COUNTER == 1 and !is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = DOUBLE_JUMP_VELOCITY
		JUMP_COUNTER = 2
	if is_on_floor() and !Input.is_action_just_pressed("ui_accept"):
		JUMP_COUNTER = 2

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SIDE_SPEED * FRICTION
		velocity.z = direction.z * SPEED * FRICTION
	else:
		velocity.x = move_toward(velocity.x, 0, SIDE_SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if direction and !is_on_floor():
		velocity.x = direction.x * SIDE_SPEED
		velocity.z = direction.z * SPEED

	# RayCast and grappling hook stuff
	if Camera_Cast.is_colliding() and Input.is_action_pressed("grapple_action"):
		if !grappling:
			target_point = Camera_Cast.get_collision_point()
			grappling = true

	# Move towards the target point if grappling
	if grappling and Input.is_action_pressed("grapple_action"):
		var to_target = (target_point - global_transform.origin).normalized()
		velocity = to_target * SPEED * 1.6
		velocity.y -= gravity * delta

		# Check if player has reached the target point
		if global_transform.origin.distance_to(target_point) < 1.0:
			grappling = false
			velocity = Vector3.ZERO

	# Reset grappling if the action is released
	if grappling and !Input.is_action_pressed("grapple_action"):
		grappling = false

	move_and_slide()
