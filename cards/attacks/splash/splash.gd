extends Area2D


var damage: int
var crown_tower_damage: int

var radius: float


func _ready() -> void:
	scale = Vector2(radius * Global.TILE_SIZE, radius * Global.TILE_SIZE)


func _on_timer_timeout() -> void:
	var cards := get_overlapping_areas()
	for card in cards:
		if card.is_in_group("towers"):
			card.current_hp -= crown_tower_damage
		else:
			card.current_hp -= damage
	queue_free()
