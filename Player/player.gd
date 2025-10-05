extends CharacterBody2D

@export var speed: float = 520.0

# Roll (bank)
@export var max_tilt_deg: float = 18.0
@export var tilt_lerp: float = 10.0

# Yaw (nose left/right)
@export var max_yaw_deg: float = 8.0
@export var yaw_lerp: float = 8.0

@export var fire_cooldown: float = 0.12

var view: Sprite2D
var sv: SubViewport
var model: Node3D
var ship_root: Node3D
var cam3d: Camera3D

var yaw_pivot: Node3D            # yaw on LOCAL Y

var tilt_deg: float = 0.0        # current roll
var yaw_deg: float = 0.0         # current yaw

var _can_fire: bool = true
var _bullet: PackedScene = preload("res://scenes/bullet/Bullet.tscn")
var dead: bool = false
signal died

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

	# Ensure YawPivot under ShipRoot, and Plane under YawPivot
	if ship_root != null:
		yaw_pivot = ship_root.get_node_or_null("YawPivot") as Node3D
	

	# bind SubViewport texture
	view.texture = sv.get_texture()
	await get_tree().process_frame
	view.texture = sv.get_texture()

	# start position
	var vp: Vector2 = get_viewport().get_visible_rect().size
	global_position = Vector2(vp.x * 0.5, vp.y * 0.86)

	add_to_group("player")
	if has_node("Hitbox"):
		$Hitbox.add_to_group("player_hitbox")

func _physics_process(delta: float) -> void:
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

	var vp: Vector2 = get_viewport().get_visible_rect().size
	global_position.x = clampf(global_position.x, 24.0, vp.x - 24.0)
	global_position.y = clampf(global_position.y, 24.0, vp.y - 24.0)

	# Targets:
	# Roll from horizontal input
	var target_roll: float = clampf(dir.x * max_tilt_deg, -max_tilt_deg, max_tilt_deg)
	# Yaw from horizontal input (smaller magnitude than roll for arcade feel)
	var target_yaw: float = clampf(dir.x * max_yaw_deg, -max_yaw_deg, max_yaw_deg)
	# (Optional) add a tiny vertical influence to yaw:
	# target_yaw += dir.y * (max_yaw_deg * 0.25)

	# Smooth
	var roll_alpha: float = clampf(1.0 - exp(-tilt_lerp * delta), 0.0, 1.0)
	var yaw_alpha: float = clampf(1.0 - exp(-yaw_lerp * delta), 0.0, 1.0)
	tilt_deg = lerpf(tilt_deg, target_roll, roll_alpha)
	yaw_deg = lerpf(yaw_deg, target_yaw, yaw_alpha)

	# Yaw on the pivot (LOCAL Y)
	if yaw_pivot != null:
		# flip sign if yaw feels backward
		yaw_pivot.rotation_degrees.y = yaw_deg
		yaw_pivot.rotation_degrees.z = -tilt_deg

	# Shooting
	if Input.is_action_pressed("ui_accept"):
		_try_fire()

func _try_fire() -> void:
	if not _can_fire: return
	_can_fire = false

	var yaw_rad: float = deg_to_rad(yaw_deg)
	var heading: Vector2 = Vector2(sin(yaw_rad), -cos(yaw_rad))   # forward in 2D
	var nose_offset_px := 28.0                                     # tweak to match your model
	var muzzle := global_position + heading * nose_offset_px

	var b: Area2D = _bullet.instantiate()
	b.global_position = muzzle
	if b.has_method("set_direction"):
		b.call("set_direction", heading)
	get_tree().current_scene.add_child(b)

	await get_tree().create_timer(fire_cooldown).timeout
	_can_fire = true

func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	var b: Area2D = _bullet.instantiate()
	b.global_position = pos
	if b.has_method("set_direction"):
		b.call("set_direction", dir.normalized())
	get_tree().current_scene.add_child(b)

func _rotate2d(v: Vector2, ang: float) -> Vector2:
	var c := cos(ang); var s := sin(ang)
	return Vector2(v.x * c - v.y * s, v.x * s + v.y * c)

# Finds the first Node3D under 'root' that has a MeshInstance3D descendant.
func _find_plane_root(root: Node) -> Node3D:
	for c in root.get_children():
		if c == yaw_pivot:
			continue
		if c is Node3D:
			if _has_mesh_descendant(c):
				return c
			var nested := _find_plane_root(c)
			if nested != null:
				return nested
	return null

func _has_mesh_descendant(n: Node) -> bool:
	for c in n.get_children():
		if c is MeshInstance3D:
			return true
		if _has_mesh_descendant(c):
			return true
	return false
	
func die() -> void:
	if dead: return
	dead = true
	emit_signal("died")
	queue_free()
