extends Node2D
var a=0



func _on_button_2_button_down() -> void:
	get_tree().quit()

func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_button_3_button_down() -> void:
	a=a+1
	


func _on_button_mouse_entered() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
