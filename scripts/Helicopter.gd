# Helicopter.gd — Fast aerial vehicle; can deploy tractor/jeep into distant fields.
extends Vehicle

const HELI_COLOR := Color(0.20, 0.40, 0.80, 1.0)  # blue

var _deploy_cooldown: float = 0.0

func _ready() -> void:
	can_fly    = true
	turn_speed = 3.2
	_build_visuals()
	add_to_group("vehicles")
	add_to_group("helicopter")

func _build_visuals() -> void:
	# Fuselage
	var pts: Array[Vector2] = []
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(Vector2(cos(a) * 28.0, sin(a) * 14.0))
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array(pts)
	body.color = HELI_COLOR
	add_child(body)

	# Rotor blade (horizontal bar)
	var rotor := Polygon2D.new()
	rotor.polygon = PackedVector2Array([
		Vector2(-36, -3), Vector2(36, -3),
		Vector2(36,  3),  Vector2(-36, 3),
	])
	rotor.color = Color(0.7, 0.7, 0.7, 0.8)
	add_child(rotor)

	# Tail boom
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(-28, -4), Vector2(-52, -4),
		Vector2(-52,  4), Vector2(-28,  4),
	])
	tail.color = Color(0.15, 0.35, 0.70, 1.0)
	add_child(tail)

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	cs.shape = circle
	add_child(cs)

func _physics_process(delta: float) -> void:
	# Helicopter ignores terrain — skip CharacterBody2D physics, use direct movement
	var speed := GameState.get_current_speed()
	var moving := abs(speed) > 5.0
	if moving:
		if turning_left:
			rotation -= turn_speed * delta * sign(speed)
		if turning_right:
			rotation += turn_speed * delta * sign(speed)

	# Move with global_translate so it bypasses collision layers
	global_position += Vector2(cos(rotation), sin(rotation)) * speed * delta
	GameState.player_position = global_position

	if _deploy_cooldown > 0.0:
		_deploy_cooldown -= delta

func deploy_vehicle(vehicle_scene: PackedScene) -> void:
	if _deploy_cooldown > 0.0:
		return
	_deploy_cooldown = 5.0
	var v: Vehicle = vehicle_scene.instantiate()
	v.global_position = global_position
	get_parent().add_child(v)
