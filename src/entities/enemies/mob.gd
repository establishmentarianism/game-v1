extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var chase = false
var speed = 100
var alive = true
var target_pos: Vector2 = Vector2.ZERO

func _ready():
	# Моб подписывается на глобальный сигнал
	Events.player_moved.connect(_on_player_moved)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if alive and chase:
		var direction = (target_pos - position).normalized()
		velocity.x = direction.x * speed
		$AnimatedSprite2D.flip_h = direction.x < 0
		move_and_slide()
	
	# Если моб мертв или не преследует, он все равно должен падать (гравитация)
	if not chase or not alive:
		move_and_slide()

func _on_player_moved(pos: Vector2):
	target_pos = pos

# --- Зоны обнаружения ---

func _on_aggro_area_body_entered(body):
	# Проверка по группе надежнее
	if body.is_in_group("player"):
		print("Моб: Вижу игрока! Начинаю погоню.")
		chase = true

func _on_aggro_area_body_exited(body):
	if body.is_in_group("player"):
		print("Моб: Игрок убежал.")
		chase = false

# --- Зоны Атаки ---

func _on_death_body_entered(body):
	if body.is_in_group("player"):
		print("Моб: Убит игроком сверху.")
		body.velocity.y -= 200
		death()

func _on_player_death_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(40)
			print("Моб: Кусь! Нанес урон.")
		death()

func death():
	alive = false
	print("Моб: Умираю...")
	queue_free()
