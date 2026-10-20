extends Control

const SEPIA := Color("#aa886f")
const SAGE := Color("#88a27d")
const BLUSH := Color("#d89b9c")


func _draw() -> void:
	var edge := Rect2(4.0, 4.0, size.x - 8.0, size.y - 8.0)
	draw_rect(edge, Color("#aa886f", 0.28), false, 1.4)
	_draw_leaf_sprig(Vector2(12, 18), 1.0)
	_draw_leaf_sprig(Vector2(size.x - 12, size.y - 18), -1.0)


func _draw_leaf_sprig(origin: Vector2, direction: float) -> void:
	var stem := PackedVector2Array([
		origin,
		origin + Vector2(9.0 * direction, -8.0),
		origin + Vector2(19.0 * direction, -7.0),
	])
	draw_polyline(stem, Color(SAGE, 0.75), 1.3, true)
	for leaf_index in range(2):
		var base := origin + Vector2((5.0 + leaf_index * 8.0) * direction, -5.0 - leaf_index)
		var leaf := PackedVector2Array([
			base,
			base + Vector2(3.0 * direction, -8.0),
			base + Vector2(10.0 * direction, -8.0),
			base + Vector2(7.0 * direction, -2.0),
		])
		draw_colored_polygon(leaf, Color(SAGE, 0.55))
	draw_circle(origin + Vector2(22.0 * direction, -7.0), 3.0, BLUSH)
	draw_circle(origin + Vector2(22.0 * direction, -7.0), 1.2, Color("#c2a064"))
