extends AIController2D


@onready var player := get_parent() as Player

func get_obs() -> Dictionary:
	var obs: Array[float] = get_parent().get_observation()
	return {"obs": obs}


func get_reward() -> float:
	# Reward is modified directly in the player script (as is done in the examples supplied by gdrl)
	return reward


func get_action_space() -> Dictionary:
	return {
		"selected_card" : {
			"size": 4,
			"action_type": "discrete"
		},
		# Can be either 0 or 1. 0 represents the bottom row and 1 the top row
		"placement_row" : {
			"size": 2,
			"action_type": "discrete"
		},
		# If 0, don't place the card. Otherwise, place it
		"place_card" : {
			"size": 2,
			"action_type": "discrete"
		}
		}
	
func set_action(action) -> void:
	# Only place a card if this value is 1
	if action.place_card == 0:
		return
	
	var pos = Vector2()
	
	# Unfortunately hard coded, but these are the y 
	# coordinates of the middle of the top and bottom rows.
	pos.y = 89 if action.placement_row == 1 else 264
	
	# Assist AI in placing projectiles
	var enemies = player.enemy.get_cards(1 if pos.y == 89 else -1)
	if player.hand.get_card(action.selected_card).is_spell and not enemies.is_empty():
		# Absolute spaghetti
		# Target the backmost enemy with a spell, offsetted to match movement speed.
		pos.x = enemies.back().position.x - (64 if player.is_blue else -64)
	else:
		# This represents either right in front of the princess towers.
		pos.x = 192 if player.is_blue else 640 - 192
	
	player.selected = action.selected_card
	
	player.place_card(pos)
