# Attribution

All ZnomeKop art is built deterministically by `tools/make_tiles.py`:

- Terrain, buildings, and UI: drawn in code under the project style guide
- Player: hand-authored pixel maps in `tools/sprites.py`
- Creatures: curated 1-bit sprites in `assets/creatures/` (generated with
  AI image tooling, then sliced, downscaled, and thresholded to 32x32 1-bit;
  the committed PNGs are the canonical art)
