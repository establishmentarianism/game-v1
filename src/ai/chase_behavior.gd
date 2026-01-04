class_name ChaseBehavior
extends MovementBehavior

# Минимальная дистанция до цели, чтобы не дрожать
@export var stop_distance: float = 10.0


func get_velocity(current_position: Vector2, target_position: Vector2, speed: float) -> Vector2:
	var direction_vector = target_position - current_position

	if direction_vector.length() > stop_distance:
		return direction_vector.normalized() * speed

	return Vector2.ZERO
