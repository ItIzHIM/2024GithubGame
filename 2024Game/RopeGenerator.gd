extends MeshInstance3D

var player = null
@export var player_loco : NodePath  # Path to the player node
@onready var meshik = $"."

func _ready():
	
	# Get the player node using the NodePath
	player = get_node(player_loco)

func _physics_process(delta):
	# Create a new BoxMesh and assign it to the MeshInstance3D node
	var rope_length = (player.global_transform.origin - player.grapple_hook_position).length()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.5, 0.5, 3 * rope_length)  # Set the size of the cube (width, height, depth)
	mesh = cube_mesh
	var midpoint = (player.grapple_hook_position + player.global_transform.origin)/2
	global_transform.origin = midpoint
	var direction = (player.grapple_hook_position - player.global_transform.origin).normalized()
	look_at(midpoint + direction, Vector3.UP)
	visibility()

func visibility():
	if player.is_grappling:
		meshik.visible = true
	else: 
		meshik.visible = false
