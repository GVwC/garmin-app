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
| Connect IQ has no sleep API; notifications aren't listed for fēnix 7 Pro; background wakes need a real watch to judge. (see ARCHITECTURE.md) | Say it honestly in the pitch: Body Battery stands in for sleep; the reminder prompt is shown as a story overlay. |

## 2. The demo, minute by minute

| Time | Screen | What the presenter says / does | Real or scripted |
|---|---|---|---|
| 0:00–0:20 | (slide) | Problem: step totals are easy to ignore; long sitting, stress, short nights. | — |
| 0:20–0:35 | **Welcome**: wobbling egg, "Hatch your companion" | "Everyone starts with an egg." START. | Real app flow |
| 0:35–1:05 | **Name → Fur (live preview) → Goals → Targets** | Pick *Momo*, golden fur, Steps 5,000 + Active 30 min. "You choose what feeds your monkey." | Real app flow |
| 1:05–1:15 | **Hatching**: egg cracks, baby Momo pops out, "Momo hatched!" | Pause for the reaction. | Real app flow |
| 1:15–2:45 | **Story mode — "A day with Momo"** (clock in the corner, DOWN = next scene, auto-play possible) | | Scripted, labelled STORY |
| | 07:30 Low recharge (Body Battery 38) | "Short night — Momo is yawning; it suggests easing in." | |
| | 10:30 Still 90 min → reminder overlay | "The background check noticed. A 5-min walk resets it." | |
| | 10:40 Walk: steps count up live, Momo jogs, *I'm back! +20 XP* | | |
| | 13:00 Midday: under half → "Momo is hungry" | | |
| | 15:10 Stressed (HR up, not moving) → START → **breathing screen** (real, 1 round) → *Calm again* | Show the breathing screen for ~16 s. | Breathing screen is real |
| | 18:00 Goals met: eats banana, bounce, +XP, streak flame | | |
| | 18:01 Level up → **evolution** baby → kid | "Consistency grows your monkey." | |
| | 22:30 Night: sleeps, quiet hours | "No reminders at night." | |
| 2:45–3:20 | **Live mode** on simulator (or watch) | Set *Activity Monitoring → 120 steps/min*: counter climbs, bar fills, pose changes. Show the **glance** in the widget list. | Real data |
| 3:20–3:40 | (slide) | Battery: no sensors in background, 30-min checks, history only. Next: sleep via cloud API, social. | — |

Backup: a recorded video of 0:20–3:20, and the watch with a pre-created monkey in case the laptop fails.

## 3. Product changes to build

| # | Feature | Why | Owner | Status |
|---|---|---|---|---|
| 1 | **Growth stages** egg → baby (Lv 1–2) → kid (3–5) → adult (6–9) → crowned (10+) | Visible progress; hooks the teammate's art | dev | building |
| 2 | **Onboarding**: Welcome egg → Name → Fur with live preview → Goals → Hatch animation | Strong first minute | dev | building |
| 3 | **Story mode** "A day with Momo": timed scenes with clock, captions, count-up steps, reminder overlay, breathing hand-off, evolution scene | Deterministic demo of every state | dev | next |
| 4 | **New game** (menu, with confirmation) wipes the monkey so setup can be shown again | Repeatable demos | dev | next |
| 5 | Stage art (egg, baby, kid, adult, crowned) per pose | Visual quality | teammate | open |
| 6 | Demo runbook + backup video | Reliability | presenter | open |

Live mode keeps working exactly as today; story mode never writes the real monkey's XP.

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
