class_name Mob
extends CharacterBody2D

# --- Настройки ---
@export var speed = 100
@export var gravity_scale = 1.0
# Добавили ускорение для плавности (чем меньше число, тем больше моба "заносит")
@export var acceleration = 800.0
@export var friction = 1000.0

# --- Компоненты ---
@export var movement_behavior: MovementBehavior
@export var soft_collision: SoftCollision

# --- Состояние ---
var chase = false
var alive = true
var target_pos: Vector2 = Vector2.ZERO
var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Узлы ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var aggro_area: Area2D = $AggroArea
@onready var damage_area: Area2D = $Dmage
@onready var death_area: Area2D = $MobDeath


func _ready():
	add_to_group("enemies")
	Events.player_moved.connect(_on_player_moved)

	if not movement_behavior:
		movement_behavior = get_node_or_null("ChaseBehavior")
	if not soft_collision:
		soft_collision = get_node_or_null("SoftCollision")

	_connect_signals_safely()


func _physics_process(delta):
	# 1. Гравитация
	if not is_on_floor():
		velocity.y += default_gravity * gravity_scale * delta

	if alive:
		# Считаем ЖЕЛАЕМУЮ скорость, а не присваиваем её сразу
		var target_velocity_x = 0.0

		# А. Логика преследования
		if chase and movement_behavior:
			var move_vec = movement_behavior.get_velocity(global_position, target_pos, speed)
			target_velocity_x = move_vec.x

			if target_velocity_x != 0:
				anim_sprite.flip_h = target_velocity_x < 0

		# Б. Логика расталкивания (Мягкая)
		if soft_collision and soft_collision.is_colliding():
			var push_vector = soft_collision.get_push_vector()
			# Просто добавляем влияние толчка к желаемой скорости
			target_velocity_x += push_vector.x

		# В. Плавное применение скорости (СГЛАЖИВАНИЕ)
		# Вместо velocity.x = target_velocity_x, мы двигаемся к ней постепенно
		if target_velocity_x != 0:
			velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
		else:
			# Торможение (трение)
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()


# ... Остальной код (сигналы) без изменений ...
func _on_player_moved(pos: Vector2):
	target_pos = pos


func _connect_signals_safely():
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	if damage_area:
		if not damage_area.body_entered.is_connected(_on_damage_body_entered):
			damage_area.body_entered.connect(_on_damage_body_entered)
	if death_area:
		if not death_area.body_entered.is_connected(_on_weak_spot_body_entered):
			death_area.body_entered.connect(_on_weak_spot_body_entered)


func _on_aggro_area_body_entered(body):
	if body.is_in_group("player"):
		chase = true


func _on_aggro_area_body_exited(body):
	if body.is_in_group("player"):
		chase = false


func _on_weak_spot_body_entered(body):
	if alive and body.is_in_group("player"):
		body.velocity.y = -300
		die()


func _on_damage_body_entered(body):
	if alive and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(20)


func die():
	if not alive:
		return
	alive = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	if damage_area:
		damage_area.set_deferred("monitoring", false)
	queue_free()
