# Map.gd — Procedural world map generator.
# Creates a 5120×5120 world with:
#   • Grassland background
#   • Criss-cross grid of roads (E/W and N/S)
#   • Farm buildings (Barns, Mills, Houses) at road intersections
#   • Wildland areas with enemy dens / lairs
#   • Rectangular farm fields scattered across grass patches
extends Node2D

const WORLD_SIZE  := 5120
const ROAD_WIDTH  := 48
const ROAD_STEP   := 512   # distance between parallel roads
const GRASS_COLOR := Color(0.42, 0.70, 0.28, 1.0)
const ROAD_COLOR  := Color(0.55, 0.52, 0.48, 1.0)
const WILD_COLOR  := Color(0.28, 0.50, 0.18, 1.0)

@export var num_barns:     int = 6
@export var num_mills:     int = 5
@export var num_fields:    int = 18
@export var num_enemies:   int = 12

var _field_id_counter: int = 0

func _ready() -> void:
	_draw_background()
	_draw_roads()
	_place_wildlands()
	_place_buildings()
	_place_fields()
	_spawn_enemies()

# ── Background ────────────────────────────────────────────────────────────────
func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color    = GRASS_COLOR
	bg.size     = Vector2(WORLD_SIZE, WORLD_SIZE)
	bg.position = Vector2(-WORLD_SIZE / 2, -WORLD_SIZE / 2)
	add_child(bg)

# ── Roads ─────────────────────────────────────────────────────────────────────
func _draw_roads() -> void:
	var half := WORLD_SIZE / 2
	var steps := range(-half, half, ROAD_STEP)
	for x in steps:
		# Vertical road
		var v := ColorRect.new()
		v.color    = ROAD_COLOR
		v.size     = Vector2(ROAD_WIDTH, WORLD_SIZE)
		v.position = Vector2(x - ROAD_WIDTH / 2, -half)
		add_child(v)
	for y in steps:
		# Horizontal road
		var h := ColorRect.new()
		h.color    = ROAD_COLOR
		h.size     = Vector2(WORLD_SIZE, ROAD_WIDTH)
		h.position = Vector2(-half, y - ROAD_WIDTH / 2)
		add_child(h)

# ── Wildland patches ──────────────────────────────────────────────────────────
func _place_wildlands() -> void:
	for _i in 8:
		var w := ColorRect.new()
		var ww := randf_range(200, 400)
		var wh := randf_range(200, 400)
		w.color    = WILD_COLOR
		w.size     = Vector2(ww, wh)
		w.position = _random_grass_pos(ww, wh)
		add_child(w)

		# Den label
		var lbl := Label.new()
		lbl.text     = "🐾 Den"
		lbl.position = w.position + Vector2(10, 10)
		lbl.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		add_child(lbl)

# ── Buildings ─────────────────────────────────────────────────────────────────
func _place_buildings() -> void:
	var barn_scene := load("res://scenes/Barn.tscn")
	var mill_scene := load("res://scenes/Mill.tscn")

	# Place barns at road intersections
	var intersections := _get_road_intersections()
	intersections.shuffle()
	var idx := 0
	for _i in num_barns:
		if idx >= intersections.size():
			break
		var barn: StaticBody2D = barn_scene.instantiate()
		barn.global_position  = intersections[idx]
		add_child(barn)
		idx += 1
	for _i in num_mills:
		if idx >= intersections.size():
			break
		var mill: StaticBody2D = mill_scene.instantiate()
		mill.global_position  = intersections[idx]
		add_child(mill)
		idx += 1

	# Simple house decorations (ColorRect + label)
	for _i in 8:
		var hpos := _road_side_pos()
		var house := ColorRect.new()
		house.color    = Color(0.85, 0.75, 0.60, 1.0)
		house.size     = Vector2(50, 40)
		house.position = hpos
		add_child(house)
		var hlbl := Label.new()
		hlbl.text     = "🏠"
		hlbl.position = hpos + Vector2(8, 4)
		add_child(hlbl)

func _get_road_intersections() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var half  := WORLD_SIZE / 2
	var steps := range(-half, half, ROAD_STEP)
	for x in steps:
		for y in steps:
			result.append(Vector2(x, y))
	return result

func _road_side_pos() -> Vector2:
	var half  := WORLD_SIZE / 2
	var steps := range(-half, half, ROAD_STEP)
	var x: int = steps[randi() % steps.size()]
	var y: int = steps[randi() % steps.size()]
	return Vector2(x + ROAD_WIDTH + randf_range(20, 80),
				   y + ROAD_WIDTH + randf_range(20, 80))

# ── Fields ────────────────────────────────────────────────────────────────────
func _place_fields() -> void:
	var field_scene := load("res://scenes/Field.tscn")
	for _i in num_fields:
		var fw: float = randf_range(3, 10) * 32.0   # 3–10 "cells" wide
		var fh: float = randf_range(4, 15) * 32.0   # 4–15 "cells" tall
		var field: Node2D = field_scene.instantiate()
		field.set("field_width",  fw)
		field.set("field_height", fh)
		field.set("field_id",     _field_id_counter)
		_field_id_counter += 1
		field.global_position = _random_grass_pos(fw, fh)
		add_child(field)

# ── Enemies ───────────────────────────────────────────────────────────────────
func _spawn_enemies() -> void:
	var enemy_scene := load("res://scenes/Enemy.tscn")
	for i in num_enemies:
		var enemy: CharacterBody2D = enemy_scene.instantiate()
		# Alternate between scarecrow and chicken
		enemy.set("enemy_type", i % 2)
		enemy.global_position = _random_grass_pos(20, 20)
		add_child(enemy)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _random_grass_pos(w: float, h: float) -> Vector2:
	var half := WORLD_SIZE / 2
	return Vector2(
		randf_range(-half + w, half - w),
		randf_range(-half + h, half - h)
	)
