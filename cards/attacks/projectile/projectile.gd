extends Area2D


signal hit_target()

var pixels_per_second: float
var target: Card


func _physics_process(delta: float) -> void:
	# If the target is deleted, delete the projectile
	if target == null:
		queue_free()
		return
	
	global_position = global_position.move_toward(target.global_position, pixels_per_second * delta)


func _on_area_entered(area: Node2D) -> void:
	if area == target:
		hit_target.emit()
		queue_free()
