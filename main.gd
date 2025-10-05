extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
@export var spawn_interval: float = 0.9
@export var x_margin: float = 24.0

func _ready() -> void:
	randomize()               # safe in 4.x
	_spawn_loop()

func _spawn_loop() -> void:
	while true:
		_spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_enemy() -> void:
	var e: Area2D = enemy_scene.instantiate()
	var vp := get_viewport_rect().size
	var x  := randf_range(x_margin, vp.x - x_margin)
	e.position = Vector2(x, -40)
	add_child(e)
