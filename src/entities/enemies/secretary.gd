class_name Secr1
extends CharacterBody2D

# --- Настройки передвижения ---
@export var speed: float = 100.0
@export var gravity_scale: float = 1.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

# --- Настройки боя (НОВОЕ) ---
@export var attack_range: float = 0 # Дистанция для начала удара
@export var attack_duration: float = 0.5 # Сколько длится сам удар (время включенного хитбокса)
@export var attack_cooldown: float = 1.0 # Задержка после удара (время, когда секретарь стоит и тупит)

# --- Компоненты ---
@export var movement_behavior: MovementBehavior
@export var soft_collision: SoftCollision
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent
@export var hitbox_component: HitboxComponent # Ссылка на зону, которая бьет игрока

# --- Состояние ---
var chase: bool = false
var alive: bool = true
var is_attacking: bool = false # Флаг: бьет ли сейчас секретарь
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
	add_to_group("secretaries")
	Events.player_moved.connect(_on_player_moved)

	# Автопоиск компонентов
	if not movement_behavior: movement_behavior = get_node_or_null("ChaseBehavior")
	if not soft_collision: soft_collision = get_node_or_null("SoftCollision")
	if not health_component: health_component = get_node_or_null("BodyHealthComponent")
	if not hurtbox_component: hurtbox_component = get_node_or_null("BodyHurtboxComponent")
	if not hitbox_component: hitbox_component = get_node_or_null("HitboxComponent")

	# Важно: Выключаем урон по умолчанию, чтобы не бил постоянно
	if hitbox_component:
		hitbox_component.monitoring = false

	# Настройка здоровья
	if health_component:
		health_component.died.connect(die)
		if hurtbox_component and not hurtbox_component.health_component:
			hurtbox_component.health_component = health_component
			health_component.health_changed.connect(func(_current): _blink_effect())

	_connect_signals_safely()
	_autonomous_attack_loop()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta

	if alive:
		# Если Секретарь сейчас атакует, он ОБЯЗАН стоять на месте
		if is_attacking:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
		else:
			var target_velocity_x: float = 0.0

			# Преследование игрока
			if chase:
				if movement_behavior:
					var move_vec = movement_behavior.get_velocity(global_position, target_pos, speed)
					target_velocity_x = move_vec.x
					if target_velocity_x != 0:
						sprite.flip_h = target_velocity_x < 0

			# Расталкивание (чтобы мобы не слипались в одну точку)
			if soft_collision and soft_collision.is_colliding():
				var push_vector = soft_collision.get_push_vector()
				target_velocity_x += push_vector.x

			# Применяем движение
			if target_velocity_x != 0:
				velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

# --- Логика Атаки ---

func _autonomous_attack_loop():
	while alive:
		# 1. Ждем кулдаун (1 секунда, в это время секретарь может бежать)
		await get_tree().create_timer(attack_cooldown).timeout

		# Защита от ошибки, если убили во время ожидания
		if not alive:
			break

		# 2. Атакуем (0.5 секунд, секретарь будет стоять на месте)
		await _perform_attack()

func _perform_attack():
	is_attacking = true

	# 1. Поворачиваем хитбокс в сторону игрока
	#if hitbox_component:
	#	var dir = sign(target_pos.x - global_position.x)
	#	if dir != 0:
	#		hitbox_component.scale.x = dir
	#		sprite.flip_h = (dir < 0)

	# 2. Включаем урон
	if hitbox_component:
		hitbox_component.set_deferred("monitoring", true)

	# 3. ЗАПУСКАЕМ АНИМАЦИЮ (укажите точное имя анимации!)
	#var anim_player = $AttackHitbox/AnimationPlayer
	#if anim_player and anim_player.has_animation("attack_anim"):
	#	anim_player.play("attack_anim")

	# 4. Ждем время самого удара (attack_duration = 0.5)
	await get_tree().create_timer(attack_duration).timeout

	# 5. Выключаем урон
	if hitbox_component:
		hitbox_component.set_deferred("monitoring", false)

	# 6. Снимаем блокировку, секретарь снова готов бежать (кулдаун обрабатывается в цикле)
	is_attacking = false

# --- Системные функции ---
func die():
	if not alive:
		return
	alive = false
	stats['kills'] += 1
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	if hurtbox_component: hurtbox_component.set_deferred("monitorable", false)
	if hitbox_component: hitbox_component.set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(self , "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _blink_effect():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_player_moved(pos: Vector2):
	target_pos = pos

func _connect_signals_safely():
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)
