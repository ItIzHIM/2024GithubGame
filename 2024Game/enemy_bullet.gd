extends Node3D

const SPEED = 20


@onready var mesh = $bullet

func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	$Timer.start()
	

func _on_timer_timeout():
	queue_free()


func _on_area_3d_area_entered(area):
	queue_free()
