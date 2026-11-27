class_name ChaseCamera
extends Camera3D
## Camera with 4 views: near chase, far chase, bumper, cockpit. Only the heading is
## smoothed, so the distance to the car stays constant at high speed.
## Effects: speed/nitro FOV, nitro rumble, crash shake, drift look-ahead.

const VIEW_BUMPER := 2
const VIEW_COCKPIT := 3
const DIST := [6.2, 8.8]
const HEIGHT := [2.3, 3.2]
const BASE_FOV := [68.0, 70.0, 78.0, 82.0]

var target: CarController
var mode: int = 0

var _heading: Vector3 = Vector3.BACK
var _shake: float = 0.0


func _ready() -> void:
    top_level = true
    fov = BASE_FOV[0]
    current = true


func cycle_mode() -> void:
    mode = (mode + 1) % 4
    if mode < VIEW_BUMPER and target != null and is_instance_valid(target):
        snap(target.global_transform)


func shake(amount: float) -> void:
    _shake = maxf(_shake, amount)


var _intro_left: float = 0.0
var _intro_total: float = 1.0


## Start-of-race cinematic: the camera swings round the car from the front to
## the normal chase position, then hands over to the chase camera.
func start_intro(duration: float) -> void:
    _intro_left = duration
    _intro_total = maxf(duration, 0.1)


func skip_intro() -> void:
    _intro_left = 0.0


func is_intro_running() -> bool:
    return _intro_left > 0.0


func _play_intro(delta: float) -> void:
    _intro_left -= delta
    var t := clampf(1.0 - _intro_left / _intro_total, 0.0, 1.0)
    var e := t * t * (3.0 - 2.0 * t)   # smooth in / out
    var a := lerpf(PI * 0.8, 0.0, e)
    var r := lerpf(7.5, 6.2, e)
    var h := lerpf(1.3, 2.3, e)
    var xf := target.global_transform
    var local := Vector3(sin(a) * r, h, cos(a) * r)
    global_position = xf.origin + xf.basis * local
    look_at(xf.origin + Vector3.UP * 0.8, Vector3.UP)
    fov = lerpf(fov, 62.0 + e * 6.0, 1.0 - exp(-4.0 * delta))
    if _intro_left <= 0.0:
        snap(xf)


func snap(xf: Transform3D) -> void:
    _heading = _flat(xf.basis.z, Vector3.BACK)
    _place(xf.origin, 0.0)


func _physics_process(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    if _intro_left > 0.0:
        _play_intro(delta)
        return

    var boost := target.nitro.boost
    var drift_amt := target.drift.amount
    var ratio := clampf(target.speed_kmh / 250.0, 0.0, 1.0)
    var base_fov: float = BASE_FOV[mode]
    fov = lerpf(fov, base_fov + ratio * 18.0 + boost * 14.0, 1.0 - exp(-3.0 * delta))

    if mode == VIEW_COCKPIT:
        # driver's eye inside the glass cabin
        var xfc := target.global_transform
        global_transform = Transform3D(xfc.basis, xfc.origin + xfc.basis * target.eye_offset())
    elif mode == VIEW_BUMPER:
        var l: float = float(target.data["length"])
        var xf := target.global_transform
        global_transform = Transform3D(xf.basis, xf.origin + xf.basis * Vector3(0.0, 0.62, -l * 0.5 + 0.35))
    else:
        var back := _flat(target.global_transform.basis.z, _heading)
        var vel := target.linear_velocity
        if drift_amt > 0.01 and vel.length() > 8.0:
            # while sliding, look more along the direction of travel
            var vback := _flat(-vel, back)
            back = _flat(back.lerp(vback, 0.55 * drift_amt), back)
        _heading = _flat(_heading.lerp(back, 1.0 - exp(-6.0 * delta)), back)
        _place(target.global_position, ratio)

    var s := _shake + boost * 0.12
    h_offset = randf_range(-1.0, 1.0) * s * 0.25
    v_offset = randf_range(-1.0, 1.0) * s * 0.25
    _shake = move_toward(_shake, 0.0, delta * 2.0)


func _place(origin: Vector3, ratio: float) -> void:
    var i := mini(mode, 1)
    var d: float = DIST[i]
    var h: float = HEIGHT[i]
    global_position = origin + _heading * (d + ratio * 1.8) + Vector3.UP * (h + ratio * 0.3)
    look_at(origin + Vector3.UP * 1.0 - _heading * 5.0, Vector3.UP)


func _flat(v: Vector3, fallback: Vector3) -> Vector3:
    v.y = 0.0
    if v.length() < 0.001:
        return fallback
    return v.normalized()
