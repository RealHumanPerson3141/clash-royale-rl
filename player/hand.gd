class_name Hand

var deck: Array[CardStats]

var cards: Array[int]
var next: Array[int]


func _init(card_stats: Array[CardStats]):
	deck = card_stats
	
	cards = []
	
	var sorted_deck := range(8)
	for i in range(8):
		var random_index = sorted_deck.pop_at(randi_range(0, 7 - i))
		
		if i < 4:
			cards.append(random_index)
		else:
			next.append(random_index)


func _to_string() -> String:
	var cards_str = "Cards: " + str(cards.map(_index_to_card_name)) + "\n"
	var next_str = "Next: " + str(next.map(_index_to_card_name))
	
	return cards_str + next_str


func get_card(index: int) -> CardStats:
	if index < 0 or index >= 4:
		return null
	
	return deck[cards[index]]


func draw_card(index: int) -> CardStats:
	if index < 0 or index >= 4:
		return null
	
	var chosen_card = deck[cards[index]]
	
	next.append(cards[index])
	cards.set(index, next.pop_front())
	
	return chosen_card


func get_next() -> CardStats:
	return deck[next[0]]


func get_observation() -> Array[float]:
	var obs: Array[float] = []

	for card in cards + [next[0]]:
		var card_obs = deck[card].get_observation()
		
		# Account for cards spawning multiple troops
		card_obs[0] *= deck[card].count
		card_obs[1] *= deck[card].count
		
		obs.append(deck[card].elixir / 10.0)
		obs.append_array(card_obs)
	
	return obs


func _index_to_card_name(index: int) -> String:
	if index < 0 or index >= 8:
		return "Error"
		
	return deck[index].resource_name
