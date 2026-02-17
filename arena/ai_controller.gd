extends AIController2D


@export var is_blue: bool

func get_obs() -> Dictionary:
	var obs: Array[float] = get_parent().get_observation(is_blue)
	
	return {"obs": obs}


func get_reward() -> float:
	assert(false, "the get_reward method is not implemented when extending from ai_controller") 
	return 0.0


func get_action_space() -> Dictionary:
	return {
		"card_confidences" : {
			"size": 4,
			"action_type": "continuous"
		},
		"placement_position" : {
			"size": 2,
			"action_type": "continuous"
		},
		}
	
func set_action(action) -> void:	
	assert(false, "the get set_action method is not implemented when extending from ai_controller") 	
# -----------------------------------------------------------------------------#
