extends MenuPanel


func _on_resolution_item_selected(index: int) -> void:
	var text = $VBoxContainer/HBoxContainer/Resolution.get_item_text(index)
	
	var resolution: Vector2i
	match text:
		"1920x1080":
			resolution = Vector2(1920, 1080)
		"1280x720":
			resolution = Vector2(1280, 720)
		"640x360":
			resolution = Vector2(640, 360)
	
	var screen_resolution := DisplayServer.screen_get_size()
	
	var screen_mode: int
	if screen_resolution == resolution:
		screen_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	else:
		screen_mode = DisplayServer.WINDOW_MODE_WINDOWED
	
	DisplayServer.window_set_mode(screen_mode)
	get_viewport().size = resolution
