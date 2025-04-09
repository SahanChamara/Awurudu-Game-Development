extends Label

func _process(delta):
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		text = "Score: %d" % players[0].score
	else:
		text = "Score: 0 (Player not found)"
