# Tractor.gd — Slow vehicle that collects hay carts (4 fwd / 2 rev gears)
extends Vehicle

const TRACTOR_COLOR  := Color(0.18, 0.55, 0.18, 1.0)  # dark green body
const WHEEL_COLOR    := Color(0.12, 0.12, 0.12, 1.0)

func _ready() -> void:
	can_collect_hay = true
	turn_speed      = 1.6
	_build_visuals()
	add_to_group("vehicles")
	add_to_group("tractor")

func _build_visuals() -> void:
	# Body — simple rectangle polygon (local coords, facing right)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-22, -14), Vector2(22, -14),
		Vector2(26, -8),   Vector2(26,  8),
		Vector2(22,  14),  Vector2(-22, 14),
	])
	body.color = TRACTOR_COLOR
	add_child(body)

	# Cab (rear-left block)
	var cab := Polygon2D.new()
	cab.polygon = PackedVector2Array([
		Vector2(-22, -14), Vector2(2, -14),
		Vector2(2, -22),   Vector2(-22, -22),
	])
	cab.color = Color(0.25, 0.45, 0.25, 1.0)
	add_child(cab)

	# Wheels
	for pos in [Vector2(-16, 18), Vector2(18, 18),
				Vector2(-16, -18), Vector2(18, -18)]:
		var w := Polygon2D.new()
		w.color = WHEEL_COLOR
		var pts: Array[Vector2] = []
		for i in 8:
			var a := i * TAU / 8.0
			pts.append(pos + Vector2(cos(a), sin(a)) * 8.0)
		w.polygon = PackedVector2Array(pts)
		add_child(w)

	# Collision shape
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 30)
	cs.shape = rect
	add_child(cs)
