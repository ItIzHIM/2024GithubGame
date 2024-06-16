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
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D


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
	if SPEED:
		pass
	if SPEED < 15:
		SPEED = 15
	# falling velocity increase 
	if velocity.y < 0 and (velocity.x != 0 and velocity.z != 0 or (velocity.x > 0 or velocity.z > 0)) and SPEED < 30:
		SPEED += 0.04
	if velocity.y < 0 and (velocity.x != 0 and velocity.z != 0 or (velocity.x > 0 or velocity.z > 0)) and SPEED < 40 and SPEED >= 30:
		SPEED += 0.02
	if velocity.y < 0 and (velocity.x != 0 and velocity.z != 0 or (velocity.x > 0 or velocity.z > 0)) and SPEED < 47 and SPEED >= 40:
		SPEED += 0.015
	if velocity.y < 0 and (velocity.x != 0 and velocity.z != 0 or (velocity.x > 0 or velocity.z > 0)) and SPEED < 55 and SPEED >= 47:
		SPEED += 0.01
		
	if is_on_floor() and SPEED > 15:
		SPEED -= 0.6
	if (velocity.x == 0 and velocity.z == 0 or (velocity.x == 0 or velocity.z == 0)) and SPEED > 15:
		SPEED -= 0.9
	if wall_sliding == true and SPEED < 55:
		SPEED += 0.1
	# Add the gravity.
	if not is_on_floor() and !is_on_wall():
		velocity.y -= gravity * delta
	
	
	
	# hadle wall slide
	if !is_on_floor() and is_on_wall():
		if velocity.y == 0 or velocity.y < 0 and SPEED <= 17:
			velocity.y -= 0.8 * gravity * delta
			wall_sliding = true
		if velocity.y == 0 or velocity.y < 0 and SPEED <= 25 and SPEED > 17:
			velocity.y -= 0.3 * gravity * delta
			wall_sliding = true
		if velocity.y == 0 or velocity.y < 0 and SPEED < 70 and SPEED > 25:
			velocity.y -= 0.1 * gravity * delta
			wall_sliding = true
		if velocity.y > gravity or velocity.y == gravity:
			velocity.y -= 1.5 * gravity * delta 
			wall_sliding = false
		if velocity.y < gravity and velocity.y > 0:
			velocity.y -= gravity * delta
			wall_sliding = true
	if wall_sliding == true and Input.is_action_just_pressed("ui_accept") and WALL_JUMP_COUNTER == 1:
		velocity.y = WALL_JUMP_VELOCITY
		wall_sliding = false
		WALL_JUMP_COUNTER = 0
	if !is_on_wall() and WALL_JUMP_COUNTER == 0:
		WALL_JUMP_COUNTER = 1
	if wall_sliding == true and !is_on_wall():
		wall_sliding = false
	
	# Handle jump and double jump
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and JUMP_COUNTER == 2:
		velocity.y = JUMP_VELOCITY
		JUMP_COUNTER = 1
	if JUMP_COUNTER == 1 and !is_on_floor() and Input.is_action_just_pressed("ui_accept") and wall_sliding == false:
		velocity.y = DOUBLE_JUMP_VELOCITY
		JUMP_COUNTER = 2
	if is_on_floor() and !Input.is_action_just_pressed("ui_accept"):
		JUMP_COUNTER = 2
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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
		
	move_and_slide()






func _on_collision_shape_3d_2_child_entered_tree(node):
	print("entered")


func _on_collision_shape_3d_2_child_exiting_tree(node):
	pass # Replace with function body.
