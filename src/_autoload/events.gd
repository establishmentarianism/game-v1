extends Node

# @warning_ignore("unused_signal") отключает предупреждение только для следующей строки.
# Для чистоты кода в Event Bus можно игнорировать их массово,
# либо просто принять как данность. Но вот способ убрать ошибки:

# Сигнал для передачи позиции игрока (чтобы мобы знали, куда бежать)
@warning_ignore("unused_signal")
signal player_moved(position: Vector2)

# Сигналы игровой логики
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal score_changed(new_score: int)

# Сигнал для UI (чтобы не искать игрока через ../../)
@warning_ignore("unused_signal")
signal player_health_changed(current: int, max_health: int)
