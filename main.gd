extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
@export var spawn_interval: float = 0.9
@export var x_margin: float = 24.0
var game_over := false

func _ready() -> void:
	randomize()
	if has_node("Player"):
		$Player.connect("died", Callable(self, "_on_player_died"))
	call_deferred("_spawn_loop")

func _spawn_loop() -> void:
	while is_inside_tree() and not game_over:
		await get_tree().create_timer(spawn_interval).timeout
		if not game_over: _spawn_enemy()
		
func _on_player_died() -> void:
	game_over = true
	_show_restart()

func _show_restart() -> void:
	var l := Label.new()
	l.text = "GAME OVER\nPress Enter"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.scale = Vector2(2,2)
	add_child(l)
	l.position = get_viewport_rect().size * 0.5
	
func _unhandled_input(e: InputEvent) -> void:
	if game_over and e.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

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
