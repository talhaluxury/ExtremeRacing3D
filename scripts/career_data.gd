class_name CareerData
extends RefCounted
## Career events. An event is passed when the player finishes in `req_pos` or
## better. Passing the first time pays `reward`, repeats pay a quarter.
## `unlock_track` / `unlock_car` (-1 / "" = none) are given on the first pass.
## Event n+1 opens when event n is passed.

const EVENTS := [
    {"name": "ROOKIE CUP", "track": 0, "laps": 2, "diff": 0, "req_pos": 3, "reward": 600, "unlock_track": -1, "unlock_car": ""},
    {"name": "TECHNICAL TEST", "track": 1, "laps": 2, "diff": 0, "req_pos": 3, "reward": 700, "unlock_track": 2, "unlock_car": ""},
    {"name": "COASTAL CRUISE", "track": 2, "laps": 2, "diff": 0, "req_pos": 3, "reward": 800, "unlock_track": 3, "unlock_car": ""},
    {"name": "DUNE DASH", "track": 3, "laps": 2, "diff": 1, "req_pos": 3, "reward": 1000, "unlock_track": 4, "unlock_car": "muscle_car"},
    {"name": "NEON NIGHTS", "track": 4, "laps": 2, "diff": 1, "req_pos": 3, "reward": 1200, "unlock_track": -1, "unlock_car": ""},
    {"name": "LOOP CHALLENGE", "track": 0, "laps": 3, "diff": 1, "req_pos": 2, "reward": 1500, "unlock_track": -1, "unlock_car": "luxury_sedan"},
    {"name": "TECH MASTER", "track": 1, "laps": 3, "diff": 1, "req_pos": 2, "reward": 1800, "unlock_track": -1, "unlock_car": ""},
    {"name": "COAST SPRINT", "track": 2, "laps": 3, "diff": 2, "req_pos": 2, "reward": 2200, "unlock_track": -1, "unlock_car": "supercar"},
    {"name": "DESERT KING", "track": 3, "laps": 3, "diff": 2, "req_pos": 2, "reward": 2600, "unlock_track": -1, "unlock_car": ""},
    {"name": "NIGHT CHAMPION", "track": 4, "laps": 3, "diff": 2, "req_pos": 1, "reward": 5000, "unlock_track": -1, "unlock_car": "hypercar"},
]


static func count() -> int:
    return EVENTS.size()


## Sets GameManager up for event `i` (the caller then loads the race scene).
static func apply(i: int) -> void:
    var e: Dictionary = EVENTS[i]
    GameManager.career_event = i
    GameManager.mode = GameManager.MODE_QUICK
    GameManager.track_index = int(e["track"])
    GameManager.laps = int(e["laps"])
    GameManager.difficulty = int(e["diff"])
