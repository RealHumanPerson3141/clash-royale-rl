class_name CardStats
extends Resource

# Health points
var hp: int
#var hp_shield: int

# Used to calculate how units are pushed around
var mass: int

# Speeds
var speed: int
var hit_speed: float

# Deploy related stats
var first_hit_speed: float
var deploy_time: float

# Ranges
var hit_range: float
var sight_range: float

# Damage
var damage: int
var crown_tower_damage: int
var damage_per_second: int

# Targeting
var target_troops: bool
var target_air: bool
var target_ground: bool

# Card type
var is_air: bool
var is_troop: bool
var is_spell: bool
#var is_building: bool
