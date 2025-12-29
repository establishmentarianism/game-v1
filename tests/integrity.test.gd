extends "res://addons/gut/test.gd"


func test_project_setup():
	# Проверяем, что главная сцена настроена
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	assert_ne(main_scene, "", "Главная сцена должна быть выбрана в настройках проекта")

	# Проверяем, что важные папки существуют (через DirAccess)
	var dir = DirAccess.open("res://")
	assert_true(dir.dir_exists("res://dev_tools"), "Папка dev_tools должна быть на месте")
