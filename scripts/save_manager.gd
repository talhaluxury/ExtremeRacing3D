extends Node
## Autoload: local save file (user://save.cfg). Works fully offline.
## Holds coins, records, owned cars, upgrades and paint/wheel choices.

const PATH := "user://save.cfg"
## [wins needed, coins]
const MILESTONES := [[5, 1000], [15, 3000], [40, 8000]]

var coins: int = 0
var races_won: int = 0
var selected_id: String = "sports_coupe"
var reward_streak: int = 0

var _cfg := ConfigFile.new()


func _ready() -> void:
    if _cfg.load(PATH) == OK:
        coins = int(_cfg.get_value("profile", "coins", 0))
        races_won = int(_cfg.get_value("profile", "races_won", 0))
        selected_id = str(_cfg.get_value("profile", "selected_car", "sports_coupe"))
        reward_streak = int(_cfg.get_value("rewards", "streak", 0))
    if not is_owned(selected_id) or CarData.index_of(selected_id) < 0:
        selected_id = str(CarData.CARS[0]["id"])
    GameManager.selected_car = CarData.index_of(selected_id)


func save_game() -> void:
    _cfg.set_value("profile", "coins", coins)
    _cfg.set_value("profile", "races_won", races_won)
    _cfg.set_value("profile", "selected_car", selected_id)
    _cfg.save(PATH)


func add_coins(amount: int) -> void:
    coins += amount
    save_game()


# ---------------------------------------------------------------- records

func get_best_lap(track: int) -> float:
    return float(_cfg.get_value("best_lap", str(track), -1.0))


## Returns true if this lap time is a new personal record for the track.
func submit_lap(track: int, lap_time: float) -> bool:
    var best := get_best_lap(track)
    if best < 0.0 or lap_time < best:
        _cfg.set_value("best_lap", str(track), lap_time)
        save_game()
        return true
    return false


# ---------------------------------------------------------------- garage

func is_owned(id: String) -> bool:
    if id == str(CarData.CARS[0]["id"]):
        return true   # the starter car is always owned
    return bool(_cfg.get_value("owned", id, false))


func buy_car(id: String) -> bool:
    var idx := CarData.index_of(id)
    if idx < 0 or is_owned(id):
        return false
    var price: int = int(CarData.CARS[idx]["price"])
    if coins < price:
        return false
    coins -= price
    _cfg.set_value("owned", id, true)
    save_game()
    return true


func select_car(id: String) -> void:
    if is_owned(id):
        selected_id = id
        save_game()


func get_upgrade(id: String, key: String) -> int:
    return clampi(int(_cfg.get_value("upgrades", id + "_" + key, 0)), 0, CarData.MAX_LEVEL)


func buy_upgrade(id: String, key: String) -> bool:
    if not is_owned(id):
        return false
    var lvl := get_upgrade(id, key)
    if lvl >= CarData.MAX_LEVEL:
        return false
    var cost := CarData.upgrade_cost(lvl)
    if coins < cost:
        return false
    coins -= cost
    _cfg.set_value("upgrades", id + "_" + key, lvl + 1)
    save_game()
    return true


## -1 means the stock colour of the car.
func get_paint(id: String) -> int:
    return int(_cfg.get_value("paint", id, -1))


func set_paint(id: String, index: int) -> void:
    _cfg.set_value("paint", id, index)
    save_game()


func get_wheel(id: String) -> int:
    return int(_cfg.get_value("wheels", id, -1))


func set_wheel(id: String, index: int) -> void:
    _cfg.set_value("wheels", id, index)
    save_game()


# ---------------------------------------------------------------- tracks + career

func is_track_unlocked(i: int) -> bool:
    return i < 2 or bool(_cfg.get_value("tracks", str(i), false))


func unlock_track(i: int) -> void:
    if not is_track_unlocked(i):
        _cfg.set_value("tracks", str(i), true)
        save_game()


## Best finishing position in a career event, 0 = never finished it.
func career_best_pos(event: int) -> int:
    return int(_cfg.get_value("career", str(event), 0))


func career_passed(event: int) -> bool:
    var e: Dictionary = CareerData.EVENTS[event]
    var p := career_best_pos(event)
    return p > 0 and p <= int(e["req_pos"])


func career_event_open(event: int) -> bool:
    return event == 0 or career_passed(event - 1)


## Stores the result. Returns {"passed", "first", "coins", "unlocked_track", "unlocked_car"}.
## Coins are added by the caller together with the other race rewards.
func career_submit(event: int, pos: int) -> Dictionary:
    var e: Dictionary = CareerData.EVENTS[event]
    var was_passed := career_passed(event)
    var passed := pos <= int(e["req_pos"])
    var best := career_best_pos(event)
    if best == 0 or pos < best:
        _cfg.set_value("career", str(event), pos)
    var out := {"passed": passed, "first": passed and not was_passed, "coins": 0, "unlocked_track": -1, "unlocked_car": ""}
    if passed:
        out["coins"] = int(e["reward"]) if not was_passed else floori(float(e["reward"]) / 4.0)
        if not was_passed:
            var ut: int = int(e["unlock_track"])
            if ut >= 0:
                unlock_track(ut)
                out["unlocked_track"] = ut
            var uc: String = str(e["unlock_car"])
            if uc != "" and not is_owned(uc):
                _cfg.set_value("owned", uc, true)
                out["unlocked_car"] = uc
    save_game()
    return out


# ---------------------------------------------------------------- rewards

func _today() -> int:
    return int(Time.get_unix_time_from_system() / 86400.0)   # UTC day number


func daily_reward_available() -> bool:
    return int(_cfg.get_value("rewards", "last_day", -1)) != _today()


## Streak the player will have after claiming now (1 if the streak was broken).
func next_streak() -> int:
    var last := int(_cfg.get_value("rewards", "last_day", -1))
    if last == _today() - 1:
        return reward_streak + 1
    return 1


func daily_reward_amount() -> int:
    return 200 + 100 * mini(next_streak(), 7)


## Returns the coins paid (0 if already claimed today).
func claim_daily_reward() -> int:
    if not daily_reward_available():
        return 0
    var amount := daily_reward_amount()
    reward_streak = next_streak()
    _cfg.set_value("rewards", "last_day", _today())
    _cfg.set_value("rewards", "streak", reward_streak)
    add_coins(amount)
    return amount


func milestone_claimed(i: int) -> bool:
    return bool(_cfg.get_value("rewards", "milestone_" + str(i), false))


func claim_milestone(i: int) -> bool:
    var m: Array = MILESTONES[i]
    if milestone_claimed(i) or races_won < int(m[0]):
        return false
    _cfg.set_value("rewards", "milestone_" + str(i), true)
    add_coins(int(m[1]))
    return true
