extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var restart_button = $VBoxContainer/RestartButton

func _ready():
	# Display final score
	score_label.text = "Final Score: " + str(GameManager.current_score)
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# Reset score
	GameManager.reset_score()
	
	# Change back to main game scene
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
