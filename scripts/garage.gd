extends Node3D
## 3D showroom: browse the 8 cars, buy / select them, buy upgrades, change
## paint and wheel colour. Drag to rotate the car, pinch or +/- to zoom.
## Everything is built from code. All purchases go through SaveManager.

const MAX_STAT := {"speed": 105.0, "accel": 17.0, "grip": 38.0, "brake": 35.0}

var _index: int = 0
var _car: CarController
var _yaw: float = 0.6
var _idle: float = 0.0
var _dist: float = 7.5
var _cam: Camera3D

var _name: Label
var _status: Label
var _coins: Label
var _bars: Dictionary = {}
var _upg_btns: Array[Button] = []
var _paint_lbl: Label
var _wheel_lbl: Label
var _action: Button
var _paint_btns: Array[Button] = []
var _wheel_btns: Array[Button] = []


func _ready() -> void:
    AudioManager.play_music("menu")
    _index = GameManager.selected_car
    _build_scene()
    _build_ui()
    _spawn_car()
    _refresh()


# ---------------------------------------------------------------- showroom

func _build_scene() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.02, 0.02, 0.05)
    sm.sky_horizon_color = Color(0.28, 0.30, 0.40)
    sm.ground_horizon_color = Color(0.28, 0.30, 0.40)
    sm.ground_bottom_color = Color(0.03, 0.03, 0.04)
    sky.sky_material = sm
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.6
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    # floor: dark disc with metallic sheen
    var floor_mi := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 6.0
    cyl.bottom_radius = 6.0
    cyl.height = 0.1
    cyl.radial_segments = 48
    floor_mi.mesh = cyl
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color(0.05, 0.05, 0.07)
    fm.metallic = 0.8
    fm.roughness = 0.35
    floor_mi.material_override = fm
    floor_mi.position = Vector3(0, -0.05, 0)
    add_child(floor_mi)

    # gold ring around the floor
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 5.9
    tm.outer_radius = 6.1
    ring.mesh = tm
    var rm := StandardMaterial3D.new()
    rm.albedo_color = Color(1.0, 0.75, 0.15)
    rm.emission_enabled = true
    rm.emission = Color(1.0, 0.7, 0.1)
    rm.emission_energy_multiplier = 1.5
    ring.material_override = rm
    ring.position = Vector3(0, 0.0, 0)
    add_child(ring)

    # key light (shadow), rim lights
    var key := SpotLight3D.new()
    key.position = Vector3(4, 7, 5)
    key.look_at_from_position(key.position, Vector3(0, 0.5, 0), Vector3.UP)
    key.light_energy = 6.0
    key.spot_range = 20.0
    key.spot_angle = 40.0
    key.shadow_enabled = GameManager.graphics_quality > 0
    add_child(key)
    var rim := OmniLight3D.new()
    rim.position = Vector3(-5, 2.5, -4)
    rim.light_color = Color(0.4, 0.6, 1.0)
    rim.light_energy = 3.0
    rim.omni_range = 14.0
    add_child(rim)
    var rim2 := OmniLight3D.new()
    rim2.position = Vector3(5, 2.0, -5)
    rim2.light_color = Color(1.0, 0.7, 0.4)
    rim2.light_energy = 2.0
    rim2.omni_range = 14.0
    add_child(rim2)

    _cam = Camera3D.new()
    _cam.fov = 50.0
    add_child(_cam)
    _place_camera()


func _place_camera() -> void:
    _cam.position = Vector3(_dist * 0.55, 1.4 + _dist * 0.12, _dist * 0.83)
    _cam.look_at_from_position(_cam.position, Vector3(0, 0.55, 0), Vector3.UP)


func _spawn_car() -> void:
    if _car != null:
        _car.queue_free()
    _car = CarController.new()
    _car.setup(GameManager.tuned_data(_index))
    # Display only: no gravity, no driving. The turntable sets the rotation.
    _car.freeze = true
    _car.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    _car.gravity_scale = 0.0
    _car.locked = true
    add_child(_car)
    _car.position = Vector3(0, 0.05, 0)
    _car.rotation.y = _yaw


func _process(delta: float) -> void:
    _idle += delta
    if _idle > 2.0:
        _yaw += delta * 0.45
    if _car != null:
        _car.rotation.y = _yaw


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        _yaw += event.relative.x * 0.01
        _idle = 0.0
    elif event is InputEventMagnifyGesture:
        _zoom(1.0 / maxf(event.factor, 0.1))
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(0.92)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(1.08)


func _zoom(mult: float) -> void:
    _dist = clampf(_dist * mult, 4.5, 11.0)
    _place_camera()


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    # left panel
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
    panel.offset_left = 10.0
    panel.offset_top = 10.0
    panel.offset_right = 470.0
    panel.offset_bottom = -10.0
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.04, 0.04, 0.06, 0.88)
    sb.border_color = Color(1.0, 0.75, 0.15, 0.8)
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(10)
    sb.set_content_margin_all(12)
    panel.add_theme_stylebox_override("panel", sb)
    root.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    panel.add_child(scroll)
    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(420, 0)
    box.add_theme_constant_override("separation", 6)
    scroll.add_child(box)

    _name = _label(box, 34, Color(1.0, 0.8, 0.25))
    _status = _label(box, 22, Color.WHITE)

    for k: String in ["speed", "accel", "grip", "brake"]:
        var row := HBoxContainer.new()
        box.add_child(row)
        var l := _label(row, 20, Color(0.8, 0.8, 0.85))
        l.text = k.to_upper()
        l.custom_minimum_size = Vector2(110, 0)
        var bar := ProgressBar.new()
        bar.max_value = 1.0
        bar.show_percentage = false
        bar.custom_minimum_size = Vector2(190, 18)
        bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        row.add_child(bar)
        var v := _label(row, 20, Color.WHITE)
        v.custom_minimum_size = Vector2(70, 0)
        v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _bars[k] = {"bar": bar, "val": v}

    var hu := _label(box, 22, Color(1.0, 0.8, 0.25))
    hu.text = "UPGRADES"
    for i in CarData.UPGRADES.size():
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 50)
        b.add_theme_font_size_override("font_size", 22)
        b.pressed.connect(_on_upgrade.bind(i))
        box.add_child(b)
        _upg_btns.append(b)

    var hp := _label(box, 22, Color(1.0, 0.8, 0.25))
    hp.text = "PAINT"
    _paint_lbl = _label(box, 20, Color.WHITE)
    _swatch_grid(box, CarData.PAINTS, _paint_btns, _on_paint)

    var hw := _label(box, 22, Color(1.0, 0.8, 0.25))
    hw.text = "WHEELS"
    _wheel_lbl = _label(box, 20, Color.WHITE)
    _swatch_grid(box, CarData.WHEELS, _wheel_btns, _on_wheel)

    # coins (top right)
    _coins = _label(root, 30, Color(1.0, 0.85, 0.3))
    _coins.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _coins.offset_left = -360.0
    _coins.offset_right = -20.0
    _coins.offset_top = 14.0
    _coins.offset_bottom = 60.0
    _coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    # bottom bar (right side)
    var bar_box := HBoxContainer.new()
    bar_box.add_theme_constant_override("separation", 10)
    bar_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    bar_box.offset_left = -780.0
    bar_box.offset_right = -14.0
    bar_box.offset_top = -92.0
    bar_box.offset_bottom = -14.0
    bar_box.alignment = BoxContainer.ALIGNMENT_END
    root.add_child(bar_box)
    _btn(bar_box, "<", 80, func() -> void: _change_car(-1))
    _action = _btn(bar_box, "SELECT", 230, _on_action)
    _btn(bar_box, ">", 80, func() -> void: _change_car(1))
    _btn(bar_box, "+", 60, func() -> void: _zoom(0.85))
    _btn(bar_box, "-", 60, func() -> void: _zoom(1.18))
    _btn(bar_box, "BACK", 140, func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))


func _swatch_grid(parent: Control, items: Array, store: Array[Button], handler: Callable) -> void:
    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    parent.add_child(grid)
    for i in items.size():
        var b := Button.new()
        b.custom_minimum_size = Vector2(70, 46)
        var st := StyleBoxFlat.new()
        st.bg_color = items[i]["color"]
        st.set_corner_radius_all(6)
        st.border_color = Color(1, 1, 1, 0.5)
        st.set_border_width_all(2)
        b.add_theme_stylebox_override("normal", st)
        b.add_theme_stylebox_override("hover", st)
        b.add_theme_stylebox_override("pressed", st)
        b.add_theme_stylebox_override("disabled", st)
        b.pressed.connect(handler.bind(i))
        grid.add_child(b)
        store.append(b)


func _label(parent: Control, size: int, color: Color) -> Label:
    var l := Label.new()
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    parent.add_child(l)
    return l


func _btn(parent: Control, text: String, w: float, handler: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(w, 78)
    b.add_theme_font_size_override("font_size", 30)
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


# ---------------------------------------------------------------- logic

func _id() -> String:
    return str(CarData.CARS[_index]["id"])


func _change_car(step: int) -> void:
    _index = posmod(_index + step, CarData.CARS.size())
    _spawn_car()
    _refresh()


func _on_action() -> void:
    var id := _id()
    if SaveManager.is_owned(id):
        GameManager.select_car(_index)
    else:
        SaveManager.buy_car(id)
    _refresh()


func _on_upgrade(i: int) -> void:
    if SaveManager.buy_upgrade(_id(), str(CarData.UPGRADES[i]["key"])):
        _rebuild_keep_yaw()
    _refresh()


func _on_paint(i: int) -> void:
    if SaveManager.is_owned(_id()):
        SaveManager.set_paint(_id(), i)
        _rebuild_keep_yaw()
        _refresh()


func _on_wheel(i: int) -> void:
    if SaveManager.is_owned(_id()):
        SaveManager.set_wheel(_id(), i)
        _rebuild_keep_yaw()
        _refresh()


func _rebuild_keep_yaw() -> void:
    _spawn_car()


func _refresh() -> void:
    var id := _id()
    var base: Dictionary = CarData.CARS[_index]
    var d := GameManager.tuned_data(_index)
    var owned := SaveManager.is_owned(id)

    _name.text = str(base["name"]).to_upper()
    _coins.text = "COINS  %d" % SaveManager.coins
    if not owned:
        _status.text = "LOCKED  -  %d coins" % int(base["price"])
    elif GameManager.selected_car == _index:
        _status.text = "OWNED  -  SELECTED"
    else:
        _status.text = "OWNED"

    _set_bar("speed", float(d["max_speed"]) * 3.6, MAX_STAT["speed"] * 3.6, "%d km/h" % int(float(d["max_speed"]) * 3.6))
    _set_bar("accel", float(d["accel"]), MAX_STAT["accel"], "%.1f" % float(d["accel"]))
    _set_bar("grip", float(d["grip"]), MAX_STAT["grip"], "%.0f" % float(d["grip"]))
    _set_bar("brake", float(d["brake"]), MAX_STAT["brake"], "%.0f" % float(d["brake"]))

    for i in CarData.UPGRADES.size():
        var key: String = CarData.UPGRADES[i]["key"]
        var lvl := SaveManager.get_upgrade(id, key)
        var b := _upg_btns[i]
        var pips := "#".repeat(lvl) + "-".repeat(CarData.MAX_LEVEL - lvl)
        if not owned:
            b.text = "%s  [%s]  (buy car first)" % [CarData.UPGRADES[i]["name"], pips]
            b.disabled = true
        elif lvl >= CarData.MAX_LEVEL:
            b.text = "%s  [%s]  MAX" % [CarData.UPGRADES[i]["name"], pips]
            b.disabled = true
        else:
            var cost := CarData.upgrade_cost(lvl)
            b.text = "%s  [%s]  %d" % [CarData.UPGRADES[i]["name"], pips, cost]
            b.disabled = SaveManager.coins < cost

    var p := SaveManager.get_paint(id)
    _paint_lbl.text = "Stock" if p < 0 else str(CarData.PAINTS[p]["name"])
    var w := SaveManager.get_wheel(id)
    _wheel_lbl.text = "Stock" if w < 0 else str(CarData.WHEELS[w]["name"])
    for b in _paint_btns:
        b.disabled = not owned
    for b in _wheel_btns:
        b.disabled = not owned

    if not owned:
        _action.text = "BUY  %d" % int(base["price"])
        _action.disabled = SaveManager.coins < int(base["price"])
    elif GameManager.selected_car == _index:
        _action.text = "SELECTED"
        _action.disabled = true
    else:
        _action.text = "SELECT"
        _action.disabled = false


func _set_bar(key: String, value: float, maxv: float, text: String) -> void:
    var e: Dictionary = _bars[key]
    (e["bar"] as ProgressBar).value = clampf(value / maxv, 0.0, 1.0)
    (e["val"] as Label).text = text
