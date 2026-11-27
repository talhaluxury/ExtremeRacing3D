class_name NitroSystem
extends RefCounted
## Nitro meter. Hold the nitro button to burn the meter for extra
## acceleration and a higher top speed. The meter recharges slowly on its own
## and faster while drifting (see car_controller.gd).

const MAX_METER := 100.0
const DRAIN := 28.0         # per second while active
const RECHARGE := 4.0       # per second while idle
const MIN_TO_START := 12.0

var drain: float = DRAIN
var recharge: float = RECHARGE
var meter: float = 60.0
var active: bool = false
var boost: float = 0.0      # smoothed 0..1, used for physics and camera


func update(delta: float, pressed: bool) -> void:
    if active:
        if not pressed or meter <= 0.0:
            active = false
    elif pressed and meter >= MIN_TO_START:
        active = true

    if active:
        meter = maxf(0.0, meter - drain * delta)
    else:
        meter = minf(MAX_METER, meter + recharge * delta)

    var goal := 1.0 if active else 0.0
    boost = move_toward(boost, goal, delta * (4.0 if active else 2.5))


func add(amount: float) -> void:
    meter = minf(MAX_METER, meter + amount)


func ratio() -> float:
    return meter / MAX_METER
