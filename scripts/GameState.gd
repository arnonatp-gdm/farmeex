# GameState.gd — Global autoload singleton
# Manages all persistent game state: resources, vehicles, gear, and carts.
extends Node

# ── Signals ──────────────────────────────────────────────────────────────────
signal mp_changed(value: int)
signal sp_changed(value: int)
signal vehicle_changed(type: int)
signal gear_changed(gear: int)
signal cart_count_changed(count: int)
signal field_haste_changed(field_id: int, seconds_saved: float)

# ── Currency ──────────────────────────────────────────────────────────────────
var moon_points: int = 0
var star_points: int = 0

# ── Vehicles ──────────────────────────────────────────────────────────────────
enum VehicleType { TRACTOR = 0, JEEP = 1, HELICOPTER = 2 }

var current_vehicle: int = VehicleType.TRACTOR
var vehicles_unlocked: Array[int] = [VehicleType.TRACTOR, VehicleType.JEEP, VehicleType.HELICOPTER]

# ── Gear system ───────────────────────────────────────────────────────────────
# Gear range: -2 (fast reverse) to 4 (fastest forward); 0 = neutral / stopped
var current_gear: int = 0

# Base speeds in pixels/second for each gear (modified by vehicle multiplier)
const GEAR_SPEEDS: Dictionary = {
	-2: -100.0,
	-1:  -50.0,
	 0:    0.0,
	 1:   70.0,
	 2:  130.0,
	 3:  190.0,
	 4:  250.0,
}

const VEHICLE_SPEED_MULT: Dictionary = {
	VehicleType.TRACTOR:    1.0,
	VehicleType.JEEP:       1.6,
	VehicleType.HELICOPTER: 2.8,
}

# ── Cart tracking ─────────────────────────────────────────────────────────────
var cart_count: int = 0

# ── Player world position (updated by active vehicle) ─────────────────────────
var player_position: Vector2 = Vector2.ZERO

# ── Field haste (minigame reward) ─────────────────────────────────────────────
# Maps field_id → extra seconds removed from spawn timer
var field_haste: Dictionary = {}

# =============================================================================
# Currency helpers
# =============================================================================

func add_mp(amount: int) -> void:
	moon_points += amount
	mp_changed.emit(moon_points)

func add_sp(amount: int) -> void:
	star_points += amount
	sp_changed.emit(star_points)

func can_afford(mp_cost: int, sp_cost: int) -> bool:
	return moon_points >= mp_cost and star_points >= sp_cost

func spend_resources(mp_cost: int, sp_cost: int) -> bool:
	if can_afford(mp_cost, sp_cost):
		moon_points -= mp_cost
		star_points -= sp_cost
		mp_changed.emit(moon_points)
		sp_changed.emit(star_points)
		return true
	return false

# =============================================================================
# Hay collection — immediate bonus + queues a cart
# =============================================================================

func collect_hay() -> void:
	add_mp(10)
	add_sp(2)
	cart_count += 1
	cart_count_changed.emit(cart_count)

# =============================================================================
# Delivery formulas
# n carts at barn  → n*2 + (n-1)*1 MP,  n*5 + (n-1)*2 SP
# n carts at mill  → n*5 + (n-1)*1 MP,  n*2 + (n-1)*2 SP
# =============================================================================

func deliver_to_barn() -> int:
	if cart_count == 0:
		return 0
	var n: int = cart_count
	add_mp(n * 2 + (n - 1) * 1)
	add_sp(n * 5 + (n - 1) * 2)
	var delivered := cart_count
	cart_count = 0
	cart_count_changed.emit(cart_count)
	return delivered

func deliver_to_mill() -> int:
	if cart_count == 0:
		return 0
	var n: int = cart_count
	add_mp(n * 5 + (n - 1) * 1)
	add_sp(n * 2 + (n - 1) * 2)
	var delivered := cart_count
	cart_count = 0
	cart_count_changed.emit(cart_count)
	return delivered

func lose_cart() -> void:
	if cart_count > 0:
		cart_count -= 1
		cart_count_changed.emit(cart_count)

# =============================================================================
# Gear helpers
# =============================================================================

func shift_gear_up() -> void:
	if current_gear < 4:
		current_gear += 1
		gear_changed.emit(current_gear)

func shift_gear_down() -> void:
	if current_gear > -2:
		current_gear -= 1
		gear_changed.emit(current_gear)

func stop_vehicle() -> void:
	current_gear = 0
	gear_changed.emit(current_gear)

func get_current_speed() -> float:
	var base: float = GEAR_SPEEDS.get(current_gear, 0.0)
	return base * VEHICLE_SPEED_MULT.get(current_vehicle, 1.0)

# =============================================================================
# Vehicle switching
# =============================================================================

func switch_vehicle() -> void:
	var idx: int = vehicles_unlocked.find(current_vehicle)
	idx = (idx + 1) % vehicles_unlocked.size()
	current_vehicle = vehicles_unlocked[idx]
	vehicle_changed.emit(current_vehicle)

# =============================================================================
# Minigame field-haste reward
# =============================================================================

func apply_field_haste(field_id: int, seconds: float) -> void:
	field_haste[field_id] = field_haste.get(field_id, 0.0) + seconds
	field_haste_changed.emit(field_id, field_haste[field_id])

func consume_haste(field_id: int) -> float:
	var h: float = field_haste.get(field_id, 0.0)
	field_haste.erase(field_id)
	return h
