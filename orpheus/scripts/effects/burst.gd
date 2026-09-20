extends Node2D
## A one-shot burst of glowing pixel sparks. Frees itself when finished.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")


func setup(color: Color, amount: int, speed: float, lifetime: float, gravity: float) -> void:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 6.0
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, gravity)
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.material = PixelArt.additive_material()
	add_child(particles)
	particles.emitting = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.5)
	tween.tween_callback(queue_free)
