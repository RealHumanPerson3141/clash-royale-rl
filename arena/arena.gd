extends Node2D


signal round_ended()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		reset()


func reset():
	$BluePlayer.reset()
	$RedPlayer.reset()
	
	$MatchTimer.start()
	
	round_ended.emit()
	
