# BirdEnemy.gd
extends CharacterBody2D

@export var fly_speed := 50.0
@export var detection_range := 300.0
@export var attack_speed := 250.0
@export var hit_cooldown := 1.0

var can_attack := true
var player_ref = null
var is_attacking := false

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var timer = $Timer
@onready var visibility_notifier = $VisibleOnScreenNotifier2D

func _ready():
	add_to_group("BirdEnemy")
	
	visibility_notifier.screen_exited.connect(_on_screen_exited)
	timer.wait_time = randf_range(1.0, 3.0)
	timer.start()

func _physics_process(delta):
	if player_ref:
		_chase_player(delta)
	else:
		_patrol(delta)
	
	move_and_slide()
	_update_animation()

func _patrol(delta):
	# Simple back-and-forth movement when not chasing
	velocity.x = fly_speed * (1 if animated_sprite.flip_h else 1)
	velocity.y = sin(Time.get_ticks_msec() * 0.002) * 30

func _chase_player(delta):
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * (attack_speed if is_attacking else fly_speed)
	
	# Face the player
	animated_sprite.flip_h = direction.x > 0

func _update_animation():
	animated_sprite.play("fly")
	if velocity.length() > 0:
		animated_sprite.speed_scale = 1.5 if is_attacking else 1.0

func _on_detection_area_body_entered(body):
	if body.name == "Player":
		player_ref = body
		timer.start()

func _on_detection_area_body_exited(body):
	if body == player_ref:
		player_ref = null
		is_attacking = false

func _on_timer_timeout():
	if can_attack and player_ref:
		is_attacking = true
		can_attack = false
		timer.wait_time = randf_range(0.5, 1.5)
		timer.start()
		
		#get_tree().create_timer(hit_cooldown).timeout.connect(_reset_attack)
		if get_tree().get_nodes_in_group("bird_cooldown").size() == 0:
			var cooldown_timer = get_tree().create_timer(hit_cooldown)
			cooldown_timer.add_to_group("bird_cooldown")
			cooldown_timer.timeout.connect(_reset_attack)
		
func _reset_attack():
	can_attack = true

func _on_screen_exited():
	queue_free()
