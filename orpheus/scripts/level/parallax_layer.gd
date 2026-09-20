extends Node2D
## One layer of the scrolling background. The background script positions it;
## this script only knows how to draw its own kind of scenery.

const SCREEN := Vector2(1280.0, 720.0)

var kind := ""
## Width of the area to draw (the screen plus however far the layer scrolls).
var width := 1280.0
## How much of the camera's movement this layer follows (0 = fixed sky).
var factor_x := 0.0
var factor_y := 0.0
var seed_value := 1


func _draw() -> void:
	match kind:
		"sky":
			_draw_sky()
		"stars":
			_draw_stars(150, 1.0)
		"big_stars":
			_draw_stars(30, 2.0)
		"moon":
			_draw_moon()
		"mountains_far":
			_draw_ridge(Color("#241a63"), Color("#3a2c8a"), 420.0, 150.0, 0.006, 0.0)
		"mountains_near":
			_draw_ridge(Color("#1a1350"), Color("#2b2075"), 500.0, 130.0, 0.010, 1.7)
		"ruins":
			_draw_ruins()
		"trees":
			_draw_trees()


func _draw_sky() -> void:
	# Deep blue at the top, purple in the middle, a warm violet glow at the horizon
	var bands := [
		[0.0, 250.0, Color("#0a0724"), Color("#1a1052")],
		[250.0, 500.0, Color("#1a1052"), Color("#3a2380")],
		[500.0, 760.0, Color("#3a2380"), Color("#7a3f96")],
	]
	for band in bands:
		var y0: float = band[0]
		var y1: float = band[1]
		var top: Color = band[2]
		var bottom: Color = band[3]
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(SCREEN.x, y0), Vector2(SCREEN.x, y1), Vector2(0, y1)]),
				PackedColorArray([top, top, bottom, bottom]))


func _draw_stars(count: int, size: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var x := rng.randf_range(0.0, SCREEN.x)
		var y := rng.randf_range(0.0, 420.0)
		var brightness := rng.randf_range(0.35, 1.0)
		var tint := Color(0.85, 0.9, 1.0, brightness)
		if rng.randf() < 0.2:
			tint = Color(1.0, 0.9, 0.7, brightness)
		draw_rect(Rect2(floorf(x), floorf(y), size * 2.0, size * 2.0), tint)


func _draw_moon() -> void:
	var center := Vector2(1010.0, 130.0)
	for i in 6:
		draw_circle(center, 120.0 - float(i) * 16.0, Color(0.75, 0.8, 1.0, 0.035))
	draw_circle(center, 44.0, Color("#e8ecff"))
	draw_circle(center + Vector2(-14.0, -8.0), 9.0, Color("#c9cfee"))
	draw_circle(center + Vector2(12.0, 14.0), 6.0, Color("#c9cfee"))
	draw_circle(center + Vector2(16.0, -18.0), 4.0, Color("#d5daf5"))


func _draw_ridge(fill: Color, rim: Color, base_y: float, amplitude: float, frequency: float, offset: float) -> void:
	var points := PackedVector2Array()
	var x := 0.0
	while x <= width:
		var wave := sin(x * frequency + offset) * 0.55 + sin(x * frequency * 2.3 + offset * 2.0) * 0.3 \
				+ sin(x * frequency * 5.1 + offset) * 0.15
		# Pixel-steps: snap heights so ridges look chunky
		var y := base_y - floorf((wave * 0.5 + 0.5) * amplitude / 6.0) * 6.0
		points.append(Vector2(x, y))
		x += 12.0
	var polygon := PackedVector2Array(points)
	polygon.append(Vector2(width, base_y + 700.0))
	polygon.append(Vector2(0.0, base_y + 700.0))
	draw_colored_polygon(polygon, fill)
	draw_polyline(points, rim, 3.0)


func _draw_ruins() -> void:
	# Distant broken pillars and arches, with a few faintly glowing windows
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stone := Color("#2a2170")
	var dark := Color("#211a5c")
	var x := 120.0
	while x < width:
		var kind_roll := rng.randf()
		var base_y := 640.0
		if kind_roll < 0.45:
			var h := rng.randf_range(120.0, 260.0)
			draw_rect(Rect2(x, base_y - h, 30.0, h + 200.0), stone)
			draw_rect(Rect2(x - 6.0, base_y - h - 10.0, 42.0, 12.0), dark)
			if rng.randf() < 0.5:
				draw_rect(Rect2(x + 11.0, base_y - h + 30.0, 8.0, 18.0), Color(0.45, 0.95, 0.9, 0.5))
		elif kind_roll < 0.75:
			var span := rng.randf_range(90.0, 140.0)
			var h := rng.randf_range(150.0, 220.0)
			draw_rect(Rect2(x, base_y - h, 24.0, h + 200.0), stone)
			draw_rect(Rect2(x + span, base_y - h, 24.0, h + 200.0), stone)
			draw_arc(Vector2(x + span * 0.5 + 12.0, base_y - h), span * 0.5 + 12.0, PI, TAU, 24, stone, 22.0)
		else:
			var h := rng.randf_range(60.0, 110.0)
			draw_rect(Rect2(x, base_y - h, 60.0, h + 200.0), stone)
			draw_rect(Rect2(x + 8.0, base_y - h - 12.0, 16.0, 14.0), stone)
		x += rng.randf_range(260.0, 520.0)


func _draw_trees() -> void:
	# Near silhouette: stacked-triangle pines, dark against the ruins
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var color := Color("#120c3a")
	var x := 0.0
	while x < width:
		var h := rng.randf_range(150.0, 260.0)
		var w := rng.randf_range(54.0, 90.0)
		var base_y := 720.0
		draw_rect(Rect2(x + w * 0.5 - 5.0, base_y - 30.0, 10.0, 200.0), color)
		for tier in 4:
			var t := float(tier)
			var tier_w := w * (1.0 - t * 0.2)
			var top_y := base_y - h * (0.35 + t * 0.2)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x + w * 0.5 - tier_w * 0.5, top_y + h * 0.28),
				Vector2(x + w * 0.5, top_y - h * 0.08),
				Vector2(x + w * 0.5 + tier_w * 0.5, top_y + h * 0.28)]), color)
		x += rng.randf_range(90.0, 210.0)
