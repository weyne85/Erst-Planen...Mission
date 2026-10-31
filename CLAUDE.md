# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

DCS World training mission for the Caucasus map: eight independent zones (ground attack + Moose RANGE, carrier/AIRBOSS, SEAD/DEAD, intercept, JTAC, CTLD, random CSAR, ambient traffic/convoys). Lua scripts run inside the DCS mission sandbox on top of MIST, Moose and CTLD. `mission/DCS_Training_Kaukasus.miz` is generated, not hand-edited. The README (German) is the detailed reference; user-facing answers are expected in short German, in-game text and kneeboards are English.

DCS is not available here: nothing can be run in the game. Verification is limited to the commands below.

@docs/README.md

## Commands

```
luac5.1 -p scripts/*.lua                      # syntax check
luacheck scripts                              # lint (config: .luacheckrc; apt install lua-check); must report 0 warnings
lua5.1 tests/mock_test.lua                    # logic test with DCS/Moose/MIST/CTLD stubs (85 checks, must end with 0 errors)
python3 tools/build_miz.py --sounds-dir <MOOSE_SOUND-clone>   # maps + kneeboards + .miz
```

- New DCS/Moose globals used in scripts must be added to `read_globals` in `.luacheckrc`.
- There is no single-test runner; `mock_test.lua` runs everything and prints one line per check.
- Build needs `pip install pydcs matplotlib adjustText mgrs pillow` (the package is `pydcs`, not `dcs`) and `lua5.1`. pydcs prints many harmless "Couldn't detect any installed DCS World version" lines on Linux.
- `--sounds-dir` is a clone of the MOOSE_SOUND repo (FlightControl-Master; not part of this repo, clone it first; source of the `Range Soundfiles`, `Airboss Soundfiles` and `CTLD CSAR/beacon.ogg`). Only Moose sounds are allowed, no own sound files.

## Architecture

**Script load order matters** and is defined in two places that must stay identical: `LOAD_ORDER` in `tools/build_miz.py` (one MISSION START trigger with one `DO SCRIPT FILE` per file) and README chapter 2. `libs/mist.lua`, `Moose.lua`, `CTLD-i18n.lua`, `CTLD.lua`, `A10_laste_Winds.lua` are unmodified third-party files (LASTE script is MIT, CaptMikeDK). `scripts/99_init.lua` must load last.

Script layers (`scripts/`):
- `00_config.lua`: `TRN.CFG`, the single source of truth. All mission object names (`TRN_*` zones, groups, templates), frequencies, TACAN, difficulty levels, timers. Scripts never hardcode names; the Python tools read this file too (via `lua5.1` dumped to JSON in `tools/briefing.py:load_cfg`).
- `01_core.lua`: helpers (`TRN.Spawn` with cached SPAWN per template, geometry, MGRS) and the `Zone`/`Session` framework: one session per zone at a time, round timer, automatic cleanup of tracked groups, pcall-wrapped `OnTick` that stops the zone with a message on error.
- `02_audio.lua`: text-only announcements per player group, queued. `03_menu.lua`: per-group F10 menu "Training Zones" built from `TRN.ZoneOrder`, scans players every 3 s; `TRN.Menu.OnNewPlayer(fn)` hooks run once per new player group.
- `10`..`70`: one file per zone, each registers a def via `TRN.RegisterZone` (`OnRound`, `OnTick`, `OnStop`, optional `extras` menu entries). `10` also holds `TRN.Range_Init`, `20` the AIRBOSS setup, `60` the CTLD tables, `70` the CSAR, `80` RAT flights and convoys.
- `99_init.lua`: dependency check, then calls the `*_Init` functions and `TRN.Menu.Start()`.

**DCS sandbox pitfalls that already caused real bugs:**
- `os`/`io` are absent and `math.randomseed` can be nil: guard it (a crash in `99_init` silently aborted all inits).
- Moose AIRBOSS and RANGE only create their F10 menu on the Birth event: players already seated need the `OnNewPlayer` hook.
- CTLD converts its zone tables to numeric format at init (colour names to numbers, `"yes"` to 1, limit -1 to 10000); `60_ctld.lua` must write the converted format after init, otherwise CTLD errors with "compare number with string".
- Frequencies must not collide (Range instructor 257.0 vs. Marshal 305.0 was fixed).

**Python pipeline (`tools/`):** `build_miz.py` runs two phases. Phase 1 builds a temporary `.miz`, `plot_map.py` renders the maps (`mission/map/`) and kneeboard maps from it, `briefing.py` renders kneeboard pages (`mission/kneeboard/`, 768x1024 PNG, per aircraft type via `TYPES`/`PROC`/`ROUTES`). Phase 2 builds the final `.miz` with briefing text, pictures, kneeboards (`KNEEBOARD/<type id>/IMAGES/`), client-slot waypoints, scripts and sounds, then checks that every `TRN_` name from `00_config.lua` exists in the mission. `types_extra.py` registers the custom `CH-47Fbl1` type (importing it from `build_miz` would be circular).

**Coordinates:** all unit/zone positions are placeholders in the `POS` dict of `build_miz.py` (no terrain data). DCS coordinates are x = north, y = east. Positions must be checked/moved in the Mission Editor.

## Conventions

- Adding a zone, object name or script file means: update `00_config.lua`, `LOAD_ORDER`, README chapter 2, `mock_test.lua` (script list in the load loop, near line 273), and rebuild the `.miz`.
- After changing anything that feeds the mission (scripts, config, `tools/`), rebuild and commit the regenerated `mission/` outputs together with the source change.
- Do not list airfield TACAN/ILS on kneeboards: pydcs has no data and values must not be guessed.
- `wiki/` is generated from `README.md` by `python3 tools/make_wiki.py`; edit the README, then regenerate. Publishing to the GitHub wiki (separate repo `<repo>.wiki.git`) is done manually.

## Second mission: `Kaukasus_Allround/`

Independent mission, shares no code with the one above (user decision: "komplett neu ohne Altcode"). Moose-only (2.9.18 as `libs/Moose_.lua`, no MiST, Moose `Ops.CTLD`), as many modern Moose Ops/Functional modules as possible, no SRS (text + Moose sound packs), training scenarios on demand (F10 "Training") plus an endless CHIEF ground war Senaki-Sukhumi. Delivered as scripts + German `Kaukasus_Allround/README.md` (the user builds the `.miz` in the Mission Editor; no pydcs build, no kneeboards). The README lists every ME object (docs/README.md section 5 fields), the 20-step load order, the manual sound setup and the open "TODO: verifizieren" points.

```
cd Kaukasus_Allround
luac5.1 -p scripts/*.lua
luacheck scripts                 # own .luacheckrc, 0 warnings
lua5.1 tests/mock_test.lua       # 110 checks, must end with 0 errors; also checks every config name appears in README.md
```

- Namespace `KA`; `00_config.lua` (`KA.CFG`) is the single source of names/frequencies. `01_core.lua`: `KA.Need` (records missing ME objects for the start report), cached `KA.Spawner`, session framework (`KA.RegisterScenario` with `OnStart`/`OnTick`/`Status`, `parallel`, `restart`, `replace`), player tracking (`CLIENTWATCH` + birth replay for players seated before scripts ran). `02_menu.lua`: `CLIENTMENUMANAGER`, handlers get `(group, client)`.
- Every Moose call was looked up in the 2.9.18 source. Known traps found there: `TIRESIAS` 2.9.18 stores types `" Vehicle"`/`" AAA"` but compares `"Vehicle"`/`"AAA"` (AI never switched back on) - not used; `ZONE:GetCoordinate()` returns a shared cached object (use `KA.ZoneCoord`); `PLAYERTASKCONTROLLER:AddAgentSet` is a one-time snapshot (pass a prefix table to `SetupIntel` instead); AIRWING assets need a payload (`NewPayload`) and tanker missions only match templates with the same refuel system; `AICSAR` and `CSAR` on the same coalition both spawn a pilot (AICSAR is used for RED only).
- Adding a name or script: `00_config.lua`, README (chapter 3 load order / chapter 7-9 tables), `tests/mock_test.lua` (`SCRIPTS` list).
