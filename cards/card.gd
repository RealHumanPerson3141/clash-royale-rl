class_name Card
extends Area2D


@export var stats: CardStats
@export var is_blue: bool

var current_hp: int

var tiles_per_second: float

var enemy_group: String

var target: Card = null
var targets: Array[Card] = []
var target_groups: Array[String]

var in_combat: bool = false

@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var health_bar: ProgressBar = $HealthBar

@onready var hit_timer: Timer = $HitTimer

@onready var sight_area: Area2D = $SightArea
@onready var hit_area: Area2D = $HitArea

@onready var projectile_scene := preload("res://cards/attacks/projectile/projectile.tscn")
@onready var splash_scene := preload("res://cards/attacks/splash/splash.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Add actual card designs
	$Sprite2D.modulate = Color(0,0,1,1) if is_blue else Color(1,0,0,1)
	
	# Set collision layers to differenciate blue and red (but give all cards the card layer)
	collision_layer = 2 - int(is_blue) + 4
	sight_area.collision_mask = 2 - int(not is_blue)
	hit_area.collision_mask = 2 - int(not is_blue)
	
	navigation.target_desired_distance = stats.hit_range * Global.TILE_SIZE
	
	current_hp = stats.hp
	health_bar.max_value = stats.hp
	
	tiles_per_second = stats.move_speed * 0.02 * Global.TILE_SIZE
	
	# The only children of these areas should be their collision circles
	sight_area.get_child(0).shape = CircleShape2D.new()
	sight_area.get_child(0).shape.radius = stats.sight_range * Global.TILE_SIZE
	hit_area.get_child(0).shape = CircleShape2D.new()
	hit_area.get_child(0).shape.radius = stats.hit_range * Global.TILE_SIZE
	
	_configure_groups()
	_configure_target_groups()


func _physics_process(delta: float) -> void:
	health_bar.value = current_hp
	
	if stats.is_spell:
		_attack()
		queue_free()
		return
	
	# TODO: Add actual attack animations
	$Sprite2D.modulate.g = hit_timer.time_left / hit_timer.wait_time
	if is_blue:
		$Sprite2D.modulate.r = hit_timer.time_left / hit_timer.wait_time
	else:
		$Sprite2D.modulate.b = hit_timer.time_left / hit_timer.wait_time
	
	if current_hp <= 0:
		print(name, " died")
		queue_free()
	
	if target == null:
		_retarget()
	
	if stats.move_speed > 0 and hit_timer.is_stopped():
		navigation.target_position = target.position
		
		var next_path_direction = to_local(navigation.get_next_path_position()).normalized()
		position += next_path_direction * tiles_per_second * delta
	
	_repel_colliding_cards()


func _configure_groups():
	if stats.is_air:
		add_to_group("air")
	else:
		add_to_group("ground")
	
	if stats.is_troop:
		add_to_group("troops")
	elif stats.is_building:
		add_to_group("buildings")
	
	if is_blue:
		add_to_group("blue")
		enemy_group = "red"
	else:
		add_to_group("red")
		enemy_group = "blue"


func _configure_target_groups():
	target_groups.append(enemy_group)
	
	# If the troop ONLY targets ground/flying/troop/building units, add a filter
	# for that group. All cards outside that group (besides towers) will be
	# ignored.
	
	if stats.target_ground and not stats.target_air:
		target_groups.append("ground")
	elif stats.target_air and not stats.target_ground:
		target_groups.append("air")
	
	if stats.target_buildings and not stats.target_troops:
		target_groups.append("buildings")
	elif stats.target_troops and not stats.target_buildings:
		target_groups.append("troops")


func _retarget():
	# TODO: Find an even slightly more elegant solution because this sucks
	if targets.is_empty():
		# Add enemy crown towers to targets, as they are
		# anomalously targeted by every card since start
		var towers = get_tree().get_nodes_in_group("towers")
		for tower in towers:
			if tower.is_in_group(enemy_group):
				targets.append(tower)
	
	target = _get_nearest(targets)
	
	if not hit_area.overlaps_area(target):
		hit_timer.stop()
	if not sight_area.overlaps_area(target):
		in_combat = false


func _attack() -> void:
	if stats.splash_radius == 0:
		if target.is_in_group("towers"):
			target.current_hp -= stats.crown_tower_damage
		else:
			target.current_hp -= stats.damage
		return
	
	var splash = splash_scene.instantiate()
	# TODO: Make this not suck
	splash.position = position if stats.is_centered_attack else target.position
	splash.damage = stats.damage
	splash.crown_tower_damage = stats.crown_tower_damage
	splash.radius = stats.splash_radius
	
	splash.collision_mask = hit_area.collision_mask
	
	add_sibling(splash)


func _repel_colliding_cards() -> void:
	var radius := Global.TILE_SIZE / 2.0
	
	
	for card in get_overlapping_areas():
		if not card is Card:
			continue
		
		#var mass_ratio := stats.mass / card.stats.mass
		var position_diff := -to_local(card.position)
		
		var repel_force := exp(-position_diff.length() / Global.TILE_SIZE)
		var repel_vector = position_diff.normalized() * repel_force * radius
		
		position += repel_vector


func _on_sight_area_entered(area: Node2D) -> void:
	# Enemy towers are always targeted, and so are not appended when spotted
	if _is_targetable(area) and not area.is_in_group("towers"):
		targets.append(area)
	
	if not in_combat and _is_targetable(area):
		target = area
		in_combat = true


func _on_sight_area_exited(area: Node2D) -> void:
	if area in targets:
		targets.erase(area)
	if area == target:
		_retarget()


func _on_hit_area_entered(area: Node2D) -> void:
	if _is_targetable(area) and hit_timer.is_stopped():
		hit_timer.start(stats.first_hit_speed)


func _on_hit_area_exited(area: Node2D) -> void:
	if area == target:
		hit_timer.stop()


func _on_hit_timer_timeout() -> void:
	if target == null or target.current_hp <= 0:
		_retarget()
	if not in_combat:
		return
	
	if stats.is_ranged:
		var projectile = projectile_scene.instantiate()
		
		projectile.position = position
		projectile.target = target
		projectile.tiles_per_second = 600 * 0.02 * Global.TILE_SIZE
		projectile.hit_target.connect(_attack)
		
		add_sibling(projectile)
	else:
		_attack()
	
	hit_timer.start(stats.hit_speed)


func _get_nearest(nodes: Array):
	var nearest_node: Node2D = null
	var min_distance := 1.79769e308 # Maximum float value
	
	for node in nodes:
		# TODO: Fix allowing freed cards to remain in target pool
		if node == null:
			continue
		
		var distance_to_node = position.distance_squared_to(node.position)
		if distance_to_node < min_distance:
			nearest_node = node
			min_distance = distance_to_node
		
	return nearest_node


func _is_targetable(card: Card) -> bool:
	for group in target_groups:
		if not card.is_in_group(group):
			return card.is_in_group(enemy_group) and card.is_in_group("towers")
	return true
