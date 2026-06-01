class_name MenuPanel
extends PanelContainer


signal closed()

@export var title: String


func _ready() -> void:
	$VBoxContainer/Label.text = title


func _on_return_pressed() -> void:
	visible = false
	closed.emit()
