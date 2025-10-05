extends Control

@onready var score_lbl: Label = $ScoreLabel
@onready var health_lbl: Label = $HealthLabel

func _ready() -> void:
	score_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	score_lbl.offset_right = -16
	score_lbl.offset_top = 16

	health_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
	health_lbl.offset_left = 16
	health_lbl.offset_bottom = -16

	GameState.connect("score_changed", Callable(self, "_on_score"))
	GameState.connect("health_changed", Callable(self, "_on_health"))
	_on_score(GameState.score)
	_on_health(GameState.health)

func _on_score(v: int) -> void:
	score_lbl.text = "SCORE %06d" % v

func _on_health(v: int) -> void:
	health_lbl.text = "HEALTH %d/%d" % [v, GameState.max_health]
