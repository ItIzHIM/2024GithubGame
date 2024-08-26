extends Node3D

const SPEED = 80


@onready var mesh = $bullet
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D

func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(3.0).timeout
		queue_free()
	



func _on_timer_timeout():
	queue_free()
