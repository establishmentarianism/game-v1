extends CharacterBody2D

var gravity=ProjectSettings.get_setting("physics/2d/default_gravity")

var chase = false
var speed=100
var alive = true

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	var player=$"../../Player/Player"
	var direction = (player.position-self.position).normalized()
	if alive==true:
		if chase==true:
			velocity.x=direction.x*speed
			move_and_slide()


func _on_aggro_area_body_entered(body):
	if body.name=="Player":
		chase=true


func _on_aggro_area_body_exited(body):
	if body.name=="Player":
		chase=false


func _on_death_body_entered(body):
	if body.name=="Player":
		body.velocity.y-=200
		death()

func _on_player_death_body_entered(body):
	if body.name=="Player":
		body.health=body.health-40
		death()# Replace with function body.func _on_player_death_entered(body):
	

func death():
	alive=false
	#anim.play("Death")
	#await anim.animation_finished
	queue_free()
