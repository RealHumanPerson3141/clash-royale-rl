extends Node2D

var deck := range(1,9)

var queue
var hand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("deck:", deck)
	
	var deck_duplicate = deck.duplicate()
	deck_duplicate.shuffle()
	
	hand = deck_duplicate.slice(4)
	queue = deck_duplicate.slice(0, 4)
	
	_display_hand()
	

func _display_hand():
	print("hand: ", hand)
	print("next: ", queue[0])


func _input(event: InputEvent) -> void:
	var index := -1
	
	if event.is_action_pressed("one"):
		index = 0
	if event.is_action_pressed("two"):
		index = 1
	if event.is_action_pressed("three"):
		index = 2
	if event.is_action_pressed("four"):
		index = 3
	
	if index == -1:
		return
	
	print("used #%d card " % (index + 1), "(%d)" % hand[index])
	
	queue.push_back(hand[index])
	hand[index] = queue.pop_front()
	
	_display_hand()
