extends VBoxContainer


signal selected_changed(new: int)

@export var player: Player

@onready var button_group := ButtonGroup.new()


func _ready() -> void:
	if player == null:
		queue_free()
	
	player.card_placed.connect(update)
	
	var color_name = "blue" if player.is_blue else "red"
	
	var slot_texture := load("res://ui/cards/assets/card_slot_%s.png" % color_name)
	var next_texture := load("res://ui/cards/assets/next_card_slot_%s.png" % color_name)
	
	for slot in find_children("CardSlot?"):
		slot.texture = slot_texture
	
	$NextCard.texture = next_texture
	
	# Make all CardFrames have the same button group
	for frame in find_children("CardFrame"):
		frame.button_group = button_group
	
	button_group.allow_unpress = true
	
	update()


func update() -> void:
	var hand := player.hand
	
	for i in range(4):
		var card = hand.get_card(i)
		
		var slot = get_child(i)
		
		slot.get_node("Card").texture = card.card_sprite
		slot.get_node("Elixir/Label").text = str(card.elixir)
	
	$NextCard/Card.texture = hand.get_next().card_sprite


func _on_card_toggled(_toggled_on: bool):
	if button_group.get_pressed_button() == null:
		selected_changed.emit(-1)
		return
	
	selected_changed.emit(button_group.get_pressed_button().get_node("../..").get_index())


func _on_card_placed() -> void:
	button_group.get_pressed_button().button_pressed = false
