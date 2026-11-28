extends Node
## Autoload: global state, input actions and graphics quality.

const MODE_QUICK := 0
const MODE_TRIAL := 1
const MODE_FREE := 2
const TRACK_NAMES := ["GRAND LOOP", "TECHNICAL CIRCUIT", "COASTAL HIGHWAY", "DESERT RUN", "NIGHT CITY"]
const TILT_SENS_STEPS := [0.5, 0.75, 1.0, 1.5, 2.0]
const RENDER_SCALES := [0.0, 0.6, 0.75, 1.0]   # 0 = automatic (by graphics quality)
const TOUCH_SCALES := [0.8, 1.0, 1.25]
const TILT_FULL_LOCK_DEG := 25.0
const TILT_DEADZONE_DEG := 2.0
const GFX_PATH := "user://graphics.cfg"
const QUALITY_NAMES := ["LOW", "MEDIUM", "HIGH"]
const FPS_OPTIONS := [30, 60]

var mode: int = MODE_QUICK
var track_index: int = 0
var difficulty: int = 1   # 0 easy, 1 normal, 2 hard
var laps: int = 3
var selected_car: int = 0
var graphics_quality: int = 1  # 0 = low, 1 = medium, 2 = high
var target_fps: int = 60
var career_event: int = -1   # -1 = not a career race
var tilt_enabled: bool = false
var tilt_sensitivity: float = 1.0
var tilt_invert: bool = false
var rain: bool = false
var render_scale: float = 0.0
var touch_scale: float = 1.0
var touch_mirror: bool = false
var steer_wheel: bool = false

var _tilt_down_axis: int = 1   # accelerometer axis that carries gravity when held level
var _tilt_base: float = 0.0


func _ready() -> void:
    _setup_input()
    _load_graphics()
    Engine.max_fps = target_fps


func _load_graphics() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(GFX_PATH) == OK:
        graphics_quality = clampi(int(cfg.get_value("graphics", "quality", 1)), 0, 2)
        target_fps = 30 if int(cfg.get_value("graphics", "fps", 60)) == 30 else 60
        tilt_enabled = bool(cfg.get_value("controls", "tilt", false))
        tilt_sensitivity = clampf(float(cfg.get_value("controls", "tilt_sens", 1.0)), 0.5, 2.0)
        tilt_invert = bool(cfg.get_value("controls", "tilt_invert", false))
        rain = bool(cfg.get_value("graphics", "rain", false))
        render_scale = float(cfg.get_value("graphics", "render_scale", 0.0))
        touch_scale = clampf(float(cfg.get_value("controls", "touch_scale", 1.0)), 0.8, 1.25)
        touch_mirror = bool(cfg.get_value("controls", "touch_mirror", false))
        steer_wheel = bool(cfg.get_value("controls", "steer_wheel", false))


func _save_graphics() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("graphics", "quality", graphics_quality)
    cfg.set_value("graphics", "fps", target_fps)
    cfg.set_value("graphics", "rain", rain)
    cfg.set_value("graphics", "render_scale", render_scale)
    cfg.set_value("controls", "touch_scale", touch_scale)
    cfg.set_value("controls", "touch_mirror", touch_mirror)
    cfg.set_value("controls", "steer_wheel", steer_wheel)
    cfg.set_value("controls", "tilt", tilt_enabled)
    cfg.set_value("controls", "tilt_sens", tilt_sensitivity)
    cfg.set_value("controls", "tilt_invert", tilt_invert)
    cfg.save(GFX_PATH)


func set_quality(q: int) -> void:
    graphics_quality = clampi(q, 0, 2)
    _save_graphics()


func set_fps(f: int) -> void:
    target_fps = 30 if f == 30 else 60
    Engine.max_fps = target_fps
    _save_graphics()


func cycle_render_scale() -> void:
    var next: float = RENDER_SCALES[0]
    for v: float in RENDER_SCALES:
        if v > render_scale + 0.01:
            next = v
            break
    render_scale = next
    _save_graphics()


func set_rain(on: bool) -> void:
    rain = on
    _save_graphics()


func cycle_touch_scale() -> void:
    var next: float = TOUCH_SCALES[0]
    for v: float in TOUCH_SCALES:
        if v > touch_scale + 0.01:
            next = v
            break
    touch_scale = next
    _save_graphics()


func toggle_touch_mirror() -> void:
    touch_mirror = not touch_mirror
    _save_graphics()


func toggle_steer_wheel() -> void:
    steer_wheel = not steer_wheel
    _save_graphics()


func set_tilt(on: bool) -> void:
    tilt_enabled = on
    _save_graphics()


func cycle_tilt_sensitivity() -> void:
    var next: float = TILT_SENS_STEPS[0]
    for v: float in TILT_SENS_STEPS:
        if v > tilt_sensitivity + 0.01:
            next = v
            break
    tilt_sensitivity = next
    _save_graphics()


func toggle_tilt_invert() -> void:
    tilt_invert = not tilt_invert
    _save_graphics()


## Call while the phone is held the way the player will drive (race start).
## Gravity in the screen plane lies on one of the two accelerometer axes; the
## stronger one is "down", the other one measures the left/right tilt.
func calibrate_tilt() -> void:
    var a := Input.get_accelerometer()
    _tilt_down_axis = 0 if absf(a.x) > absf(a.y) else 1
    _tilt_base = _tilt_angle(a)


func _tilt_angle(a: Vector3) -> float:
    var down := a.x if _tilt_down_axis == 0 else a.y
    var side := a.y if _tilt_down_axis == 0 else a.x
    return atan2(side, maxf(absf(down), 0.001))


## Steering from phone tilt, -1..1, positive = left (like steer_left).
## Returns 0 on devices without an accelerometer (PC).
func tilt_steer() -> float:
    if not tilt_enabled:
        return 0.0
    var deg := rad_to_deg(_tilt_angle(Input.get_accelerometer()) - _tilt_base)
    if absf(deg) < TILT_DEADZONE_DEG:
        return 0.0
    deg -= signf(deg) * TILT_DEADZONE_DEG
    var v := clampf(deg * tilt_sensitivity / (TILT_FULL_LOCK_DEG - TILT_DEADZONE_DEG), -1.0, 1.0)
    return -v if tilt_invert else v


## Opens the loading screen, which then opens the race.
func start_race() -> void:
    get_tree().change_scene_to_file("res://scenes/loading.tscn")


func next_unlocked_track(from: int) -> int:
    var n := TRACK_NAMES.size()
    for step in range(1, n + 1):
        var i := (from + step) % n
        if SaveManager.is_track_unlocked(i):
            return i
    return from


func _add_key(action: StringName, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventKey.new()
    ev.physical_keycode = keycode
    InputMap.action_add_event(action, ev)


func _setup_input() -> void:
    # Keyboard is only for testing on PC. Touch buttons use the same actions.
    _add_key(&"accelerate", KEY_W)
    _add_key(&"accelerate", KEY_UP)
    _add_key(&"brake", KEY_S)
    _add_key(&"brake", KEY_DOWN)
    _add_key(&"steer_left", KEY_A)
    _add_key(&"steer_left", KEY_LEFT)
    _add_key(&"steer_right", KEY_D)
    _add_key(&"steer_right", KEY_RIGHT)
    _add_key(&"reset_car", KEY_R)
    _add_key(&"next_car", KEY_C)
    _add_key(&"nitro", KEY_SHIFT)
    _add_key(&"handbrake", KEY_SPACE)
    _add_key(&"change_view", KEY_V)


## Player car data: base stats + owned upgrades + chosen paint and wheels.
func get_car_data(index: int = -1) -> Dictionary:
    if index < 0:
        index = selected_car
    return tuned_data(index)


func tuned_data(index: int) -> Dictionary:
    var d: Dictionary = CarData.CARS[index % CarData.CARS.size()].duplicate()
    var id: String = d["id"]
    var eng := SaveManager.get_upgrade(id, "engine")
    var tir := SaveManager.get_upgrade(id, "tires")
    var nit := SaveManager.get_upgrade(id, "nitro")
    var han := SaveManager.get_upgrade(id, "handling")
    d["accel"] = float(d["accel"]) * (1.0 + 0.05 * eng)
    d["max_speed"] = float(d["max_speed"]) * (1.0 + 0.025 * eng)
    d["grip"] = float(d["grip"]) * (1.0 + 0.04 * han)
    d["brake"] = float(d["brake"]) * (1.0 + 0.04 * tir)
    d["tire_mult"] = 1.0 + 0.04 * tir
    d["steer_rate"] = 1.0 + 0.08 * han
    d["nitro_drain"] = NitroSystem.DRAIN * (1.0 - 0.06 * nit)
    d["nitro_recharge"] = NitroSystem.RECHARGE * (1.0 + 0.25 * nit)
    var p := SaveManager.get_paint(id)
    if p >= 0 and p < CarData.PAINTS.size():
        d["color"] = CarData.PAINTS[p]["color"]
    var w := SaveManager.get_wheel(id)
    if w >= 0 and w < CarData.WHEELS.size():
        d["wheel_color"] = CarData.WHEELS[w]["color"]
    return d


func select_car(index: int) -> void:
    index = index % CarData.CARS.size()
    if SaveManager.is_owned(str(CarData.CARS[index]["id"])):
        selected_car = index
        SaveManager.select_car(str(CarData.CARS[index]["id"]))


## Index of the next car the player owns after the current one.
func next_owned_car() -> int:
    var n := CarData.CARS.size()
    for step in range(1, n + 1):
        var i := (selected_car + step) % n
        if SaveManager.is_owned(str(CarData.CARS[i]["id"])):
            return i
    return selected_car


func apply_quality(vp: Viewport, sun: DirectionalLight3D) -> void:
    match graphics_quality:
        0:
            vp.scaling_3d_scale = 0.7
            vp.msaa_3d = Viewport.MSAA_DISABLED
            sun.shadow_enabled = false
        1:
            vp.scaling_3d_scale = 1.0
            vp.msaa_3d = Viewport.MSAA_2X
            sun.shadow_enabled = true
            sun.directional_shadow_max_distance = 90.0
        _:
            vp.scaling_3d_scale = 1.0
            vp.msaa_3d = Viewport.MSAA_4X
            sun.shadow_enabled = true
            sun.directional_shadow_max_distance = 150.0
    if render_scale > 0.0:
        vp.scaling_3d_scale = render_scale   # user override (resolution scaling)
