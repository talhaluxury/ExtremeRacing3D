class_name CarAudio
extends Node3D
## Engine, tyre and nitro sounds for one car (add as a child of the car).
## The engine is one looping sample whose pitch follows a simple 5-gear rpm
## model. The player hears it directly; AI cars are positional (3D).

const GEARS := 5
const IDLE_RPM := 0.18

var car: CarController
var is_player: bool = true

var _engine = null     # AudioStreamPlayer (player) or AudioStreamPlayer3D (AI)
var _screech: AudioStreamPlayer
var _nitro: AudioStreamPlayer
var _rpm: float = IDLE_RPM
var _gear: int = 0


func _ready() -> void:
    if is_player:
        var p := AudioStreamPlayer.new()
        p.bus = &"SFX"
        add_child(p)
        _engine = p
        _screech = AudioStreamPlayer.new()
        _screech.bus = &"SFX"
        add_child(_screech)
        _nitro = AudioStreamPlayer.new()
        _nitro.bus = &"SFX"
        add_child(_nitro)
    else:
        var p3 := AudioStreamPlayer3D.new()
        p3.bus = &"SFX"
        p3.unit_size = 10.0
        p3.max_distance = 140.0
        p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        p3.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
        add_child(p3)
        _engine = p3


func _ensure_streams() -> void:
    if _engine.stream == null:
        var s: AudioStream = AudioManager.get_stream("engine")
        if s != null:
            _engine.stream = s
    if is_player:
        if _screech.stream == null:
            _screech.stream = AudioManager.get_stream("screech")
        if _nitro.stream == null:
            _nitro.stream = AudioManager.get_stream("nitro")


func _process(delta: float) -> void:
    if car == null or not is_instance_valid(car):
        return
    _ensure_streams()

    var throttle := 0.0
    if car.ai_controlled:
        if not car.locked:
            throttle = car.ai_throttle
    else:
        throttle = Input.get_action_strength(&"accelerate")
        if car.locked:
            throttle *= 0.5   # rev the engine at the start line

    # --- engine: 5 gears, rpm falls after each shift
    var ratio := clampf(car.speed_kmh / 3.6 / maxf(car.max_speed, 1.0), 0.0, 1.0)
    var scaled := pow(ratio, 0.75) * float(GEARS)
    var g := mini(int(scaled), GEARS - 1)
    var frac := scaled - float(g)
    var target := clampf(IDLE_RPM + 0.55 * frac + 0.22 * throttle, 0.0, 1.0)
    _rpm = lerpf(_rpm, target, 1.0 - exp(-delta * 8.0))
    if g > _gear and is_player and throttle > 0.4:
        AudioManager.play_sfx("shift", -14.0, randf_range(0.95, 1.05))
    _gear = g

    var boost := car.nitro.boost
    _engine.pitch_scale = 0.75 + _rpm * 2.1 + 0.12 * boost
    _engine.volume_db = (-10.0 + 5.0 * throttle) if is_player else -6.0
    if _engine.stream != null and not _engine.playing:
        _engine.play()

    if not is_player:
        return

    # --- tyre screech while drifting / handbraking
    var skid := 0.0
    if car.grounded_wheels >= 2 and car.speed_kmh > 35.0:
        if car.drift.drifting:
            skid = clampf(car.drift.slip / 0.5, 0.3, 1.0)
        elif car.handbrake_on:
            skid = 0.6
    var screech_db := -45.0 if skid <= 0.0 else lerpf(-14.0, -3.0, skid)
    _screech.volume_db = lerpf(_screech.volume_db, screech_db, 1.0 - exp(-delta * 10.0))
    _screech.pitch_scale = 0.9 + skid * 0.35
    if _screech.stream != null:
        if skid > 0.0 and not _screech.playing:
            _screech.volume_db = -30.0
            _screech.play()
        elif skid <= 0.0 and _screech.playing and _screech.volume_db < -35.0:
            _screech.stop()

    # --- nitro whoosh
    if _nitro.stream != null:
        _nitro.volume_db = lerpf(-40.0, -6.0, boost)
        _nitro.pitch_scale = 0.9 + boost * 0.3
        if boost > 0.02 and not _nitro.playing:
            _nitro.play()
        elif boost <= 0.02 and _nitro.playing:
            _nitro.stop()
