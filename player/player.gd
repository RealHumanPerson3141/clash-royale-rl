class_name Player
extends Area2D


signal card_placed()
signal elixir_changed(new: float)
signal princess_died()
signal king_died()

@export var is_blue: bool
@export var enemy: Player

var card_scene: PackedScene = preload("res://cards/card.tscn")
var deck: Array[CardStats] = [ # This is the standard deck used in clash royale.
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
		# Elixir cannot exceed 10
		_elixir = min(value, 10)
		elixir_changed.emit(_elixir)

# The player's score, determined by the number of enemy towers remaining
var score: int = 0

@onready var hand := Hand.new(deck)

@onready var king_tower := $CrownTowers/King


func _ready() -> void:
	# Towers are blue by default. If the player is red, update the towers accordingly.
	if not is_blue:
		var towers = get_crown_towers()
		
		for tower in towers:
			tower.is_blue = false
			tower.update_color()
			
			tower.position.x = 640 - tower.position.x
	
	# Registers towers taking damage (used for AI reward function)
	for tower in get_crown_towers() + enemy.get_crown_towers():
		tower.took_damage.connect(_on_tower_damaged.bind(tower))
	
	# Register input events on the enemy's side
	enemy.input_event.connect(_on_enemy_input_event)
	
	# Change control mode of player to match global settings
	var control_mode = Global.blue_control_mode if is_blue else Global.red_control_mode
	$AIController2D.control_mode = control_mode


func get_crown_towers() -> Array[Card]:
	var towers: Array[Card] = []
	towers.assign($CrownTowers.get_children())
	
	return towers


## Gets cards summoned by the player.[br]
## If side is positive, only get cards from the top side, 
## and if side is negative, only get cards from the bottom side.
## If side is 0, get all cards.
func get_cards(side: int = 0) -> Array[Card]:
	var cards: Array[Card] = []
	
	cards.assign($Cards.get_children())
	
	if side == 0:
		return cards
	
	const MIDDLE_Y = 178 # Middle of the arena
	# Get cards above MIDDLE_Y
	if side > 0:
		cards = cards.filter(func(card): return card.position.y < MIDDLE_Y)
	# Get cards below MIDDLE_Y
	else:
		cards = cards.filter(func(card): return card.position.y > MIDDLE_Y)
	
	# Sort the array by distance from home side
	var sort_position = func (a: Card, b: Card) -> bool:
		return a.position.x < b.position.x != is_blue
	
	cards.sort_custom(sort_position)
	
	return cards


func get_total_elixir() -> int:
	var sum := int(elixir)
	
	for card in get_cards():
		sum += card.stats.elixir
	
	return sum


func get_observation() -> Array[float]:
	var obs: Array[float] = []
	
	# Since good players can essentially figure this out in game
	# the AI should be able to as well
	obs.append(elixir / 10.0)
	obs.append(enemy.elixir / 10.0)
	
	obs.append_array(hand.get_observation())
	obs.append_array(enemy.hand.get_observation())
	
	const CARD_OBS_SIZE = 10
	const MAX_CARDS_PER_SIDE = 10
	
	for side in [1, -1]:
		var friendly_cards = get_cards(side)
		var enemy_cards = enemy.get_cards(side)
	
		for cards in [friendly_cards, enemy_cards]:
			#if cards == friendly_cards:
			#	print("\tfriendly")
			#else:
			#	print("\tenemy")
			
			for card in cards:
				obs.append_array(card.get_observation(is_blue))
	
			assert(len(cards) <= MAX_CARDS_PER_SIDE, "maximum card observation reached")
			
			# Add zeroes to pad the obs array so it has constant size
			for i in range(CARD_OBS_SIZE * (MAX_CARDS_PER_SIDE - len(cards))):
				obs.append(0)
	
	return obs

## Place the selected card at the inputted position.
func place_card(pos: Vector2):
	if selected == -1:
		return
	
	# Ensure enough elixir to summon card
	var card = hand.get_card(selected)
	if elixir < card.elixir:
		# lightly punish placing a card without enough elixir
		_add_reward(-50)
		return
	
	var stats := hand.draw_card(selected)
	
	# AI playing
	if $AIController2D.heuristic != "human":
		evaluate_placement(card, pos)
	
	_instantiate_card(stats, pos)
	
	card_placed.emit()

## Add appropriate reward for the placement of the card, depending on various factors
func evaluate_placement(card: CardStats, pos: Vector2) -> void:
	var card_side = 1 if pos.y < 178 else -1
	
	var enemies = enemy.get_cards(card_side)
	
	if not enemies.is_empty():
		# Encourage proper air defense
		if enemies[0].stats.is_air and card.target_air:
			print("well placed ", card.resource_name, " (anti-air)")
			_add_reward(200)
		elif enemies[0].stats.is_air:
			_add_reward(-100)
			print("poorly placed ", card.resource_name, " (into air units)")
		
		# Encourage capitalizing on lack of air defense
		if card.is_air and not enemies.any(func(c): return c.stats.target_air):
			_add_reward(100)
			print("well placed ", card.resource_name, " (no anti-air)")
		
		# Encourage defending melee cards with ranged cards
		if card.is_ranged and not enemies[0].stats.is_ranged:
			_add_reward(100)
			print("well placed ", card.resource_name, " (ranged defense)")
		
		# Encourage attacking flying and ranged enemies with spells
		if (
				card.is_spell and card.damage > enemies.back().stats.hp
				and (enemies.back().stats.is_ranged or enemies.back().stats.is_air)
		):
			_add_reward(300)
			print("spell value")
		
		# Discourage placing a non-attacking card directly into enemy cards
		if not card.target_troops:
			_add_reward(-200)
			print("poorly placed ", card.resource_name, " (into enemies)")
		
		# Discourage placing a card on one side while there are undefended enemies on the other side
		if not enemy.get_cards(card_side * -1).is_empty() and get_cards(card_side * -1).is_empty():
			_add_reward(-100)
			print("no defense on other lane")
	
	# Discourage spell waste
	if card.is_spell and enemies.is_empty():
		_add_reward(-300)
		print("wasted spell")
	
	if enemy.elixir < 1:
		_add_reward(100)
		print("opportunistic attack")

## Reset the player to the start-of-match state.
func reset():
	for tower in get_crown_towers():
		tower.reset()
	
	# Delete placed cards.
	for card in get_cards():
		card.queue_free()
	
	score = 0
	
	elixir = 5.0
	hand = Hand.new(deck)
	
	# Add reward for winning
	$AIController2D.done = true
	_add_reward(1000 * (1 if is_winning() else 0))
	
	$AIController2D.reset()

## Calculate who's winning, assuming the game is ongoing
func is_winning():
	if score != enemy.score:
		return score > enemy.score
	
	var princess_towers = get_crown_towers()
	princess_towers.erase(king_tower)
	
	var enemy_princess_towers = enemy.get_crown_towers()
	enemy_princess_towers.erase(enemy.king_tower)
	
	var lowest_tower := 3052.0
	for tower in princess_towers:
		if tower.current_hp < lowest_tower:
			lowest_tower = tower.current_hp
			
	var lowest_enemy_tower = 3052.0
	for tower in enemy_princess_towers:
		if tower.current_hp < lowest_tower:
			lowest_enemy_tower = tower.current_hp
	
	# If princess tower amounts are equal, the side with the lowest health tower loses.
	return lowest_tower > lowest_enemy_tower

## Configure a card node to be placed at the specified position. Does the dirty work for place_card
func _instantiate_card(stats: CardStats, pos: Vector2):
	elixir -= stats.elixir
	
	for i in range(stats.count):
		var card := card_scene.instantiate()
		
		card.stats = stats
		card.is_blue = is_blue
		# Slightly randomize card placement to avoid repulsion artefacts
		card.position = pos + Vector2(randf() * 2 - 1, randf() * 2 - 1)
		
		# Generate a unique name for the node i.e. RedKnight5
		var color := "blue" if is_blue else "red"
		var unique_id := str(get_tree().get_node_count_in_group(color))
		card.name = color.capitalize() + stats.resource_name + unique_id
		
		# Make card target all enemy towers
		card.targets.append_array(enemy.get_crown_towers())
		
		$Cards.add_child(card)

# Register reward for AI training.
func _add_reward(amount: float):
	$AIController2D.reward += amount


func _on_selected_changed(new: int):
	selected = new


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var action_name = "place_blue" if is_blue else "place_red"
	# If placed card on allied side of the arena, place it on the mouse.
	if event.is_action_pressed(action_name):
		place_card(get_global_mouse_position())


func _on_enemy_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var action_name = "place_blue" if is_blue else "place_red"
	
	if selected == -1:
		return
	
	if event.is_action_pressed(action_name) and hand.get_card(selected).is_spell:
		place_card(get_global_mouse_position())

# Adds elixir every set interval (0.25 elixir every 0.7 seconds)
func _on_elixir_timer_timeout() -> void:
	# Penalize leaking elixir (letting the elixir count overflow)
	if elixir == 10:
		print("leaking elixir")
		_add_reward(-50)
	elixir += 0.25


func _on_princess_died() -> void:
	_add_reward(-500)
	enemy.score += 1
	princess_died.emit()


func _on_king_died() -> void:
	_add_reward(-1000)
	enemy.score = 3
	king_died.emit()


func _on_tower_damaged(damage: float, tower: Card) -> void:
	var is_enemy = is_blue != tower.is_blue
	
	_add_reward(damage * (1 if is_enemy else -1))
