extends MenuPanel


var blue_buttons := ButtonGroup.new()
var red_buttons := ButtonGroup.new()


func _ready() -> void:
	super._ready()
	
	$VBoxContainer/HBoxContainer/BlueContainer/Human.button_group = blue_buttons
	$VBoxContainer/HBoxContainer/BlueContainer/AI.button_group = blue_buttons
	
	$VBoxContainer/HBoxContainer/RedContainer/Human.button_group = red_buttons
	$VBoxContainer/HBoxContainer/RedContainer/AI.button_group = red_buttons


func _on_start_game_pressed() -> void:
	# If blue is AI
	if blue_buttons.get_pressed_button().name == "AI":
		Global.blue_control_mode = AIController2D.ControlModes.ONNX_INFERENCE
	else:
		Global.blue_control_mode = AIController2D.ControlModes.HUMAN
	
	# If red is AI
	if red_buttons.get_pressed_button().name == "AI":
		Global.red_control_mode = AIController2D.ControlModes.ONNX_INFERENCE
	else:
		Global.red_control_mode = AIController2D.ControlModes.HUMAN
	
	get_tree().change_scene_to_file("res://arena/arena.tscn")
