extends Node2D
## Draws one vertical slice of the level: terrain tiles plus decoration.
## The level is split into chunks so off-screen slices are skipped by the renderer.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")
const TILE := 32
const SOLID_CHARS := "#S"

var _rows: Array = []
var _x_start := 0
var _x_end := 0
var _atlas: Texture2D


func setup(rows: Array, x_start: int, x_end: int) -> void:
	_rows = rows
	_x_start = x_start
	_x_end = x_end
	_atlas = PixelArt.get_tile_atlas()
	queue_redraw()


func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= _rows.size():
		return "."
	var row: String = _rows[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


func _is_solid(x: int, y: int) -> bool:
	return SOLID_CHARS.contains(_char_at(x, y))


## How many solid tiles sit directly above this one (used to darken deep tiles).
func _depth(x: int, y: int) -> int:
	var depth := 0
	while depth < 8 and _is_solid(x, y - 1 - depth):
		depth += 1
	return depth


func _draw() -> void:
	if _atlas == null:
		return
	for y in _rows.size():
		for x in range(_x_start, _x_end):
			var c := _char_at(x, y)
			if not SOLID_CHARS.contains(c):
				continue
			var exposed := not _is_solid(x, y - 1)
			var variant := absi((x * 73856093) ^ (y * 19349663)) % 100
			var kind := PixelArt.EARTH_A
			if c == "#":
				if exposed:
					kind = PixelArt.GRASS_TOP
				elif variant >= 50:
					kind = PixelArt.EARTH_B
			else:
				if exposed:
					kind = PixelArt.STONE_TOP
				elif variant < 14:
					kind = PixelArt.STONE_RUNE
				else:
					kind = PixelArt.STONE_A
			var shade := lerpf(1.0, 0.5, clampf(float(_depth(x, y)) / 8.0, 0.0, 1.0))
			draw_texture_rect_region(_atlas, Rect2(x * TILE, y * TILE, TILE, TILE),
					Rect2(kind * TILE, 0, TILE, TILE), Color(shade, shade, minf(shade * 1.06, 1.0), 1.0))
	_draw_decor()


# ---------------------------------------------------------------- decoration
func _draw_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150 + _x_start
	for y in _rows.size():
		for x in range(_x_start, _x_end):
			var c := _char_at(x, y)
			if not SOLID_CHARS.contains(c):
				continue
			var px := float(x * TILE)
			var py := float(y * TILE)
			var above := _char_at(x, y - 1)
			if above == "." and not _is_solid(x, y - 1):
				if c == "#":
					_decor_grass_top(rng, px, py)
				else:
					_decor_stone_top(rng, px, py)
			if not _is_solid(x, y + 1) and _char_at(x, y + 1) == "." and rng.randf() < 0.22:
				_vine(rng, px + rng.randf_range(4.0, 26.0), py + TILE)


func _snap(v: float) -> float:
	return floorf(v / 2.0) * 2.0


func _decor_grass_top(rng: RandomNumberGenerator, px: float, py: float) -> void:
	_grass_tuft(rng, px + rng.randf_range(2.0, 24.0), py)
	var roll := rng.randf()
	var x := px + rng.randf_range(6.0, 24.0)
	if roll < 0.16:
		_flower(rng, x, py)
	elif roll < 0.28:
		_mushroom(rng, x, py)
	elif roll < 0.36:
		_pebbles(x, py)


func _decor_stone_top(rng: RandomNumberGenerator, px: float, py: float) -> void:
	var roll := rng.randf()
	var x := px + rng.randf_range(6.0, 24.0)
	if roll < 0.28:
		_grass_tuft(rng, x, py)
	elif roll < 0.42:
		_crystal(rng, x, py)
	elif roll < 0.50:
		_stub(rng, x, py)


func _grass_tuft(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var colors := [Color("#3fbf8f"), Color("#2f9e78"), Color("#7fe3a8")]
	var base_x := _snap(x)
	for i in rng.randi_range(2, 4):
		var height := float(rng.randi_range(3, 7)) * 2.0
		var color: Color = colors[rng.randi() % 3]
		var bx := base_x + float(i) * 4.0
		draw_rect(Rect2(bx, y - height, 2.0, height), color)
		var lean := 2.0 if i % 2 == 0 else -2.0
		draw_rect(Rect2(bx + lean, y - height - 2.0, 2.0, 2.0), Color("#7fe3a8"))


func _flower(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var bloom: Color = [Color("#ffd35a"), Color("#ff8fc8"), Color("#9ad0ff")][rng.randi() % 3]
	var fx := _snap(x)
	draw_rect(Rect2(fx, y - 12.0, 2.0, 12.0), Color("#2f9e78"))
	draw_rect(Rect2(fx - 2.0, y - 16.0, 6.0, 6.0), bloom)
	draw_rect(Rect2(fx, y - 14.0, 2.0, 2.0), Color("#fff6d0"))
	draw_circle(Vector2(fx + 1.0, y - 13.0), 10.0, Color(bloom.r, bloom.g, bloom.b, 0.10))


func _mushroom(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var cap: Color = [Color("#7df9e6"), Color("#c58bff")][rng.randi() % 2]
	var mx := _snap(x)
	var h := float(rng.randi_range(2, 4)) * 2.0
	draw_rect(Rect2(mx + 2.0, y - h, 4.0, h), Color("#d7d2f5"))
	draw_rect(Rect2(mx - 2.0, y - h - 4.0, 12.0, 4.0), cap.darkened(0.25))
	draw_rect(Rect2(mx, y - h - 6.0, 8.0, 2.0), cap)
	draw_rect(Rect2(mx + 2.0, y - h - 4.0, 2.0, 2.0), Color("#ffffff"))
	draw_circle(Vector2(mx + 4.0, y - h - 3.0), 14.0, Color(cap.r, cap.g, cap.b, 0.10))
	draw_circle(Vector2(mx + 4.0, y - h - 3.0), 8.0, Color(cap.r, cap.g, cap.b, 0.12))


func _pebbles(x: float, y: float) -> void:
	var rx := _snap(x)
	draw_rect(Rect2(rx, y - 6.0, 8.0, 6.0), Color("#3d3660"))
	draw_rect(Rect2(rx, y - 6.0, 8.0, 2.0), Color("#5b4f8a"))
	draw_rect(Rect2(rx + 10.0, y - 4.0, 6.0, 4.0), Color("#33294f"))


func _crystal(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var cx := _snap(x)
	var body := Color("#4fd8d0")
	for i in rng.randi_range(2, 3):
		var height := float(rng.randi_range(8, 16))
		var ox := cx + float(i) * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(ox, y), Vector2(ox + 2.0, y - height), Vector2(ox + 6.0, y)]), body)
		draw_colored_polygon(PackedVector2Array([Vector2(ox, y), Vector2(ox + 2.0, y - height), Vector2(ox + 3.0, y)]), Color("#b8fff6"))
	draw_circle(Vector2(cx + 7.0, y - 6.0), 16.0, Color(0.3, 1.0, 0.9, 0.09))


func _stub(rng: RandomNumberGenerator, x: float, y: float) -> void:
	# A broken ruin column
	var sx := _snap(x)
	var height := float(rng.randi_range(8, 16)) * 2.0
	draw_rect(Rect2(sx - 2.0, y - height - 2.0, 18.0, height + 2.0), Color("#141a30"))
	draw_rect(Rect2(sx, y - height, 14.0, height), Color("#4b5679"))
	draw_rect(Rect2(sx, y - height, 4.0, height), Color("#6a789f"))
	draw_rect(Rect2(sx - 2.0, y - height - 4.0, 18.0, 4.0), Color("#6a789f"))
	draw_rect(Rect2(sx + 6.0, y - height + 6.0, 2.0, 8.0), Color(0.49, 0.98, 0.9, 0.7))


func _vine(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var vx := _snap(x)
	var length := float(rng.randi_range(3, 8)) * 4.0
	draw_rect(Rect2(vx, y, 2.0, length), Color("#1d7560"))
	var leaf := 8.0
	while leaf < length:
		draw_rect(Rect2(vx + 2.0, y + leaf, 4.0, 2.0), Color("#2f9e78"))
		draw_rect(Rect2(vx - 4.0, y + leaf + 4.0, 4.0, 2.0), Color("#3fbf8f"))
		leaf += 8.0
