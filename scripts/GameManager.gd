extends Node

var current_score: int = 0
var high_score: int = 0

signal score_updated(new_score)
signal game_over(final_score)

func _ready():
	# This ensures the GameManager isn't destroyed when changing scenes
	process_mode = Node.PROCESS_MODE_ALWAYS

func update_score(new_score: int) -> void:
	current_score = new_score
	if current_score > high_score:
		high_score = current_score
	score_updated.emit(current_score)

func reset_score() -> void:
	current_score = 0
	score_updated.emit(current_score)
	get_tree().paused = false

func end_game() -> void:
	print("GameManager: end_game called with score:", current_score)
	high_score = max(high_score, current_score)
	game_over.emit(current_score)
	
	# Don't pause the tree immediately as it might interfere with scene change
	# Instead use a separate timer to delay the scene change
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.timeout.connect(func(): _change_to_game_over())
	add_child(timer)
	timer.start()

func _change_to_game_over():
	print("Changing to GameOver scene")
	# Make sure the tree isn't paused when changing scenes
	get_tree().paused = false
	var result = get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	if result != OK:
		print("ERROR: Could not change to GameOver scene. Error code: ", result)
