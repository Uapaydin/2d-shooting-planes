extends Area2D

@export var speed: float = 140.0
@export var hp: int = 1
@export var sway_amp: float = 32.0
@export var sway_freq: float = 1.5
var t := 0.0


func _ready() -> void:
	add_to_group("enemy")
	z_index = 8
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	t += delta
	global_position.y += speed * delta
	global_position.x += sin(t * TAU * sway_freq) * sway_amp * delta
	if global_position.y > get_viewport_rect().size.y + 60:
		queue_free()

func _on_area_entered(a: Area2D) -> void:
	if a.is_in_group("player_bullet"):
		hp -= 1
		a.queue_free()
		if hp <= 0:
			GameState.add_score(100)
			queue_free()
	elif a.is_in_group("player_hitbox"):
		var player := a.get_parent()
		if player and player.has_method("take_damage"):
			player.call("take_damage", 1)
		queue_free()
