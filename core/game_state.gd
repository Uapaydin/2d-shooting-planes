extends Node

signal score_changed(v: int)
signal health_changed(v: int)
signal player_died

@export var max_health: int = 3
var score: int = 0
var health: int = max_health

func reset() -> void:
	score = 0
	health = max_health
	emit_signal("score_changed", score)
	emit_signal("health_changed", health)

func add_score(v: int) -> void:
	score += v
	emit_signal("score_changed", score)

func damage_player(v: int = 1) -> void:
	if health <= 0:
		return
	health = max(health - v, 0)
	emit_signal("health_changed", health)
	if health == 0:
		emit_signal("player_died")
