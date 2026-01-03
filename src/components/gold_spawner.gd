extends Node2D

# Используем @export, чтобы можно было перетащить сцену золота прямо в инспекторе.
# Это лучше, чем хардкодить путь "res://..."
@export var gold_scene: PackedScene

# Настройки спавна
@export var x_range_min: int = 50
@export var x_range_max: int = 500
@export var spawn_y: int = 530


func _on_timer_timeout():
	if not gold_scene:
		printerr("GoldSpawner: Не назначена сцена золота!")
		return

	var gold_instance = gold_scene.instantiate()

	# Генерируем позицию
	var random_x = randi_range(x_range_min, x_range_max)
	gold_instance.position = Vector2(random_x, spawn_y)

	add_child(gold_instance)
