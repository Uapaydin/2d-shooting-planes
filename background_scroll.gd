extends Parallax2D

@onready var sprite: Sprite2D = $Sprite2D
var t := 0.0

func _ready():
	print("[Player] SV size:")
	# Sprite ekranı doldursun; offset/center kayması olmasın
	sprite.centered = false
	sprite.position = Vector2.ZERO
	_fit_sprite_to_viewport()

	# Shader kur
	var code := """
        shader_type canvas_item;

        // Ekran-uzayında tam ekran tiling + yukarı akış
        uniform float scroll_speed_px_per_sec = 60.0;    // piksel/sn
        uniform vec2  viewport_px = vec2(480.0, 800.0);  // script günceller
        uniform vec2  tex_px = vec2(626.0, 417.0);       // görsel boyutu
        uniform float time_accum = 0.0;

        void fragment() {
            vec2 tiles = viewport_px / tex_px;            // ekrana kaç karo düşer
            float off_y = -(time_accum * scroll_speed_px_per_sec) / tex_px.y; // yukarı akış
            vec2 uv;
            uv.x = fract(SCREEN_UV.x * tiles.x);
            uv.y = fract(SCREEN_UV.y * tiles.y + off_y);
            COLOR = texture(TEXTURE, uv);
        }
	""";

	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	sprite.material = mat

	_push_shader_viewport()
	get_viewport().connect("size_changed", Callable(self, "_on_resize"))

func _process(delta):
	t += delta
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("time_accum", t)

func _on_resize():
	_fit_sprite_to_viewport()
	_push_shader_viewport()

func _fit_sprite_to_viewport():
	var vp := get_viewport_rect().size
	var tex := sprite.texture
	if tex:
		var tex_size := Vector2(tex.get_width(), tex.get_height())
		sprite.scale = vp / tex_size  # Sprite quad'ı tam ekran olur

func _push_shader_viewport():
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("viewport_px", get_viewport_rect().size)
		mat.set_shader_parameter("tex_px", Vector2(626.0, 417.0))  # senin görselin
