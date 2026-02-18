extends TextureProgressBar


func _on_elixir_changed(new: float):
	value = new
	
	find_child("Label").text = str(int(new))
