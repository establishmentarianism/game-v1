class_name Mob
extends CharacterBody2D

# --- Настройки ---
@export var speed = 100
@export var gravity_scale = 1.0

# --- Состояние ---
var chase = false
var alive = true
var target_pos: Vector2 = Vector2.ZERO

var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Узлы ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var aggro_area: Area2D = $AggroArea
# Имя узла "Dmage" сохранено как в сцене
@onready var damage_area: Area2D = $Dmage
@onready var death_area: Area2D = $MobDeath


func _ready():
	add_to_group("enemies")

	# 1. Глобальные события (для обновления позиции игрока)
	Events.player_moved.connect(_on_player_moved)

	# 2. Ищем игрока сразу, чтобы не ждать первого движения
	var player = get_tree().get_first_node_in_group("player")
	if player:
		target_pos = player.global_position

	# 3. БЕЗОПАСНОЕ ПОДКЛЮЧЕНИЕ СИГНАЛОВ
	# Проверяем is_connected перед подключением, чтобы избежать ошибки "Already connected"

	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)

		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	else:
		printerr("CRITICAL: AggroArea не найдена в Mob!")

	if damage_area:
		if not damage_area.body_entered.is_connected(_on_damage_body_entered):
			damage_area.body_entered.connect(_on_damage_body_entered)

	if death_area:
		if not death_area.body_entered.is_connected(_on_weak_spot_body_entered):
			death_area.body_entered.connect(_on_weak_spot_body_entered)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += default_gravity * gravity_scale * delta

	if alive:
		if chase:
			var direction_vector = target_pos - position
			if direction_vector.length() > 10:
				var direction = direction_vector.normalized()
				velocity.x = direction.x * speed
				anim_sprite.flip_h = direction.x < 0
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()


func _on_player_moved(pos: Vector2):
	target_pos = pos


# --- Обработчики Зон ---


func _on_aggro_area_body_entered(body):
	if body.is_in_group("player"):
		chase = true
		# print("Mob: Вижу игрока!")


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

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
