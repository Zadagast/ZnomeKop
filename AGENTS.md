# AGENTS.md

## Cursor Cloud specific instructions

ZnomeKop is a single **Playdate handheld game** written in **Lua** (no backend, database, web server, or listening ports). The toolchain is the **Playdate SDK** (`pdc` compiler + `PlaydateSimulator`) plus **Python 3 + Pillow** for procedural asset generation. Standard commands live in `README.md` and `build.sh`; the notes below are the non-obvious, environment-specific caveats.

### Environment (already provisioned in the VM snapshot)
- Playdate SDK 3.1.1 is installed at `~/PlaydateSDK`. `PLAYDATE_SDK_PATH` and the SDK `bin/` are exported from `~/.bashrc`, so `pdc`, `pdutil`, and `PlaydateSimulator` are on `PATH` in login shells. `build.sh` also falls back to `$PLAYDATE_SDK_PATH` or `./PlaydateSDK`.
- The Simulator is a GTK/WebKit GUI app; it requires the system package `libwebkit2gtk-4.1-0` (already installed in the snapshot). Without it `PlaydateSimulator` fails to start with a missing-`.so` error.
- A display is available at `DISPLAY=:1`. The Simulator will not launch headless — always set `DISPLAY=:1` (and use the computerUse subagent to interact/screenshot).

### Build (this is the correctness gate)
- Run `./build.sh` from the repo root. It regenerates 1-bit art via `python3 tools/generate_assets.py`, then compiles `source/` into `ZnomeKop.pdx` with `pdc`.
- There is **no lint config and no automated test suite** in this repo. A clean `pdc` compile (no errors from `build.sh`) is the primary way to verify the Lua source is valid. `*.pdx` and the generated `source/images/*-table-*.png` / `source/SystemAssets/*.png` are build outputs (gitignored / regenerated) — don't hand-edit them.

### Run
- `DISPLAY=:1 "$PLAYDATE_SDK_PATH/bin/PlaydateSimulator" ZnomeKop.pdx`
- Controls in the Simulator: arrow keys = D-pad; the on-screen/keyboard A and B buttons map to Playdate A/B. The keyboard mapping depends on the Simulator's "Controls" preference — the default keys vary, so if key presses do nothing, either switch the Controls preset (e.g. "Arrows A S") or click the on-screen buttons.
- Harmless startup noise you can ignore: ALSA "couldn't open play stream" (no audio device) and a Gtk pixbuf/theme warning. A first-run "test on real hardware" dialog may appear — dismiss it.
