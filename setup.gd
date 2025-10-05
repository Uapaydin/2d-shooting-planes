extends Node
class_name Setup

signal viewport_changed(new_size)

var BASE_VP = Vector2(900, 1200)

func _ready():
	# connect to the Viewport's size_changed signal (correct in 4.5)
	get_viewport().connect("size_changed", Callable(self, "_on_size_changed"))

func viewport_size() -> Vector2:
	# correct way from a Node (autoload) in 4.5
	var vp := get_viewport()
	if vp:
		return vp.get_visible_rect().size
	return Vector2.ZERO

func viewport_aspect() -> float:
	var s := viewport_size()
	if s.y == 0.0:
		return 0.0
	return s.x / s.y

func _on_size_changed() -> void:
	emit_signal("viewport_changed", viewport_size())
