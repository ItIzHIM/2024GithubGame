extends CharacterBody3D

@export var Bullet_To_Spawn : PackedScene
@export var Bullet_Spawn_Point: Node3D
@export var Bullet_Speed: float = 20

@onready var Player_Position = global_transform.origin
@onready var Rope_Length = 0
@onready var Max_Rope_Length = 0
@onready var SPEED = 15
@onready var ON_WALL = false

const MAX_SPEED = 30
const SIDE_SPEED = 15
const ACCELERATION = 5
const FRICTION = 0.9
const JUMP_VELOCITY = 13
const DOUBLE_JUMP_VELOCITY = 8
const WALL_JUMP_VELOCITY = 8

@onready var GRAPPLE_ACCELARATION = 1
@onready var MAX_POSITION = 0
@onready var JUMP_COUNTER = 2
@onready var WALL_JUMP_COUNTER = 1
@onready var wall_sliding = false
@onready var Camera_Cast = $Neck/Camera3D/camera_cast
@onready var grapple_line = $Neck/Camera3D/GrappleLine
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var camera_cast = $Neck/Camera3D/camera_cast
@onready var GrappleLine = $Neck/Camera3D/GrappleLine

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
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(90))

func _physics_process(delta):
	var space_state = get_world_3d().direct_space_state

	# Add the gravity if not grappling
	if not is_on_floor() and !is_on_wall():
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
			grappling = true
	if Camera_Cast.is_colliding() and Input.is_action_just_pressed("grapple_action"):
		target_point = Camera_Cast.get_collision_point()
		Rope_Length = global_transform.origin.distance_to(target_point)

	 # Move towards the target point if grappling
	if grappling:
		var below_target = (target_point.y - Rope_Length)
		#glabal_transform.origin.x = 
		GrappleLine.visible = true
		var to_target = (target_point - global_transform.origin).normalized()
		if global_transform.origin.distance_to(target_point) == Rope_Length or (global_transform.origin.distance_to(target_point) > Rope_Length - 0.5 and global_transform.origin.distance_to(target_point) < Rope_Length + 0.5):
			MAX_POSITION = global_transform.origin
		if global_transform.origin.distance_to(target_point) > Rope_Length:
			global_transform.origin = MAX_POSITION
			velocity.y = 0
		else: 
			velocity.y -= gravity * delta
		# Adjust the threshold as needed
		
		var horizontal_move = to_target * 10  * delta
		global_transform.origin.y += horizontal_move.y * 3
		global_transform.origin.z += horizontal_move.z
		global_transform.origin.x += horizontal_move.x
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity") / 2
		print(horizontal_move.x)
			# Apply gravity
			#if global_transform.origin.y < target_point.y - 3:
			#else:
			#	velocity.y -= gravity * delta
		GrappleLine.look_at(target_point, Vector3(0, 0, 1))
	else:
		GrappleLine.visible = false
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

	if Input.is_action_just_pressed("LMB"):
		pass  # shoot(Get_Camera_Collision())

	# Reset grappling if the action is released
	if grappling and !Input.is_action_pressed("grapple_action"):
		grappling = false

	move_and_slide()
	
func shoot(Point: Vector3):
	var Direction_Bullet = (Point - Bullet_Spawn_Point.get_global_transform().origin.normalized())
	var Bullet = Bullet_To_Spawn.instantiate()
