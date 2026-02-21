extends Label


@export var timer: Timer


func _physics_process(_delta: float) -> void:
	var mins = int(timer.time_left / 60)
	var secs = int(timer.time_left) % 60
	
	text = "%s:%s" % [mins, secs]
	if secs < 10:
		text = text.insert(2, "0")
