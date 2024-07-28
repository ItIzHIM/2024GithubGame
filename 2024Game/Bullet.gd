extends CharacterBody3D

const SPEED = 5.0


func _physics_process(delta):
	pass
	
	
func _on_child_entered_tree(node):
	queue_free()


func _on_timer_timeout():
	queue_free()
