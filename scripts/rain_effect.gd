class_name RainEffect
extends GPUParticles3D
## Rain streaks that follow the camera. Particles stay in world space, so
## they fall past a moving car. Amount depends on graphics quality.

const AMOUNTS := [350, 800, 1400]

var target: Camera3D

var _snd: AudioStreamPlayer


func _ready() -> void:
    top_level = true
    amount = AMOUNTS[GameManager.graphics_quality]
    lifetime = 0.9
    preprocess = 1.0
    local_coords = false
    visibility_aabb = AABB(Vector3(-45, -30, -45), Vector3(90, 40, 90))
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    pm.emission_box_extents = Vector3(32.0, 1.0, 32.0)
    pm.direction = Vector3(0.05, -1.0, 0.0)
    pm.spread = 2.0
    pm.initial_velocity_min = 26.0
    pm.initial_velocity_max = 32.0
    pm.gravity = Vector3(0.0, -6.0, 0.0)
    process_material = pm

    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.015, 0.7, 0.015)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.8, 0.85, 0.95, 0.35)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mat
    draw_pass_1 = mesh
    emitting = true
    _snd = AudioStreamPlayer.new()
    _snd.bus = &"SFX"
    _snd.volume_db = -14.0
    add_child(_snd)


func _process(_delta: float) -> void:
    if _snd.stream == null:
        _snd.stream = AudioManager.get_stream("rain")   # generated in the background at start-up
    if _snd.stream != null and not _snd.playing:
        _snd.play()
    if target != null and is_instance_valid(target):
        global_position = target.global_position + Vector3(0.0, 17.0, 0.0)
