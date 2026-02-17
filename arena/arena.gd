extends Node2D


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

@export var blue_hand_ui: ButtonGroup
@export var red_hand_ui: ButtonGroup

var blue_elixir := 5.0
var red_elixir := 5.0

var on_blue := false
var on_red := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blue_hand = Hand.new(deck, $UI/MarginContainerLeft/BlueCards)
	red_hand = Hand.new(deck, $UI/MarginContainerRight/RedCards)
	
	print(blue_hand, "\n")
	print(red_hand)


func get_observation(is_observer_blue: bool) -> Array[float]:
	var obs: Array[float] = []
	
	if is_observer_blue:
		obs.append(blue_elixir)
		
		obs.append_array(blue_hand.get_observation())
		obs.append_array(red_hand.get_observation())
	else:
		obs.append(red_elixir)
		
		obs.append_array(red_hand.get_observation())
		obs.append_array(blue_hand.get_observation())
	
	var blue_cards := get_tree().get_nodes_in_group("blue").slice(3)
	var red_cards := get_tree().get_nodes_in_group("red").slice(3)
	
	var cards_order = [blue_cards, red_cards] if is_observer_blue else [red_cards, blue_cards]
	
	const CARD_OBS_SIZE = 5
	const MAX_CARDS = 16
	
	for cards in cards_order:
		for card in cards:
			obs.append_array(card.get_observation(is_observer_blue))
	
		for i in range(CARD_OBS_SIZE * (MAX_CARDS - len(cards))):
			obs.append(0)
	
	return obs


func _instantiate_card(stats: CardStats, is_blue: bool):
	if is_blue:
		blue_elixir -= stats.elixir
	else:
		red_elixir -= stats.elixir
	
	_update_elixir_ui()
	
	for i in range(stats.count):
		var card := card_scene.instantiate()
		
		card.stats = stats
		card.is_blue = is_blue
		# Slightly randomize card placement to avoid repulsion artefacts
		card.position = get_global_mouse_position() + Vector2(randf() * 2 - 1, randf() * 2 - 1)
		
		var color := "blue" if is_blue else "red"
		var unique_id := str(get_tree().get_node_count_in_group(color))
		card.name = color.capitalize() + stats.resource_name + unique_id
		
		$Cards.add_child(card)


func _update_elixir_ui():
	var blue_bar = $UI/MarginContainerBottom/HBoxContainer/BlueElixir
	var red_bar = $UI/MarginContainerBottom/HBoxContainer/RedElixir
	
	blue_bar.value = blue_elixir
	red_bar.value = red_elixir
	
	blue_bar.get_child(0).get_child(0).text = str(int(blue_elixir))
	red_bar.get_child(0).get_child(0).text = str(int(red_elixir))


func _place_card(is_blue: bool, hand: Hand, button_group: ButtonGroup):
	var selected_card = button_group.get_pressed_button()
	if selected_card == null:
		return
		
	selected_card.button_pressed = false
		
	# Hierarchy finagling
	var index = selected_card.get_parent().get_parent().get_index()
		
	var elixir = blue_elixir if is_blue else red_elixir
	
	if not hand.sufficient_elixir(index, elixir):
		return
	
	var card_stats := hand.get_card(index)
	
	_instantiate_card(card_stats, is_blue)


func _on_elixir_timer_timeout() -> void:
	if red_elixir < 10:
		red_elixir += 0.25
	if blue_elixir < 10:
		blue_elixir += 0.25
	
	_update_elixir_ui()


func _on_arena_collider_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var blue_spell := false
	var red_spell := false
	
	if blue_hand_ui.get_pressed_button() != null:
		blue_spell = blue_hand.is_spell(blue_hand_ui.get_pressed_button().get_node("../..").get_index())
	if red_hand_ui.get_pressed_button() != null:
		red_spell = red_hand.is_spell(red_hand_ui.get_pressed_button().get_node("../..").get_index())
	
	if event.is_action_pressed("place_blue") and (on_blue or (blue_spell and on_red)):
		_place_card(true, blue_hand, blue_hand_ui)
		print(get_observation(true), len(get_observation(true)))
	
	if event.is_action_pressed("place_red") and (on_red or (red_spell and on_blue)):
		_place_card(false, red_hand, red_hand_ui)
		print(get_observation(false), len(get_observation(false)))


func _on_blue_side_mouse_entered() -> void:
	on_blue = true


func _on_blue_side_mouse_exited() -> void:
	on_blue = false


func _on_red_side_mouse_entered() -> void:
	on_red = true


func _on_red_side_mouse_exited() -> void:
	on_red = false


class Hand:
	var deck: Array[CardStats]
	var cards: Array[int]
	var next: Array[int]
	
	var ui: BoxContainer
	
	func _init(card_stats: Array[CardStats], box_container: BoxContainer):
		deck = card_stats
		ui = box_container
		
		cards = []
		
		var sorted_deck := range(8)
		for i in range(8):
			var random_index = sorted_deck.pop_at(randi_range(0, 7 - i))
			
			if i < 4:
				cards.append(random_index)
				_set_ui_card(i, deck[random_index])
			else:
				next.append(random_index)
		
		_set_ui_card(-1, deck[next[0]])
	
	
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
		
		_set_ui_card(index, deck[cards[index]])
		_set_ui_card(-1, deck[next[0]])
		
		return chosen_card
	
	
	func get_observation() -> Array[float]:
		var obs: Array[float] = []
	
		for card in cards:
			obs.append(deck[card].id)
			obs.append(deck[card].elixir)
		
		obs.append(deck[next[0]].id)
		
		return obs
	
	
	func sufficient_elixir(index: int, elixir: float) -> bool:
		return deck[cards[index]].elixir <= elixir
	
	
	func is_spell(index: int) -> bool:
		return deck[cards[index]].is_spell
	
	
	func _index_to_card_name(index: int) -> String:
		if index < 0 or index >= 8:
			return "Error"
			
		return deck[index].resource_name
	
	func _set_ui_card(hand_index: int, card: CardStats) -> void:
		var card_texture = ui.get_child(hand_index).get_child(0)
		card_texture.texture = card.card_sprite
		if hand_index >= 0 and hand_index < 4:
			var card_elixir_label = ui.get_child(hand_index).get_child(1).get_child(0)
			card_elixir_label.text = str(card.elixir)
