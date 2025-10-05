extends Area2D

@export var speed: float = 900.0
@export var lifetime: float = 1.8
var dir: Vector2 = Vector2.UP

func set_direction(v: Vector2) -> void:
	dir = v

func _ready() -> void:
	add_to_group("player_bullet")
	z_index = 12
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	global_position += dir.normalized() * speed * delta

	# free when off any screen edge (with a small margin)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if global_position.x < -60 or global_position.x > vp.x + 60 \
	or global_position.y < -60 or global_position.y > vp.y + 60:
		queue_free()
