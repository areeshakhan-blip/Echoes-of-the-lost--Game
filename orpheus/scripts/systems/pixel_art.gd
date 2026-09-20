extends RefCounted
## Procedural pixel-art helpers: builds the tile atlas, glow and vignette
## textures in code, so the game needs no external image files.

const TILE := 32          # size of one tile on screen
const ART := 16           # tiles are painted at 16x16 and upscaled 2x (crisp pixels)
const TILE_COUNT := 6

const GRASS_TOP := 0
const EARTH_A := 1
const EARTH_B := 2
const STONE_TOP := 3
const STONE_A := 4
const STONE_RUNE := 5

static var _atlas: ImageTexture = null
static var _glow: ImageTexture = null
static var _vignette: ImageTexture = null
static var _additive: CanvasItemMaterial = null


static func new_image(width: int, height: int) -> Image:
	var bytes := PackedByteArray()
	bytes.resize(width * height * 4)
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes)


# ---------------------------------------------------------------- tiles
static func get_tile_atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var atlas := new_image(TILE * TILE_COUNT, TILE)
	for i in TILE_COUNT:
		var art := _make_tile(i)
		art.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(art, Rect2i(0, 0, TILE, TILE), Vector2i(i * TILE, 0))
	_atlas = ImageTexture.create_from_image(atlas)
	return _atlas


static func _make_tile(kind: int) -> Image:
	var img := new_image(ART, ART)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + kind * 131
	if kind <= EARTH_B:
		_paint_earth(img, rng, kind == GRASS_TOP)
	else:
		_paint_stone(img, rng, kind)
	return img


static func _paint_earth(img: Image, rng: RandomNumberGenerator, grass_top: bool) -> void:
	var base := Color("#2c2447")
	var dark := Color("#231c3b")
	var light := Color("#3b3160")
	var pebble := Color("#5b4f8a")
	for y in ART:
		for x in ART:
			var pixel := base
			var roll := rng.randf()
			if roll < 0.14:
				pixel = dark
			elif roll < 0.22:
				pixel = light
			img.set_pixel(x, y, pixel)
	for i in 3:
		var px := rng.randi_range(1, ART - 3)
		var py := rng.randi_range(6, ART - 3)
		img.set_pixel(px, py, pebble)
		img.set_pixel(px + 1, py, pebble)
		img.set_pixel(px, py + 1, dark)
	if grass_top:
		var grass_dark := Color("#1d7560")
		var grass_mid := Color("#2f9e78")
		var grass_light := Color("#7fe3a8")
		for x in ART:
			var depth := 3 + rng.randi_range(0, 2)
			for y in depth:
				var pixel := grass_mid
				if y == 0:
					pixel = grass_light
				elif y >= depth - 1:
					pixel = grass_dark
				img.set_pixel(x, y, pixel)


static func _paint_stone(img: Image, rng: RandomNumberGenerator, kind: int) -> void:
	var base := Color("#4b5679")
	var mortar := Color("#262e4a")
	var light := Color("#6a789f")
	var dark := Color("#3a4463")
	for y in ART:
		for x in ART:
			var pixel := base
			var roll := rng.randf()
			if roll < 0.12:
				pixel = dark
			elif roll < 0.20:
				pixel = light
			img.set_pixel(x, y, pixel)
	# Brick pattern: mortar lines every 5 pixels, joints staggered per row
	for y in ART:
		var brick_row := y / 5
		if y % 5 == 4:
			for x in ART:
				img.set_pixel(x, y, mortar)
		else:
			var joint := (brick_row % 2) * 4
			for k in 2:
				img.set_pixel((joint + k * 8) % ART, y, mortar)
			if y % 5 == 0:
				for x in ART:
					if img.get_pixel(x, y) != mortar:
						img.set_pixel(x, y, light)
	if kind == STONE_TOP:
		var moss := Color("#2f9e78")
		var moss_light := Color("#7fe3a8")
		for x in ART:
			if rng.randf() < 0.85:
				img.set_pixel(x, 0, moss_light)
				img.set_pixel(x, 1, moss)
				if rng.randf() < 0.4:
					img.set_pixel(x, 2, moss)
	elif kind == STONE_RUNE:
		var glow := Color("#7df9e6")
		var shade := Color("#2d9c9a")
		var rune := [Vector2i(8, 3), Vector2i(8, 4), Vector2i(8, 5), Vector2i(8, 6), Vector2i(8, 7),
			Vector2i(8, 8), Vector2i(9, 4), Vector2i(10, 3), Vector2i(7, 6), Vector2i(6, 5),
			Vector2i(9, 7), Vector2i(10, 8)]
		for point in rune:
			var p: Vector2i = point
			img.set_pixel(p.x + 1, p.y + 1, shade)
		for point in rune:
			var p: Vector2i = point
			img.set_pixel(p.x, p.y, glow)


# ---------------------------------------------------------------- glow / vignette
static func get_glow_texture() -> ImageTexture:
	if _glow != null:
		return _glow
	var size := 64
	var img := new_image(size, size)
	var center := (size - 1) * 0.5
	for y in size:
		for x in size:
			var dist := Vector2(x - center, y - center).length() / center
			var alpha := pow(clampf(1.0 - dist, 0.0, 1.0), 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_glow = ImageTexture.create_from_image(img)
	return _glow


static func get_vignette_texture() -> ImageTexture:
	if _vignette != null:
		return _vignette
	var width := 160
	var height := 90
	var img := new_image(width, height)
	for y in height:
		for x in width:
			var dx := (x - width * 0.5) / (width * 0.5)
			var dy := (y - height * 0.5) / (height * 0.5)
			var dist := sqrt(dx * dx + dy * dy) / 1.41
			var alpha := smoothstep(0.5, 1.0, dist) * 0.7
			img.set_pixel(x, y, Color(0.02, 0.0, 0.08, alpha))
	_vignette = ImageTexture.create_from_image(img)
	return _vignette


static func additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


## A soft additive light. Add it as a child to make something glow.
static func make_glow(color: Color, radius: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = get_glow_texture()
	sprite.material = additive_material()
	sprite.modulate = color
	sprite.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.show_behind_parent = true
	return sprite
