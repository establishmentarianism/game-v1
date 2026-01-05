class_name HurtboxComponent
extends Area2D

# Ссылка на здоровье, которое будем отнимать
@export var health_component: HealthComponent

# Время неуязвимости после получения урона
@export var invincibility_time: float = 0.5

var is_invincible = false


func _ready():
	# Hurtbox - это то, во что бьют. Он должен быть Monitorable (обнаруживаемым),
	# но ему не нужно самому ничего Monitoring (искать).
	# Настраиваем слои коллизий позже в редакторе, но задаем базу тут:
	monitorable = true
	monitoring = false


func receive_damage(amount: int):
	if is_invincible:
		return

	if health_component:
		health_component.take_damage(amount)

	_start_invincibility()


func _start_invincibility():
	is_invincible = true

	# Отключаем коллизию, чтобы физически нельзя было ударить снова
	set_deferred("monitorable", false)

	# Таймер неуязвимости
	await get_tree().create_timer(invincibility_time).timeout

	# Включаем обратно
	is_invincible = false
	set_deferred("monitorable", true)
