extends MenuPanel


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
