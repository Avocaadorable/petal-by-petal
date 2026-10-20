extends Control

const INK := Color("#7b6658")


func _draw() -> void:
	# Soft paper portrait of Mina, with the cream blouse, sage apron and floral
	# hair detail used throughout the art bible's character illustrations.
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f7ede1"))
	draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), Color("#f2e5d5"), false, 1.5)
	draw_rect(Rect2(9, 9, size.x - 18, size.y - 18), Color("#dce8d4"))
	draw_rect(Rect2(14, 15, size.x - 28, 44), Color("#c4debf"))
	draw_rect(Rect2(14, 53, size.x - 28, 3), Color("#b8cdaa"))
	var cx := size.x * 0.5
	# Neck and blouse.
	draw_rect(Rect2(cx - 8, 62, 16, 18), Color("#edc2a7"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 39, 107), Vector2(cx - 34, 79), Vector2(cx - 17, 70),
		Vector2(cx, 81), Vector2(cx + 17, 70), Vector2(cx + 34, 79),
		Vector2(cx + 39, 107),
	]), Color("#f7ede1"))
	# Hair mass behind the head, painted in soft overlapping locks.
	draw_circle(Vector2(cx, 44), 31, Color("#80614d"))
	for lock in [Vector2(-25, 49), Vector2(-22, 67), Vector2(24, 48), Vector2(22, 66)]:
		draw_circle(Vector2(cx, 0) + lock, 9, Color("#906d56"))
	# Face and fringe.
	draw_circle(Vector2(cx, 46), 24, Color("#f0c6aa"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 24, 42), Vector2(cx - 19, 23), Vector2(cx - 7, 17),
		Vector2(cx + 4, 23), Vector2(cx + 18, 19), Vector2(cx + 24, 36),
		Vector2(cx + 9, 32), Vector2(cx - 3, 37),
	]), Color("#80614d"))
	# Gentle cheeks, expressive eyes, and a small welcoming smile.
	draw_circle(Vector2(cx - 12, 51), 4.5, Color("#dd9a90", 0.52))
	draw_circle(Vector2(cx + 12, 51), 4.5, Color("#dd9a90", 0.52))
	draw_circle(Vector2(cx - 8, 45), 2.8, Color("#4b3b34"))
	draw_circle(Vector2(cx + 8, 45), 2.8, Color("#4b3b34"))
	draw_arc(Vector2(cx, 53), 5.5, 0.15, PI - 0.15, 14, Color("#a95f61"), 1.6)
	# Apron bib and straps.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 17, 78), Vector2(cx - 12, 73), Vector2(cx + 12, 73),
		Vector2(cx + 17, 78), Vector2(cx + 24, 107), Vector2(cx - 24, 107),
	]), Color("#8ba77f"))
	draw_line(Vector2(cx - 15, 76), Vector2(cx - 21, 65), Color("#8ba77f"), 3.0)
	draw_line(Vector2(cx + 15, 76), Vector2(cx + 21, 65), Color("#8ba77f"), 3.0)
	# Little botanical pin.
	var pin := Vector2(cx + 27, 76)
	draw_line(pin, pin + Vector2(0, 9), Color("#6e8f65"), 1.6)
	draw_circle(pin + Vector2(-3, -2), 3.3, Color("#df9294"))
	draw_circle(pin + Vector2(3, -2), 3.3, Color("#df9294"))
	draw_circle(pin + Vector2(0, -5), 3.0, Color("#f0b7ad"))
	draw_circle(pin, 1.7, Color("#c2a064"))
	# A few delicate ink strokes suggest watercolor illustration without hard UI icon lines.
	draw_polyline(PackedVector2Array([Vector2(cx - 28, 53), Vector2(cx - 25, 68), Vector2(cx - 19, 76)]), INK, 1.2)
	draw_polyline(PackedVector2Array([Vector2(cx + 28, 53), Vector2(cx + 25, 68), Vector2(cx + 19, 76)]), INK, 1.2)
