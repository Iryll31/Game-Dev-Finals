extends Area2D


func _on_body_entered(body):
	get_tree().change_scene_to_file("C:/Users/User/Desktop/Villanueva_MidtermPractical/scenes/game2.tscn")
	print("i am a horse.")
