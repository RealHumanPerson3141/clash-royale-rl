extends Node2D

# TODO: Replace this with an actual card placement system


var card_scene: PackedScene = preload("res://cards/card.tscn")
var deck: Array[CardStats] = [
	preload("res://cards/troops/knight/knight.tres"),
	preload("res://cards/spells/arrows/arrows.tres"),
	preload("res://cards/troops/archers/archers.tres"),
	preload("res://cards/troops/minions/minions.tres"),
	preload("res://cards/troops/mini_pekka/mini_pekka.tres"),
	preload("res://cards/spells/fireball/fireball.tres"),
	preload("res://cards/troops/giant/giant.tres"),
	preload("res://cards/troops/musketeer/musketeer.tres"),
]

var blue_hand: Hand
var red_hand: Hand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blue_hand = Hand.new(deck)
	red_hand = Hand.new(deck)
	
	print(blue_hand, "\n")
	print(red_hand)


func _input(event: InputEvent) -> void:
	for color in ["blue", "red"]:
		for index in range(4):
			if not event.is_action_pressed(color + "_" + str(index + 1)):
				continue
				
			var hand = blue_hand if color == "blue" else red_hand
			
			var card_stats := hand.get_card(index)
			
			var card := card_scene.instantiate()
			
			card.stats = card_stats
			card.is_blue = color == "blue"
			card.position = get_global_mouse_position()
			card.name = color.capitalize() + " " + card_stats.resource_name
			
			$Cards.add_child(card)
			
			print("\n" + card.name)


class Hand:
	var deck: Array[CardStats]
	var cards: Array[int]
	var next: Array[int]
	
	func _init(card_stats: Array[CardStats]):
		deck = card_stats
		cards = []
		
		var sorted_deck := range(8)
		for i in range(8):
			var random_card = sorted_deck.pop_at(randi_range(0, 7 - i))
			
			if i < 4:
				cards.append(random_card)
			else:
				next.append(random_card)
	
	func _to_string() -> String:
		var cards_str = "Cards: " + str(cards.map(_index_to_card_name)) + "\n"
		var next_str = "Next: " + str(next.map(_index_to_card_name))
		
		return cards_str + next_str
	
	func get_card(index: int) -> CardStats:
		if index < 0 or index >= 4:
			return null
		
		var chosen_card = deck[cards[index]]
		
		next.append(cards[index])
		cards.set(index, next.pop_front())
		
		return chosen_card
	
	func _index_to_card_name(index: int) -> String:
		if index < 0 or index >= 8:
			return "Error"
			
		return deck[index].resource_name
