# Manual test checklist (run on phone, tick each item)

- [ ] Game starts, main menu shows, every button cycles its option
- [ ] Quick Race: 3-2-1-GO, cars cannot move before GO
- [ ] Car drives, steers, brakes, reverses; wheels spin
- [ ] Nitro and drift (handbrake) work; HUD bar and score update
- [ ] 5 AI cars follow the track, brake in corners, finish laps
- [ ] POS and LAP counters on the HUD are correct
- [ ] Finishing shows the results screen; Retry / Next track / Menu work
- [ ] Time Trial: best lap is saved and shown after restarting the app
- [ ] Free Drive: CAR button switches car, no countdown, no AI
- [ ] RESET puts the car back on the track
- [ ] Both tracks load; frame rate is acceptable (note device model)

## Phase 4 (garage)
- [ ] MENU -> GARAGE opens; the car shows and rotates by itself; drag rotates; pinch / +/- zoom
- [ ] < > cycles all 8 cars, stats bars change, locked cars show price
- [ ] BUY is disabled when coins are too low; buying deducts coins and unlocks upgrades/paint
- [ ] SELECT, then BACK: menu CAR shows the selected car; race uses it
- [ ] Upgrade buttons raise the level pips, deduct coins, stats change; MAX level disables the button
- [ ] Paint and wheel colours change the car; they persist after restarting the app
- [ ] An upgraded car is clearly faster / grips better than stock in a Time Trial
- [ ] CAR button in menu / C in Free Drive skip cars you do not own
- [ ] AI cars are from your tier (+/- 1)

## Phase 5A (audio)
- [ ] Menu: music starts a few seconds after launch; SOUND / MUSIC buttons cycle 0-100% and the level is kept after restarting the app
- [ ] Countdown: beep on 3, 2, 1 and a higher GO; engine revs while holding gas at the start line
- [ ] Engine pitch rises with speed, drops after each gear shift; AI cars are louder when close
- [ ] Drift / handbrake: tyre screech starts and stops with the slide
- [ ] Nitro: whoosh fades in and out with the boost
- [ ] Crash: hit sound, louder for harder crashes
- [ ] Finish: win jingle (top 3 or time trial) or lose sound; race music plays during the race, menu music after returning
- [ ] Home button: sound stops, returns when the app is reopened
- [ ] Note any lag at launch or crackling (device model)

## Phase 5B (lighting / environment / optimization)
- [ ] Menu: GRAPHICS cycles LOW/MEDIUM/HIGH, FPS toggles 30/60; both kept after restarting the app; menu still fits on screen
- [ ] Grand Loop = daylight with clouds; Technical Circuit = sunset
- [ ] Street lamps, rocks and bushes along the road; no lamp or rock inside the road or walls
- [ ] Sunset: headlights light the road ahead (Medium/High); lamps glow
- [ ] No visible popping of trees at distance (note if you see it)
- [ ] LOW is clearly smoother than HIGH on your phone (note device model, FPS on each)
- [ ] 30 FPS option really caps the frame rate
- [ ] Smoke and nitro flames still appear on all three quality levels

## Phase 7 (maps, career, pause, tilt)
- [ ] Menu fits the screen (two columns); CAREER, GARAGE, START all work
- [ ] Career list: only event 1 open; passing it opens event 2; unlocks show in the footer of the results
- [ ] Failing an event (finish below required place) pays 100 coins and does not unlock
- [ ] NEXT EVENT starts the next event; CAREER LIST returns to the list
- [ ] Quick Race TRACK button skips locked tracks; new tracks appear after the career unlocks
- [ ] Coastal Highway: ocean around sand, palms, bright sky; Desert Run: cacti, dunes; Night City: dark, buildings, neon, headlights
- [ ] No building / dune on the road; note FPS on each map and quality level
- [ ] II button pauses (car, timer, countdown stop); Resume continues; Restart and Quit work; Android back button toggles pause
- [ ] Pause happens automatically when switching to another app
- [ ] Tilt ON: tilt steers the car; wrong direction -> INVERTED; sensitivity changes the amount; state kept after restart

## Phase 8 (rain, tunnels, cockpit)
- [ ] WEATHER: RAIN shows streaks, grey sky, fog; kept after restarting the app; no big FPS drop (note device / quality)
- [ ] In rain the car slides a bit more and brakes later than in CLEAR
- [ ] Each track has its tunnel(s): car drives through, no lamp post or tree poking inside, ceiling lights visible
- [ ] VIEW cycles 4 views; cockpit shows the hood and nothing blocks the view

## Phase 9 (car shapes, rain sound)
- [ ] Garage: the 8 cars look clearly different (cabin size, wing, intakes); Hypercar has fins and a high wing
- [ ] Cockpit view works on every car (eye inside the cabin, nothing blocking)
- [ ] WEATHER: RAIN plays a rain loop a few seconds after the app start; it stops when paused

## Phase 10 (menus, rewards, layout, perfect start)
- [ ] Main menu fits the screen: CAREER/START left, GARAGE/SETTINGS/PROFILE/REWARDS right
- [ ] SETTINGS: every button cycles and is kept after restarting the app; BACK returns to the menu
- [ ] Touch size 80% / 125% changes the on-screen buttons; LEFT-HANDED mirrors the bottom buttons (steer on the right, pedals on the left)
- [ ] PROFILE shows the right numbers (coins, wins, cars, career, best laps)
- [ ] REWARDS: daily claim works once per day and pays coins; the menu shows (NEW!) only when claimable; milestones unlock at 5/15/40 wins
- [ ] Perfect start: pressing GAS just before GO gives the message and extra nitro; holding from the beginning does not

## Phase 11
- [ ] Countdown: camera orbits the car, ends behind it exactly when GO appears; no jump at GO
- [ ] Minimap matches the track shape, your dot moves correctly, AI dots move; does not overlap the buttons
- [ ] Drive backwards on the track: WRONG WAY shows; it disappears when you turn around

## Phase 12
- [ ] SETTINGS > RESOLUTION cycles AUTO / 60 / 75 / 100% and is kept; lower values make the image softer and FPS higher
- [ ] Desert Run: dust behind all cars when fast; no dust on other tracks

## Phase 13
- [ ] Time Trial: finish a lap, the next lap shows a transparent blue ghost car repeating your best lap
- [ ] A slower lap does not replace the ghost; a faster one does; the ghost is still there after restarting the app
- [ ] Quick Race and Free Drive show no ghost

## Phase 14 (GLB cars)
- [ ] Add one .glb with tools/add_car.sh: it shows in the garage and in the race, right size, on the ground, facing forward
- [ ] If backwards: set glb_rotation_y to 180 for that car and check again
- [ ] Cars without a .glb still use the built-in body
