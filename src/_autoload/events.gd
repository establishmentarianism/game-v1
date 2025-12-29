extends Node

# Сигнал для передачи позиции игрока (чтобы мобы знали, куда бежать)
signal player_moved(position: Vector2)

# Сигналы игровой логики
signal player_died
signal score_changed(new_score: int)

# Сигнал для UI (чтобы не искать игрока через ../../)
signal player_health_changed(current: int, max_health: int)
