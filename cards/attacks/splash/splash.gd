extends Area2D


var summoner: Card

var radius: float


func _ready() -> void:
	global_scale = Vector2(radius * Global.TILE_SIZE, radius * Global.TILE_SIZE)
	summoner = get_parent().get_parent() as Card


func _on_timer_timeout() -> void:
	var cards := get_overlapping_areas()
	for card in cards:
		summoner.target = card
		summoner._hurt()
	
	queue_free()
