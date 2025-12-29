extends CharacterBody2D
class_name Player

# --- Настройки ---
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# --- Зависимости ---
# Теперь это необязательно назначать вручную, но можно
@export var health_component: HealthComponent
@onready var anim = $AnimatedSprite2D

# --- Состояние ---
var gold = 0
var is_attacking = false

func _ready():
	add_to_group("player")
	anim.animation_finished.connect(_on_animation_finished)

	# --- АВТОПОИСК КОМПОНЕНТА ---
	# 1. Если не назначено в Инспекторе, ищем по имени "Health Component" (с пробелом)
	if not health_component:
		health_component = get_node_or_null("Health Component")

	# 2. Если все еще нет, ищем по имени без пробела (на всякий случай)
	if not health_component:
		health_component = get_node_or_null("HealthComponent")

	# 3. Финальная проверка и подключение
	if health_component:
		health_component.died.connect(die)
		health_component.health_changed.connect(_on_health_changed)
		print("Player: HealthComponent успешно подключен.")
	else:
		printerr("CRITICAL: HealthComponent не найден! Убедись, что у игрока есть дочерний узел 'Health Component'.")
		# Чтобы игра не упала с криш-ошибкой, просто выходим
		return

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Сообщаем позицию
	Events.player_moved.emit(global_position)

	# Атака
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		start_attack()

	# Движение
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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func update_animations():
	if is_on_floor():
		if velocity.x == 0:
			anim.play("Idle")
		else:
			anim.play("Moving")

func start_attack():
	is_attacking = true
	anim.play("Attack")
	velocity.x = 0

func _on_animation_finished():
	if anim.animation == "Attack":
		is_attacking = false
		update_animations()

func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)

func _on_health_changed(new_val: int):
	if health_component:
		Events.player_health_changed.emit(new_val, health_component.max_health)

func die():
	set_physics_process(false)
	anim.play("Death")
	Events.player_died.emit()
	await anim.animation_finished
	ScreenManager.load_menu()
