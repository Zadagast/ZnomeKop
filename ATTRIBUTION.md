# Attribution

All ZnomeKop art is original to this project and assembled deterministically
by `tools/make_tiles.py`.

## Art sources

| Source | Contents |
| --- | --- |
| `assets/player/` | 4-facing explorer sprites (walk frames derived in code) |
| `assets/terrain/` | terrain objects: spire, boulder, reeds, crater, cave, vent |
| `assets/buildings/` | 96x64 dome habitat, research lab, ruin |
| `assets/creatures/` | Znome creature sprites |
| `tools/sprites.py` | hand-authored seamless fill tiles and cliff tiles |

Sprites in `assets/` were drawn with AI image tooling, then sliced,
downscaled, and thresholded to 1-bit with `tools/extract_art.py`. The
committed PNGs are the canonical art, so `./build.sh` never needs network
access and always produces identical output.

Each `assets/*/source_sheet.png` is the original generated sheet, kept so
sprites can be re-extracted at different sizes or thresholds.
