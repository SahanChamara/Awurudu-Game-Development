# BirdSpawner.gd
extends Node2D

@export var bird_scene: PackedScene
@export var spawn_rate: float = 5.0
@export var max_birds: int = 2
@export var spawn_area: Rect2 = Rect2(100, -300, 500, 200)  # x,y,width,height

@onready var timer = $Timer
var current_birds = 0

func _ready():
	await get_tree().create_timer(1.0).timeout
	timer.start()
	timer.wait_time = spawn_rate
	timer.timeout.connect(_spawn_bird)
	timer.start()

func _spawn_bird():
	if current_birds >= max_birds:
		return
	
	#var player = get_tree().get_nodes_in_group("Player")[0]	
	var bird = bird_scene.instantiate()	
	bird.add_to_group("BirdEnemy")
		
	# Set random position within spawn area (above player)
	bird.position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	
	add_child(bird)
	current_birds += 1	
	# Connect to bird's tree_exited signal to track when it's removed
	bird.tree_exited.connect(_on_bird_removed)

func _on_bird_removed():
	current_birds -= 1
