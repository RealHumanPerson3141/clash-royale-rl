extends AIController2D


@onready var player := get_parent() as Player

func get_obs() -> Dictionary:
	var obs: Array[float] = get_parent().get_observation()
	return {"obs": obs}


func get_reward() -> float:
	reward = player.get_reward()
	
	return reward


func get_action_space() -> Dictionary:
	return {
		"card_confidences" : {
			"size": 4,
			"action_type": "continuous"
		},
		"placement_position" : {
			"size": 1,
			"action_type": "continuous"
		},
		}
	
func set_action(action) -> void:
	var confidences: Array[float]
	confidences.assign(action.card_confidences)
	
	var pos = Vector2()
	
	pos.y = action.placement_position[0] * 144 + 176
	pos.x = 192 if player.is_blue else 640 - 192
	
	var max_i = 0
	for i in range(1, 4):
		if confidences[i] > confidences[max_i]:
			max_i = i
	
	player.selected = max_i
	if confidences[max_i] > 0.5:
		player.place_card(pos)
