# Monkey Miles — demo plan

Goal: a 3–4 minute demo that takes judges from **creating a monkey** (egg → hatch) to **living a day with it** (steps, vitals, breathing, reminders, growth) and ends on **real watch data**. Everything shown must work every time, on a laptop simulator and on a fēnix 7 Pro.

## 1. What the research says (and what it means for us)

| Finding | Consequence for the demo |
|---|---|
| Judges remember one clear story; a polished demo of a few features beats a broken demo of many. Demos run 2–5 min, problem in the first 20 s. ([AngelHack](https://angelhack.com/blog/10-tips-to-help-you-rock-your-next-hackathon-demo/), [Reskilll](https://blogs.reskilll.com/hackathon-demo-presentation-tips-pitch-3-minutes-win-2026/), [JetBrains](https://blog.jetbrains.com/ai/2026/06/how-to-win-a-hackathon-notes-from-the-judging-table/)) | One narrative: "a day with Momo". Scripted scenes, not random menu tours. |
| Live demos break; rehearse to find break points and keep a backup video. (same sources) | Story mode is deterministic and offline. Record a backup video of the full run. |
| Successful pet-fitness apps start by **hatching**, then the pet **visibly grows** with consistency; streak milestones and cosmetics keep people coming back. ([CalPets](https://www.trendhunter.com/trends/calpets), [Streaksy](https://peerpush.net/p/streaksy-app), [Mochi](https://apps.apple.com/bb/app/id6759009775), [Tep](https://techcrunch.com/2015/08/31/tep-is-an-adorable-fitness-tracking-app-that-works-like-a-tamagotchi)) | Egg → baby → kid → adult → crowned, driven by level; hatching is the emotional hook of the setup. |
| The simulator can drive steps live: *Simulation → Activity Monitoring → Set Steps Per Minute*; steps 0 + *Fast Forward* fills the move bar (60/75/90/105/120 min). FIT *Simulate Data* covers sensors. ([forum](https://forums.garmin.com/developer/connect-iq/f/discussion/247/movebarlevel---how-to-simulate), [forum](https://forums.garmin.com/developer/connect-iq/f/discussion/6595/move-bar-simulator), [forum](https://forums.garmin.com/developer/connect-iq/f/discussion/3794/playback-fit-file-in-simulator/28917)) | Live part: set 120 steps/min and watch the counter climb. |
| Simulator gaps: active minutes not set, odd history `startOfDay`, no midnight reset. ([forum](https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-activeminutesday-activeminutesweek-are-not-set-in-simulator), [forum](https://forums.garmin.com/developer/connect-iq/i/bug-reports/smulator-activitymonitor-history-startofday-is-incorrect-successive-entries-are-1-second-apart)) | Stress, Pulse Ox, cold, streaks, evolution come from the scripted story, clearly labelled. Live part sticks to steps (+ move bar). |
| The fēnix 7 Pro (API 5.2.0, SDK 9.1.0) exposes no sleep data; a sleep-score complication is reported only from API 6.0.2 on newer devices. Notifications aren't listed for fēnix 7 Pro; background wakes need a real watch to judge. (see ARCHITECTURE.md) | Say it honestly in the pitch: we show *low morning recharge* from Body Battery, never a sleep claim; the reminder is shown as a story screen (the same screen opens on the watch after a background wake). |

## 2. The demo in five chapters

Story mode starts **by itself right after hatching** (or Hold UP → *Story demo*) and plays a scripted day, marked by a STORY badge at the top; **DOWN** = next scene, **UP** = previous, **BACK** = leave. Full-screen moments open automatically when their scene is entered.

| Time | Chapter / screen | What the presenter says / does | Real or scripted |
|---|---|---|---|
| 0:00–0:20 | (slide) | Problem: step totals are easy to ignore; long sitting, stress, poor recovery. | — |
| **0:20–1:15** | **1. Create your monkey** | | Real app flow |
| | Welcome: wobbling egg, "Hatch your companion" | "Everyone starts with an egg." START. | |
| | Name → Fur (UP/DOWN recolours the egg's spots) → Goals (Steps, Active min, Floors; each with a target) → Done | "You choose what feeds your monkey." | |
| | Hatching: wobble, two cracks, baby pops out of its shell with sparkles, "Momo hatched!" | Pause for the reaction. START → the story begins at 07:30. | |
| **1:15–2:00** | **2. Steps, states and reminders** (story scenes 0–4) | | Scripted, labelled STORY |
| | 07:30 *Low morning recharge* → yawning monkey, "Body Battery 38/100" | "This watch doesn't share sleep data with apps, so we don't guess sleep — Body Battery says the morning recharge was low." | |
| | 10:30 still 90 min → **Reminder screen**: buzz, shaking tired monkey, "Momo needs you!" | "This is what the background check sends — on the watch it wakes the app." BACK = later. | |
| | 10:40 walk → steps **count up**, monkey jogs; 10:45 *I'm back! +20 XP* | | |
| | 13:00 under half → **Reminder screen** (hungry, banana dropped) | "Half the day, under half the goal." | |
| **2:00–2:30** | **3. Stress and breathing** (scenes 5–6) | | |
| | 15:10 stressed → **Reminder screen** → START → **breathing screen** (ring + monkey breathe, live HR) | One 16-s round in story mode; START or tap skips anytime. BACK. | Breathing screen is real |
| | 15:12 *Calm again* | "Heart rate only counts as stress when you're not moving." | |
| | 16:30 **Climb milestone**: Momo plants a flag, "Climb milestone +30", then the **sunglasses slide on** ("Sunglasses earned!") and stay on | "Garmin's own floor count says we climbed — Momo earned shades." | Scripted; live uses the same rule on real floors |
| | 18:00 goals met: eats, bounces, +XP, **evolves baby → kid** (still in shades); 22:30 asleep, quiet hours | | |
| **2:30–2:50** | **4. A missed day** (scene 10) | | |
| | **Day recap**: sad monkey, 35 % bar, XP counting down −50, streak flame goes out, "Tomorrow is a new banana" | "Missing costs a little XP — never shame, always a way back." | |
| **2:50–3:20** | **5. Progress — the monkey and you** (scene 11) | | |
| | **Journey**: egg → baby → kid → adult → king, one stage every 1.6 s with a buzz, next to *your* weekly steps chart rising (+100 % since week 1) | "The monkey grows because *you* grew." | |
| 3:20–3:40 | Live mode on simulator or watch | *Simulation → Activity Monitoring → 120 steps/min*: real counter climbs. Show the glance. | Real data |
| 3:40–4:00 | (slide) | Battery (no sensors in background, 30-min checks, history only), privacy (on-watch), next steps. | — |

Replay the sunglasses moment any time: in story press UP once (back to 15:12) and DOWN again (they come off and slide on again); live unlocks and XP are never touched.

Extra scenes after the journey (12–19) show the remaining states for Q&A: still 2 h, exhausted, alert, breath low (twice), cold, hot, routine.

Backup: a recorded video of chapters 1–5, and the watch with a pre-created monkey in case the laptop fails. *New game* (menu) brings the egg back for the next run.

## 3. Product changes

| # | Feature | Why | Owner | Status |
|---|---|---|---|---|
| 1 | Growth stages egg → baby (Lv 1–2, smaller) → kid (3–5, leaf) → adult (6–9, headband) → king (10+, crown) | Visible progress; hooks the teammate's art | dev | done (placeholder art) |
| 2 | Onboarding: Welcome egg → Name → Fur preview → Goals → Hatch | Strong first minute | dev | done |
| 3 | Story mode: scripted day + day 2 + journey, clock captions, count-up steps, evolution on level-up | Deterministic demo of every chapter | dev | done |
| 4 | Reminder screen (buzz, shaking monkey, START = act / breathe, BACK = later); also opens when the watch launches the app from a background reminder | Chapter 2–3; real behaviour on the watch | dev | done |
| 5 | Day recap for a missed day (XP drain, streak out, kind wording); also shown in live mode after a missed day | Chapter 4 | dev | done |
| 6 | Journey screen: story (egg → king + rising weekly steps) and live (current stage + real last 7 days) — menu *Journey* | Chapter 5 | dev | done |
| 7 | New game (menu, Yes/No) | Repeatable demos | dev | done |
| 8 | Stage art per pose (egg, baby, kid, adult, king) | Visual quality | teammate | open |
| 9 | Demo runbook rehearsal + backup video | Reliability | presenter | open |

Live mode keeps working exactly as before; story mode never writes the real monkey's XP.

### More ideas worth adding (ranked by demo value / effort)

| Idea | Why it engages | Effort |
|---|---|---|
| **Comeback challenge** after a missed day: tomorrow's goal pays ×2 | Turns a loss into a reason to come back (loss aversion without shame) | S |
| **Badges** (first walk, 3-day streak, breath master, explorer) shown on the Journey screen | Collectibles; easy to show in a demo | M |
| **Weekly recap** every Monday (best day, streak, stage progress) | Long-term engagement, the "you" story | M |
| **Auto-play** for story mode (scene every ~6 s) | Hands-free demo while talking | S |
| **Treats / cosmetics** bought with XP (hats, colours) | Classic pet-app retention loop | L |
| **Friends' monkeys** via phone companion | Social motivation | L (needs phone app) |

## 4. Art contract (for the teammate)

The app draws pixel art from **text grids** so it can recolour fur and stay tiny in memory. Two ways to deliver:

1. **Preferred — text patches** in `source/views/` (same format as `MonkeyArt.mc`): rows of characters, one per pixel.
2. **PNG** (Aseprite/Piskel), 1 px = 1 art pixel, only the palette colours below, transparent background. We convert to text patches with a small script.

Palette characters (64-colour MIP screen):

| Char | Colour | Use |
|---|---|---|
| `.` | transparent | |
| `K` | `#000000` | outline, eyes |
| `B` | fur (recoloured: brown `#AA5500`, golden `#FFAA00`, silver `#AAAAAA`, shadow `#555555`) | body fur |
| `D` | dark fur (`#550000` / `#AA5500` / `#555555` / `#000000`) | arms, shading |
| `T` | `#FFAA55` | face, belly, hands, feet |
| `P` | `#FFAAAA` | ears, cheeks |
| `W` | `#FFFFFF` | eye shine, Zzz, teeth |
| `G` / `Y` | `#55AA00` / `#FFFF00` | banana green / ripe, leaf / crown |
| `R` | `#AA0000` | mouth, headband, flag |
| `C` | `#55AAFF` | ice, sweat, egg spots (night) |

Sizes (drawn at ×4 on the 260×260 screen; ×3 for baby):

| Stage | Grid (w×h) | Shown at | Needed sprites |
|---|---|---|---|
| Egg | 16×20 | ×4 | idle, wobble-left, wobble-right, crack-1, crack-2, hatched shell halves |
| Baby | 24×23 (current body) | ×3 | all poses below |
| Kid | 24×23 | ×4 | all poses below |
| Adult / crowned | up to 28×26 | ×4 | all poses below (crown/headband can stay as accessories) |

Poses per stage (names match `MonkeyStatus.POSE_*`): relax, perk, eat, tired, asleep, alert, stressed, jog, jog2, stretch, breathe, pant, cold, hot, climb, bored. Rules: keep the **same body silhouette** within a stage and change only face/arms/tail/props, keep important details at least 2 px wide, leave 4 px free at the top for `Z`/`!`/crown, and keep the body centre at column 12 (or tell us the new centre).

Preview: run `python tools/preview_art.py` (to be added) to render every pose to a PNG before committing.

## 5. Technical design

- `Growth` (model): `stageFor(level, hatched)` → EGG / BABY / KID / ADULT / CROWNED; sprite set + scale per stage. Level-up across a boundary raises an *evolved* event (banner + sparkle animation).
- `MonkeyModel`: adds `name`, `hatched`; `newGame()` clears storage for a fresh egg.
- Onboarding views (`views/setup/`): `WelcomeView` (egg wobble), `FurPickerView` (UP/DOWN cycles fur with live sprite preview, START confirms), goals via the existing menus, `HatchView` (crack frames → baby, then the dashboard).
- Story mode: a scene table (time of day, goal %, vitals, effect, caption, duration) replacing the old demo table; count-up of steps between scenes; a reminder overlay that imitates the watch's "open app?" prompt; scenes may hand off to the real breathing screen.
- Everything new stays in the 768 KB app budget; sprite compile is lazy (watchdog).

## 6. Rehearsal checklist

- [ ] `.\scripts\ciq.ps1 build` and `test` green on the demo laptop.
- [ ] Simulator: fēnix 7 Pro, app data reset, *Activity Monitoring* steps/min = 0 before start.
- [ ] Run setup → story → live three times in a row without touching code.
- [ ] Watch: sideload `bin\GarminStarter.prg`, pre-created monkey as fallback.
- [ ] Backup video recorded and on a second device.
- [ ] Answers ready: battery (no sensors in background, 30-min checks), privacy (all on-watch), sleep (no API → Body Battery proxy), medical wording (never diagnostic).
