class_name Minimap
extends Control
## Small track map in the corner of the HUD: road outline, the player (yellow)
## and the AI cars (red).

const SIZE := 170.0

var track: TrackBuilder
var cars: Array[CarController] = []
var player: CarController

var _pts := PackedVector2Array()
var _scale: float = 1.0


func setup(t: TrackBuilder, all_cars: Array[CarController], p: CarController) -> void:
    track = t
    cars = all_cars
    player = p
    custom_minimum_size = Vector2(SIZE, SIZE)
    size = Vector2(SIZE, SIZE)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    anchor_left = 1.0
    anchor_right = 1.0
    offset_left = -SIZE - 24.0
    offset_right = -24.0
    offset_top = 135.0
    offset_bottom = 135.0 + SIZE
    var extent := 1.0
    for i in range(0, track.count, 4):
        var v := Vector2(track.points[i].x, track.points[i].z)
        _pts.append(v)
        extent = maxf(extent, maxf(absf(v.x), absf(v.y)))
    if _pts.size() > 0:
        _pts.append(_pts[0])
    _scale = (SIZE * 0.46) / extent


func _to_map(world: Vector3) -> Vector2:
    return Vector2(SIZE * 0.5 + world.x * _scale, SIZE * 0.5 + world.z * _scale)


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    draw_circle(Vector2(SIZE * 0.5, SIZE * 0.5), SIZE * 0.5, Color(0, 0, 0, 0.45))
    if _pts.size() < 2:
        return
    var mapped := PackedVector2Array()
    for v in _pts:
        mapped.append(Vector2(SIZE * 0.5 + v.x * _scale, SIZE * 0.5 + v.y * _scale))
    draw_polyline(mapped, Color(0.9, 0.9, 0.95, 0.9), 3.0, true)
    draw_circle(mapped[0], 4.0, Color(1, 1, 1))   # start / finish
    for c in cars:
        if c == null or not is_instance_valid(c) or c == player:
            continue
        draw_circle(_to_map(c.global_position), 4.0, Color(0.95, 0.2, 0.2))
    if player != null and is_instance_valid(player):
        draw_circle(_to_map(player.global_position), 5.5, Color(1.0, 0.85, 0.1))
