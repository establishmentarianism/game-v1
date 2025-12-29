extends Label


func _ready() -> void:
	# Подписываемся на изменение счета (нужно добавить сигнал в Events, если его нет,
	# или использовать _process временно)
	pass


func _process(_delta):
	# Временное решение: ищем игрока, чтобы показать золото.
	# В будущем переделаем на сигналы (Events.gold_changed)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		text = "Gold: " + str(player.gold)
