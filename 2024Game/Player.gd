extends CharacterBody3D

enum WalkState{
	NORMAL,
	SPRINT,
	CROUCH,
	PRONE,
	SLIDE
}


var player = null
var bullet = load("res://bullet.tscn")
var enemy = load("res://Zombie.tscn")


@onready var spawn_point = $"../SpawnPoint"
@onready var gun_barrel = $CameraPivot/Camera3D/Gun/gun_raycast2
var instance
var instance_enemy

@export var Grapple_Force = 40
var grapple_hook_position : Vector3 = Vector3.ZERO

var current_walk_state : WalkState = WalkState.NORMAL

var player_position = 0


#Grappling stuff
@onready var camera_cast = $CameraPivot/Camera3D/CameraCast
var grapple_raycast_hit = 0
var is_grappling = false

#movement attribute values
const TARGET_LERP = .8
 
const SPRINT_SPEED = 18.0
const SPRINT_LERP_ACC = 1
const SPRINT_LERP_DEC = 8
 
const WALK_SPEED = 6.0
const WALK_LERP_ACC = 3.5
const WALK_LERP_DEC = 10
 
const CROUCH_SPEED = 3.0
const CROUCH_LERP_ACC = 8
const CROUCH_LERP_DEC = 14
 
const PRONE_SPEED = 1.5
const PRONE_LERP_ACC = 12
const PRONE_LERP_DEC = 22
 
const SLIDE_SPEED = 30
const SLIDE_TIME_MAX = .7
const SLIDE_DAMPEN_RATE = .05
const SLIDE_FLAT_DAMPEN_RATE = .001
const SLOPE_SLIDE_THRESHOLD = .1
var current_slide_time = 0
var current_slide_vector : Vector3 = Vector3.ZERO
 
var SPRINT_CD_MAX = .2
var current_sprint_cd = 0
 
const FALL_SPEED_MAX = 30
const JUMP_VELOCITY = 6
const JUMP_HANG_TIME_THRESHOLD = .3
const JUMP_HANG_TIME_SPEED_MULT = 1.05
const JUMP_HANG_TIME_ACC_MULT = 3
 
const COYOTE_TIME_MAX = .1
var current_coyote_time = 0
var current_jump_cd = 0
const JUMP_CD_MAX = .25


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity_default = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_falling = 3.3 * gravity_default
var gravity_hang_time = .5 * gravity_default
var current_gravity = gravity_default

@onready var collider = $Collider

var input_dir = Vector2.ZERO
var direction = Vector3.ZERO

var current_max_speed : float = 0 
var current_lerp_acc : float = 0
var current_lerp_dec : float = 0
var current_camera_height : float = 0

var floor_angle

const COLLIDER_HEIGHT_NORMAL = 2
const COLLIDER_HEIGHT_CROUCH = 1.1
const COLLIDER_HEIGHT_PRONE = .5

const CAMERA_HEIGHT_NORMAL = 1.8
const CAMERA_HEIGHT_CROUCH = .9
const CAMERA_HEIGHT_PRONE = .3
 
@export var camera_sensitivity = .25
const CAMERA_LERP = 10
const CAMERA_FOV_NORMAL = 70.0
const CAMERA_FOV_MAX_SPEED = 100.0


@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var height_raycast = $HeightRaycast

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_UpdateCollider()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(camera_sensitivity * -event.relative.x))
		camera_pivot.rotate_x(deg_to_rad(camera_sensitivity * -event.relative.y))
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	
	#grapple crap
	if Input.is_action_pressed("escape"):
		get_tree().quit()
	player_position = global_transform.origin
	grapple_raycast_hit = camera_cast.get_collision_point()
	if grapple_raycast_hit and Input.is_action_just_pressed("grappling"):
		grapple_hook_position = camera_cast.get_collision_point()
		is_grappling = true
	if Input.is_action_just_released("grappling"):
		is_grappling = false
	if is_grappling:
		var grapple_direction = (grapple_hook_position - global_transform.origin).normalized()
		var grapple_target_speed = grapple_direction * Grapple_Force
		var grapple_dif = (grapple_target_speed - velocity)
		velocity += grapple_dif * delta
		current_gravity = 0
	if WalkState.SLIDE == current_walk_state:
		if current_slide_time > 0:
			if floor_angle < SLOPE_SLIDE_THRESHOLD || velocity.y > 0:
				current_slide_time -= delta
				current_slide_time = clamp(current_slide_time, 0, SLIDE_TIME_MAX)
			
		else:
			current_walk_state = WalkState.CROUCH
			_UpdateCollider()
	
	if current_sprint_cd > 0:
		current_sprint_cd -= delta
 
	#calc target speed based on current input
	var target_speed : Vector3 = direction * current_max_speed
 
	var current_acc_rate : Vector3 = Vector3.ZERO
	if input_dir:
		current_acc_rate = Vector3(current_lerp_acc,
				0,
				current_lerp_acc)
	else:
		current_acc_rate = Vector3(current_lerp_dec,
			0,
			current_lerp_dec)
	
	
	#lerp the target speed for smoother change
	#if the movement is in the same direction make the target closer to the current velocity
	#otherwise, since direction shift is required make the target closer to actual target
	#if player is faster than top speed don't slow down on X and Z axis
	if (target_speed.x != 0 &&
		abs(velocity.x) >= abs(target_speed.x) &&
		sign(velocity.x) == sign(target_speed.x)):
			
		target_speed.x = lerp(velocity.x, target_speed.x, 1-TARGET_LERP)
	else:
		target_speed.x = lerp(velocity.x, target_speed.x, TARGET_LERP)
		
	if (target_speed.z != 0 &&
		abs(velocity.z) >= abs(target_speed.z) &&
		sign(velocity.z) == sign(target_speed.z)):
 
		target_speed.z = lerp(velocity.z, target_speed.z, 1-TARGET_LERP)
	else:
		target_speed.z = lerp(velocity.z, target_speed.z, TARGET_LERP)
	
	# Handle Jump.
	if Input.is_action_just_released("jump") and velocity.y > 0:
		current_jump_cd = 0
		velocity.y = velocity.y / 2.0
	elif current_coyote_time > 0 && (
		Input.is_action_just_pressed("jump") || current_jump_cd > 0):
		current_jump_cd = JUMP_CD_MAX
		velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("sprint"): current_walk_state = WalkState.SPRINT
		else: current_walk_state = WalkState.NORMAL
		_UpdateCollider()
		
	if abs(velocity.y) < JUMP_HANG_TIME_THRESHOLD && !is_on_floor():
		#make the gravity weaker around apex of jump
		current_gravity = gravity_hang_time
		
		#increase responsiveness
		target_speed *= JUMP_HANG_TIME_SPEED_MULT
		current_acc_rate *= JUMP_HANG_TIME_ACC_MULT
	else:
		#if falling make gravity stronger
		if velocity.y < 0:
			current_gravity = gravity_falling
		else:
			current_gravity = gravity_default
	
	# Add the gravity.
	if not is_on_floor():
		current_coyote_time -= delta
		if current_coyote_time < 0: current_coyote_time = 0
		velocity.y -= current_gravity * delta
	else:
		current_coyote_time = COYOTE_TIME_MAX
 
	
	#calculate dif between max and current speed
	#ignore y axis
	var speed_difference : Vector3 = target_speed - velocity
	speed_difference.y = 0
 
	#final force that will be applied to character
	var movement = speed_difference * current_acc_rate
 
	if is_on_floor() && floor_angle > SLOPE_SLIDE_THRESHOLD:
		var plane = Plane(get_floor_normal())
		movement = plane.project(movement)
		current_slide_vector = plane.project(current_slide_vector)
 
	if WalkState.SLIDE == current_walk_state:
		velocity = velocity + (movement) * delta * SLIDE_DAMPEN_RATE
		velocity = velocity + current_slide_vector * delta * (current_slide_time) * (-(current_slide_vector.y) + .01)
	else:
		velocity = velocity + (movement) * delta
 
	if velocity.y < -FALL_SPEED_MAX:
		velocity.y = -FALL_SPEED_MAX
		
	current_jump_cd -= delta
	if current_jump_cd < 0: current_jump_cd = 0
	
	_UpdateCameraPosition(delta, inverse_lerp(0, abs(SPRINT_SPEED), velocity.length()))
	
	#bullet crap
	if Input.is_action_just_pressed("shoot"):
		instance = bullet.instantiate()
		instance.position = gun_barrel.global_position
		instance.transform.basis = gun_barrel.global_transform.basis 
		get_parent().add_child(instance)
	
	move_and_slide()

func _UpdateCameraPosition(delta, speed_t):
	var t = CAMERA_LERP * delta
 
	if WalkState.SLIDE == current_walk_state:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(15.0), t)
	else:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, t)
		
		
	var tmp = lerp(CAMERA_FOV_NORMAL, CAMERA_FOV_MAX_SPEED, speed_t)
	camera_3d.fov = lerp(camera_3d.fov, min(tmp, CAMERA_FOV_MAX_SPEED), t)
	camera_pivot.position.y = lerp(camera_pivot.position.y, current_camera_height, t)

func _process(delta):
	input_dir = Input.get_vector("left", "right", "forward", "back")
 
	direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y).normalized()
 
	if WalkState.SLIDE != current_walk_state:
		if Input.is_action_pressed("prone") && is_on_floor():
			if current_walk_state != WalkState.PRONE:
				current_walk_state = WalkState.PRONE
				_UpdateCollider()
		elif Input.is_action_pressed("crouch") and !height_raycast.is_colliding() && is_on_floor():
			if current_walk_state != WalkState.CROUCH:
				if current_sprint_cd > 0:
					current_walk_state = WalkState.SLIDE
					current_slide_time = SLIDE_TIME_MAX
					current_slide_vector = abs(velocity) * direction
					current_slide_vector.y = 0
					_UpdateCollider()
				else:
					current_walk_state = WalkState.CROUCH
					_UpdateCollider()
		elif !height_raycast.is_colliding():
			if current_walk_state == WalkState.PRONE:
				current_walk_state = WalkState.CROUCH
				_UpdateCollider()
			elif Input.is_action_pressed("sprint"):
				current_sprint_cd = SPRINT_CD_MAX
				if current_walk_state != WalkState.SPRINT:
					current_walk_state = WalkState.SPRINT
					_UpdateCollider()
			elif current_walk_state != WalkState.NORMAL:
				current_walk_state = WalkState.NORMAL
				_UpdateCollider()
				
	floor_angle = get_floor_angle()
 
func _UpdateCollider():
	match current_walk_state:
		WalkState.NORMAL:
			collider.shape.height = COLLIDER_HEIGHT_NORMAL
			collider.position.y = COLLIDER_HEIGHT_NORMAL / 2.0
			height_raycast.target_position.y = COLLIDER_HEIGHT_NORMAL
			current_camera_height = CAMERA_HEIGHT_NORMAL
			current_max_speed = WALK_SPEED
			current_lerp_acc = WALK_LERP_ACC
			current_lerp_dec = WALK_LERP_DEC
		WalkState.CROUCH:   
			collider.shape.height = COLLIDER_HEIGHT_CROUCH
			collider.position.y = COLLIDER_HEIGHT_CROUCH / 2.0
			height_raycast.target_position.y = COLLIDER_HEIGHT_NORMAL
			current_camera_height = CAMERA_HEIGHT_CROUCH
			current_max_speed = CROUCH_SPEED
			current_lerp_acc = CROUCH_LERP_ACC
			current_lerp_dec = CROUCH_LERP_DEC
		WalkState.SLIDE:    
			collider.shape.height = COLLIDER_HEIGHT_CROUCH
			collider.position.y = COLLIDER_HEIGHT_CROUCH / 2.0
			height_raycast.target_position.y = COLLIDER_HEIGHT_NORMAL
			current_camera_height = CAMERA_HEIGHT_CROUCH
			current_max_speed = WALK_SPEED
			current_lerp_acc = CROUCH_LERP_ACC
			current_lerp_dec = CROUCH_LERP_DEC
		WalkState.PRONE:    
			collider.shape.height = COLLIDER_HEIGHT_PRONE
			collider.position.y = COLLIDER_HEIGHT_PRONE / 2.0
			height_raycast.target_position.y = COLLIDER_HEIGHT_CROUCH
			current_camera_height = CAMERA_HEIGHT_PRONE
			current_max_speed = PRONE_SPEED
			current_lerp_acc = PRONE_LERP_ACC
			current_lerp_dec = PRONE_LERP_DEC
		WalkState.SPRINT:   
			collider.shape.height = COLLIDER_HEIGHT_NORMAL
			collider.position.y = COLLIDER_HEIGHT_NORMAL / 2.0
			height_raycast.target_position.y = COLLIDER_HEIGHT_NORMAL
			current_camera_height = CAMERA_HEIGHT_NORMAL
			current_max_speed = SPRINT_SPEED
			current_lerp_acc = SPRINT_LERP_ACC
			current_lerp_dec = SPRINT_LERP_DEC





func _on_timer_timeout():
	var zombie = enemy.instantiate()
	
	var zombie_spawn_location = spawn_point.global_position
	
	zombie.position = zombie_spawn_location
	
	get_parent().add_child(zombie)
