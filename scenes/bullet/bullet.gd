extends Area2D

@export var speed: float = 900.0
@export var lifetime: float = 1.8

func _ready() -> void:
	add_to_group("player_bullet")
	z_index = 12
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	global_position.y -= speed * delta
	# hard off-screen safety
	if global_position.y < -50:
		queue_free()
