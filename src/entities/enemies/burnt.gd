class_name Burnt
extends CharacterBody2D

# --- Настройки ---
@export var speed: float = 100.0
@export var gravity_scale: float = 1.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

# --- Компоненты ---
@export var movement_behavior: MovementBehavior
@export var soft_collision: SoftCollision
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent

# --- Состояние ---
var chase: bool = false
var alive: bool = true
var target_pos: Vector2 = Vector2.ZERO

# --- Узлы ---
@onready var sprite = $Sprite2D
@onready var aggro_area: Area2D = $AggroArea
var stats = {
	'kills': 0,
}

func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase = false

func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase = true

func _ready():
	add_to_group("ghosts")
	Events.player_moved.connect(_on_player_moved)

	# Автопоиск компонентов
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
		if hurtbox_component and not hurtbox_component.health_component:
			hurtbox_component.health_component = health_component
			health_component.health_changed.connect(func(_current): _blink_effect())

	_connect_signals_safely()

func _physics_process(delta: float) -> void:
	# Изящное решение гравитации (умножаем вектор на float)
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta

	if alive:
		var target_velocity_x: float = 0.0

		# 1. Преследование
		if chase and movement_behavior:
			var move_vec = movement_behavior.get_velocity(global_position, target_pos, speed)
			target_velocity_x = move_vec.x
			if target_velocity_x != 0:
				sprite.flip_h = target_velocity_x < 0

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

	stats['kills'] += 1
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	if hurtbox_component:
		hurtbox_component.set_deferred("monitorable", false)
	var hitbox = get_node_or_null("HitboxComponent")
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(self , "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _blink_effect():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

# --- Сигналы ---

func _on_player_moved(pos: Vector2):
	target_pos = pos

func _connect_signals_safely():
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)
