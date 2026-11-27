class_name Ghost
extends Node3D
## Time Trial ghost: records the player's fastest lap (20 samples per second,
## saved per track in user://) and replays it as a transparent car next to
## the player on every following lap.

const RATE := 20.0
const FLOATS := 7   # x, y, z, quaternion x, y, z, w

var manager: RaceManager
var car: CarController
var track_index: int = 0

var _best_time: float = INF
var _best := PackedFloat32Array()
var _rec := PackedFloat32Array()
var _visual: Node3D


func setup(m: RaceManager, c: CarController, track: int) -> void:
    manager = m
    car = c
    track_index = track
    _load()
    _build_visual()
    manager.lap_completed.connect(_on_lap_completed)


func _path() -> String:
    return "user://ghost_%d.dat" % track_index


func _load() -> void:
    if not FileAccess.file_exists(_path()):
        return
    var f := FileAccess.open(_path(), FileAccess.READ)
    if f == null:
        return
    var v: Variant = f.get_var()
    f.close()
    if v is Dictionary:
        var d: Dictionary = v
        var data: Variant = d.get("data", null)
        if data is PackedFloat32Array and (data as PackedFloat32Array).size() >= FLOATS * 2:
            _best = data
            _best_time = float(d.get("time", INF))


func _save() -> void:
    var f := FileAccess.open(_path(), FileAccess.WRITE)
    if f == null:
        return
    f.store_var({"time": _best_time, "data": _best})
    f.close()


func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.visible = false
    add_child(_visual)
    var w: float = float(car.data["width"])
    var l: float = float(car.data["length"])
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.3, 0.9, 1.0, 0.35)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var body := BoxMesh.new()
    body.size = Vector3(w * 0.95, 0.5, l)
    var cabin := BoxMesh.new()
    cabin.size = Vector3(w * 0.8, 0.4, l * 0.4)
    var mb := MeshInstance3D.new()
    mb.mesh = body
    mb.material_override = mat
    mb.position = Vector3(0.0, 0.4, 0.0)
    _visual.add_child(mb)
    var mc := MeshInstance3D.new()
    mc.mesh = cabin
    mc.material_override = mat
    mc.position = Vector3(0.0, 0.8, l * 0.06)
    _visual.add_child(mc)


func _physics_process(_delta: float) -> void:
    if manager == null or manager.player == null or car == null or not is_instance_valid(car):
        return
    if manager.state != RaceManager.State.RACING:
        return
    var t := manager.current_lap_time(manager.player)

    # record
    if t * RATE >= float(_rec.size() / FLOATS):
        var q := car.global_transform.basis.get_rotation_quaternion()
        var p := car.global_position
        _rec.append_array(PackedFloat32Array([p.x, p.y, p.z, q.x, q.y, q.z, q.w]))

    # replay
    if _best.is_empty():
        return
    var f := t * RATE
    var i0 := floori(f)
    var count := _best.size() / FLOATS
    if i0 + 1 >= count:
        _visual.visible = false
        return
    var w := f - float(i0)
    var a := i0 * FLOATS
    var b := a + FLOATS
    var pos := Vector3(lerpf(_best[a], _best[b], w), lerpf(_best[a + 1], _best[b + 1], w), lerpf(_best[a + 2], _best[b + 2], w))
    var qa := Quaternion(_best[a + 3], _best[a + 4], _best[a + 5], _best[a + 6])
    var qb := Quaternion(_best[b + 3], _best[b + 4], _best[b + 5], _best[b + 6])
    _visual.global_transform = Transform3D(Basis(qa.slerp(qb, w)), pos)
    _visual.visible = true


func _on_lap_completed(r: RaceManager.Racer, lap_time: float) -> void:
    if not r.is_player:
        return
    if _rec.size() >= FLOATS * 2 and lap_time < _best_time:
        _best_time = lap_time
        _best = _rec.duplicate()
        _save()
    _rec = PackedFloat32Array()
