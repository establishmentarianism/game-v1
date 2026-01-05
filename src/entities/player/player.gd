class_name Player
extends CharacterBody2D

# --- Настройки ---
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# --- Компоненты ---
@export var health_component: HealthComponent
# HitboxComponent (Меч) - нужно добавить в сцену игрока
@export var sword_hitbox: HitboxComponent
# HurtboxComponent (Тело) - нужно добавить в сцену игрока
@export var hurtbox_component: HurtboxComponent

# --- Состояние ---
var gold = 0
var is_attacking = false
var is_dying = false  # Флаг, предотвращающий любые действия после смерти

@onready var anim = $AnimatedSprite2D


func _ready():
	add_to_group("player")
	anim.animation_finished.connect(_on_animation_finished)
	_setup_components()


func _physics_process(delta):
	# Если мертв, обрабатываем только гравитацию (чтобы упал) и выходим
	if is_dying:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	Events.player_moved.emit(global_position)

	# Атака (прерывает движение, если так задумано)
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		start_attack()

	# Управление движением
	if is_attacking:
		velocity.x = 0
	else:
		handle_movement()

	# Прыжок
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if not is_attacking:
		update_animations()


func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = (direction < 0)

		# Поворачиваем хитбокс атаки вместе с игроком
		if sword_hitbox:
			# Если смотрим влево (-1), scale.x тоже -1
			sword_hitbox.scale.x = -1 if direction < 0 else 1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func update_animations():
	if is_on_floor():
		if velocity.x == 0:
			anim.play("Idle")
		else:
			anim.play("Moving")
	else:
		# Можно добавить анимацию прыжка/падения
		pass


func start_attack():
	is_attacking = true
	anim.play("Attack")
	velocity.x = 0

	# Включаем хитбокс меча
	if sword_hitbox:
		sword_hitbox.monitoring = true


func _on_animation_finished():
	if anim.animation == "Attack":
		is_attacking = false
		if sword_hitbox:
			sword_hitbox.set_deferred("monitoring", false)
		update_animations()

	# Если закончилась анимация
	elif anim.animation == "Death":
		await get_tree().create_timer(1.0).timeout
		ScreenManager.load_menu()


# --- Обработка Здоровья ---


func _on_health_changed(new_val: int):
	# Визуализация получения урона (мигание)
	_play_hurt_effect()
	Events.player_health_changed.emit(new_val, health_component.max_health)


func _play_hurt_effect():
	# Если мы уже умираем, не мигаем
	if is_dying:
		return

	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.RED, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)


func die():
	if is_dying:
		return

	is_dying = true

	# 1. Отключаем получение урона (на всякий случай дублируем тут)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitorable", false)

	# 2. Выключаем меч, чтобы труп не мог убивать
	if sword_hitbox:
		sword_hitbox.set_deferred("monitoring", false)

	# 3. Останавливаем физику
	velocity = Vector2.ZERO

	# 4. Запускаем анимацию
	anim.play("Death")
	Events.player_died.emit()


# --- Setup ---


func _setup_components():
	# 1. Health Component
	if not health_component:
		health_component = get_node_or_null("HealthComponent")

	if health_component:
		health_component.died.connect(die)
		health_component.health_changed.connect(_on_health_changed)
	else:
		printerr("CRITICAL: HealthComponent не найден у игрока!")

	# 2. Hurtbox (Прием урона)
	if not hurtbox_component:
		hurtbox_component = get_node_or_null("HurtboxComponent")

	if hurtbox_component:
		# Связываем Hurtbox с HealthComponent
		hurtbox_component.health_component = health_component
	else:
		printerr("WARNING: Player не имеет HurtboxComponent и бессмертен.")

	# 3. Hitbox (Меч)
	if not sword_hitbox:
		sword_hitbox = get_node_or_null("SwordHitbox")

	if sword_hitbox:
		sword_hitbox.monitoring = false  # Выключен по умолчанию
		sword_hitbox.monitorable = false
