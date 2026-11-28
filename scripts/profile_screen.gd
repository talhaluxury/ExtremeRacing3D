extends Control
## Player profile: coins, wins, garage and career progress, best laps.


func _ready() -> void:
    var box := UiKit.screen(self, "PROFILE")
    var cars_owned := 0
    for c: Dictionary in CarData.CARS:
        if SaveManager.is_owned(str(c["id"])):
            cars_owned += 1
    var events_passed := 0
    for i in CareerData.count():
        if SaveManager.career_passed(i):
            events_passed += 1
    var tracks_open := 0
    for i in TrackData.count():
        if SaveManager.is_track_unlocked(i):
            tracks_open += 1

    UiKit.label(box, "COINS:  %d" % SaveManager.coins, 36, UITheme.ACCENT_2)
    UiKit.label(box, "RACES WON:  %d" % SaveManager.races_won, 30)
    UiKit.label(box, "CARS OWNED:  %d / %d" % [cars_owned, CarData.CARS.size()], 30)
    UiKit.label(box, "CAREER EVENTS PASSED:  %d / %d" % [events_passed, CareerData.count()], 30)
    UiKit.label(box, "TRACKS UNLOCKED:  %d / %d" % [tracks_open, TrackData.count()], 30)
    UiKit.label(box, "")
    UiKit.label(box, "BEST LAPS", 32, UITheme.ACCENT_2)
    for i in TrackData.count():
        var t := RaceHud.format_time(SaveManager.get_best_lap(i))
        var text := "%s:   %s" % [TrackData.track_name(i), t]
        if not SaveManager.is_track_unlocked(i):
            text = "%s:   LOCKED" % TrackData.track_name(i)
        UiKit.label(box, text, 26)
