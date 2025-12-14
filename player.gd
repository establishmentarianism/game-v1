extends CharacterBody2D

enum{
	Attack,
	Idle,
	Death,
	Moving,
	Block,
	Falling,
	Sliding
}

var health = 100
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var anim=$AnimatedSprite2D
var gold = 0
var state=Moving

func _physics_process(delta):
	match state:
		Moving:
			move_state()
		Attack:
			pass
		Death:
			pass
		Idle:
			pass
		Block:
			block_state()
		Falling:
			pass
		Sliding:
			slide_state()
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("ui_accept"):
		anim.play("Attack")
		#await anim.animation_finished
	if not is_on_floor():
		state=Falling
	if is_on_floor():
		state=Moving
	if health<=0:
		anim.play("Death")
		get_tree().change_scene_to_file("res://menu.tscn")
	move_and_slide()
var direction := Input.get_axis("ui_left", "ui_right")
func move_state():
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.play("Moving")
		#if velocity.y==0:
		#	anim.play("Moving")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		anim.play("Idle")
		#if velocity.y==0:
		#	anim.play("Idle")
	if direction==-1:
		$AnimatedSprite2D.flip_h = true
	elif direction==1:
		$AnimatedSprite2D.flip_h= false
		
	if Input.is_action_just_pressed("ui_accept"):
		state=Attack
	if Input.is_action_just_pressed("ui_down"):
		if velocity.x==0:
			state = Block
		#else:
			#state=Sliding
func block_state():
	velocity.x=0
	anim.play("Idle")
	if Input.is_action_just_released("ui_down"):
		state=Moving
func slide_state():
	velocity.x=500*direction

func attack_state():
	velocity.x=0
	anim.play("Attack")
	await anim.animation_finished
	state=Moving
