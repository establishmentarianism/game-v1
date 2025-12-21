extends CharacterBody2D
class_name Player # Чтобы мобы вас видели

# --- Настройки ---
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# --- Состояние ---
var health = 100
var gold = 0
var is_attacking = false # Флаг: атакуем мы сейчас или нет

# --- Ссылки ---
@onready var anim = $AnimatedSprite2D

func _ready():
	# Сообщаем, что игрок появился (для мобов и UI)
	add_to_group("player")
	# Подключаем сигнал окончания анимации через код, чтобы не настраивать в редакторе
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# 1. Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Обработка Атаки
	# Если нажали атаку и мы сейчас не заняты атакой
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		start_attack()

	# 3. Движение (только если мы НЕ атакуем)
	# Мы хотим стоять на месте во время удара
	if is_attacking:
		velocity.x = 0
	else:
		handle_movement()

	# 4. Прыжок (Можно прыгать, если не атакуем)
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# 5. Применяем движение
	move_and_slide()
	
	# 6. Обновляем анимации (если не атакуем)
	if not is_attacking:
		update_animations()

	# 7. Смерть
	if health <= 0:
		die()

# --- Логика Движения ---
func handle_movement():
	# Получаем ввод (-1 влево, 1 вправо, 0 стоим)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		# Поворачиваем спрайт
		if direction < 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
	else:
		# Плавная остановка (или можно просто velocity.x = 0)
		velocity.x = move_toward(velocity.x, 0, SPEED)

# --- Логика Анимаций (Бег/Прыжок/Стойка) ---
func update_animations():
	if is_on_floor():
		if velocity.x == 0:
			anim.play("Idle")
		else:
			anim.play("Moving")
	else:
		# Если у вас есть анимация падения/прыжка, вставьте сюда
		# anim.play("Jump") 
		pass

# --- Логика Атаки ---
func start_attack():
	is_attacking = true
	anim.play("Attack")
	velocity.x = 0 # Стоп при ударе

# Этот метод вызовется сам, когда любая анимация доиграет до конца
func _on_animation_finished():
	if anim.animation == "Attack":
		is_attacking = false
		# После атаки сразу решаем, какую анимацию играть (чтобы не было мигания)
		update_animations()

# --- Получение урона ---
func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	set_physics_process(false) # Отключаем управление
	anim.play("Death")
	await anim.animation_finished # Ждем проигрывания смерти
	get_tree().change_scene_to_file("res://menu.tscn")