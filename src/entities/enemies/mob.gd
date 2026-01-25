class_name Mob
extends CharacterBody2D

# --- Настройки ---
@export var speed = 100
@export var gravity_scale = 1.0
@export var acceleration = 800.0
@export var friction = 1000.0

# --- Компоненты ---
@export var movement_behavior: MovementBehavior
@export var soft_collision: SoftCollision
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent

# --- Состояние ---
var chase = false
var alive = true
var target_pos: Vector2 = Vector2.ZERO
var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Узлы ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var aggro_area: Area2D = $AggroArea

func _ready():
	add_to_group("enemies")
	Events.player_moved.connect(_on_player_moved)

	# Автопоиск компонентов (если забыли назначить в инспекторе)
	if not movement_behavior:
		movement_behavior = get_node_or_null("ChaseBehavior")
	if not soft_collision:
		soft_collision = get_node_or_null("SoftCollision")
	if not health_component:
		health_component = get_node_or_null("HealthComponent")
	if not hurtbox_component:
		hurtbox_component = get_node_or_null("HurtboxComponent")

	# Настройка здоровья
	if health_component:
		health_component.died.connect(die)
		# Привязываем Hurtbox к Health, если это не сделано в инспекторе
		if hurtbox_component and not hurtbox_component.health_component:
			hurtbox_component.health_component = health_component
			# Добавляем реакцию на урон (мигание)
			health_component.health_changed.connect(func(_current): _blink_effect())

	_connect_signals_safely()


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += default_gravity * gravity_scale * delta

	if alive:
		var target_velocity_x = 0.0

		# 1. Преследование
		if chase and movement_behavior:
			var move_vec = movement_behavior.get_velocity(global_position, target_pos, speed)
			target_velocity_x = move_vec.x
			if target_velocity_x != 0:
				anim_sprite.flip_h = target_velocity_x < 0

		# 2. Расталкивание (Soft Collision)
		if soft_collision and soft_collision.is_colliding():
			var push_vector = soft_collision.get_push_vector()
			target_velocity_x += push_vector.x

		# 3. Движение
		if target_velocity_x != 0:
			velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()


func die():
	if not alive:
		return
	alive = false

	# Отключаем физику и хитбоксы
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	# Отключаем возможность получать и наносить урон
	if hurtbox_component:
		hurtbox_component.set_deferred("monitorable", false)
	# Если есть Hitbox (урон телом), отключаем его
	var hitbox = get_node_or_null("HitboxComponent")
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _blink_effect():
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.1)


# --- Сигналы ---


func _on_player_moved(pos: Vector2):
	target_pos = pos


func _connect_signals_safely():
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)


func _on_aggro_area_body_entered(body):
	if body.is_in_group("player"):
		chase = true


func _on_aggro_area_body_exited(body):
	if body.is_in_group("player"):
		chase = false
