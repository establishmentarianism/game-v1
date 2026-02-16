extends Label
var a = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func _on_button_3_button_down() -> void:
	a += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	text = str(a)
