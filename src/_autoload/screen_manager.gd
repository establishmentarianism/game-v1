extends Node

# Здесь ТОЛЬКО те сцены, которые заменяют друг друга целиком
const SCREENS = {
	"MENU": "res://src/screens/menu.tscn",
	"GAME": "res://src/screens/game.tscn"
}

func load_menu():
	_change_scene(SCREENS.MENU)

func load_game():
	_change_scene(SCREENS.GAME)

func _change_scene(path: String):
	if ResourceLoader.exists(path):
		# Используем отложенный вызов для безопасности
		call_deferred("_deferred_change_scene", path)
	else:
		printerr("SceneManager: Путь не найден! ", path)

func _deferred_change_scene(path: String):
	get_tree().change_scene_to_file(path)
