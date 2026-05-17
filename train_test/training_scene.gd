extends Node


func _init() -> void:
	# Tweak global settings so training can occur
	Global.is_training = true
