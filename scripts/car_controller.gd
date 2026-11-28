class_name CarController
extends VehicleBody3D
## Arcade car on top of VehicleBody3D.
## Wheels, suspension and steering come from Godot's vehicle system.
## Acceleration, braking, drag and downforce are applied as plain forces
## (mass * acceleration) so the numbers in car_data.gd are real m/s^2 values.

signal crashed(intensity: float)

const WHEEL_RADIUS := 0.34
const REVERSE_MAX := 12.0
const GRIP_NORMAL := 4.0
const GRIP_HANDBRAKE := 1.5

var data: Dictionary = {}
var accel: float = 9.5
var max_speed: float = 60.0
var grip_accel: float = 24.0
var brake_decel: float = 22.0
var wheelbase: float = 2.8

var forward_speed: float = 0.0
var speed_kmh: float = 0.0
var grounded_wheels: int = 0
var handbrake_on: bool = false

# Set these to drive the car from code (AI) instead of player input.
var ai_controlled: bool = false
var ai_throttle: float = 0.0
var ai_brake: float = 0.0
var ai_steer: float = 0.0     # positive = left, like the steer_left action
var ai_nitro: bool = false
var locked: bool = false      # countdown / finished: car cannot drive

var nitro := NitroSystem.new()
var drift := DriftSystem.new()

var _wheels: Array[VehicleWheel3D] = []
var _wheel_visuals: Array[Node3D] = []
var _tail_mats: Array[StandardMaterial3D] = []
var _body_visual: Node3D
var tire_mult: float = 1.0
var steer_rate_mult: float = 1.0
var _rear_grip: float = GRIP_NORMAL
var _prev_speed: float = 0.0
var _smoke: Array[GPUParticles3D] = []
var _flames: Array[GPUParticles3D] = []
var _dust: Array[GPUParticles3D] = []


func setup(car_data: Dictionary) -> void:
    data = car_data
    mass = float(data["mass"])
    accel = float(data["accel"])
    max_speed = float(data["max_speed"])
    grip_accel = float(data["grip"])
    brake_decel = float(data["brake"])
    if GameManager.rain:
        grip_accel *= 0.88   # wet road
        brake_decel *= 0.88
    wheelbase = float(data["length"]) * 0.64
    tire_mult = float(data.get("tire_mult", 1.0))
    steer_rate_mult = float(data.get("steer_rate", 1.0))
    if GameManager.rain:
        tire_mult *= 0.92
    _rear_grip = GRIP_NORMAL * tire_mult
    nitro.drain = float(data.get("nitro_drain", NitroSystem.DRAIN))
    nitro.recharge = float(data.get("nitro_recharge", NitroSystem.RECHARGE))
    center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
    center_of_mass = Vector3(0.0, 0.1, 0.0)
    angular_damp = 1.0
    continuous_cd = true
    can_sleep = false
    _build_collision()
    _build_body()
    _build_wheels()
    _build_effects()
    _try_load_glb()


func reset_to(xform: Transform3D) -> void:
    var rid := get_rid()
    PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, xform)
    PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
    PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
    steering = 0.0


func is_upside_down() -> bool:
    return global_transform.basis.y.dot(Vector3.UP) < 0.2


# ---------------------------------------------------------------- driving

func _physics_process(delta: float) -> void:
    var fwd := -global_transform.basis.z
    var right := global_transform.basis.x
    forward_speed = linear_velocity.dot(fwd)
    var spd := linear_velocity.length()
    speed_kmh = spd * 3.6

    # A sudden speed drop in one physics tick means we hit something.
    if _prev_speed - spd > 4.0:
        crashed.emit(clampf((_prev_speed - spd) / 15.0, 0.25, 1.0))
        drift.cancel()
    _prev_speed = spd

    grounded_wheels = 0
    for w in _wheels:
        if w.is_in_contact():
            grounded_wheels += 1

    var throttle: float
    var brake_in: float
    var steer_in: float
    var nitro_in: bool
    if ai_controlled:
        throttle = ai_throttle
        brake_in = ai_brake
        steer_in = ai_steer
        nitro_in = ai_nitro
        handbrake_on = false
    else:
        throttle = Input.get_action_strength(&"accelerate")
        brake_in = Input.get_action_strength(&"brake")
        steer_in = clampf(Input.get_axis(&"steer_right", &"steer_left") + GameManager.tilt_steer(), -1.0, 1.0)
        nitro_in = Input.is_action_pressed(&"nitro")
        handbrake_on = Input.is_action_pressed(&"handbrake")
    if locked:
        throttle = 0.0
        brake_in = 0.0
        steer_in = 0.0
        nitro_in = false
        handbrake_on = false

    nitro.update(delta, nitro_in)
    drift.update(delta, linear_velocity, fwd, right, grounded_wheels >= 2)
    if drift.drifting:
        nitro.add(8.0 * delta)   # drifting refills nitro

    _update_grip(delta)
    angular_damp = 3.0 if drift.drifting else 1.0
    _update_steering(steer_in, delta)
    _apply_forces(throttle, brake_in, fwd)
    _update_lights(brake_in)
    _update_effects()


func _update_grip(delta: float) -> void:
    # Handbrake drops rear grip fast; releasing it brings grip back gradually.
    if handbrake_on:
        _rear_grip = move_toward(_rear_grip, GRIP_HANDBRAKE, delta * 40.0)
    else:
        _rear_grip = move_toward(_rear_grip, GRIP_NORMAL * tire_mult, delta * 3.0)
    for w in _wheels:
        if not w.use_as_steering:
            w.wheel_friction_slip = _rear_grip


func _update_steering(steer_in: float, delta: float) -> void:
    # Maximum steering angle is limited by how much lateral grip the car has:
    # lateral_accel = v^2 * angle / wheelbase  ->  angle = grip * wheelbase / v^2
    var speed := absf(forward_speed)
    var limit := clampf(grip_accel * wheelbase / maxf(speed * speed, 1.0), 0.025, 0.5)
    if handbrake_on or drift.drifting:
        limit = maxf(limit, 0.2)   # allow counter-steering in a slide
    var target := steer_in * limit
    var rate := (2.5 if absf(target) > absf(steering) else 4.0) * steer_rate_mult
    steering = move_toward(steering, target, rate * delta)


func _apply_forces(throttle: float, brake_in: float, fwd: Vector3) -> void:
    var vel := linear_velocity
    var speed := vel.length()
    var force := Vector3.ZERO

    force += -vel * speed * 0.35                       # air drag
    force += Vector3.DOWN * speed * speed * 0.6        # downforce
    if speed > 0.5:
        force += -vel.normalized() * mass * 0.12       # rolling resistance

    if locked:
        force += -vel * mass * 4.0    # roll to a stop / hold on the grid
        apply_central_force(force)
        return

    if grounded_wheels >= 2:
        var boost := nitro.boost
        var eff_accel := accel * (1.0 + 0.9 * boost)
        var eff_max := max_speed * (1.0 + 0.22 * boost)
        var drive := maxf(throttle, 1.0 if nitro.active else 0.0)
        var ratio := clampf(forward_speed / eff_max, 0.0, 1.0)
        var taper := 1.0 - ratio * ratio * ratio
        if brake_in > 0.1 and forward_speed > 1.0:
            force += -fwd * mass * brake_decel * brake_in
        elif brake_in > 0.1 and drive < 0.1:
            if forward_speed > -REVERSE_MAX:
                force += -fwd * mass * accel * 0.45 * brake_in
        elif drive > 0.1:
            if forward_speed < -1.0:
                force += fwd * mass * brake_decel * drive
            else:
                force += fwd * mass * eff_accel * drive * taper
        if handbrake_on and speed > 0.5:
            force += -vel.normalized() * mass * 5.0 * clampf(speed / 5.0, 0.0, 1.0)

    apply_central_force(force)


func _update_lights(brake_in: float) -> void:
    var e := 7.0 if brake_in > 0.1 else 1.5
    for m in _tail_mats:
        m.emission_energy_multiplier = e


func _update_effects() -> void:
    var smoking := (drift.drifting or (handbrake_on and speed_kmh > 35.0)) and grounded_wheels >= 2
    for s in _smoke:
        s.emitting = smoking
    for f in _flames:
        f.emitting = nitro.active
    var dusty := speed_kmh > 45.0 and grounded_wheels >= 2
    for d in _dust:
        d.emitting = dusty


func _build_effects() -> void:
    var w: float = float(data["width"])
    var l: float = float(data["length"])
    var half_track := w * 0.5 - 0.06
    for sx: float in [-half_track, half_track]:
        var sm := _make_smoke()
        sm.amount = [10, 18, 24][GameManager.graphics_quality]
        sm.position = Vector3(sx, 0.1, l * 0.32)
        add_child(sm)
        _smoke.append(sm)
    if str(TrackData.info(GameManager.track_index)["scenery"]) == "cactus":
        # desert: dust kicked up behind the rear wheels
        for sx: float in [-half_track, half_track]:
            var d := _make_smoke()
            d.amount = [8, 14, 20][GameManager.graphics_quality]
            var dm := d.process_material as ParticleProcessMaterial
            dm.initial_velocity_max = 2.5
            dm.color_ramp = _color_ramp(
                PackedFloat32Array([0.0, 0.2, 1.0]),
                PackedColorArray([Color(0.85, 0.70, 0.50, 0.0), Color(0.85, 0.70, 0.50, 0.35), Color(0.80, 0.65, 0.45, 0.0)]))
            d.position = Vector3(sx, 0.1, l * 0.4)
            add_child(d)
            _dust.append(d)
    for sx: float in [-0.28, 0.28]:
        var fl := _make_flame()
        fl.amount = [8, 12, 16][GameManager.graphics_quality]
        fl.position = Vector3(sx, 0.2, l * 0.5 + 0.15)
        add_child(fl)
        _flames.append(fl)


## Two spot lights on the front of the car (used at sunset, medium+ quality).
func build_headlights() -> void:
    var w: float = float(data["width"])
    var l: float = float(data["length"])
    for sx: float in [-1.0, 1.0]:
        var sp := SpotLight3D.new()
        sp.position = Vector3(sx * w * 0.32, 0.5, -l * 0.5 - 0.1)
        sp.rotation_degrees = Vector3(-4.0, 0.0, 0.0)   # slightly down, car faces -Z
        sp.light_color = Color(1.0, 0.95, 0.85)
        sp.light_energy = 5.0
        sp.spot_range = 55.0
        sp.spot_angle = 28.0
        sp.spot_attenuation = 0.8
        sp.shadow_enabled = false
        add_child(sp)


func _soft_dot() -> GradientTexture2D:
    var g := Gradient.new()
    g.offsets = PackedFloat32Array([0.0, 1.0])
    g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
    var t := GradientTexture2D.new()
    t.gradient = g
    t.fill = GradientTexture2D.FILL_RADIAL
    t.fill_from = Vector2(0.5, 0.5)
    t.fill_to = Vector2(1.0, 0.5)
    t.width = 64
    t.height = 64
    return t


func _color_ramp(offsets: PackedFloat32Array, colors: PackedColorArray) -> GradientTexture1D:
    var g := Gradient.new()
    g.offsets = offsets
    g.colors = colors
    var t := GradientTexture1D.new()
    t.gradient = g
    return t


func _scale_curve(a: float, b: float) -> CurveTexture:
    var c := Curve.new()
    c.add_point(Vector2(0.0, a))
    c.add_point(Vector2(1.0, b))
    var t := CurveTexture.new()
    t.curve = c
    return t


func _make_smoke() -> GPUParticles3D:
    var p := GPUParticles3D.new()
    p.amount = 24
    p.lifetime = 1.3
    p.emitting = false
    p.local_coords = false
    var pm := ParticleProcessMaterial.new()
    pm.direction = Vector3(0.0, 1.0, 0.0)
    pm.spread = 25.0
    pm.initial_velocity_min = 0.5
    pm.initial_velocity_max = 1.5
    pm.gravity = Vector3(0.0, 0.4, 0.0)
    pm.scale_min = 1.0
    pm.scale_max = 1.6
    pm.scale_curve = _scale_curve(0.4, 2.5)
    pm.color_ramp = _color_ramp(
        PackedFloat32Array([0.0, 0.2, 1.0]),
        PackedColorArray([Color(0.9, 0.9, 0.9, 0.0), Color(0.85, 0.85, 0.85, 0.55), Color(0.7, 0.7, 0.7, 0.0)]))
    p.process_material = pm
    var quad := QuadMesh.new()
    quad.size = Vector2(0.8, 0.8)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.vertex_color_use_as_albedo = true
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    mat.billboard_keep_scale = true
    mat.albedo_texture = _soft_dot()
    quad.material = mat
    p.draw_pass_1 = quad
    return p


func _make_flame() -> GPUParticles3D:
    var p := GPUParticles3D.new()
    p.amount = 16
    p.lifetime = 0.22
    p.emitting = false
    p.local_coords = true
    var pm := ParticleProcessMaterial.new()
    pm.direction = Vector3(0.0, 0.0, 1.0)   # backwards (car faces -Z)
    pm.spread = 6.0
    pm.initial_velocity_min = 7.0
    pm.initial_velocity_max = 10.0
    pm.gravity = Vector3.ZERO
    pm.scale_min = 0.8
    pm.scale_max = 1.2
    pm.scale_curve = _scale_curve(1.0, 0.1)
    pm.color_ramp = _color_ramp(
        PackedFloat32Array([0.0, 0.4, 1.0]),
        PackedColorArray([Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.5, 0.1, 0.8), Color(1.0, 0.2, 0.0, 0.0)]))
    p.process_material = pm
    var quad := QuadMesh.new()
    quad.size = Vector2(0.45, 0.45)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    mat.vertex_color_use_as_albedo = true
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    mat.billboard_keep_scale = true
    mat.albedo_texture = _soft_dot()
    quad.material = mat
    p.draw_pass_1 = quad
    return p


# ---------------------------------------------------------------- building

func _build_collision() -> void:
    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(float(data["width"]), 0.5, float(data["length"]) * 0.96)
    cs.shape = box
    cs.position = Vector3(0.0, 0.42, 0.0)
    add_child(cs)


func _paint_material(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = 0.75
    m.metallic_specular = 0.8
    m.roughness = 0.25
    m.clearcoat_enabled = true
    m.clearcoat = 0.8
    m.clearcoat_roughness = 0.05
    return m


func _metal_material(c: Color, metallic: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metallic
    m.roughness = rough
    return m


func _emissive_material(c: Color, energy: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = energy
    return m


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat
    mi.position = pos
    parent.add_child(mi)
    return mi


func _build_body() -> void:
    var w: float = float(data["width"])
    var l: float = float(data["length"])
    var paint := _paint_material(data["color"])
    var dark := _metal_material(Color(0.04, 0.04, 0.05), 0.5, 0.4)
    var chrome := _metal_material(Color(0.8, 0.8, 0.85), 1.0, 0.15)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.05, 0.08, 0.12, 0.75)
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.metallic = 0.9
    glass.roughness = 0.05
    var head := _emissive_material(Color(1.0, 0.95, 0.8), 3.0)
    var tail := _emissive_material(Color(1.0, 0.05, 0.03), 1.5)
    _tail_mats.append(tail)

    _body_visual = Node3D.new()
    add_child(_body_visual)

    var cab_len := _shape_f("cab_len", 0.40)
    var cab_h := _shape_f("cab_h", 0.40)
    var cab_z := _shape_f("cab_z", 0.06)
    var cab_w := _shape_f("cab_w", 0.82)
    var fend_f := _shape_f("fend_f", 0.20)
    var fend_r := _shape_f("fend_r", 0.20)
    var wing := int(_shape_f("wing", 2.0 if bool(data["spoiler"]) else 0.0))

    # main body, fenders, cabin
    _add_box(_body_visual, Vector3(w * 0.92, 0.36, l), Vector3(0, 0.32, 0), paint)
    _add_box(_body_visual, Vector3(w, fend_f, l * 0.26), Vector3(0, 0.4 + fend_f * 0.5, -l * 0.32), paint)
    _add_box(_body_visual, Vector3(w, fend_r, l * 0.26), Vector3(0, 0.4 + fend_r * 0.5, l * 0.32), paint)
    _add_box(_body_visual, Vector3(w * cab_w, cab_h, l * cab_len), Vector3(0, 0.5 + cab_h * 0.5, l * cab_z), glass)
    _add_box(_body_visual, Vector3(w * (cab_w - 0.04), 0.05, l * cab_len * 0.7), Vector3(0, 0.5 + cab_h + 0.025, l * (cab_z + 0.01)), paint)

    # splitter, diffuser, side skirts
    _add_box(_body_visual, Vector3(w, 0.07, 0.35), Vector3(0, 0.16, -l * 0.5 + 0.1), dark)
    _add_box(_body_visual, Vector3(w * 0.9, 0.07, 0.3), Vector3(0, 0.16, l * 0.5 - 0.1), dark)
    for sx: float in [-1.0, 1.0]:
        _add_box(_body_visual, Vector3(0.06, 0.1, l * 0.45), Vector3(sx * w * 0.46, 0.2, 0), dark)

    # lights
    for sx: float in [-1.0, 1.0]:
        _add_box(_body_visual, Vector3(0.38, 0.1, 0.08), Vector3(sx * w * 0.32, 0.4, -l * 0.5 + 0.02), head)
        _add_box(_body_visual, Vector3(0.5, 0.1, 0.06), Vector3(sx * w * 0.3, 0.42, l * 0.5), tail)
    _add_box(_body_visual, Vector3(w * 0.5, 0.05, 0.05), Vector3(0, 0.42, l * 0.5), tail)
    if _shape_f("lightbar", 0.0) > 0.5:
        _add_box(_body_visual, Vector3(w * 0.84, 0.04, 0.05), Vector3(0, 0.46, -l * 0.5 + 0.02), head)
        _add_box(_body_visual, Vector3(w * 0.84, 0.04, 0.05), Vector3(0, 0.5, l * 0.5), tail)

    # exhaust pipes (not on the electric car)
    if _shape_f("no_exhaust", 0.0) < 0.5:
        for sx: float in [-0.28, 0.28]:
            var mi := MeshInstance3D.new()
            var cm := CylinderMesh.new()
            cm.top_radius = 0.06
            cm.bottom_radius = 0.06
            cm.height = 0.25
            mi.mesh = cm
            mi.material_override = chrome
            mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
            mi.position = Vector3(sx, 0.2, l * 0.5 + 0.04)
            _body_visual.add_child(mi)

    # shape details
    if _shape_f("scoop", 0.0) > 0.5:
        _add_box(_body_visual, Vector3(w * 0.28, 0.08, l * 0.14), Vector3(0, 0.64, -l * 0.2), dark)
    if _shape_f("intakes", 0.0) > 0.5:
        for sx: float in [-1.0, 1.0]:
            _add_box(_body_visual, Vector3(0.06, 0.15, l * 0.15), Vector3(sx * w * 0.47, 0.4, l * 0.1), dark)
    if _shape_f("fins", 0.0) > 0.5:
        for sx: float in [-1.0, 1.0]:
            _add_box(_body_visual, Vector3(0.04, 0.26, l * 0.26), Vector3(sx * w * 0.2, 0.7, l * 0.3), paint)

    # rear wing: 1 = low lip, 2 = high wing on posts
    if wing == 1:
        _add_box(_body_visual, Vector3(w * 0.9, 0.04, 0.28), Vector3(0, 0.62, l * 0.5 - 0.1), paint)
    elif wing >= 2:
        for sx: float in [-1.0, 1.0]:
            _add_box(_body_visual, Vector3(0.06, 0.4, 0.1), Vector3(sx * w * 0.3, 0.72, l * 0.5 - 0.2), dark)
        _add_box(_body_visual, Vector3(w * 0.95, 0.05, 0.35), Vector3(0, 0.95, l * 0.5 - 0.2), paint)


func _shape_f(key: String, default_value: float) -> float:
    var sh: Dictionary = data.get("shape", {})
    var v: Variant = sh.get(key, default_value)
    if v is bool:
        return 1.0 if v else 0.0
    return float(v)


## Driver's eye position (car local space) for the cockpit camera.
func eye_offset() -> Vector3:
    return Vector3(0.0, 0.5 + _shape_f("cab_h", 0.40) * 0.72, float(data["length"]) * _shape_f("cab_z", 0.06))


func _build_wheels() -> void:
    var w: float = float(data["width"])
    var l: float = float(data["length"])
    var half_track := w * 0.5 - 0.06
    for zi in 2:
        for xi in 2:
            var wheel := VehicleWheel3D.new()
            var sx := -half_track if xi == 0 else half_track
            var sz := -l * 0.32 if zi == 0 else l * 0.32
            wheel.position = Vector3(sx, 0.45, sz)
            wheel.wheel_radius = WHEEL_RADIUS
            wheel.wheel_rest_length = 0.25
            wheel.suspension_travel = 0.3
            wheel.suspension_stiffness = 45.0
            wheel.suspension_max_force = mass * 12.0
            wheel.damping_compression = 0.45
            wheel.damping_relaxation = 0.7
            wheel.wheel_friction_slip = GRIP_NORMAL * tire_mult
            wheel.wheel_roll_influence = 0.1
            wheel.use_as_steering = (zi == 0)
            wheel.use_as_traction = (zi == 1)
            add_child(wheel)
            var visual := _make_wheel_visual()
            wheel.add_child(visual)
            _wheels.append(wheel)
            _wheel_visuals.append(visual)


func _make_wheel_visual() -> Node3D:
    # Cylinder axis is Y, so rotate 90 degrees around Z to lie along the axle (X).
    var root := Node3D.new()
    root.rotation = Vector3(0.0, 0.0, PI * 0.5)
    var tire_mat := _metal_material(Color(0.03, 0.03, 0.03), 0.0, 0.9)
    var disc_mat := _metal_material(Color(0.12, 0.12, 0.13), 0.6, 0.4)
    var spoke_mat := _metal_material(data.get("wheel_color", Color(0.85, 0.85, 0.9)), 1.0, 0.2)

    var tire := MeshInstance3D.new()
    var tm := CylinderMesh.new()
    tm.top_radius = WHEEL_RADIUS
    tm.bottom_radius = WHEEL_RADIUS
    tm.height = 0.28
    tm.radial_segments = 24
    tm.rings = 1
    tire.mesh = tm
    tire.material_override = tire_mat
    root.add_child(tire)

    var disc := MeshInstance3D.new()
    var dm := CylinderMesh.new()
    dm.top_radius = 0.23
    dm.bottom_radius = 0.23
    dm.height = 0.29
    dm.radial_segments = 16
    dm.rings = 1
    disc.mesh = dm
    disc.material_override = disc_mat
    root.add_child(disc)

    _add_box(root, Vector3(0.44, 0.31, 0.05), Vector3.ZERO, spoke_mat)
    _add_box(root, Vector3(0.05, 0.31, 0.44), Vector3.ZERO, spoke_mat)
    return root


## Model file for this car: the "glb" path from car_data.gd, else
## assets/cars/<id>/scene.gltf (a zipped Sketchfab download), scene.glb or <id>.gltf.
func _find_model_path() -> String:
    var cands: Array[String] = []
    var p := str(data.get("glb", ""))
    if p != "":
        cands.append(p)
    var id := str(data["id"])
    for c: String in ["res://assets/cars/%s/scene.gltf", "res://assets/cars/%s/scene.glb", "res://assets/cars/%s.gltf"]:
        cands.append(c % id)
    for c: String in cands:
        if ResourceLoader.exists(c):
            return c
    return ""


func _try_load_glb() -> void:
    var path := _find_model_path()
    if path == "":
        return
    var res: Variant = load(path)
    if not (res is PackedScene):
        return
    var inst := (res as PackedScene).instantiate() as Node3D
    if inst == null:
        return
    if bool(data.get("glb_autofit", true)):
        _fit_glb(inst)
    else:
        inst.scale = Vector3.ONE * float(data.get("glb_scale", 1.0))
        inst.rotation.y = deg_to_rad(float(data.get("glb_rotation_y", 0.0)))
        inst.position = data.get("glb_offset", Vector3.ZERO)
    add_child(inst)
    _body_visual.queue_free()
    _tail_mats.clear()
    var hw: Variant = data.get("glb_has_wheels", "auto")
    var has_wheels := _model_has_wheels(inst) if str(hw) == "auto" else bool(hw)
    if has_wheels:
        for v in _wheel_visuals:
            v.queue_free()
    print("car %s model %s wheels_in_model=%s" % [str(data["id"]), path, str(has_wheels)])


## True when the imported model contains separate wheel parts (by node name).
func _model_has_wheels(n: Node) -> bool:
    var cnt := _count_wheel_nodes(n)
    return cnt >= 4


func _count_wheel_nodes(n: Node) -> int:
    var c := 0
    var nm := n.name.to_lower()
    if nm.contains("wheel") or nm.contains("tire") or nm.contains("tyre"):
        c += 1
    for ch in n.get_children():
        c += _count_wheel_nodes(ch)
    return c


## Scales the model to the car's length, turns its long side along the driving
## direction (front = -Z, glTF models usually face +Z so it is turned 180
## degrees; use "glb_rotation_y": 180 in car_data.gd if one comes out
## backwards), centres it and puts its lowest point on the ground.
func _fit_glb(inst: Node3D) -> void:
    var box := _glb_bounds(inst, Transform3D.IDENTITY)
    if box.size.length() < 0.01:
        return
    var yaw := 0.0
    if box.size.x > box.size.z:
        yaw = PI * 0.5
    yaw += PI + deg_to_rad(float(data.get("glb_rotation_y", 0.0)))
    var long_len := maxf(box.size.x, box.size.z)
    var k := float(data["length"]) / long_len * float(data.get("glb_scale", 1.0))
    var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * k)
    var center := box.get_center()
    var bottom := Vector3(center.x, box.position.y, center.z)
    var offset: Vector3 = data.get("glb_offset", Vector3.ZERO)
    inst.transform = Transform3D(b, -(b * bottom) + offset)


func _glb_bounds(n: Node, xf: Transform3D) -> AABB:
    var out := AABB()
    var have := false
    if n is MeshInstance3D:
        var mi := n as MeshInstance3D
        if mi.mesh != null:
            out = xf * mi.get_aabb()
            have = true
    for c in n.get_children():
        if c is Node3D:
            var sub := _glb_bounds(c, xf * (c as Node3D).transform)
            if sub.size.length() > 0.0:
                out = sub if not have else out.merge(sub)
                have = true
    return out
