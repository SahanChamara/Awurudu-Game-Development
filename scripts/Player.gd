extends CharacterBody2D
var score: int = 0
const FALL_PENALTY: int = 30
const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const LADDER_FALL_SPEED = 400.0
const KNOCKBACK_FORCE = 300.0
const HIT_STUN_DURATION = 0.5
const KNOCKBACK_DECAY = 0.85
const CLIMB_WRAP_POINT = -1000
const WRAP_AMOUNT = 2000
var is_climbing := false
var climb_start_y := 0.0
const CLIMB_SCORE_MULTIPLIER := 2.0
#@onready var anim = get_node("AnimationPlayer")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ladder_ray_cast: RayCast2D = $LadderRayCast
@onready var hit_cooldown_timer: Timer = $HitCooldownTimer
#@onready var score_label: Label = $"../HUD/Label"
var can_take_damage = true
var is_hit = false
var was_on_ladder = false  # Track previous ladder state
var knockback_velocity = Vector2.ZERO
var is_knockback_active = false
var health = 1  # Player dies in one hit

func _ready():
	set_invincible(true)
	await get_tree().create_timer(1.0).timeout
	# Initialize score in GameManager
	GameManager.update_score(score)

func set_invincible(value: bool):
	can_take_damage = not value
	modulate.a = 0.5 if value else  1.0

func _physics_process(delta: float) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("BirdEnemy"):
			print("direct collision with bird detected")
			take_damage(collider)		
	
	if ladder_ray_cast.get_collider() and Input.is_action_pressed("ui_up"):
		if !is_climbing:
			is_climbing = true
			climb_start_y = position.y
		else:
			var distance_climbed = climb_start_y - position.y
			if distance_climbed > 0:
				score += int(distance_climbed * CLIMB_SCORE_MULTIPLIER)
				GameManager.update_score(score)  # Update score in GameManager
				climb_start_y = position.y
	else:
		is_climbing = false
		
	print("Climbing: ", is_climbing, " | Climbed: ", climb_start_y - position.y, " | Score: ", score)
		
	if velocity.y > LADDER_FALL_SPEED * 0.8:
		score = max(0, score - FALL_PENALTY)
		GameManager.update_score(score)  # Update score in GameManager
	
	if is_knockback_active:
		velocity = knockback_velocity
		knockback_velocity *= KNOCKBACK_DECAY
		
		velocity.y += get_gravity().y * delta
		
		if knockback_velocity.length() < 50.0:
			is_knockback_active = false
			is_hit = false
			
		move_and_slide()
		return
		
	var laddercollider = ladder_ray_cast.get_collider()
	
	if laddercollider and not is_hit:  # Only climb if not hit
		was_on_ladder = true
		_ladder_climb(delta)
	else:
		if was_on_ladder:
			# Just left ladder - small cooldown before regular movement
			velocity.y = LADDER_FALL_SPEED
			was_on_ladder = false
		_movement(delta)
		
	velocity.x = 0
	
	_setAnimation()
	move_and_slide()
	
func _ladder_climb(delta):
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction: 
		velocity = direction * SPEED / 10
	else: 
		velocity = Vector2(0, LADDER_FALL_SPEED)

func _movement(delta):
	# Add the gravity.
	if not is_on_floor(): 
		velocity.y += get_gravity().y * delta
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Get the input direction
	var direction := Input.get_axis("ui_left", "ui_right")    
	if direction:
		velocity.x = direction * SPEED         
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _setAnimation() -> void:
	if velocity.x < 0: 
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0: 
		animated_sprite_2d.flip_h = false

func _on_hit_area_body_entered(body):
	print("Player hit by: ", body.name)
	if body.is_in_group("BirdEnemy") and can_take_damage:
		print("Taking damage from bird enemy")
		take_damage(body)
	else:
		print("Hit by: ", body.name, " is in BirdEnemy group: ", body.is_in_group("BirdEnemy"), " can take damage: ", can_take_damage)
		
func take_damage(hitting_bird):   
	if !can_take_damage:
		return
		 
	health -= 1
	print("Player health: ", health)
	
	var knockback_direction = (global_position - hitting_bird.global_position).normalized()
	knockback_velocity = knockback_direction * KNOCKBACK_FORCE
	knockback_velocity.y = abs(knockback_velocity.y) * 1.5  # Ensure downward knock
	
	is_knockback_active = true
	is_hit = true
	can_take_damage = false
	was_on_ladder = false  # Force exit ladder state
	hit_cooldown_timer.start(HIT_STUN_DURATION)
	
	# Check if player is dead
	if health <= 0:
		# Call game over
		GameManager.end_game()

func _on_hit_cooldown_timer_timeout():
	is_hit = false
	can_take_damage = true
