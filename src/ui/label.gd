extends Label


func _ready() -> void:
	# Подписываемся на глобальное событие изменения здоровья
	Events.player_health_changed.connect(update_health_text)
	text = "HP: 100"  # Начальное значение


func update_health_text(current: int, _max: int):
	text = "HP: " + str(current)
