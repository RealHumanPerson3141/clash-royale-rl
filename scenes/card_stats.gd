class_name CardStats
extends Resource

@export_group("Health")
@export var hp: int
@export var hp_shield: int

@export_group("Speeds")
@export var move_speed: int
@export var hit_speed: float
@export var first_hit_speed: float

@export_group("Deploy")
@export var count: int = 1
@export var deploy_time: float = 1

@export_group("Attack Range")
@export var sight_range: float
@export var hit_range: float

@export_group("Damage")
@export var damage: int
@export var crown_tower_damage: int

@export_group("Splash")
@export var splash_radius: float
@export var is_centered_attack: bool

@export_group("Targeting")
@export var target_troops: bool
@export var target_buildings: bool
@export var target_air: bool
@export var target_ground: bool

@export_group("Type")
@export var is_troop: bool
@export var is_spell: bool
@export var is_building: bool

@export_group("Miscellaneous")
@export var is_air: bool
@export var is_ranged: bool
@export var mass: int
