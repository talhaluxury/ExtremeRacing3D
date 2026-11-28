class_name Showroom
extends Node3D
## Small 3D stage: dark floor, glowing ring, lights and a slowly turning car.
## Used behind the main menu (inside a SubViewport).

var _car: CarController
var _cam: Camera3D
var _yaw: float = 0.5
var _ring_mat: StandardMaterial3D


func _ready() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.02, 0.025, 0.05)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.35, 0.4, 0.55)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    var floor_mi := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 4.2
    cyl.bottom_radius = 4.2
    cyl.height = 0.1
    cyl.radial_segments = 48
    floor_mi.mesh = cyl
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color(0.04, 0.05, 0.08)
    fm.metallic = 0.85
    fm.roughness = 0.3
    floor_mi.material_override = fm
    floor_mi.position = Vector3(0, -0.05, 0)
    add_child(floor_mi)

    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 4.1
    tm.outer_radius = 4.25
    ring.mesh = tm
    _ring_mat = StandardMaterial3D.new()
    _ring_mat.albedo_color = Color(0.1, 0.75, 1.0)
    _ring_mat.emission_enabled = true
    _ring_mat.emission = Color(0.1, 0.7, 1.0)
    _ring_mat.emission_energy_multiplier = 2.0
    ring.material_override = _ring_mat
    add_child(ring)

    var key := SpotLight3D.new()
    key.look_at_from_position(Vector3(3.5, 6.0, 4.5), Vector3(0, 0.5, 0), Vector3.UP)
    key.light_energy = 7.0
    key.spot_range = 20.0
    key.spot_angle = 42.0
    key.shadow_enabled = GameManager.graphics_quality > 0
    add_child(key)
    var blue := OmniLight3D.new()
    blue.position = Vector3(-4.5, 2.0, -3.5)
    blue.light_color = Color(0.35, 0.55, 1.0)
    blue.light_energy = 4.0
    blue.omni_range = 14.0
    add_child(blue)
    var warm := OmniLight3D.new()
    warm.position = Vector3(4.5, 1.8, -4.0)
    warm.light_color = Color(1.0, 0.6, 0.3)
    warm.light_energy = 3.0
    warm.omni_range = 14.0
    add_child(warm)

    _cam = Camera3D.new()
    _cam.fov = 38.0
    add_child(_cam)
    _cam.look_at_from_position(Vector3(5.2, 1.7, 6.6), Vector3(0, 0.55, 0), Vector3.UP)
    show_car(GameManager.selected_car)


func show_car(index: int) -> void:
    if _car != null:
        _car.queue_free()
    _car = CarController.new()
    _car.setup(GameManager.tuned_data(index))
    _car.freeze = true
    _car.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    _car.gravity_scale = 0.0
    _car.locked = true
    add_child(_car)
    _car.position = Vector3(0, 0.05, 0)
    _car.rotation.y = _yaw


func _process(delta: float) -> void:
    _yaw += delta * 0.4
    if _car != null:
        _car.rotation.y = _yaw
