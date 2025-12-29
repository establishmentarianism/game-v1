class_name HealthComponent
extends Node

signal died
signal health_changed(new_value: int)

@export var max_health: int = 100
var current_health: int


func _ready():
	current_health = max_health
	# Сообщаем начальное состояние (например, для UI)
	# Используем call_deferred, чтобы убедиться, что все остальные узлы готовы
	call_deferred("emit_health_signal")


func take_damage(amount: int):
	current_health -= amount
	emit_health_signal()

	if current_health <= 0:
		died.emit()


func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	emit_health_signal()


func emit_health_signal():
	health_changed.emit(current_health)
