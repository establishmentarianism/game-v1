class_name SoftCollision
extends Area2D

# Сила отталкивания
@export var push_force: float = 400.0


func is_colliding() -> bool:
	return has_overlapping_areas()


func get_push_vector() -> Vector2:
	var push_vector = Vector2.ZERO
	var areas = get_overlapping_areas()

	if areas.size() == 0:
		return push_vector

	# Суммируем векторы отталкивания от ВСЕХ соседей
	for area in areas:
		# Вектор ОТ соседа К нам
		var direction = area.global_position.direction_to(global_position)
		push_vector += direction

	# Нормализуем и применяем силу
	return push_vector.normalized() * push_force
