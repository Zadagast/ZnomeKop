#!/usr/bin/env python3
"""
Build Playdate imagetables from vendored CC0 asset packs.

Sources (see support/tilesets/ATTRIBUTION.md):
  - Stealthix 1-Bit RPG Tileset 32x32 (terrain / props)
  - Kenney 1-Bit Pack (player + sci-fi accents, scaled 16->32)
  - Hexany Monster Menagerie (creature icons)

This is deterministic. Running it always produces the same PNGs.
There is no procedural art fallback.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "support" / "tilesets"
OUT = ROOT / "source" / "images"
SYS = ROOT / "source" / "SystemAssets"

STEALTH = PACKS / "stealthix" / "tileset_32x32_1bit.png"
KENNEY = PACKS / "kenney" / "monochrome_packed.png"
HEXANY = PACKS / "hexany" / "monsters.png"


def require(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(
            f"Missing required pack asset: {path}\n"
            "Restore support/tilesets/ from git. No fallback art is available."
        )


def flatten(im: Image.Image, bg=(255, 255, 255)) -> Image.Image:
    im = im.convert("RGBA")
    base = Image.new("RGBA", im.size, bg + (255,))
    base.alpha_composite(im)
    return base.convert("RGB")


def to_playdate_1bit(im: Image.Image) -> Image.Image:
    """Convert to Playdate-friendly 1-bit (white bg, black ink)."""
    rgb = flatten(im, (255, 255, 255))
    # Threshold: dark pixels -> black
    return rgb.convert("L").point(lambda p: 255 if p > 160 else 0, mode="1")


def slice_grid(path: Path, tw: int, th: int) -> list[Image.Image]:
    im = flatten(Image.open(path))
    cols = im.width // tw
    rows = im.height // th
    tiles = []
    for y in range(rows):
        for x in range(cols):
            tiles.append(im.crop((x * tw, y * th, x * tw + tw, y * th + th)))
    return tiles


def kenney(x: int, y: int) -> Image.Image:
    im = flatten(Image.open(KENNEY))
    return im.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16))


def scale2(im: Image.Image) -> Image.Image:
    return im.resize((im.width * 2, im.height * 2), Image.NEAREST)


def stealth(tiles: list[Image.Image], x: int, y: int) -> Image.Image:
    return tiles[y * 10 + x]


def stack_v(top: Image.Image, bottom: Image.Image) -> Image.Image:
    out = Image.new("RGB", (32, 64), (255, 255, 255))
    out.paste(top, (0, 0))
    out.paste(bottom, (0, 32))
    return out.crop((0, 16, 32, 64))  # 32x48


def make_table(frames: list[Image.Image], path: Path) -> None:
    w, h = frames[0].size
    sheet = Image.new("1", (w * len(frames), h), 1)
    for i, fr in enumerate(frames):
        bit = fr if fr.mode == "1" else to_playdate_1bit(fr)
        if bit.size != (w, h):
            raise SystemExit(f"Frame size mismatch at {i}: {bit.size} != {(w,h)}")
        sheet.paste(bit, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path} ({sheet.size[0]}x{sheet.size[1]}, {len(frames)} frames)")


def build_tiles(st: list[Image.Image]) -> list[Image.Image]:
    # Fixed mapping — game look is defined here.
    # Indices must stay aligned with source/data/tiles.lua
    empty = Image.new("RGB", (32, 32), (255, 255, 255))
    return [
        empty,                           # 1 EMPTY
        stealth(st, 0, 3),               # 2 ROCK path / cobble
        stealth(st, 2, 2),               # 3 DUST dither plain
        stealth(st, 2, 0),               # 4 CANYON striated
        stealth(st, 7, 1),               # 5 LAVA / rocky
        stealth(st, 4, 9),               # 6 FROST sparse brine / ice flecks
        stealth(st, 0, 4),               # 7 COLONY diamond plaza
        stealth(st, 0, 1),               # 8 WALL stone
        stealth(st, 4, 0),               # 9 OUTPOST pad (cabinet/module)
        stealth(st, 5, 0),               # 10 LAB pad
        stealth(st, 1, 1),               # 11 TUBE dark mouth
        stealth(st, 7, 2),               # 12 RUINS marker
        stealth(st, 8, 0),               # 13 ENCOUNTER tall grass / dustreed
        stealth(st, 8, 6),               # 14 DOME / plated floor
        stealth(st, 2, 3),               # 15 WALKWAY stairs/boards
        stealth(st, 8, 1),               # 16 CRATER boulder
        stealth(st, 6, 0),               # 17 SPIRE stump/tree base
    ]


def build_props(st: list[Image.Image]) -> list[Image.Image]:
    # Tall 32x48 props from Stealthix parts
    pine_top = stealth(st, 6, 0)
    pine_mid = stealth(st, 6, 1)
    round_top = stealth(st, 8, 3)
    round_bot = stealth(st, 9, 3)
    cabinet = stealth(st, 4, 0)
    dresser = stealth(st, 5, 0)
    shelf = stealth(st, 5, 1)
    stump = stealth(st, 7, 0)
    sign = stealth(st, 6, 2)

    def building(body: Image.Image, roof: Image.Image) -> Image.Image:
        return stack_v(roof, body)

    return [
        building(cabinet, pine_top),     # outpost
        building(dresser, shelf),        # lab
        building(sign, stump),           # ruins
        building(round_bot, round_top),  # dome
        stack_v(pine_top, pine_mid),     # spire / silica tree
    ]


def build_player() -> list[Image.Image]:
    # Kenney humanoids (16x16) scaled to 32x32.
    # Four facings x two step frames (duplicate facing if no alt frame).
    # Chosen from packed sheet character row.
    faces = {
        "down": [(25, 0), (26, 0)],
        "up": [(27, 0), (28, 0)],
        "left": [(29, 0), (30, 0)],
        "right": [(31, 0), (25, 1)],
    }
    frames = []
    for facing in ("down", "up", "left", "right"):
        for xy in faces[facing]:
            frames.append(scale2(kenney(*xy)))
    return frames


def build_creatures() -> list[Image.Image]:
    hx = slice_grid(HEXANY, 32, 32)
    # Stable picks: multi-tile creature "heads"/icons that read at 32x32.
    # Coordinates from Hexany sheet (25 columns).
    picks = [
        (1, 7),   # compact critter-ish
        (2, 7),
        (6, 7),
        (7, 7),
        (11, 7),
        (12, 7),
        (1, 8),
        (2, 8),
        (16, 7),
        (17, 7),
        (21, 7),
        (22, 7),
    ]
    frames = []
    for x, y in picks:
        idx = y * 25 + x
        if idx >= len(hx):
            raise SystemExit(f"Hexany tile out of range: {x},{y}")
        frames.append(hx[idx])
    # Ensure none are empty black — swap to Kenney critters if needed
    for i, fr in enumerate(frames):
        if fr.convert("L").getextrema()[1] < 20:
            # fallback within packs only: Kenney critter tiles scaled
            frames[i] = scale2(kenney(20 + (i % 8), 5))
    return frames


def build_system_assets(st: list[Image.Image]) -> None:
    SYS.mkdir(parents=True, exist_ok=True)
    # Card
    card = Image.new("1", (350, 155), 1)
    grass = to_playdate_1bit(stealth(st, 8, 0))
    path = to_playdate_1bit(stealth(st, 0, 3))
    tree = to_playdate_1bit(stealth(st, 6, 0))
    for y in range(20, 130, 32):
        for x in range(16, 150, 32):
            card.paste(grass if ((x + y) // 32) % 2 == 0 else path, (x, y))
    card.paste(tree, (64, 40))
    # border
    from PIL import ImageDraw
    d = ImageDraw.Draw(card)
    d.rectangle((6, 6, 343, 148), outline=0, width=3)
    d.rectangle((170, 40, 330, 78), outline=0, width=2)
    d.rectangle((170, 90, 300, 112), outline=0)
    card.save(SYS / "card.png")

    launch = Image.new("1", (400, 240), 1)
    for y in range(0, 240, 32):
        for x in range(0, 400, 32):
            launch.paste(grass if y > 140 else path, (x, y))
    launch.paste(tree, (250, 80))
    launch.paste(to_playdate_1bit(stealth(st, 4, 0)), (280, 120))
    d = ImageDraw.Draw(launch)
    d.rectangle((110, 28, 290, 70), outline=0, width=2)
    launch.save(SYS / "launchImage.png")
    print(f"wrote {SYS / 'card.png'}")
    print(f"wrote {SYS / 'launchImage.png'}")


def main() -> None:
    require(STEALTH)
    require(KENNEY)
    require(HEXANY)

    st = slice_grid(STEALTH, 32, 32)
    if len(st) < 130:
        raise SystemExit(f"Stealthix sheet unexpected size: {len(st)} tiles")

    OUT.mkdir(parents=True, exist_ok=True)
    # Remove old generated sheets so pdc cannot pick stale art
    for stale in OUT.glob("*-table-*.png"):
        stale.unlink()

    make_table([to_playdate_1bit(t) for t in build_tiles(st)], OUT / "tiles-table-32-32.png")
    make_table([to_playdate_1bit(t) for t in build_props(st)], OUT / "props-table-32-48.png")
    make_table([to_playdate_1bit(t) for t in build_player()], OUT / "player-table-32-32.png")
    make_table([to_playdate_1bit(t) for t in build_creatures()], OUT / "creatures-table-32-32.png")
    build_system_assets(st)
    print("Pack import complete (deterministic).")


if __name__ == "__main__":
    main()
