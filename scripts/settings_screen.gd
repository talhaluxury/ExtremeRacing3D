extends Control
## Settings: sound, graphics, steering and touch layout.

const VOLUME_STEPS := [0.0, 0.25, 0.5, 0.75, 1.0]

var _sfx: Button
var _music: Button
var _gfx: Button
var _fps: Button
var _res: Button
var _tilt: Button
var _sens: Button
var _invert: Button
var _size: Button
var _mirror: Button
var _wheel: Button


func _ready() -> void:
    var box := UiKit.screen(self, "SETTINGS")
    var cols := HBoxContainer.new()
    cols.add_theme_constant_override("separation", 24)
    cols.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_child(cols)
    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 10)
    cols.add_child(left)
    var right := VBoxContainer.new()
    right.add_theme_constant_override("separation", 10)
    cols.add_child(right)

    _sfx = UiKit.button(left, "", _cycle_sfx)
    _music = UiKit.button(left, "", _cycle_music)
    _gfx = UiKit.button(left, "", _cycle_gfx)
    _fps = UiKit.button(left, "", _cycle_fps)
    _res = UiKit.button(left, "", _cycle_res)

    _tilt = UiKit.button(right, "", _toggle_tilt)
    _sens = UiKit.button(right, "", _cycle_sens)
    _invert = UiKit.button(right, "", _toggle_invert)
    _size = UiKit.button(right, "", _cycle_size)
    _mirror = UiKit.button(right, "", _toggle_mirror)
    _wheel = UiKit.button(right, "", _toggle_wheel)

    var note := UiKit.label(box, "Tilt: hold the phone the way you drive; it calibrates at the race start.\nIf it steers the wrong way, switch TILT DIRECTION.", 20, Color(0.7, 0.7, 0.75))
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _refresh()


func _refresh() -> void:
    var gm := GameManager
    _sfx.text = "SOUND:  %d%%" % roundi(AudioManager.sfx_volume * 100.0)
    _music.text = "MUSIC:  %d%%" % roundi(AudioManager.music_volume * 100.0)
    _gfx.text = "GRAPHICS:  " + gm.QUALITY_NAMES[gm.graphics_quality]
    _fps.text = "FPS:  %d" % gm.target_fps
    _res.text = "RESOLUTION:  " + ("AUTO" if gm.render_scale <= 0.0 else "%d%%" % roundi(gm.render_scale * 100.0))
    _tilt.text = "TILT STEERING:  " + ("ON" if gm.tilt_enabled else "OFF")
    _sens.text = "TILT SENSITIVITY:  %d%%" % roundi(gm.tilt_sensitivity * 100.0)
    _invert.text = "TILT DIRECTION:  " + ("INVERTED" if gm.tilt_invert else "NORMAL")
    _size.text = "TOUCH BUTTON SIZE:  %d%%" % roundi(gm.touch_scale * 100.0)
    _mirror.text = "CONTROL LAYOUT:  " + ("LEFT-HANDED" if gm.touch_mirror else "STANDARD")
    _wheel.text = "STEERING:  " + ("WHEEL" if gm.steer_wheel else "BUTTONS")
    _sens.disabled = not gm.tilt_enabled
    _invert.disabled = not gm.tilt_enabled


func _next_step(current: float) -> float:
    for v: float in VOLUME_STEPS:
        if v > current + 0.01:
            return v
    return 0.0


func _cycle_sfx() -> void:
    AudioManager.set_sfx_volume(_next_step(AudioManager.sfx_volume))
    AudioManager.play_sfx("beep", -10.0)
    _refresh()


func _cycle_music() -> void:
    AudioManager.set_music_volume(_next_step(AudioManager.music_volume))
    _refresh()


func _cycle_gfx() -> void:
    GameManager.set_quality((GameManager.graphics_quality + 1) % GameManager.QUALITY_NAMES.size())
    _refresh()


func _cycle_fps() -> void:
    GameManager.set_fps(30 if GameManager.target_fps == 60 else 60)
    _refresh()


func _cycle_res() -> void:
    GameManager.cycle_render_scale()
    _refresh()


func _toggle_tilt() -> void:
    GameManager.set_tilt(not GameManager.tilt_enabled)
    _refresh()


func _cycle_sens() -> void:
    GameManager.cycle_tilt_sensitivity()
    _refresh()


func _toggle_invert() -> void:
    GameManager.toggle_tilt_invert()
    _refresh()


func _cycle_size() -> void:
    GameManager.cycle_touch_scale()
    _refresh()


func _toggle_wheel() -> void:
    GameManager.toggle_steer_wheel()
    _refresh()


func _toggle_mirror() -> void:
    GameManager.toggle_touch_mirror()
    _refresh()
