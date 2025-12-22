extends Area2D


var enemy_group: String

var damage: int
var crown_tower_damage: int

var radius: float


func _pyhsics_process(_delta: float) -> void:
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius * Global.TILE_SIZE
	
	var cards := get_overlapping_bodies()
	
	for card in cards:
		if card.is_in_group(enemy_group):
			if card.is_in_group("towers"):
				card.current_health -= crown_tower_damage
			else:
				card.current_health -= damage
	
	queue_free()
