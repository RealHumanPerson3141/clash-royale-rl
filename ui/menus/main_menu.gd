extends Control


func _on_play_button_pressed() -> void:
	$PlayerSelect.visible = true
	$Main.visible = false


func _on_settings_button_pressed() -> void:
	$Settings.visible = true
	$Main.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_menu_panel_closed() -> void:
	$Main.visible = true
