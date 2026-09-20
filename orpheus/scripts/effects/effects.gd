extends RefCounted
## Small helpers that spawn one-shot visual effects into the running scene.

const BURST_SCENE := preload("res://scenes/effects/burst.tscn")
const RING_SCENE := preload("res://scenes/effects/ring_effect.tscn")
const TEXT_SCENE := preload("res://scenes/effects/floating_text.tscn")


static func _world(tree: SceneTree) -> Node:
	var scene := tree.current_scene
	if scene == null:
		return tree.root
	return scene


## A puff of coloured sparks.
static func burst(tree: SceneTree, world_pos: Vector2, color: Color, amount: int = 16,
		speed: float = 180.0, lifetime: float = 0.6, gravity: float = 300.0) -> void:
	var node = BURST_SCENE.instantiate()
	_world(tree).add_child(node)
	node.global_position = world_pos
	node.setup(color, amount, speed, lifetime, gravity)


## An expanding ring.
static func ring(tree: SceneTree, world_pos: Vector2, color: Color, radius: float = 56.0, duration: float = 0.5) -> void:
	var node = RING_SCENE.instantiate()
	_world(tree).add_child(node)
	node.global_position = world_pos
	node.setup(color, radius, duration)


## Text that floats upwards and fades ("+100", "CHECKPOINT!").
static func text(tree: SceneTree, world_pos: Vector2, message: String, color: Color = Color.WHITE) -> void:
	var node = TEXT_SCENE.instantiate()
	_world(tree).add_child(node)
	node.global_position = world_pos
	node.setup(message, color)
