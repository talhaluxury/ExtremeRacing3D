class_name DriftSystem
extends RefCounted
## Detects drifting from the slip angle (angle between where the car points
## and where it actually moves), builds a score with a growing multiplier and
## banks it when the drift ends.

const START_SLIP := 0.28    # radians (about 16 degrees)
const END_SLIP := 0.14
const MIN_SPEED := 12.0     # m/s (about 43 km/h)
const MIN_TIME_TO_BANK := 0.6

var drifting: bool = false
var amount: float = 0.0     # smoothed 0..1, used by the camera
var slip: float = 0.0
var current_points: float = 0.0
var multiplier: float = 1.0
var total_score: float = 0.0
var last_bank: float = 0.0
var since_bank: float = 99.0

var _time: float = 0.0
var _end_timer: float = 0.0


func update(delta: float, vel: Vector3, forward: Vector3, right: Vector3, grounded: bool) -> void:
    since_bank += delta
    var speed := vel.length()
    var fwd_speed := vel.dot(forward)
    var lat_speed := vel.dot(right)
    slip = absf(atan2(lat_speed, maxf(absf(fwd_speed), 0.1)))

    var threshold := END_SLIP if drifting else START_SLIP
    var active := grounded and speed > MIN_SPEED and slip > threshold
    if active:
        if not drifting:
            drifting = true
            _time = 0.0
            current_points = 0.0
        _end_timer = 0.0
        _time += delta
        multiplier = minf(1.0 + _time * 0.5, 5.0)
        current_points += speed * 3.6 * slip * 0.6 * multiplier * delta
    elif drifting:
        _end_timer += delta
        if _end_timer > 0.5:
            _finish()

    var goal := clampf(slip / 0.6, 0.0, 1.0) if drifting else 0.0
    amount = move_toward(amount, goal, delta * 4.0)


func cancel() -> void:
    # Called after a crash: the drift points are lost.
    drifting = false
    current_points = 0.0
    multiplier = 1.0
    _time = 0.0


func _finish() -> void:
    if _time >= MIN_TIME_TO_BANK and current_points > 0.0:
        total_score += current_points
        last_bank = current_points
        since_bank = 0.0
    cancel()
