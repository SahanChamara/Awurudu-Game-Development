extends Control

@onready var score_label = $ScoreLabel

func _ready():
	# Connect to GameManager signals
	GameManager.score_updated.connect(_on_score_updated)
	
	# Initialize score display
	score_label.text = "Score: 0"

func _on_score_updated(new_score):
	score_label.text = "Score: " + str(new_score)
