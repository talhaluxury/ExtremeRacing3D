extends Node3D
## Race scene for all modes (quick race, time trial, free drive).
## Everything is built from code: environment, track, cars, camera, HUD.

const AI_NAMES := ["Viper", "Nova", "Blaze", "Ghost", "Rogue"]
const AI_COLORS := [
    Color(0.1, 0.7, 0.2), Color(0.9, 0.9, 0.9), Color(0.5, 0.1, 0.7),
    Color(0.05, 0.05, 0.05), Color(0.1, 0.8, 0.9),
]
const AI_SKILL := [0.80, 0.90, 0.98]

var track: TrackBuilder
var cam: ChaseCamera
var hud: RaceHud
var touch: TouchControls
var speed_lines: SpeedLines
var sun: DirectionalLight3D
var manager: RaceManager
var results: ResultsScreen
var pause_menu: PauseMenu
var player_car: CarController

var environment_is_dusk: bool = false
var _upside_time: float = 0.0
var _gas_press_time: float = -1.0   # seconds before GO when GAS was last pressed
var _all_cars: Array[CarController] = []


func _ready() -> void:
    var environment := RaceEnvironment.new()
    add_child(environment)
    environment.build(RaceEnvironment.preset_for_track(GameManager.track_index))
    sun = environment.sun

    track = TrackBuilder.new()
    track.layout = GameManager.track_index
    track.dusk = environment.dusk
    environment_is_dusk = environment.dusk
    add_child(track)
    track.build()

    GameManager.apply_quality(get_viewport(), sun)

    speed_lines = SpeedLines.new()
    add_child(speed_lines)
    hud = RaceHud.new()
    add_child(hud)
    touch = TouchControls.new()
    add_child(touch)
    if GameManager.mode != GameManager.MODE_FREE:
        touch.hide_action("next_car")

    cam = ChaseCamera.new()
    cam.far = 3500.0
    add_child(cam)
    if GameManager.rain:
        var rain := RainEffect.new()
        rain.target = cam
        add_child(rain)

    results = ResultsScreen.new()
    add_child(results)
    results.retry_pressed.connect(func() -> void: get_tree().reload_current_scene())
    results.next_pressed.connect(_on_next_track)
    results.menu_pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

    pause_menu = PauseMenu.new()
    add_child(pause_menu)
    pause_menu.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
    pause_menu.menu_requested.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    if GameManager.tilt_enabled:
        GameManager.calibrate_tilt()

    _setup_race()


func _setup_race() -> void:
    var mode := GameManager.mode
    manager = RaceManager.new()
    manager.track = track
    manager.laps = 0 if mode == GameManager.MODE_FREE else GameManager.laps
    add_child(manager)
    manager.countdown_changed.connect(func(text: String) -> void:
        hud.show_message(text)
        if text != "":
            AudioManager.play_sfx("beep", -4.0))
    manager.race_started.connect(_on_race_started)
    AudioManager.play_music("race")
    manager.player_finished.connect(_on_player_finished)

    var ai_count := 5 if mode == GameManager.MODE_QUICK else 0
    var total := ai_count + 1
    var player_slot := mini(2, total - 1)
    var ai_list: Array[AIController] = []
    var ai_n := 0

    for s in total:
        var is_player := (s == player_slot)
        var row := s >> 1
        var start_idx := track.count - 4 - row * 4
        var lateral := -4.0 if s % 2 == 0 else 4.0

        var data: Dictionary
        if is_player:
            data = GameManager.get_car_data()
        else:
            # AI cars are from the same tier as the player's car (+/- one step)
            var tier := clampi(GameManager.selected_car + randi_range(-1, 1), 0, CarData.CARS.size() - 1)
            data = CarData.CARS[tier].duplicate()
            data["color"] = AI_COLORS[ai_n % AI_COLORS.size()]

        var car := CarController.new()
        car.setup(data)
        car.transform = track.grid_transform(start_idx, lateral)
        add_child(car)
        _all_cars.append(car)
        var car_audio := CarAudio.new()
        car_audio.car = car
        car_audio.is_player = is_player
        car.add_child(car_audio)

        var ai: AIController = null
        var racer_name := "YOU"
        if is_player:
            player_car = car
            if environment_is_dusk and GameManager.graphics_quality >= 1:
                car.build_headlights()
            car.crashed.connect(cam.shake)
            car.crashed.connect(func(intensity: float) -> void:
                AudioManager.play_sfx("crash", lerpf(-10.0, 0.0, intensity), randf_range(0.9, 1.1)))
        else:
            racer_name = AI_NAMES[ai_n % AI_NAMES.size()]
            car.ai_controlled = true
            ai = AIController.new()
            ai.car = car
            ai.track = track
            ai.skill = AI_SKILL[GameManager.difficulty] * randf_range(0.97, 1.0)
            ai.use_nitro = GameManager.difficulty == 2
            ai.init_at(start_idx, lateral)
            add_child(ai)
            ai_list.append(ai)
            ai_n += 1
        manager.add_racer(car, ai, racer_name, is_player, start_idx)

    for ai in ai_list:
        ai.others = _all_cars

    cam.target = player_car
    cam.snap(player_car.transform)
    manager.begin()
    if manager.laps > 0:
        cam.start_intro(3.0)   # cinematic during the countdown

    if GameManager.mode == GameManager.MODE_TRIAL:
        var ghost := Ghost.new()
        add_child(ghost)
        ghost.setup(manager, player_car, GameManager.track_index)

    var map_layer := CanvasLayer.new()
    map_layer.layer = 3
    add_child(map_layer)
    var minimap := Minimap.new()
    map_layer.add_child(minimap)
    minimap.setup(track, _all_cars, player_car)


func _on_race_started() -> void:
    hud.show_message("GO!", 1.0)
    AudioManager.play_sfx("go", -2.0)
    if GameManager.tilt_enabled:
        GameManager.calibrate_tilt()
    # perfect start: GAS pressed in the last 0.6 s before GO and still held
    if _gas_press_time >= 0.0 and _gas_press_time <= 0.6 and Input.is_action_pressed(&"accelerate"):
        player_car.nitro.add(35.0)
        hud.show_message("PERFECT START!", 1.4)
        AudioManager.play_sfx("shift", -2.0, 1.4)


func _respawn_player() -> void:
    var xf := track.grid_transform(manager.player.last_idx, 0.0)
    player_car.reset_to(xf)
    cam.snap(xf)
    _upside_time = 0.0


func _physics_process(delta: float) -> void:
    if player_car == null or manager == null:
        return

    if manager.state == RaceManager.State.COUNTDOWN and Input.is_action_just_pressed(&"accelerate"):
        _gas_press_time = manager.time_to_go()
    if cam.is_intro_running() and manager.state != RaceManager.State.COUNTDOWN:
        cam.skip_intro()
    if manager.state == RaceManager.State.RACING and manager.player != null:
        var tdir := track.tangents[manager.player.last_idx]
        var fwd := -player_car.global_transform.basis.z
        if fwd.dot(tdir) < -0.3 and player_car.speed_kmh > 15.0:
            hud.show_message("WRONG WAY", 0.25)
    if Input.is_action_just_pressed(&"change_view"):
        cam.cycle_mode()
    if Input.is_action_just_pressed(&"reset_car") and manager.state != RaceManager.State.COUNTDOWN:
        _respawn_player()
    if Input.is_action_just_pressed(&"next_car") and GameManager.mode == GameManager.MODE_FREE:
        GameManager.select_car(GameManager.next_owned_car())
        get_tree().reload_current_scene()
        return

    if manager.state == RaceManager.State.RACING:
        if player_car.is_upside_down():
            _upside_time += delta
        else:
            _upside_time = 0.0
        if _upside_time > 2.5 or player_car.global_position.y < -20.0:
            _respawn_player()

    var r := manager.player
    var total := manager.racers.size()
    var lap_shown := r.lap + 1
    if manager.laps > 0:
        lap_shown = mini(lap_shown, manager.laps)
    var best := r.best_lap
    var saved := SaveManager.get_best_lap(GameManager.track_index)
    if saved > 0.0 and (best < 0.0 or saved < best):
        best = saved

    hud.set_speed(player_car.speed_kmh)
    hud.set_race_info(manager.get_position(r), total, lap_shown, manager.laps, manager.current_lap_time(r), best)
    hud.set_nitro(player_car.nitro.ratio(), player_car.nitro.active)
    hud.update_drift(player_car.drift)
    speed_lines.set_intensity(clampf((player_car.speed_kmh - 110.0) / 160.0, 0.0, 1.0) * 0.6 + player_car.nitro.boost * 0.7)


func _on_player_finished() -> void:
    pause_menu.set_can_pause(false)
    await get_tree().create_timer(1.5).timeout
    _show_results()


func _show_results() -> void:
    var quick := GameManager.mode == GameManager.MODE_QUICK
    var lines := PackedStringArray()
    var player_pos := 1
    var place := 1
    for r in manager.get_ranking():
        var t: String = RaceHud.format_time(r.finish_time) if r.finished else "--"
        var nm := "YOU" if r.is_player else r.racer_name
        lines.append("%d.   %s   %s" % [place, nm, t])
        if r.is_player:
            player_pos = place
        place += 1

    var best := manager.player.best_lap
    var record := false
    if best > 0.0:
        record = SaveManager.submit_lap(GameManager.track_index, best)
    var coins := 100
    if quick:
        coins = [500, 300, 200][player_pos - 1] if player_pos <= 3 else 100
        if player_pos == 1:
            SaveManager.races_won += 1
    if record:
        coins += 100
    SaveManager.add_coins(coins)

    var footer := "+%d COINS" % coins
    if best > 0.0:
        footer += "     BEST LAP %s" % RaceHud.format_time(best)
    if record:
        footer += "  (NEW RECORD!)"
    var title := "RACE RESULTS" if quick else "TIME TRIAL COMPLETE"
    var good := not quick or player_pos <= 3
    if GameManager.career_event >= 0:
        var ev := GameManager.career_event
        var info := SaveManager.career_submit(ev, player_pos)
        var passed: bool = info["passed"]
        var career_coins: int = int(info["coins"]) if passed else 100
        if record:
            career_coins += 100
        SaveManager.add_coins(career_coins - coins)   # replaces the quick-race reward
        coins = career_coins
        title = "EVENT PASSED" if passed else "EVENT FAILED"
        good = passed
        footer = "+%d COINS" % coins
        if not passed:
            footer += "     NEED TOP %d" % int(CareerData.EVENTS[ev]["req_pos"])
        if int(info["unlocked_track"]) >= 0:
            footer += "\nUNLOCKED: " + TrackData.track_name(int(info["unlocked_track"]))
        if str(info["unlocked_car"]) != "":
            footer += "\nUNLOCKED CAR: " + str(CarData.CARS[CarData.index_of(str(info["unlocked_car"]))]["name"]).to_upper()
        results.set_next("NEXT EVENT" if (passed and ev + 1 < CareerData.count()) else "CAREER LIST", true)
    AudioManager.play_sfx("win" if good else "lose", -2.0)
    results.show_results(title, lines, footer)


func _on_next_track() -> void:
    var ev := GameManager.career_event
    if ev >= 0:
        if SaveManager.career_passed(ev) and ev + 1 < CareerData.count():
            CareerData.apply(ev + 1)
            get_tree().reload_current_scene()
        else:
            get_tree().change_scene_to_file("res://scenes/career.tscn")
        return
    GameManager.track_index = GameManager.next_unlocked_track(GameManager.track_index)
    get_tree().reload_current_scene()
