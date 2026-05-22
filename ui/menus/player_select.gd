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
	Global.is_blue_ai = blue_buttons.get_pressed_button().name == "AI"
	Global.is_red_ai = red_buttons.get_pressed_button().name == "AI"
	
	get_tree().change_scene_to_file("res://arena/arena.tscn")
