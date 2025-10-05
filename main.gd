extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
@export var spawn_interval: float = 0.9
@export var x_margin: float = 24.0

func _ready() -> void:
	print("[Main] ready")
	randomize()
	# sanity: spawn a few immediately so you SEE them even if loop fails
	for i in 3:
		_spawn_enemy()
	# start loop after one frame (avoids edge timing)
	call_deferred("_spawn_loop")

func _spawn_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(spawn_interval).timeout
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null:
		push_error("[Main] enemy_scene is null! Check preload path.")
		return

	var e: Area2D = enemy_scene.instantiate()
	var vp := get_viewport_rect().size
	var x  := randf_range(x_margin, vp.x - x_margin)
	e.position = Vector2(x, -40)
	add_child(e)
	print("[Main] spawned enemy at x=", x)
