class_name TrackBuilder
extends Node3D
## Builds a closed-loop racing track from code: road mesh with collision,
## barrier walls, ground, trees, distant mountains and a start line.

const SAMPLES := 480
const ROAD_WIDTH := 18.0
const WALL_HEIGHT := 1.2
const WALL_THICKNESS := 0.6
const TUNNEL_HEIGHT := 7.0
const CHUNKS := 12                       # scenery is split into chunks so far ones are culled
const TREE_COUNTS := [180, 320, 450]     # by graphics quality (low, medium, high)
const ROCK_COUNTS := [40, 90, 140]
const BUSH_COUNTS := [60, 160, 260]
const LAMP_STEP := [24, 16, 12]          # road samples between lamp posts
const SCENERY_VIEW := 900.0              # metres
const LAMP_VIEW := 450.0
const PALM_COUNTS := [70, 140, 200]
const CACTUS_COUNTS := [60, 120, 180]
const DUNE_COUNTS := [14, 24, 36]
const BUILDING_COUNTS := [60, 110, 170]

var points := PackedVector3Array()
var tangents := PackedVector3Array()
var count: int = SAMPLES
var layout: int = 0   # index into TrackData.TRACKS (0 Grand Loop ... 4 Night City)
var theme: Dictionary = {}
var dusk: bool = false   # lamps glow brighter at sunset

var _rng := RandomNumberGenerator.new()


func build() -> void:
    _rng.seed = 12345 + layout
    theme = TrackData.info(layout)
    _make_centerline()
    _build_road()
    _build_walls()
    _build_tunnels()
    _build_ground()
    match str(theme["scenery"]):
        "palm":
            _build_palms()
        "cactus":
            _build_cacti()
            _build_dunes()
        "city":
            _build_city()
        _:
            _build_trees()
    _build_props()
    _build_mountains()
    _build_start_line()


func spawn_transform(index: int) -> Transform3D:
    var i := posmod(index, SAMPLES)
    return Transform3D(Basis.looking_at(tangents[i], Vector3.UP), points[i] + Vector3.UP * 0.6)


func grid_transform(index: int, lateral: float = 0.0) -> Transform3D:
    var i := posmod(index, SAMPLES)
    var pos := points[i] + _right(i) * lateral + Vector3.UP * 0.6
    return Transform3D(Basis.looking_at(tangents[i], Vector3.UP), pos)


func nearest_index(pos: Vector3, hint: int, window: int = 40) -> int:
    var best := hint
    var best_d := INF
    for k in range(-window, window + 1):
        var i := posmod(hint + k, SAMPLES)
        var d := pos.distance_squared_to(points[i])
        if d < best_d:
            best_d = d
            best = i
    return best


# ---------------------------------------------------------------- centerline

func _make_centerline() -> void:
    points.resize(SAMPLES)
    tangents.resize(SAMPLES)
    for i in SAMPLES:
        var a := float(i) / float(SAMPLES) * TAU
        var r := 250.0 + 50.0 * sin(2.0 * a) + 25.0 * sin(3.0 * a + 1.0)
        match layout:
            1:
                r = 260.0 + 45.0 * sin(3.0 * a) + 15.0 * sin(5.0 * a + 0.5)
            2:   # coastal: one long gentle bulge
                r = 280.0 + 50.0 * sin(a + 0.4) + 28.0 * sin(3.0 * a)
            3:   # desert: fast sweepers
                r = 270.0 + 50.0 * sin(2.0 * a + 0.3) + 32.0 * sin(4.0 * a)
            4:   # night city
                r = 255.0 + 55.0 * sin(2.0 * a + 1.2) + 22.0 * sin(4.0 * a)
        points[i] = Vector3(cos(a) * r, 0.0, sin(a) * r)
    for i in SAMPLES:
        var nxt := points[(i + 1) % SAMPLES]
        var prv := points[(i - 1 + SAMPLES) % SAMPLES]
        tangents[i] = (nxt - prv).normalized()


func _right(i: int) -> Vector3:
    return tangents[i].cross(Vector3.UP).normalized()


# ---------------------------------------------------------------- road

func _road_vertex(st: SurfaceTool, p: Vector3, uv: Vector2) -> void:
    st.set_normal(Vector3.UP)
    st.set_uv(uv)
    st.add_vertex(p)


func _build_road() -> void:
    var dists := PackedFloat32Array()
    dists.resize(SAMPLES + 1)
    var total := 0.0
    for i in SAMPLES:
        dists[i] = total
        total += points[i].distance_to(points[(i + 1) % SAMPLES])
    dists[SAMPLES] = total

    var half := ROAD_WIDTH * 0.5
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in SAMPLES:
        var j := (i + 1) % SAMPLES
        var li := points[i] - _right(i) * half
        var ri := points[i] + _right(i) * half
        var lj := points[j] - _right(j) * half
        var rj := points[j] + _right(j) * half
        var vi := dists[i] / ROAD_WIDTH
        var vj := dists[i + 1] / ROAD_WIDTH
        _road_vertex(st, li, Vector2(0.0, vi))
        _road_vertex(st, lj, Vector2(0.0, vj))
        _road_vertex(st, ri, Vector2(1.0, vi))
        _road_vertex(st, ri, Vector2(1.0, vi))
        _road_vertex(st, lj, Vector2(0.0, vj))
        _road_vertex(st, rj, Vector2(1.0, vj))
    var mesh := st.commit()

    var mat := StandardMaterial3D.new()
    mat.albedo_texture = _make_road_texture()
    mat.roughness = 0.85
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)
    _add_trimesh_body(mesh)


func _add_trimesh_body(mesh: Mesh) -> void:
    var body := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    var shape := mesh.create_trimesh_shape()
    shape.backface_collision = true
    cs.shape = shape
    body.add_child(cs)
    add_child(body)


func _make_road_texture() -> ImageTexture:
    var w := 256
    var h := 128
    var img := Image.create(w, h, false, Image.FORMAT_RGB8)
    for y in h:
        var v := float(y) / float(h)
        for x in w:
            var u := float(x) / float(w)
            var c := 0.16 + _rng.randf() * 0.04
            var col := Color(c, c, c * 1.05)
            if (u > 0.03 and u < 0.05) or (u > 0.95 and u < 0.97):
                col = Color(0.92, 0.92, 0.92)
            elif (u > 0.485 and u < 0.495) or (u > 0.505 and u < 0.515):
                col = Color(0.95, 0.75, 0.1)
            elif (absf(u - 0.25) < 0.005 or absf(u - 0.75) < 0.005) and v < 0.5:
                col = Color(0.9, 0.9, 0.9)
            img.set_pixel(x, y, col)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- walls

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
    var n := (b - a).cross(c - a).normalized()
    for p: Vector3 in [a, b, c, a, c, d]:
        st.set_color(col)
        st.set_normal(n)
        st.add_vertex(p)


func _build_walls() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var inner := ROAD_WIDTH * 0.5 + 0.3
    var outer := inner + WALL_THICKNESS
    var up := Vector3.UP * WALL_HEIGHT
    for side: float in [-1.0, 1.0]:
        for i in SAMPLES:
            var j := (i + 1) % SAMPLES
            var ri := _right(i) * side
            var rj := _right(j) * side
            var col := Color(0.85, 0.1, 0.1) if i % 12 < 6 else Color(0.92, 0.92, 0.92)
            var a_in := points[i] + ri * inner
            var a_out := points[i] + ri * outer
            var b_in := points[j] + rj * inner
            var b_out := points[j] + rj * outer
            _quad(st, a_in, a_in + up, b_in + up, b_in, col)
            _quad(st, a_in + up, a_out + up, b_out + up, b_in + up, col)
            _quad(st, a_out, a_out + up, b_out + up, b_out, col)
    var mesh := st.commit()

    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.6
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    add_child(mi)
    _add_trimesh_body(mesh)


# ---------------------------------------------------------------- scenery

func _make_grass_texture() -> ImageTexture:
    var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
    for y in 64:
        for x in 64:
            var n := _rng.randf()
            var b: Color = theme["ground_base"]
            var v: Color = theme["ground_var"]
            img.set_pixel(x, y, Color(b.r + n * v.r, b.g + n * v.g, b.b + n * v.b))
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)


func _build_ground() -> void:
    var pm := PlaneMesh.new()
    var ground_size := 8000.0
    if bool(theme["ocean"]):
        # Sand island with ocean around it. The invisible collision floor
        # below still covers everything, so the car never falls through.
        ground_size = 1100.0
        var sea := PlaneMesh.new()
        sea.size = Vector2(8000.0, 8000.0)
        var sea_mat := StandardMaterial3D.new()
        sea_mat.albedo_color = Color(0.04, 0.34, 0.55)
        sea_mat.metallic = 0.3
        sea_mat.roughness = 0.15
        var sea_mi := MeshInstance3D.new()
        sea_mi.mesh = sea
        sea_mi.material_override = sea_mat
        sea_mi.position = Vector3(0.0, -0.7, 0.0)
        sea_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(sea_mi)
    pm.size = Vector2(ground_size, ground_size)
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = _make_grass_texture()
    var uv := ground_size * 0.15
    mat.uv1_scale = Vector3(uv, uv, 1.0)
    mat.roughness = 1.0
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    var mi := MeshInstance3D.new()
    mi.mesh = pm
    mi.material_override = mat
    mi.position = Vector3(0.0, -0.05, 0.0)
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)

    var body := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(8000.0, 2.0, 8000.0)
    cs.shape = box
    body.add_child(cs)
    body.position = Vector3(0.0, -1.05, 0.0)
    add_child(body)


func _build_trees() -> void:
    var q := GameManager.graphics_quality
    var trunks: Array = []
    var tops: Array = []
    for n in int(TREE_COUNTS[q]):
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var offset := _rng.randf_range(ROAD_WIDTH * 0.5 + 6.0, ROAD_WIDTH * 0.5 + 90.0)
        var pos := points[i] + _right(i) * side * offset
        var s := _rng.randf_range(0.8, 1.8)
        var basis := Basis.from_scale(Vector3(s, s, s))
        trunks.append([Transform3D(basis, pos + Vector3.UP * (1.0 * s)), i])
        tops.append([Transform3D(basis, pos + Vector3.UP * (4.5 * s)), i])

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = 2.0
    trunk_mesh.radial_segments = 6
    trunk_mesh.rings = 1
    _add_chunked(trunk_mesh, _flat_material(Color(0.3, 0.2, 0.1)), trunks, SCENERY_VIEW)

    var top_mesh := CylinderMesh.new()
    top_mesh.top_radius = 0.0
    top_mesh.bottom_radius = 1.8
    top_mesh.height = 5.0
    top_mesh.radial_segments = 8
    top_mesh.rings = 1
    var leaf := Color(0.08, 0.3, 0.1)
    if dusk:
        leaf = Color(0.1, 0.24, 0.1)
    _add_chunked(top_mesh, _flat_material(leaf), tops, SCENERY_VIEW)


## Rocks, bushes and street lamps along the road.
func _build_props() -> void:
    var q := GameManager.graphics_quality
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 8
    sphere.rings = 4

    var rocks: Array = []
    for n in int(ROCK_COUNTS[q]):
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var offset := _rng.randf_range(ROAD_WIDTH * 0.5 + 8.0, ROAD_WIDTH * 0.5 + 70.0)
        var sc := Vector3(_rng.randf_range(0.8, 3.0), _rng.randf_range(0.5, 1.8), _rng.randf_range(0.8, 3.0))
        var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis.from_scale(sc)
        var pos := points[i] + _right(i) * side * offset + Vector3.UP * (sc.y * 0.35)
        rocks.append([Transform3D(basis, pos), i])
    var rock_col := Color(0.36, 0.34, 0.31)
    if str(theme["scenery"]) == "cactus":
        rock_col = Color(0.55, 0.36, 0.24)
    elif str(theme["scenery"]) == "palm":
        rock_col = Color(0.50, 0.46, 0.40)
    if str(theme["scenery"]) != "city":
        _add_chunked(sphere, _flat_material(rock_col), rocks, SCENERY_VIEW)

    var bushes: Array = []
    for n in int(BUSH_COUNTS[q]):
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var offset := _rng.randf_range(ROAD_WIDTH * 0.5 + 5.0, ROAD_WIDTH * 0.5 + 45.0)
        var r := _rng.randf_range(0.8, 1.6)
        var basis := Basis.from_scale(Vector3(r, r * 0.6, r))
        var pos := points[i] + _right(i) * side * offset + Vector3.UP * (r * 0.3)
        bushes.append([Transform3D(basis, pos), i])
    var bush_col := Color(0.12, 0.30, 0.10)
    if str(theme["scenery"]) == "cactus":
        bush_col = Color(0.42, 0.38, 0.18)
    elif str(theme["scenery"]) == "palm":
        bush_col = Color(0.18, 0.40, 0.16)
    if str(theme["scenery"]) != "city":
        _add_chunked(sphere, _flat_material(bush_col), bushes, SCENERY_VIEW)

    # street lamps: pole + arm over the road + glowing head (emissive, no real light)
    var poles: Array = []
    var arms: Array = []
    var heads: Array = []
    var lamp_offset := ROAD_WIDTH * 0.5 + 0.3 + WALL_THICKNESS + 1.2
    for i in range(0, SAMPLES, int(LAMP_STEP[q])):
        if _in_tunnel(i):
            continue
        for side: float in [-1.0, 1.0]:
            var base := points[i] + _right(i) * side * lamp_offset
            var look := Basis.looking_at(tangents[i], Vector3.UP)   # local X = road right
            var toward_road := -_right(i) * side
            poles.append([Transform3D(Basis.IDENTITY, base + Vector3.UP * 4.0), i])
            arms.append([Transform3D(look, base + toward_road * 0.8 + Vector3.UP * 8.0), i])
            heads.append([Transform3D(look, base + toward_road * 1.7 + Vector3.UP * 7.9), i])

    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.1
    pole_mesh.bottom_radius = 0.14
    pole_mesh.height = 8.0
    pole_mesh.radial_segments = 6
    pole_mesh.rings = 1
    var arm_mesh := BoxMesh.new()
    arm_mesh.size = Vector3(1.8, 0.1, 0.1)
    var head_mesh := BoxMesh.new()
    head_mesh.size = Vector3(0.9, 0.12, 0.5)
    var metal := _flat_material(Color(0.22, 0.23, 0.25))
    var lamp := StandardMaterial3D.new()
    lamp.albedo_color = Color(1.0, 0.92, 0.7)
    lamp.emission_enabled = true
    lamp.emission = Color(1.0, 0.85, 0.55)
    lamp.emission_energy_multiplier = 4.0 if dusk else 0.4
    _add_chunked(pole_mesh, metal, poles, LAMP_VIEW)
    _add_chunked(arm_mesh, metal, arms, LAMP_VIEW)
    _add_chunked(head_mesh, lamp, heads, LAMP_VIEW)


func _in_tunnel(i: int) -> bool:
    for t: Array in theme["tunnels"]:
        if i >= int(t[0]) - 2 and i <= int(t[1]) + 2:
            return true
    return false


## Concrete tunnel (side walls + ceiling with collision) and ceiling lights.
func _build_tunnels() -> void:
    var tunnels: Array = theme["tunnels"]
    if tunnels.is_empty():
        return
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var lat := ROAD_WIDTH * 0.5 + 0.3 + WALL_THICKNESS + 0.05
    var up := Vector3.UP * TUNNEL_HEIGHT
    var lights: Array = []
    for t: Array in tunnels:
        for i in range(int(t[0]), int(t[1])):
            var j := (i + 1) % SAMPLES
            var ri := _right(i)
            var rj := _right(j)
            var col := Color(0.42, 0.42, 0.44)
            var al := points[i] - ri * lat
            var ar := points[i] + ri * lat
            var bl := points[j] - rj * lat
            var br := points[j] + rj * lat
            _quad(st, al, al + up, bl + up, bl, col)       # left wall
            _quad(st, ar, ar + up, br + up, br, col)       # right wall
            _quad(st, al + up, ar + up, br + up, bl + up, Color(0.3, 0.3, 0.32))   # ceiling
            if i % 3 == 0:
                var look := Basis.looking_at(tangents[i], Vector3.UP)
                for sx: float in [-3.2, 3.2]:
                    lights.append([Transform3D(look, points[i] + ri * sx + Vector3.UP * (TUNNEL_HEIGHT - 0.1)), i])
    var mesh := st.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.9
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    add_child(mi)
    _add_trimesh_body(mesh)

    var strip := BoxMesh.new()
    strip.size = Vector3(0.4, 0.08, 2.6)
    var lamp := StandardMaterial3D.new()
    lamp.albedo_color = Color(1.0, 0.95, 0.8)
    lamp.emission_enabled = true
    lamp.emission = Color(1.0, 0.9, 0.7)
    lamp.emission_energy_multiplier = 3.5
    _add_chunked(strip, lamp, lights, LAMP_VIEW)


## Distance on the ground plane from a point to the nearest road centre sample.
func _min_road_dist(pos: Vector3) -> float:
    var best := INF
    for i in range(0, SAMPLES, 2):
        best = minf(best, Vector2(pos.x - points[i].x, pos.z - points[i].z).length_squared())
    return sqrt(best)


func _build_palms() -> void:
    var q := GameManager.graphics_quality
    var trunks: Array = []
    var crowns: Array = []
    for n in int(PALM_COUNTS[q]):
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var offset := _rng.randf_range(ROAD_WIDTH * 0.5 + 5.0, ROAD_WIDTH * 0.5 + 60.0)
        var pos := points[i] + _right(i) * side * offset
        var s := _rng.randf_range(0.9, 1.5)
        var yaw := _rng.randf() * TAU
        trunks.append([Transform3D(Basis.from_scale(Vector3(s, s * 3.4, s)), pos + Vector3.UP * (3.4 * s)), i])
        var cb := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(s * 3.2, s * 0.5, s * 3.2))
        crowns.append([Transform3D(cb, pos + Vector3.UP * (6.9 * s)), i])
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.26
    trunk_mesh.height = 2.0
    trunk_mesh.radial_segments = 6
    trunk_mesh.rings = 1
    _add_chunked(trunk_mesh, _flat_material(Color(0.42, 0.30, 0.18)), trunks, SCENERY_VIEW)
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.0
    crown_mesh.height = 2.0
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    _add_chunked(crown_mesh, _flat_material(Color(0.12, 0.45, 0.14)), crowns, SCENERY_VIEW)


func _build_cacti() -> void:
    var q := GameManager.graphics_quality
    var bodies: Array = []
    var arms: Array = []
    for n in int(CACTUS_COUNTS[q]):
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var offset := _rng.randf_range(ROAD_WIDTH * 0.5 + 6.0, ROAD_WIDTH * 0.5 + 80.0)
        var pos := points[i] + _right(i) * side * offset
        var s := _rng.randf_range(0.8, 1.6)
        var yaw := Basis(Vector3.UP, _rng.randf() * TAU)
        bodies.append([Transform3D(Basis.from_scale(Vector3(s, s, s)), pos + Vector3.UP * (1.6 * s)), i])
        arms.append([Transform3D(yaw * Basis.from_scale(Vector3(s, s, s)), pos + yaw * Vector3(0.7 * s, 2.0 * s, 0.0)), i])
    var body_mesh := CylinderMesh.new()
    body_mesh.top_radius = 0.28
    body_mesh.bottom_radius = 0.34
    body_mesh.height = 3.2
    body_mesh.radial_segments = 6
    body_mesh.rings = 1
    var arm_mesh := BoxMesh.new()
    arm_mesh.size = Vector3(1.0, 0.3, 0.3)
    var green := _flat_material(Color(0.20, 0.42, 0.18))
    _add_chunked(body_mesh, green, bodies, SCENERY_VIEW)
    _add_chunked(arm_mesh, green, arms, SCENERY_VIEW)


## Big sand dunes far from the road (visual only, no collision).
func _build_dunes() -> void:
    var q := GameManager.graphics_quality
    var dunes: Array = []
    var tries := 0
    while dunes.size() < int(DUNE_COUNTS[q]) and tries < 400:
        tries += 1
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var pos := points[i] + _right(i) * side * _rng.randf_range(110.0, 320.0)
        var sc := Vector3(_rng.randf_range(35.0, 85.0), _rng.randf_range(6.0, 14.0), _rng.randf_range(30.0, 65.0))
        if _min_road_dist(pos) < maxf(sc.x, sc.z) + ROAD_WIDTH + 15.0:
            continue
        var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis.from_scale(sc)
        dunes.append([Transform3D(basis, pos + Vector3.UP * (-sc.y * 0.35)), i])
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 10
    sphere.rings = 5
    var sand := _flat_material(Color(0.84, 0.64, 0.38))
    _add_chunked(sphere, sand, dunes, SCENERY_VIEW + 300.0)


func _make_window_texture() -> ImageTexture:
    var img := Image.create(16, 32, false, Image.FORMAT_RGB8)
    for y in 32:
        for x in 16:
            var c := Color(0.0, 0.0, 0.0)
            if x % 2 == 0 and y % 2 == 0 and _rng.randf() < 0.4:
                c = Color(1.0, 0.85, 0.5) if _rng.randf() < 0.7 else Color(0.5, 0.8, 1.0)
            img.set_pixel(x, y, c)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)


## Skyscrapers with lit windows plus neon signs on the road-facing walls.
func _build_city() -> void:
    var q := GameManager.graphics_quality
    var buildings: Array = []
    var neon: Array = [[], [], []]   # magenta, cyan, yellow
    var tries := 0
    while buildings.size() < int(BUILDING_COUNTS[q]) and tries < 900:
        tries += 1
        var i := _rng.randi_range(0, SAMPLES - 1)
        var side := -1.0 if _rng.randf() < 0.5 else 1.0
        var w := _rng.randf_range(14.0, 30.0)   # along road right
        var d := _rng.randf_range(14.0, 30.0)   # along road
        var h := _rng.randf_range(25.0, 150.0)
        var offset := _rng.randf_range(28.0, 140.0)
        var pos := points[i] + _right(i) * side * offset
        if _min_road_dist(pos) < maxf(w, d) * 0.75 + ROAD_WIDTH * 0.5 + 14.0:
            continue
        var look := Basis.looking_at(tangents[i], Vector3.UP)
        buildings.append([Transform3D(look * Basis.from_scale(Vector3(w, h, d)), pos + Vector3.UP * (h * 0.5)), i])
        if _rng.randf() < 0.6:
            var face := pos + (-_right(i) * side) * (w * 0.5 + 0.2)
            var ny := _rng.randf_range(6.0, maxf(7.0, minf(h - 2.0, 30.0)))
            neon[_rng.randi_range(0, 2)].append([Transform3D(look, face + Vector3.UP * ny), i])

    var box := BoxMesh.new()
    box.size = Vector3.ONE
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.05, 0.05, 0.07)
    mat.roughness = 0.6
    mat.emission_enabled = true
    mat.emission_texture = _make_window_texture()
    mat.emission_energy_multiplier = 1.4
    mat.uv1_scale = Vector3(2.0, 4.0, 1.0)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
    _add_chunked(box, mat, buildings, SCENERY_VIEW + 300.0)

    var sign_mesh := BoxMesh.new()
    sign_mesh.size = Vector3(0.3, 2.2, 7.0)
    var colors := [Color(1.0, 0.1, 0.7), Color(0.1, 0.9, 1.0), Color(1.0, 0.9, 0.1)]
    for k in 3:
        var nm := StandardMaterial3D.new()
        nm.albedo_color = colors[k]
        nm.emission_enabled = true
        nm.emission = colors[k]
        nm.emission_energy_multiplier = 3.0
        _add_chunked(sign_mesh, nm, neon[k], SCENERY_VIEW)


func _flat_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    return mat


## items: Array of [Transform3D in world space, road sample index].
## Items are grouped by position along the track into chunks. Each chunk is one
## MultiMeshInstance3D centred on its items, with a visibility range, so
## chunks that are far from the camera are not drawn at all.
func _add_chunked(mesh: Mesh, mat: Material, items: Array, view_end: float) -> void:
    var buckets := {}
    for it in items:
        var c := clampi(int(float(it[1]) / float(SAMPLES) * float(CHUNKS)), 0, CHUNKS - 1)
        if not buckets.has(c):
            buckets[c] = []
        buckets[c].append(it[0])
    for c in buckets:
        var list: Array = buckets[c]
        var center := Vector3.ZERO
        for xf: Transform3D in list:
            center += xf.origin
        center /= float(list.size())
        center.y = 0.0
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = mesh
        mm.instance_count = list.size()
        for k in list.size():
            var xf: Transform3D = list[k]
            xf.origin -= center
            mm.set_instance_transform(k, xf)
        var mmi := MultiMeshInstance3D.new()
        mmi.multimesh = mm
        mmi.material_override = mat
        mmi.position = center
        mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        mmi.visibility_range_end = view_end
        mmi.visibility_range_end_margin = 60.0
        add_child(mmi)


func _build_mountains() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = theme["mountain"]
    mat.roughness = 1.0
    var n_mt := int(theme["mountains"])
    for k in n_mt:
        var ang := TAU * float(k) / float(n_mt) + _rng.randf_range(-0.15, 0.15)
        var dist := _rng.randf_range(1300.0, 1800.0)
        var h := _rng.randf_range(350.0, 700.0)
        var cm := CylinderMesh.new()
        cm.top_radius = 0.0
        cm.bottom_radius = h * _rng.randf_range(0.9, 1.4)
        cm.height = h
        cm.radial_segments = 8
        cm.rings = 1
        var mi := MeshInstance3D.new()
        mi.mesh = cm
        mi.material_override = mat
        mi.position = Vector3(cos(ang) * dist, h * 0.5 - 0.05, sin(ang) * dist)
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(mi)


func _build_start_line() -> void:
    var img := Image.create(16, 2, false, Image.FORMAT_RGB8)
    for y in 2:
        for x in 16:
            img.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else Color.BLACK)
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = ImageTexture.create_from_image(img)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

    var basis := Basis.looking_at(tangents[0], Vector3.UP)
    var line := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(ROAD_WIDTH, 0.02, 3.0)
    line.mesh = bm
    line.material_override = mat
    line.transform = Transform3D(basis, points[0] + Vector3.UP * 0.02)
    line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(line)

    # simple start arch
    var arch_mat := StandardMaterial3D.new()
    arch_mat.albedo_color = Color(0.8, 0.05, 0.05)
    arch_mat.roughness = 0.5
    var half := ROAD_WIDTH * 0.5 + 1.6
    for side: float in [-1.0, 1.0]:
        var post := MeshInstance3D.new()
        var pm := BoxMesh.new()
        pm.size = Vector3(0.6, 7.0, 0.6)
        post.mesh = pm
        post.material_override = arch_mat
        post.transform = Transform3D(basis, points[0] + _right(0) * side * half + Vector3.UP * 3.5)
        add_child(post)
    var beam := MeshInstance3D.new()
    var bmesh := BoxMesh.new()
    bmesh.size = Vector3(half * 2.0 + 0.6, 0.9, 0.9)
    beam.mesh = bmesh
    beam.material_override = arch_mat
    beam.transform = Transform3D(basis, points[0] + Vector3.UP * 7.0)
    add_child(beam)
