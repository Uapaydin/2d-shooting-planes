extends Area2D

@export var speed: float = 140.0
@export var hp: int = 1

func _ready() -> void:
	add_to_group("enemy")
	z_index = 8
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position.y += speed * delta
	if global_position.y > get_viewport_rect().size.y + 60:
		queue_free()

func _on_area_entered(a: Area2D) -> void:
	# bullets are Area2D with group "player_bullet"
	if a.is_in_group("player_bullet"):
		hp -= 1
		a.queue_free()
		if hp <= 0:
			queue_free()
