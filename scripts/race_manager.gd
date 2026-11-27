class_name RaceManager
extends Node
## Countdown, lap counting, positions and finishing for every racer.
## laps <= 0 means free drive (no countdown, no finish).

signal countdown_changed(text: String)
signal race_started
signal player_finished
signal lap_completed(racer: Racer, lap_time: float)

enum State { COUNTDOWN, RACING, FINISHED }


class Racer:
    var car: CarController
    var ai: AIController
    var racer_name: String = ""
    var is_player: bool = false
    var last_idx: int = 0
    var progress: float = 0.0     # in track samples; negative before the start line
    var lap: int = 0              # completed laps
    var finished: bool = false
    var finish_time: float = 0.0
    var lap_start: float = 0.0
    var best_lap: float = -1.0
    var last_lap: float = -1.0


var track: TrackBuilder
var laps: int = 3
var state: State = State.COUNTDOWN
var racers: Array[Racer] = []
var player: Racer
var race_time: float = 0.0

var _countdown: float = 3.5
var _last_text: String = "x"


func add_racer(car: CarController, ai: AIController, racer_name: String, is_player: bool, start_idx: int) -> Racer:
    var r := Racer.new()
    r.car = car
    r.ai = ai
    r.racer_name = racer_name
    r.is_player = is_player
    r.last_idx = posmod(start_idx, track.count)
    r.progress = float(posmod(start_idx, track.count) - track.count)
    racers.append(r)
    if is_player:
        player = r
    car.locked = laps > 0
    return r


func begin() -> void:
    if laps <= 0:
        _go()


## Seconds left before GO (0 once the race runs).
func time_to_go() -> float:
    return maxf(_countdown, 0.0) if state == State.COUNTDOWN else 0.0


func current_lap_time(r: Racer) -> float:
    if state == State.COUNTDOWN:
        return 0.0
    return race_time - r.lap_start


func get_position(r: Racer) -> int:
    var pos := 1
    for o in racers:
        if o != r and _ahead(o, r):
            pos += 1
    return pos


func get_ranking() -> Array[Racer]:
    var out: Array[Racer] = []
    out.append_array(racers)
    out.sort_custom(func(a: Racer, b: Racer) -> bool: return _ahead(a, b))
    return out


func _ahead(a: Racer, b: Racer) -> bool:
    if a.finished and b.finished:
        return a.finish_time < b.finish_time
    if a.finished:
        return true
    if b.finished:
        return false
    return a.progress > b.progress


func _physics_process(delta: float) -> void:
    match state:
        State.COUNTDOWN:
            _countdown -= delta
            var text := ""
            if _countdown > 0.0 and _countdown <= 3.0:
                text = str(ceili(_countdown))
            if text != _last_text:
                _last_text = text
                countdown_changed.emit(text)
            if _countdown <= 0.0:
                _go()
        State.RACING:
            race_time += delta
            _update_racers()


func _go() -> void:
    state = State.RACING
    race_time = 0.0
    for r in racers:
        r.car.locked = false
        r.lap_start = 0.0
        if r.ai != null:
            r.ai.enabled = true
    race_started.emit()


func _update_racers() -> void:
    var n := track.count
    var half := n >> 1
    for r in racers:
        if r.finished:
            continue
        var idx := track.nearest_index(r.car.global_position, r.last_idx)
        var d := idx - r.last_idx
        if d < -half:
            d += n
        elif d > half:
            d -= n
        r.progress += float(d)
        r.last_idx = idx

        var done := maxi(0, floori(r.progress / float(n)))
        if done > r.lap:
            r.last_lap = race_time - r.lap_start
            if r.best_lap < 0.0 or r.last_lap < r.best_lap:
                r.best_lap = r.last_lap
            r.lap_start = race_time
            r.lap = done
            lap_completed.emit(r, r.last_lap)
            if laps > 0 and r.lap >= laps:
                _finish(r)

    # rubber banding: AI speeds up a little if the player is far ahead
    if player != null:
        for r in racers:
            if r.ai != null:
                r.ai.rubber = clampf((player.progress - r.progress) / (float(n) * 0.08), -1.0, 1.0)


func _finish(r: Racer) -> void:
    r.finished = true
    r.finish_time = race_time
    if r.is_player:
        r.car.locked = true
        state = State.FINISHED
        player_finished.emit()
