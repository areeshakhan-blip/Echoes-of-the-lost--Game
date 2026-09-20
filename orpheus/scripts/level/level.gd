extends Node2D
## Builds Level 1 from the text map in level_data.gd: terrain collision and
## visuals, then every shard, hazard, checkpoint and the portal.

const TILE := 32
const CHUNK_COLUMNS := 32
const PLAYER_HALF_HEIGHT := 19.0
const SOLID_CHARS := "#S"

const LevelData = preload("res://scripts/level/level_data.gd")
const ChunkScript = preload("res://scripts/level/level_chunk.gd")

const ECHO_SCENE := preload("res://scenes/collectibles/echo_shard.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/level/checkpoint.tscn")
const PORTAL_SCENE := preload("res://scenes/level/portal.tscn")
const HINT_SCENE := preload("res://scenes/level/hint_sign.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_patrol.tscn")
const SPIKES_SCENE := preload("res://scenes/enemies/spikes.tscn")
const ORB_SCENE := preload("res://scenes/enemies/moving_hazard.tscn")

@onready var terrain: Node2D = $Terrain
@onready var entities: Node2D = $Entities
@onready var player = $Player
@onready var background = $Background

var _rows: Array = []
var _width := 0
var _height := 0
var _spawn_position := Vector2.ZERO
var _echo_count := 0
var _checkpoint_count := 0
var _hint_index := 0


func _ready() -> void:
	_rows = LevelData.ROWS
	_height = _rows.size()
	var first_row: String = _rows[0]
	_width = first_row.length()
	_build_collision()
	_build_chunks()
	_spawn_entities()
	_setup_player()
	background.setup(float(_width * TILE), player.camera)
	GameState.begin_level(_spawn_position, _echo_count, _checkpoint_count, LevelData.REQUIRED_ECHOES)


# ---------------------------------------------------------------- map helpers
func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= _height:
		return "."
	var row: String = _rows[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


func _is_solid(x: int, y: int) -> bool:
	return SOLID_CHARS.contains(_char_at(x, y))


func _tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)


## The middle of the tile's bottom edge - where something standing in the tile touches the ground.
func _tile_bottom(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)


# ---------------------------------------------------------------- terrain
## One StaticBody2D with a few big rectangles (adjacent tiles are merged),
## which keeps the player from catching on seams between tiles.
func _build_collision() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.collision_layer = 1
	ground.collision_mask = 0
	terrain.add_child(ground)

	var used := PackedByteArray()
	used.resize(_width * _height)
	for y in _height:
		for x in _width:
			if not _is_solid(x, y) or used[y * _width + x] == 1:
				continue
			var w := 1
			while x + w < _width and _is_solid(x + w, y) and used[y * _width + x + w] == 0:
				w += 1
			var h := 1
			var can_grow := true
			while can_grow and y + h < _height:
				for i in w:
					if not _is_solid(x + i, y + h) or used[(y + h) * _width + x + i] == 1:
						can_grow = false
						break
				if can_grow:
					h += 1
			for yy in h:
				for xx in w:
					used[(y + yy) * _width + x + xx] = 1
			_add_rect_shape(ground, Vector2(x * TILE + w * TILE * 0.5, y * TILE + h * TILE * 0.5),
					Vector2(w * TILE, h * TILE))

	# Invisible walls at both ends of the level
	var wall_height := float(_height * TILE + 2000)
	_add_rect_shape(ground, Vector2(-32.0, _height * TILE * 0.5), Vector2(64.0, wall_height))
	_add_rect_shape(ground, Vector2(_width * TILE + 32.0, _height * TILE * 0.5), Vector2(64.0, wall_height))


func _add_rect_shape(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = center
	body.add_child(collider)


func _build_chunks() -> void:
	var x := 0
	while x < _width:
		var chunk = ChunkScript.new()
		terrain.add_child(chunk)
		chunk.setup(_rows, x, mini(x + CHUNK_COLUMNS, _width))
		x += CHUNK_COLUMNS


# ---------------------------------------------------------------- entities
func _spawn_entities() -> void:
	# Scan column by column so checkpoints and hint tablets are numbered left to right
	for x in _width:
		for y in _height:
			match _char_at(x, y):
				"P":
					_spawn_position = _tile_bottom(x, y) + Vector2(0.0, -PLAYER_HALF_HEIGHT)
				"*":
					_echo_count += 1
					_place(ECHO_SCENE, _tile_center(x, y))
				"C":
					_checkpoint_count += 1
					var checkpoint = CHECKPOINT_SCENE.instantiate()
					checkpoint.position = _tile_bottom(x, y)
					checkpoint.index = _checkpoint_count
					entities.add_child(checkpoint)
				"E":
					var enemy = ENEMY_SCENE.instantiate()
					enemy.position = _tile_bottom(x, y)
					var bounds := _patrol_bounds(x, y)
					enemy.patrol_min_x = bounds.x
					enemy.patrol_max_x = bounds.y
					entities.add_child(enemy)
				"^":
					_place(SPIKES_SCENE, _tile_bottom(x, y))
				"v", "h":
					var orb = ORB_SCENE.instantiate()
					orb.position = _tile_center(x, y)
					orb.travel = Vector2(0.0, 72.0) if _char_at(x, y) == "v" else Vector2(96.0, 0.0)
					orb.phase = float(x) * 0.7
					entities.add_child(orb)
				"t":
					var sign_node = HINT_SCENE.instantiate()
					sign_node.position = _tile_bottom(x, y)
					if _hint_index < LevelData.HINTS.size():
						sign_node.text = LevelData.HINTS[_hint_index]
					_hint_index += 1
					entities.add_child(sign_node)
				"O":
					_place(PORTAL_SCENE, _tile_bottom(x, y))


func _place(scene: PackedScene, world_position: Vector2) -> void:
	var node = scene.instantiate()
	node.position = world_position
	entities.add_child(node)


## Patrol range for an enemy standing in tile (x, y): it walks along the floor
## but stops before edges, walls, thorns and checkpoints. Returns world x limits.
func _patrol_bounds(x: int, y: int) -> Vector2:
	var left := x
	while left > x - 6 and _can_walk(left - 1, y):
		left -= 1
	var right := x
	while right < x + 6 and _can_walk(right + 1, y):
		right += 1
	return Vector2(left * TILE + 14.0, (right + 1) * TILE - 14.0)


func _can_walk(x: int, y: int) -> bool:
	if not _is_solid(x, y + 1):
		return false
	return ".*Et".contains(_char_at(x, y))


# ---------------------------------------------------------------- player
func _setup_player() -> void:
	player.global_position = _spawn_position
	player.death_y = float(_height * TILE) + 160.0
	player.set_camera_limits(0, -160, _width * TILE, _height * TILE)
	player.snap_camera()
