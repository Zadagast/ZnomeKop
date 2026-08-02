# ZnomeKop

Sci-fi monster-collecting RPG for [Playdate](https://play.date/), set on Mars.

Explore procedurally generated sectors, catch original creatures (**Znomes**), train a party, and fight turn-based battles. No story required — gameplay systems drive the loop.

## Visual direction

Playdate’s screen is dense (400×240 @ ~173 ppi). Tiny tiles look worse than they do on Game Boy.

From [Designing for Playdate](https://help.play.date/developer/designing-for-playdate/) and community practice:

- **Comfortable tiles ≈ 32×32** (8×8 strains eyes; 16×16 still feels small)
- **Player sprites ≈ 32×32 minimum**
- Power-of-two tile sizes are easier to author

**Current approach (chosen for a monster-collecting RPG):**
- Top-down **32×32** tilemap with drawn terrain objects (spires, boulders,
  reeds, craters, caves, vents) rather than geometric primitives
- **96×64 buildings** (3×2 tiles, centered door) with Y-sorted sprites
- Cliffs use separate **top and face** tiles so ridges read as rock masses
- Three **regolith variants** scattered by mapgen so open fields do not grid
- Seamless fill tiles are hand-authored pixel maps in `tools/sprites.py`
- Sprite art lives in `assets/` — see `ATTRIBUTION.md`
- Build all imagetables: `python3 tools/make_tiles.py` (deterministic)
- Re-curate a sprite sheet: `python3 tools/extract_art.py <sheet> <outdir> names...`

**Other options researched (not active yet):**
- **Mode 7 / pseudo-3D ground** via [playdate-mode7](https://github.com/risolvipro/playdate-mode7) (great for racing / open fields; heavier fit for grid battles)
- **True isometric** (e.g. GhostWheel / Melkhior’s Tower techniques) — beautiful, more engine work

## Vertical Slice 0.1

Playable now:

- Procedural Mars sectors (towns, routes, dustreed patches, cliffs)
- Persistent, revisitable zones: generate new zones explicitly and retain
  each seed plus the player's last position
- Purposeful route networks connect every building approach using an
  A*-carved minimum-spanning tree with an optional loop
- 32×32 exploration with camera follow + tall POI props
- Original four-direction astronaut with four authored animation phases per
  facing, timed like a Game Boy overworld walk cycle
- Points of interest (outposts, labs, lava tubes, ruins)
- Encounter stubs in dustreed
- Save / continue via `playdate.datastore`
- Data-driven tiles, creatures, and moves (battle combat arrives next)

Controls:

| Input | Action |
| --- | --- |
| D-pad | Move |
| A | Interact / confirm |
| B | Menu / back |

## Project layout

```
source/
  main.lua
  core/           # game facade, save, state stack
  data/           # tiles, generation params, creatures, moves
  entities/       # player
  scenes/         # title, explore
  util/           # RNG, grid helpers
  world/          # mapgen + world view
  images/         # 1-bit imagetables
  SystemAssets/   # launcher card / launch image
tools/
  generate_assets.py
PlaydateSDK/      # local SDK (gitignored) or set PLAYDATE_SDK_PATH
```

## Easiest: run the prebuilt game (Ubuntu)

**Can't ship the Playdate SDK in git** — Panic's license forbids redistributing it.

If you don't have the SDK yet:

```bash
./install-sdk-ubuntu.sh
source ~/.bashrc
./run-local.sh
```

A compiled game is committed as `ZnomeKop.pdx` (also `ZnomeKop.pdx.zip`).

```bash
git clone https://github.com/Zadagast/ZnomeKop.git
cd ZnomeKop
git checkout cursor/mars-rpg-vertical-slice

# If your Simulator is already installed:
./run-local.sh
```

Or in Playdate Simulator: **File → Open** → select the `ZnomeKop.pdx` folder.

Keyboard in Simulator: **Arrows = D-pad**, **S = A**, **A = B**.

Zip download (same build): [`ZnomeKop.pdx.zip`](./ZnomeKop.pdx.zip) — unzip, then open the `ZnomeKop.pdx` folder in the Simulator.

## Setup (only if you want to rebuild from source)

1. Install the [Playdate SDK 3.1.1+](https://play.date/dev/) for your OS.
2. Either:
   - extract/symlink it to `./PlaydateSDK`, or
   - export `PLAYDATE_SDK_PATH` to your SDK folder.
3. Install Python 3 + Pillow for asset generation:
   ```bash
   pip install Pillow
   ```

Linux quick SDK fetch:

```bash
wget https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-latest.tar.gz
tar xf PlaydateSDK-latest.tar.gz
ln -sfn PlaydateSDK-3.1.1 PlaydateSDK
export PLAYDATE_SDK_PATH="$PWD/PlaydateSDK"
```

## Build from source

```bash
./build.sh
./run-local.sh
```

## Generation notes

Maps are built to stay Playdate-friendly:

1. Cellular automata sculpt cliff ridges
2. POIs are placed with spacing rules and explicit door/approach coordinates
3. A minimum-spanning tree chooses necessary building-to-building links
4. Terrain-costed A* carves one-tile routes and passing bays at turns
5. Dustreed fields, pools, and spire groves cluster beside the route network
6. Flood-fill repairs guarantee a fully traversable main component
7. The zone seed recreates the map; saves retain all generated zone seeds

Tunables live in `source/data/generation.lua`.

## Roadmap

1. Turn-based battles with affinity matchups
2. Catching, party management, and training
3. Zone progression / deeper lava-tube layers
4. Stronger 1-bit creature art and UI polish
5. Optional crank gestures for scanners / menus

## License

Game code and original assets: add your license before release.  
Playdate SDK is subject to Panic’s SDK license and is not redistributed in this repo.
