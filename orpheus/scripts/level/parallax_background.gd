extends CanvasLayer
## The scrolling night-time backdrop. Each layer follows the camera at a
## different speed to create depth. It also drifts glowing motes across the screen.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")
const LayerScript = preload("res://scripts/level/parallax_layer.gd")

var _layers: Array = []
var _stars_big
var _camera: Camera2D
var _time := 0.0


## Call once after the level size is known.
func setup(level_width_px: float, camera: Camera2D) -> void:
	_camera = camera
	# kind, horizontal factor, vertical factor, seed
	_add_layer("sky", 0.0, 0.0, 1, level_width_px)
	_add_layer("stars", 0.0, 0.0, 11, level_width_px)
	_stars_big = _add_layer("big_stars", 0.0, 0.0, 23, level_width_px)
	_add_layer("moon", 0.02, 0.02, 1, level_width_px)
	_add_layer("mountains_far", 0.08, 0.10, 1, level_width_px)
	_add_layer("mountains_near", 0.18, 0.18, 1, level_width_px)
	_add_layer("ruins", 0.32, 0.26, 7, level_width_px)
	_add_layer("trees", 0.55, 0.40, 5, level_width_px)
	_add_motes()
	_update_layers()


func _process(delta: float) -> void:
	_time += delta
	if _stars_big != null:
		_stars_big.modulate.a = 0.6 + 0.4 * sin(_time * 1.7)
	_update_layers()


func _add_layer(kind: String, factor_x: float, factor_y: float, seed_value: int, level_width_px: float):
	var layer = LayerScript.new()
	layer.kind = kind
	layer.factor_x = factor_x
	layer.factor_y = factor_y
	layer.seed_value = seed_value
	layer.width = 1280.0 + level_width_px * factor_x + 240.0
	add_child(layer)
	_layers.append(layer)
	return layer


func _update_layers() -> void:
	if _camera == null:
		return
	var center := _camera.get_screen_center_position()
	var camera_left := center.x - 640.0
	var camera_top := center.y - 360.0
	for layer in _layers:
		layer.position = Vector2(-camera_left * layer.factor_x, -camera_top * layer.factor_y)


func _add_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.position = Vector2(640.0, 360.0)
	motes.amount = 70
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(660.0, 380.0)
	motes.direction = Vector2(0.0, -1.0)
	motes.spread = 45.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 6.0
	motes.initial_velocity_max = 18.0
	motes.scale_amount_min = 2.0
	motes.scale_amount_max = 4.0
	motes.color = Color(0.5, 1.0, 0.9, 0.5)
	motes.material = PixelArt.additive_material()
	add_child(motes)
