extends Area2D


signal hit_target()

var tiles_per_second: float
var target: Card


func _physics_process(delta: float) -> void:
	if target == null:
		queue_free()
		return
	
	position = position.move_toward(target.position, tiles_per_second * delta)


func _on_area_entered(area: Node2D) -> void:
	if area == target:
		hit_target.emit()
		queue_free()
