class_name HitboxComponent
extends Area2D

@export var damage: int = 10


func _ready():
	# Hitbox - это то, что бьет. Он ищет (Monitoring), но сам телом не является (Monitorable = false)
	monitoring = true
	monitorable = false

	# Подписываемся на вход в зону
	area_entered.connect(_on_area_entered)


func _on_area_entered(area):
	# Если мы коснулись чьего-то HurtboxComponent
	if area is HurtboxComponent:
		area.receive_damage(damage)
