extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
var game_over := false

# steady trickle
@export var spawn_interval: float = 0.9
@export var x_margin: float = 24.0

# burst waves
@export var wave_interval: float = 12.0      # seconds between bursts
@export var wave_count: int = 5              # enemies per burst
@export var wave_spread_px: float = 80.0     # horizontal spacing between burst ships
@export var spawn_y: float = -40.0           # Y spawn above the screen

func _ready() -> void:
	randomize()
	if has_node("Player"):
		$Player.connect("died", Callable(self, "_on_player_died"))
	call_deferred("_spawn_loop")
	
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


func _spawn_loop() -> void:
	var wave_elapsed := 0.0
	while is_inside_tree():
		# steady trickle
		await get_tree().create_timer(spawn_interval).timeout
		_spawn_enemy()
		wave_elapsed += spawn_interval

		# do a burst when the interval elapses
		if wave_elapsed >= wave_interval:
			_spawn_burst()
			wave_elapsed -= wave_interval  # keep leftover time so it's consistent

func _spawn_enemy() -> void:
	if enemy_scene == null:
		push_error("[Main] enemy_scene is null! Check preload path.")
		return

	var e: Area2D = enemy_scene.instantiate()
	var vp := get_viewport_rect().size
	var x  := randf_range(x_margin, vp.x - x_margin)
	e.position = Vector2(x, spawn_y)
	add_child(e)

func _spawn_burst() -> void:
	if enemy_scene == null:
		return

	var vp := get_viewport_rect().size
	var center_x := vp.x * 0.5

	# spread enemies left↔right across screen center
	# i from 0..wave_count-1, centered so middle ship is near the center
	for i in range(wave_count):
		var offset := (i - float(wave_count - 1) * 0.5) * wave_spread_px
		var x := clampf(center_x + offset, x_margin, vp.x - x_margin)

		var e: Area2D = enemy_scene.instantiate()
		e.position = Vector2(x, spawn_y)
		add_child(e)
