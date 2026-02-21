class_name Player
extends Area2D


signal card_placed()
signal elixir_changed(new: float)
signal king_died()

@export var is_blue: bool
@export var enemy: Player

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

var selected := -1

var _elixir := 5.0
var elixir: float:
	get:
		return _elixir
	set(value):
		_elixir = min(value, 10)
		elixir_changed.emit(_elixir)

@onready var hand := Hand.new(deck)

@onready var king_tower := $CrownTowers/King


func _ready() -> void:
	if not is_blue:
		var towers = get_crown_towers()
		
		for tower in towers:
			tower.is_blue = false
			tower.update_color()
			
			tower.position.x = 640 - tower.position.x
	
	enemy.input_event.connect(_on_enemy_input_event)
	
	# See only enemies
	collision_mask = 2 - int(not is_blue)


func get_crown_towers() -> Array[Card]:
	var towers: Array[Card] = []
	towers.assign($CrownTowers.get_children())
	
	return towers


func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	
	cards.assign($Cards.get_children())
	
	return cards


func get_observation() -> Array[float]:
	var obs: Array[float] = []
	
	obs.append(elixir)
	
	obs.append_array(hand.get_observation())
	obs.append_array(enemy.hand.get_observation())
	
	const CARD_OBS_SIZE = 4
	const MAX_CARDS_PER_SIDE = 10
	
	for cards in [get_cards(), enemy.get_cards()]:
		for card in cards:
			obs.append_array(card.get_observation(is_blue))
	
		assert(len(cards) <= MAX_CARDS_PER_SIDE, "maximum card observation reached")
		
		for i in range(CARD_OBS_SIZE * (MAX_CARDS_PER_SIDE - len(cards))):
			obs.append(0)
	
	
	return obs


func place_card(pos: Vector2):
	if selected == -1:
		return
	
	var card = hand.get_card(selected)
	if elixir < card.elixir:
		return
	
	var stats := hand.draw_card(selected)
	
	_instantiate_card(stats, pos)
	
	card_placed.emit()


func is_winning():
	var princess_towers = get_crown_towers()
	princess_towers.erase(king_tower)
	
	var enemy_princess_towers = enemy.get_crown_towers()
	enemy_princess_towers.erase(enemy.king_tower)
	
	if len(princess_towers) > len(enemy_princess_towers):
		return true
	
	var lowest_tower := 3052.0
	for tower in princess_towers:
		if tower.current_hp < lowest_tower:
			lowest_tower = tower.current_hp
			
	var lowest_enemy_tower = 3052.0
	for tower in enemy_princess_towers:
		if tower.current_hp < lowest_tower:
			lowest_enemy_tower = tower.current_hp
	
	
	print(lowest_tower, lowest_enemy_tower)
	if lowest_tower > lowest_enemy_tower:
		return true
	
	return false


func reset():
	for tower in get_crown_towers():
		tower.reset()
	
	for card in get_cards():
		card.queue_free()
	
	elixir = 5.0
	hand = Hand.new(deck)
	
	$AIController2D.reset()


func _instantiate_card(stats: CardStats, pos: Vector2):
	elixir -= stats.elixir
	
	for i in range(stats.count):
		var card := card_scene.instantiate()
		
		card.stats = stats
		card.is_blue = is_blue
		# Slightly randomize card placement to avoid repulsion artefacts
		card.position = pos + Vector2(randf() * 2 - 1, randf() * 2 - 1)
		
		var color := "blue" if is_blue else "red"
		var unique_id := str(get_tree().get_node_count_in_group(color))
		card.name = color.capitalize() + stats.resource_name + unique_id
		
		card.targets.append_array(enemy.get_crown_towers())
		
		$Cards.add_child(card)


func _on_selected_changed(new: int):
	selected = new


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var action_name = "place_blue" if is_blue else "place_red"
	
	if event.is_action_pressed(action_name):
		place_card(get_global_mouse_position())


func _on_enemy_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var action_name = "place_blue" if is_blue else "place_red"
	
	if selected == -1:
		return
	
	if event.is_action_pressed(action_name) and hand.get_card(selected).is_spell:
		place_card(get_global_mouse_position())


func _on_elixir_timer_timeout() -> void:
	elixir += 0.25


func _on_reward_timer_timeout() -> void:
	$AIController2D.reward += 1 if is_winning() else -1
	# Penalize enemies on player's side
	$AIController2D.reward -= len(get_overlapping_areas()) / 4.0
	
	if is_blue:
		print(get_observation())


func _on_king_died() -> void:
	king_died.emit()
