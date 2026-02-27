# Enemy.gd — Scarecrow or Chicken that wanders and chases cart snakes.
# Touching a cart steals it (handled by the Cart's body_entered signal).
extends CharacterBody2D

enum EnemyType { SCARECROW = 0, CHICKEN = 1 }

@export var enemy_type: EnemyType = EnemyType.SCARECROW
@export var wander_speed: float   = 40.0
@export var chase_speed:  float   = 90.0
@export var detection_range: float = 380.0

const COLORS := {
	EnemyType.SCARECROW: Color(0.80, 0.70, 0.40, 1.0),
	EnemyType.CHICKEN:   Color(0.98, 0.98, 0.92, 1.0),
}

var _target_cart: Node2D = null
var _wander_dir:  Vector2 = Vector2.RIGHT
var _wander_timer: float  = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 16
	collision_mask  = 1

	_build_visuals()
	_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _build_visuals() -> void:
	match enemy_type:
		EnemyType.SCARECROW:
			# Cross / T-shape scarecrow
			var body := Polygon2D.new()
			body.polygon = PackedVector2Array([
				Vector2(-3, -20), Vector2(3, -20),
				Vector2(3,   20), Vector2(-3, 20),
			])
			body.color = COLORS[EnemyType.SCARECROW]
			add_child(body)
			var arms := Polygon2D.new()
			arms.polygon = PackedVector2Array([
				Vector2(-18, -8), Vector2(18, -8),
				Vector2(18,  -2), Vector2(-18, -2),
			])
			arms.color = COLORS[EnemyType.SCARECROW]
			add_child(arms)
			# Hat
			var hat := Polygon2D.new()
			hat.polygon = PackedVector2Array([
				Vector2(-8, -20), Vector2(8, -20),
				Vector2(6, -30),  Vector2(-6, -30),
			])
			hat.color = Color(0.2, 0.15, 0.05, 1.0)
			add_child(hat)

		EnemyType.CHICKEN:
			# Oval body
			var pts: Array[Vector2] = []
			for i in 12:
				var a := i * TAU / 12.0
				pts.append(Vector2(cos(a) * 10.0, sin(a) * 14.0))
			var body := Polygon2D.new()
			body.polygon = PackedVector2Array(pts)
			body.color   = COLORS[EnemyType.CHICKEN]
			add_child(body)
			# Comb
			var comb := Polygon2D.new()
			comb.polygon = PackedVector2Array([
				Vector2(-3, -14), Vector2(3, -14),
				Vector2(2, -22),  Vector2(-2, -22),
			])
			comb.color = Color(1.0, 0.2, 0.2, 1.0)
			add_child(comb)

	var cs     := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	cs.shape = circle
	add_child(cs)

func _physics_process(delta: float) -> void:
	# Decay knockback
	_knockback_vel = _knockback_vel.lerp(Vector2.ZERO, 6.0 * delta)

	_find_target()

	if _target_cart != null and is_instance_valid(_target_cart):
		_chase(delta)
	else:
		_wander(delta)

	velocity += _knockback_vel
	move_and_slide()
	velocity -= _knockback_vel  # don't accumulate

func _find_target() -> void:
	_target_cart = null
	if GameState.cart_count == 0:
		return
	var best_dist := detection_range
	for cart in get_tree().get_nodes_in_group("carts"):
		var d := global_position.distance_to(cart.global_position)
		if d < best_dist:
			best_dist    = d
			_target_cart = cart

func _chase(delta: float) -> void:
	var dir := (_target_cart.global_position - global_position).normalized()
	velocity = dir * chase_speed
	rotation = atan2(dir.y, dir.x)

func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 4.0)
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity = _wander_dir * wander_speed
	rotation = atan2(_wander_dir.y, _wander_dir.x)

func apply_knockback(impulse: Vector2) -> void:
	_knockback_vel += impulse
