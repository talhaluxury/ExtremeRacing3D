extends Control
## Daily reward (grows with a login streak) and race-win milestones.

var _box: VBoxContainer
var _coins: Label


func _ready() -> void:
    _box = UiKit.screen(self, "REWARDS")
    _build()


func _build() -> void:
    # rebuild everything below the header after each claim
    var keep := 1   # the header row
    while _box.get_child_count() > keep:
        var c := _box.get_child(_box.get_child_count() - 1)
        _box.remove_child(c)
        c.queue_free()

    _coins = UiKit.label(_box, "COINS:  %d" % SaveManager.coins, 34, Color(1.0, 0.85, 0.3))

    UiKit.label(_box, "DAILY REWARD", 32, Color(1.0, 0.75, 0.15))
    if SaveManager.daily_reward_available():
        var amount := SaveManager.daily_reward_amount()
        var b := UiKit.button(_box, "CLAIM  +%d COINS   (day %d of streak)" % [amount, SaveManager.next_streak()], _claim_daily, 700.0, 70.0, 28)
        b.modulate = Color(0.6, 1.0, 0.6)
    else:
        UiKit.label(_box, "Already claimed today. Come back tomorrow!   Streak: %d day(s)" % SaveManager.reward_streak, 26)
    UiKit.label(_box, "A longer streak pays more (up to day 7).", 20, Color(0.7, 0.7, 0.75))

    UiKit.label(_box, "")
    UiKit.label(_box, "RACE WIN MILESTONES   (wins: %d)" % SaveManager.races_won, 32, Color(1.0, 0.75, 0.15))
    for i in SaveManager.MILESTONES.size():
        var m: Array = SaveManager.MILESTONES[i]
        var need: int = m[0]
        var reward: int = m[1]
        if SaveManager.milestone_claimed(i):
            UiKit.label(_box, "%d wins:  +%d coins   CLAIMED" % [need, reward], 26, Color(0.6, 0.9, 0.6))
        elif SaveManager.races_won >= need:
            var b := UiKit.button(_box, "%d wins:  CLAIM +%d COINS" % [need, reward], _claim_milestone.bind(i), 700.0, 60.0, 26)
            b.modulate = Color(0.6, 1.0, 0.6)
        else:
            UiKit.label(_box, "%d wins:  +%d coins   (%d to go)" % [need, reward, need - SaveManager.races_won], 26, Color(0.8, 0.8, 0.85))


func _claim_daily() -> void:
    SaveManager.claim_daily_reward()
    AudioManager.play_sfx("win", -6.0)
    _build()


func _claim_milestone(i: int) -> void:
    SaveManager.claim_milestone(i)
    AudioManager.play_sfx("win", -6.0)
    _build()
