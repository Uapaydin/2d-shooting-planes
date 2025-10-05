extends CharacterBody2D

@export var speed: float = 520.0
@export var max_tilt_deg: float = 18.0
@export var tilt_lerp: float = 10.0
@export var fire_cooldown: float = 0.12

var _can_fire := true
var _bullet := preload("res://scenes/bullet/Bullet.tscn")

var view: Sprite2D = null
var sv: SubViewport = null
var model: Node3D = null
var tilt_deg: float = 0.0
var ship_mesh: MeshInstance3D = null

func _ready() -> void:
	# --- Get/create required child nodes safely ---
	view = get_node_or_null("View") as Sprite2D
	if view == null:
		view = Sprite2D.new()
		view.name = "View"
		add_child(view)
	# >>> draw order: force above background
	view.z_index = 10000
	view.z_as_relative = false
	view.visible = true
	view.modulate = Color(1,1,1,1)
	view.centered = true
	view.position = Vector2.ZERO

	sv = get_node_or_null("SubViewport") as SubViewport
	if sv == null:
		sv = SubViewport.new()
		sv.name = "SubViewport"
		add_child(sv)

	# Configure SubViewport for 3D-in-2D
	sv.size = Vector2i(512, 512)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.disable_3d = false

	# Resolve/create Player3D under SubViewport
	model = sv.get_node_or_null("Player3D") as Node3D
	if model == null:
		model = Node3D.new()
		model.name = "Player3D"
		sv.add_child(model)
	ship_mesh = model.get_node_or_null("MeshInstance3D") as MeshInstance3D
	
	_ensure_placeholder_3d()

	await get_tree().process_frame
	# If SubViewport is not ready yet, create a visible fallback texture
	var tex := sv.get_texture()
	if tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.2, 0.8, 1.0, 1.0)) # cyan placeholder
		var itex := ImageTexture.create_from_image(img)
		view.texture = itex
	else:
		view.texture = tex

	# place near bottom-center for 900x1200
	var vp: Vector2 = get_viewport().get_visible_rect().size
	global_position = Vector2(vp.x * 0.5, vp.y * 0.86)

	# debug
	print_tree_pretty()
	print("[Player] SV size:", sv.size, "  tex null?", sv.get_texture() == null)

	view.texture = sv.get_texture()       # bind now
	await get_tree().process_frame
	view.texture = sv.get_texture()       # rebind to be safe after first render
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	dir = dir.normalized()


	velocity = dir * speed
	move_and_slide()

	var vp: Vector2 = get_viewport().get_visible_rect().size
	global_position.x = clampf(global_position.x, 24.0, vp.x - 24.0)
	global_position.y = clampf(global_position.y, 24.0, vp.y - 24.0)

	var target_tilt: float = clampf(dir.x * max_tilt_deg, -max_tilt_deg, max_tilt_deg)
	var alpha: float = 1.0 - exp(-tilt_lerp * delta)
	alpha = clampf(alpha, 0.0, 1.0)
	tilt_deg = lerpf(tilt_deg, target_tilt, alpha)
	if model != null:
		model.rotation_degrees.z = -tilt_deg
	if ship_mesh != null:
		ship_mesh.rotation_degrees.z = -tilt_deg
		
	if Input.is_action_pressed("ui_accept"): # Space/Enter default; remap if you like
		_try_fire()

func _ensure_placeholder_3d() -> void:
	# Mesh
	if model.get_node_or_null("MeshInstance3D") == null:
		var mesh := MeshInstance3D.new()
		mesh.name = "MeshInstance3D"
		mesh.mesh = BoxMesh.new()
		model.add_child(mesh)

	# Camera
	var cam: Camera3D = model.get_node_or_null("Camera3D") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "Camera3D"
		model.add_child(cam)
	cam.current = true
	cam.transform.origin = Vector3(0, 1.8, 3.8)
	cam.look_at(Vector3.ZERO, Vector3.UP)

	# Light
	if model.get_node_or_null("DirectionalLight3D") == null:
		var light := DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.rotation_degrees = Vector3(-45, 25, 0)
		model.add_child(light)
		

		
func _try_fire() -> void:
	if not _can_fire:
		return
	_can_fire = false

	var b = _bullet.instantiate()
	# spawn slightly above nose; tweak offset to match your box
	b.global_position = global_position + Vector2(0, -30)
	get_tree().current_scene.add_child(b)

	await get_tree().create_timer(fire_cooldown).timeout
	_can_fire = true
