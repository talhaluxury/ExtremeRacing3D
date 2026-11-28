class_name RaceEnvironment
extends Node3D
## Sky, sun, fog, glow and clouds for a race. One preset per time of day.
## Built from code, no asset files. Quality (GameManager.graphics_quality)
## decides which post effects and how many clouds are used.

const PRESETS := [
    {   # 0: bright day
        "name": "DAY",
        "dusk": false,
        "sky_top": Color(0.20, 0.42, 0.78),
        "sky_horizon": Color(0.68, 0.78, 0.90),
        "ground": Color(0.30, 0.35, 0.30),
        "fog": Color(0.68, 0.78, 0.90),
        "fog_density": 0.0009,
        "sun_rot": Vector3(-50.0, -35.0, 0.0),
        "sun_color": Color(1.0, 0.97, 0.9),
        "sun_energy": 1.2,
        "exposure": 1.0,
        "cloud": Color(1.0, 1.0, 1.0),
    },
    {   # 1: low golden sun
        "name": "SUNSET",
        "dusk": true,
        "sky_top": Color(0.16, 0.20, 0.45),
        "sky_horizon": Color(1.0, 0.55, 0.28),
        "ground": Color(0.25, 0.18, 0.15),
        "fog": Color(0.95, 0.60, 0.42),
        "fog_density": 0.0014,
        "sun_rot": Vector3(-11.0, -35.0, 0.0),
        "sun_color": Color(1.0, 0.62, 0.34),
        "sun_energy": 1.5,
        "exposure": 1.05,
        "cloud": Color(1.0, 0.62, 0.45),
    },
    {   # 2: bright coastal noon
        "name": "NOON",
        "dusk": false,
        "sky_top": Color(0.10, 0.50, 0.92),
        "sky_horizon": Color(0.75, 0.88, 0.98),
        "ground": Color(0.35, 0.45, 0.55),
        "fog": Color(0.75, 0.88, 0.98),
        "fog_density": 0.0006,
        "sun_rot": Vector3(-62.0, -20.0, 0.0),
        "sun_color": Color(1.0, 0.98, 0.92),
        "sun_energy": 1.4,
        "exposure": 1.0,
        "cloud": Color(1.0, 1.0, 1.0),
    },
    {   # 3: dusty desert haze
        "name": "HAZE",
        "dusk": false,
        "sky_top": Color(0.35, 0.55, 0.80),
        "sky_horizon": Color(0.95, 0.85, 0.70),
        "ground": Color(0.55, 0.42, 0.30),
        "fog": Color(0.92, 0.82, 0.65),
        "fog_density": 0.0012,
        "sun_rot": Vector3(-55.0, 40.0, 0.0),
        "sun_color": Color(1.0, 0.92, 0.78),
        "sun_energy": 1.4,
        "exposure": 1.05,
        "cloud": Color(1.0, 0.95, 0.85),
    },
    {   # 4: night (lamps glow, player gets headlights)
        "name": "NIGHT",
        "dusk": true,
        "sky_top": Color(0.01, 0.02, 0.07),
        "sky_horizon": Color(0.08, 0.08, 0.20),
        "ground": Color(0.02, 0.02, 0.04),
        "fog": Color(0.05, 0.05, 0.12),
        "fog_density": 0.0016,
        "sun_rot": Vector3(-35.0, -35.0, 0.0),
        "sun_color": Color(0.5, 0.6, 1.0),
        "sun_energy": 0.25,
        "exposure": 1.2,
        "cloud": Color(0.08, 0.08, 0.16),
        "ambient_color": Color(0.20, 0.22, 0.38),
    },
]

const CLOUD_CLUSTERS := [6, 10, 14]

var sun: DirectionalLight3D
var dusk: bool = false
var _clouds: MultiMeshInstance3D


static func preset_for_track(track_index: int) -> int:
    return clampi(int(TrackData.info(track_index)["preset"]), 0, PRESETS.size() - 1)


func build(preset_index: int) -> void:
    var p: Dictionary = PRESETS[clampi(preset_index, 0, PRESETS.size() - 1)].duplicate()
    if GameManager.rain:
        _make_rainy(p)
    var q := GameManager.graphics_quality
    dusk = bool(p["dusk"])

    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = p["sky_top"]
    sky_mat.sky_horizon_color = p["sky_horizon"]
    sky_mat.ground_horizon_color = p["sky_horizon"]
    sky_mat.ground_bottom_color = p["ground"]
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    if p.has("ambient_color"):
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = p["ambient_color"]
        env.ambient_light_energy = 1.0
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = float(p["exposure"])
    env.fog_enabled = true
    env.fog_light_color = p["fog"]
    env.fog_density = float(p["fog_density"])
    env.fog_sky_affect = 0.3
    if q >= 1:
        # Glow makes the emissive lamps, nitro flames and the low sun bloom.
        # Colour adjustment is one cheap extra pass. SSAO is not available
        # in the Mobile renderer, so it is not used.
        env.glow_enabled = true
        env.glow_intensity = 0.7 if dusk else 0.4
        env.glow_bloom = 0.04
        env.glow_hdr_threshold = 1.0
        env.adjustment_enabled = true
        env.adjustment_saturation = 1.12
        env.adjustment_contrast = 1.05
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    sun = DirectionalLight3D.new()
    sun.rotation_degrees = p["sun_rot"]
    sun.light_color = p["sun_color"]
    sun.light_energy = float(p["sun_energy"])
    sun.shadow_enabled = true
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    add_child(sun)

    _build_clouds(p["cloud"], CLOUD_CLUSTERS[q])


## Greyer sky and fog, weaker sun.
func _make_rainy(p: Dictionary) -> void:
    for key: String in ["sky_top", "sky_horizon", "fog", "cloud"]:
        var c: Color = p[key]
        var l := c.get_luminance()
        p[key] = c.lerp(Color(l, l, l) * 0.9, 0.65)
    p["fog_density"] = float(p["fog_density"]) * 2.0 + 0.0008
    p["sun_energy"] = float(p["sun_energy"]) * 0.5


func _process(delta: float) -> void:
    if _clouds != null:
        _clouds.rotation.y += delta * 0.003   # slow drift


func _build_clouds(color: Color, clusters: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 777
    var xforms: Array[Transform3D] = []
    for c in clusters:
        var ang := rng.randf() * TAU
        var dist := rng.randf_range(500.0, 1900.0)
        var height := rng.randf_range(260.0, 420.0)
        var center := Vector3(cos(ang) * dist, height, sin(ang) * dist)
        for b in 3:
            var s := rng.randf_range(70.0, 140.0)
            var basis := Basis.from_scale(Vector3(s * rng.randf_range(1.2, 1.8), s * 0.22, s))
            basis = Basis(Vector3.UP, rng.randf() * TAU) * basis
            var off := Vector3(rng.randf_range(-90.0, 90.0), rng.randf_range(-12.0, 12.0), rng.randf_range(-90.0, 90.0))
            xforms.append(Transform3D(basis, center + off))

    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 8
    sphere.rings = 4

    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = sphere
    mm.instance_count = xforms.size()
    for i in xforms.size():
        mm.set_instance_transform(i, xforms[i])

    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color
    mat.disable_fog = true

    _clouds = MultiMeshInstance3D.new()
    _clouds.multimesh = mm
    _clouds.material_override = mat
    _clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_clouds)
