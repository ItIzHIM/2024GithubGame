extends Control

var velocity : Vector2 = Vector2.ZERO

func _physics_process(delta):
	velocity.x = 20
	
func _on_play_pressed():
	$AudioStreamPlayer2.play()
	get_tree().change_scene_to_file("res://Main_level.tscn")
	


func _on_options_pressed():
	$AudioStreamPlayer2.play()
	pass # Replace with function body.


func _on_quit_pressed():
	$AudioStreamPlayer2.play()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
