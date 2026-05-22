extends Node2D


signal round_ended()

var blue_score := 0
var red_score := 0


func _ready() -> void:
	# This signal needs to be emitted in order to activate the AI sync node.
	# However, it doesn't emit when changing scenes, so we update it manually.
	get_tree().root.ready.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		reset()
	if event.is_action_pressed("test"):
		print("Blue:", $BluePlayer.get_observation())
		print("Red:", $RedPlayer.get_observation())


func end_match() -> void:
	if Global.is_training:
		reset()
	else:
		$UI/GameOver.visible = true
		get_tree().paused = true


func reset():
	$BluePlayer.reset()
	$RedPlayer.reset()
	
	$MatchTimer.start()
	
	$UI/MarginContainerTop/PanelContainer/Score.text = "0 - 0"
	
	round_ended.emit()


func _on_tower_died() -> void:
	var score_label = $UI/MarginContainerTop/PanelContainer/Score
	score_label.text = "%s - %s" % [$BluePlayer.score, $RedPlayer.score]
	
	if $BluePlayer.king_tower.current_hp < 0 or $RedPlayer.king_tower.current_hp < 0:
		end_match()


func _on_play_again() -> void:
	get_tree().paused = false
	reset()
