extends SceneTree

const PrototypeScript = preload("res://scripts/prototype.gd")


func _initialize() -> void:
	var prototype = PrototypeScript.new()
	prototype.stems.append_array([
		{"color_name": "Blush", "position": Vector2(-0.18, 0.0)},
		{"color_name": "Cream", "position": Vector2(0.18, 0.0)},
		{"color_name": "Blush", "position": Vector2(0.0, 0.22)},
	])
	assert(prototype._arrangement_score() == 3, "A spaced pink-and-cream cosmos arrangement should meet all preferences.")
	prototype.stems.clear()
	prototype.stems.append_array([
		{"color_name": "Lavender", "position": Vector2.ZERO},
		{"color_name": "Lavender", "position": Vector2(0.18, 0.0)},
		{"color_name": "Lavender", "position": Vector2(0.0, 0.18)},
	])
	assert(prototype._arrangement_score() == 2, "A gentle alternative should still receive a positive score.")
	prototype.flower_texture = prototype._make_painterly_texture()
	var flower = prototype._create_flower(Color("#f07880"))
	assert(flower.get_meta("triangle_count") <= flower.get_meta("triangle_budget"), "The first flower must stay under its art-bible triangle cap.")
	flower.free()
	prototype.free()
	print("Prototype arrangement scoring: PASS")
	quit(0)
