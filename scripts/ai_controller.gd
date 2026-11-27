class_name AIController
extends Node
## Drives a CarController along the track. It does not cheat on physics: it
## only sets throttle / brake / steering / nitro, like a player would.

const LANE_LIMIT := 6.5
const SAMPLE_SPACING := 3.3   # metres between centre-line samples (approx.)

var car: CarController
var track: TrackBuilder
var skill: float = 0.9        # 0.8 easy .. 1.0 hard
var lane_offset: float = 0.0
var use_nitro: bool = false
var enabled: bool = false
var rubber: float = 0.0   # set by RaceManager: >0 means player is ahead
var others: Array[CarController] = []

var _idx: int = 0
var _lane_now: float = 0.0
var _stuck_time: float = 0.0
var _flip_time: float = 0.0


func init_at(start_idx: int, lane: float) -> void:
    _idx = posmod(start_idx, TrackBuilder.SAMPLES)
    lane_offset = lane
    _lane_now = lane


func _physics_process(delta: float) -> void:
    if car == null or not is_instance_valid(car) or not enabled:
        return
    var n := track.count
    _idx = track.nearest_index(car.global_position, _idx)
    var fs := car.forward_speed
    var eff := skill + clampf(rubber, -1.0, 1.0) * 0.05

    # --- lane choice and overtaking
    var rt := track.tangents[_idx].cross(Vector3.UP).normalized()
    var lat := (car.global_position - track.points[_idx]).dot(rt)
    var desired := lane_offset
    for other in others:
        if other == car or not is_instance_valid(other):
            continue
        var rel := car.to_local(other.global_position)
        if rel.z < 0.0 and rel.z > -26.0 and absf(rel.x) < 3.4:
            var side := -1.0 if rel.x >= 0.0 else 1.0
            desired = clampf(lat + side * 4.5, -LANE_LIMIT, LANE_LIMIT)
            break
    _lane_now = move_toward(_lane_now, desired, 5.0 * delta)

    # --- steering towards a look-ahead point
    var look := clampi(int((8.0 + absf(fs) * 0.7) / SAMPLE_SPACING), 3, 24)
    var ti := posmod(_idx + look, n)
    var tr := track.tangents[ti].cross(Vector3.UP).normalized()
    var target := track.points[ti] + tr * _lane_now
    var local := car.to_local(target)
    var angle := atan2(local.x, -local.z)
    car.ai_steer = clampf(-angle * 2.5, -1.0, 1.0)

    # --- speed planning from upcoming corners
    var a_lat := car.grip_accel * 0.75 * eff
    var v_target := car.max_speed * eff
    var t0 := track.tangents[_idx]
    var straight := true
    for ahead_m: float in [35.0, 75.0, 120.0]:
        var steps := int(float(ahead_m) / SAMPLE_SPACING)
        var t1 := track.tangents[posmod(_idx + steps, n)]
        var turn := acos(clampf(t0.dot(t1), -1.0, 1.0))
        if turn > 0.03:
            v_target = minf(v_target, sqrt(a_lat * float(ahead_m) / turn))
        if turn > 0.12:
            straight = false
    if absf(angle) > 0.5:
        v_target = minf(v_target, 14.0)

    var err := v_target - fs
    if err > 1.0:
        car.ai_throttle = 1.0
        car.ai_brake = 0.0
    elif err < -2.5:
        car.ai_throttle = 0.0
        car.ai_brake = clampf(-err / 10.0, 0.2, 1.0)
    else:
        car.ai_throttle = 0.4
        car.ai_brake = 0.0

    car.ai_nitro = use_nitro and straight and absf(angle) < 0.1 and fs > 20.0 and car.nitro.meter > 40.0

    # --- recovery: stuck or upside down
    if car.speed_kmh < 5.0:
        _stuck_time += delta
    else:
        _stuck_time = 0.0
    if car.is_upside_down():
        _flip_time += delta
    else:
        _flip_time = 0.0
    if _stuck_time > 3.0 or _flip_time > 2.5:
        car.reset_to(track.grid_transform(_idx, 0.0))
        _stuck_time = 0.0
        _flip_time = 0.0
