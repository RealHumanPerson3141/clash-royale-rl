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
		"selected_card" : {
			"size": 4,
			"action_type": "discrete"
		},
		"placement_row" : {
			"size": 2,
			"action_type": "discrete"
		},
		"place_card" : {
			"size": 2,
			"action_type": "discrete"
		}
		}
	
func set_action(action) -> void:
	# Only place a card if this value is 1
	if action.place_card == 0:
		return
	
	print(action)
	
	var pos = Vector2()
	
	pos.x = 192 if player.is_blue else 640 - 192
	pos.y = 89 if action.placement_row == 0 else 264
	
	player.selected = action.selected_card
	player.place_card(pos)
