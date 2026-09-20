extends Area2D
## Obsidian thorns. Instantly dangerous, always visible, never moving:
## the player learns to jump over them. Origin is at the bottom centre of a tile.


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var target = body
		if target.is_in_group("player"):
			target.hurt()


func _draw() -> void:
	var dark := Color("#1d0d3d")
	var body := Color("#3a1a70")
	var edge := Color("#b04cff")
	var tip := Color("#ff5fa2")
	# Three thorns per tile: [left edge x, width, height]
	var thorns := [[-16.0, 10.0, 18.0], [-5.0, 11.0, 27.0], [6.0, 10.0, 18.0]]
	for thorn in thorns:
		var left: float = thorn[0]
		var right: float = left + float(thorn[1])
		var height: float = thorn[2]
		var middle := (left + right) * 0.5
		var apex := Vector2(middle, -height)
		# dark outline, body, then a lighter edge on the left face
		draw_colored_polygon(PackedVector2Array([Vector2(left - 1.0, 0.0), apex + Vector2(0.0, -2.0), Vector2(right + 1.0, 0.0)]), dark)
		draw_colored_polygon(PackedVector2Array([Vector2(left, 0.0), apex, Vector2(right, 0.0)]), body)
		draw_colored_polygon(PackedVector2Array([Vector2(left, 0.0), apex, Vector2(middle, 0.0)]), edge.darkened(0.3))
		draw_line(Vector2(left, 0.0), apex, edge, 2.0)
		draw_circle(apex, 2.5, tip)
	draw_rect(Rect2(-16, -3, 32, 3), dark)
