extends CharacterBody2D

@export var speed: float = 520.0

# Roll (bank)
@export var max_tilt_deg: float = 18.0
@export var tilt_lerp: float = 10.0

# Yaw (nose left/right)
@export var max_yaw_deg: float = 8.0
@export var yaw_lerp: float = 8.0

# Shooting
@export var fire_cooldown: float = 0.12

# NEW: Intro + bounds
@export var intro_time: float = 0.9           # seconds to fly in
@export var bottom_margin: float = 180.0      # how far above bottom the player can go
@export var intro_fly_target_height: float = 350.0      # how far above bottom the player can go

var view: Sprite2D
var sv: SubViewport
var model: Node3D
var ship_root: Node3D
var cam3d: Camera3D

var yaw_pivot: Node3D            # yaw (Y) + roll (Z) on same pivot

var tilt_deg: float = 0.0        # current roll
var yaw_deg: float = 0.0         # current yaw

var _can_fire: bool = true
var _bullet: PackedScene = preload("res://scenes/bullet/Bullet.tscn")

var _control_enabled: bool = false   # NEW: lock input during intro

func _ready() -> void:
	# 2D view
	view = get_node_or_null("View") as Sprite2D
	if view == null:
		view = Sprite2D.new()
		view.name = "View"
		add_child(view)
	view.z_index = 10000
	view.z_as_relative = false
	view.centered = true
	view.position = Vector2.ZERO

	# SubViewport + 3D rig
	sv = get_node_or_null("SubViewport") as SubViewport
	if sv == null:
		sv = SubViewport.new()
		sv.name = "SubViewport"
		add_child(sv)
	sv.size = Vector2i(512, 512)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	model = get_node_or_null("SubViewport/Player3D") as Node3D
	if model == null:
		model = Node3D.new()
		model.name = "Player3D"
		sv.add_child(model)

	ship_root = get_node_or_null("SubViewport/Player3D/ShipRoot") as Node3D
	cam3d = get_node_or_null("SubViewport/Player3D/Camera3D") as Camera3D

	# Ensure YawPivot under ShipRoot
	if ship_root != null:
		yaw_pivot = ship_root.get_node_or_null("YawPivot") as Node3D

	# bind SubViewport texture
	view.texture = sv.get_texture()
	await get_tree().process_frame
	view.texture = sv.get_texture()

	add_to_group("player")

	# --- Intro fly-in from below screen, then enable controls
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var target_pos: Vector2 = Vector2(vp.x * 0.5, vp.y - intro_fly_target_height)  # resting spot

	_control_enabled = false
	global_position = Vector2(target_pos.x, vp.y + 140.0)  # start off-screen below
	await get_tree().process_frame

	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target_pos, intro_time)
	await tw.finished

	_control_enabled = true

func _physics_process(delta: float) -> void:
	# During intro: let the tween drive position (no input, no clamp).
	if not _control_enabled:
		return

	# Input & movement
	var dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	if dir.length() > 1.0:
		dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()

	# Screen bounds (bottom limited above by bottom_margin)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var left   := 24.0
	var right  := vp.x - 24.0
	var top    := 24.0
	var bottom := vp.y - bottom_margin
	global_position.x = clampf(global_position.x, left, right)
	global_position.y = clampf(global_position.y, top, bottom)

	# Targets from horizontal input
	var target_roll: float = clampf(dir.x * max_tilt_deg, -max_tilt_deg, max_tilt_deg)
	var target_yaw:  float = clampf(dir.x * max_yaw_deg,  -max_yaw_deg,  max_yaw_deg)

	# Smooth
	var roll_alpha: float = clampf(1.0 - exp(-tilt_lerp * delta), 0.0, 1.0)
	var yaw_alpha:  float = clampf(1.0 - exp(-yaw_lerp  * delta), 0.0, 1.0)
	tilt_deg = lerpf(tilt_deg, target_roll, roll_alpha)
	yaw_deg  = lerpf(yaw_deg,  target_yaw,  yaw_alpha)

	# Apply yaw (Y) + roll (Z) on the pivot
	if yaw_pivot != null:
		yaw_pivot.rotation_degrees.y = yaw_deg   # flip sign if needed
		yaw_pivot.rotation_degrees.z = -tilt_deg  # flip sign if needed

	# Shooting
	if Input.is_action_pressed("ui_accept"):
		_try_fire()

func _try_fire() -> void:
	if not _can_fire:
		return
	_can_fire = false

	# forward heading from current yaw
	var yaw_rad: float = deg_to_rad(yaw_deg)
	var heading: Vector2 = Vector2(sin(yaw_rad), -cos(yaw_rad))  # 0° = straight up

	# spawn from the nose so it tracks yaw visually
	var nose_offset_px: float = 28.0  # tweak to match your model
	var muzzle: Vector2 = global_position + heading * nose_offset_px

	var b: Area2D = _bullet.instantiate()
	b.global_position = muzzle
	if b.has_method("set_direction"):
		b.call("set_direction", heading)
	get_tree().current_scene.add_child(b)

	await get_tree().create_timer(fire_cooldown).timeout
	_can_fire = true
