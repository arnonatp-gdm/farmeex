# Jeep.gd — Medium-speed vehicle with water-cannon area
extends Vehicle

const JEEP_COLOR   := Color(0.60, 0.50, 0.25, 1.0)  # tan/khaki
const CANNON_RANGE := 180.0
const CANNON_FORCE := 320.0

var _cannon_cooldown: float = 0.0

func _ready() -> void:
	can_use_cannon = true
	turn_speed     = 2.4
	_build_visuals()
	add_to_group("vehicles")
	add_to_group("jeep")

func _build_visuals() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-18, -12), Vector2(22, -12),
		Vector2(26,  -6),  Vector2(26,  6),
		Vector2(22,  12),  Vector2(-18, 12),
	])
	body.color = JEEP_COLOR
	add_child(body)

	# Cannon barrel (points forward / right)
	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([
		Vector2(26, -3), Vector2(46, -3),
		Vector2(46,  3), Vector2(26,  3),
	])
	barrel.color = Color(0.30, 0.30, 0.30, 1.0)
	add_child(barrel)

	# Wheels
	for pos in [Vector2(-14, 16), Vector2(18, 16),
				Vector2(-14, -16), Vector2(18, -16)]:
		var w := Polygon2D.new()
		w.color = Color(0.1, 0.1, 0.1, 1.0)
		var pts: Array[Vector2] = []
		for i in 8:
			var a := i * TAU / 8.0
			pts.append(pos + Vector2(cos(a), sin(a)) * 7.0)
		w.polygon = PackedVector2Array(pts)
		add_child(w)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 28)
	cs.shape = rect
	add_child(cs)

func _physics_process(delta: float) -> void:
	super(delta)
	if _cannon_cooldown > 0.0:
		_cannon_cooldown -= delta

func fire_water_cannon() -> void:
	if _cannon_cooldown > 0.0:
		return
	_cannon_cooldown = 1.5

	# Push all enemies within CANNON_RANGE away from this vehicle
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < CANNON_RANGE and dist > 0.1:
			var dir: Vector2 = (enemy.global_position - global_position).normalized()
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(dir * CANNON_FORCE)

	# Visual flash — brief white circle drawn by a temporary node
	var flash := _SpawnFlash.new(global_position, CANNON_RANGE, get_parent())
	get_parent().add_child(flash)

# ── Inner helper — ephemeral flash sprite ─────────────────────────────────────
class _SpawnFlash extends Node2D:
	var _timer: float = 0.25
	var _radius: float
	func _init(pos: Vector2, r: float, parent: Node) -> void:
		global_position = pos
		_radius = r
	func _draw() -> void:
		draw_circle(Vector2.ZERO, _radius, Color(0.5, 0.8, 1.0, 0.3))
	func _process(delta: float) -> void:
		_timer -= delta
		queue_redraw()
		if _timer <= 0.0:
			queue_free()
