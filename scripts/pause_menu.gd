class_name PauseMenu
extends CanvasLayer
## Pause button (top right), pause overlay and tilt-steering settings.
## Pauses the whole tree; this layer keeps running (PROCESS_MODE_ALWAYS).
## Also pauses by itself when the Android app goes to the background and
## reacts to the Android back button / Esc.

signal restart_requested
signal menu_requested
signal resumed

var _root: Control
var _button: Button
var _tilt_btn: Button
var _sens_btn: Button
var _inv_btn: Button
var is_paused: bool = false
var can_pause: bool = true   # race scene turns this off while the results are shown


func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS

    _button = Button.new()
    _button.text = "II"
    _button.add_theme_font_size_override("font_size", 34)
    _button.anchor_left = 1.0
    _button.anchor_right = 1.0
    _button.offset_left = -470.0
    _button.offset_right = -390.0
    _button.offset_top = 30.0
    _button.offset_bottom = 120.0
    _button.pressed.connect(pause)
    add_child(_button)

    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.visible = false
    add_child(_root)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(center)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    center.add_child(box)

    var title := Label.new()
    title.text = "PAUSED"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
    box.add_child(title)

    _make(box, "RESUME", resume, Color(1.0, 0.85, 0.3))
    _make(box, "RESTART", func() -> void:
        _unpause()
        restart_requested.emit())
    _tilt_btn = _make(box, "", func() -> void:
        GameManager.set_tilt(not GameManager.tilt_enabled)
        if GameManager.tilt_enabled:
            GameManager.calibrate_tilt()
        _refresh())
    _sens_btn = _make(box, "", func() -> void:
        GameManager.cycle_tilt_sensitivity()
        _refresh())
    _inv_btn = _make(box, "", func() -> void:
        GameManager.toggle_tilt_invert()
        _refresh())
    _make(box, "QUIT TO MENU", func() -> void:
        _unpause()
        menu_requested.emit())


func _make(parent: Control, text: String, handler: Callable, tint: Color = Color.WHITE) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(520, 58)
    b.add_theme_font_size_override("font_size", 28)
    b.modulate = tint
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


func _refresh() -> void:
    _tilt_btn.text = "TILT STEERING:  " + ("ON" if GameManager.tilt_enabled else "OFF")
    _sens_btn.text = "TILT SENSITIVITY:  %d%%" % roundi(GameManager.tilt_sensitivity * 100.0)
    _inv_btn.text = "TILT DIRECTION:  " + ("INVERTED" if GameManager.tilt_invert else "NORMAL")
    _sens_btn.disabled = not GameManager.tilt_enabled
    _inv_btn.disabled = not GameManager.tilt_enabled


func pause() -> void:
    if is_paused or not can_pause:
        return
    is_paused = true
    get_tree().paused = true
    _refresh()
    _root.visible = true
    _button.visible = false


func resume() -> void:
    if not is_paused:
        return
    _unpause()
    if GameManager.tilt_enabled:
        GameManager.calibrate_tilt()
    resumed.emit()


func _unpause() -> void:
    is_paused = false
    get_tree().paused = false
    _root.visible = false
    _button.visible = can_pause


func set_can_pause(value: bool) -> void:
    can_pause = value
    if not is_paused:
        _button.visible = value


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        if is_paused:
            resume()
        else:
            pause()
        get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if is_paused:
            resume()
        else:
            pause()
    elif what == NOTIFICATION_APPLICATION_PAUSED:
        pause()
