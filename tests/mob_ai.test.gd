extends "res://addons/gut/test.gd"

# Загружаем сцены
var MobScene = preload("res://src/entities/enemies/mob.tscn")
var PlayerScene = preload("res://src/entities/player/player.tscn")


func test_mob_detects_player_and_chases():
	# 1. Спавним моба и игрока
	var mob = MobScene.instantiate()
	var player = PlayerScene.instantiate()

	# Добавляем их в сцену теста, чтобы работала физика
	add_child_autofree(mob)
	add_child_autofree(player)

	# 2. Разносим их далеко друг от друга
	mob.global_position = Vector2(0, 0)
	player.global_position = Vector2(1000, 0)

	# Ждем пару кадров физики, чтобы инициализация прошла
	await wait_seconds(0.2)

	# ПРОВЕРКА 1: Моб спокоен
	assert_false(mob.chase, "Моб не должен преследовать игрока, который далеко")
	assert_eq(mob.velocity.x, 0.0, "Моб должен стоять на месте")

	# 3. "Телепортируем" игрока прямо под нос мобу (в зону агро)
	# Предполагаем, что радиус агро у нас около 100-200 пикселей
	player.global_position = Vector2(50, 0)

	# Эмулируем движение, чтобы сработал сигнал Events.player_moved (если он используется)
	# и физический движок обсчитал столкновение зон
	await wait_seconds(0.5)

	# ПРОВЕРКА 2: Моб должен "возбудиться"
	assert_true(mob.chase, "Моб должен включить режим погони (chase = true), когда игрок рядом")

	# Если моб увидел игрока, он должен начать двигаться
	# (мы проверяем не равенство нулю, а то что скорость изменилась)
	assert_ne(mob.velocity.x, 0.0, "Скорость моба не должна быть нулевой при погоне")


func test_mob_collision_masks_configuration():
	# Этот тест проверяет настройки сцены БЕЗ запуска физики.
	# Он скажет нам, правильно ли выставлены галочки в редакторе.
	var mob = MobScene.instantiate()
	var aggro_area = mob.get_node("AggroArea")

	autofree(mob)

	# Слой 1 = World (бит 0)
	# Слой 2 = Player (бит 1)
	# Слой 3 = Enemies (бит 2)

	# 1. Проверяем AggroArea (Зона обнаружения)
	# Она должна видеть Игрока (Слой 2, Value = 2^1 = 2)
	var aggro_mask = aggro_area.collision_mask
	# Проверяем побитово, включен ли 2-й слой
	var sees_player = (aggro_mask & 2) != 0
	assert_true(
		sees_player, "Ошибка настройки: AggroArea не имеет маски на Слой 2 (Player). Моб слепой."
	)
