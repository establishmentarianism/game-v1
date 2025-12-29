extends Node2D
var a = 0


func _on_button_2_button_down() -> void:
	get_tree().quit()

func _on_button_button_down() -> void:
	ScreenManager.load_game()

func _on_button_3_button_down() -> void:
	a += 1
