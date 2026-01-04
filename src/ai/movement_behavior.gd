class_name MovementBehavior
extends Node


# Интерфейс, который должны реализовать наследники
# Возвращает вектор желаемой скорости
# Аргументы начинаются с "_", чтобы линтер не ругался на неиспользование в классе.
func get_velocity(_current_position: Vector2, _target_position: Vector2, _speed: float) -> Vector2:
	return Vector2.ZERO
