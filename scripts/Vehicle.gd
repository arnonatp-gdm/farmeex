# Vehicle.gd — Base class for all drivable vehicles (CharacterBody2D)
# Subclasses override turn_speed, can_collect, can_fly, etc.
extends CharacterBody2D

class_name Vehicle

# ── Inspector tunables ────────────────────────────────────────────────────────
@export var turn_speed: float       = 2.0   # radians / second
@export var can_collect_hay: bool   = false
@export var can_use_cannon: bool    = false
@export var can_fly: bool           = false

# ── Steering state (set by UI buttons) ───────────────────────────────────────
var turning_left:  bool = false
var turning_right: bool = false

# ── Internal ──────────────────────────────────────────────────────────────────
var _body: Polygon2D

func _ready() -> void:
	_build_visuals()
	add_to_group("vehicles")

# Override in subclasses to supply a Polygon2D body
func _build_visuals() -> void:
	pass

func _physics_process(delta: float) -> void:
	_apply_steering(delta)
	_apply_movement()
	GameState.player_position = global_position

func _apply_steering(delta: float) -> void:
	var speed := GameState.get_current_speed()
	# Only turn while moving (realistic tractor/jeep behaviour)
	if abs(speed) > 5.0:
		var dir := sign(speed)
		if turning_left:
			rotation -= turn_speed * delta * dir
		if turning_right:
			rotation += turn_speed * delta * dir

func _apply_movement() -> void:
	var speed := GameState.get_current_speed()
	# Vehicle faces right at rotation=0; forward = +X axis rotated
	velocity = Vector2(cos(rotation), sin(rotation)) * speed
	move_and_slide()

# Called by the Jeep when fire button combo is triggered
func fire_water_cannon() -> void:
	pass
