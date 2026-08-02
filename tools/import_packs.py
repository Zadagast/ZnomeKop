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


def stealth_px(px_x: int, px_y: int) -> Image.Image:
    """Crop a 32x32 window at an arbitrary pixel offset (for seamless fills)."""
    im = flatten(Image.open(STEALTH))
    return im.crop((px_x, px_y, px_x + 32, px_y + 32))


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


def make_table_alpha(frames: list[Image.Image], path: Path) -> None:
    """Imagetable with white treated as transparent (sprite floats over terrain)."""
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        bit = fr if fr.mode == "1" else to_playdate_1bit(fr)
        rgba = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        px = bit.load()
        out = rgba.load()
        for y in range(h):
            for x in range(w):
                if px[x, y] == 0:
                    out[x, y] = (0, 0, 0, 255)
        sheet.paste(rgba, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path} (alpha, {sheet.size[0]}x{sheet.size[1]}, {len(frames)} frames)")


def build_tiles(st: list[Image.Image]) -> list[Image.Image]:
    # Fixed mapping — game look is defined here.
    # Indices must stay aligned with source/data/tiles.lua
    empty = Image.new("RGB", (32, 32), (255, 255, 255))
    return [
        empty,                           # 1 EMPTY
        stealth(st, 0, 3),               # 2 ROCK cobble route
        stealth_px(4 * 32 + 8, 9 * 32),  # 3 DUST seamless speckle plain
        stealth(st, 2, 1),               # 4 CANYON eroded strata
        stealth(st, 0, 2),               # 5 LAVA rubble / vent field
        stealth(st, 2, 2),               # 6 FROST dither shade (reserved)
        stealth(st, 8, 6),               # 7 COLONY metal panel plaza
        stealth(st, 0, 1),               # 8 WALL cliff blocks
        stealth(st, 8, 6),               # 9 OUTPOST pad (prop overlays)
        stealth(st, 8, 6),               # 10 LAB pad (prop overlays)
        stealth(st, 1, 6),               # 11 TUBE cave mouth arch
        stealth(st, 0, 2),               # 12 RUINS rubble pad (prop overlays)
        stealth(st, 8, 0),               # 13 ENCOUNTER dustreed grass
        stealth(st, 4, 10),              # 14 DOME landing pad marker
        stealth(st, 0, 4),               # 15 WALKWAY woven plating
        stealth(st, 1, 0),               # 16 CRATER rocky clumps
        stealth(st, 7, 0),               # 17 SPIRE stump base (prop overlays)
        stealth(st, 8, 8),               # 18 POOL_TL brine pool corner
        stealth(st, 9, 8),               # 19 POOL_TR
        stealth(st, 8, 10),              # 20 POOL_BL
        stealth(st, 9, 10),              # 21 POOL_BR
    ]


def build_props(st: list[Image.Image]) -> list[Image.Image]:
    # Tall 32x48 props from Stealthix parts
    pine_top = stealth(st, 6, 0)
    pine_mid = stealth(st, 6, 1)
    console = stealth(st, 0, 7)      # windowed console face
    wall_a = stealth(st, 2, 7)       # pillared wall body
    wall_b = stealth(st, 3, 7)       # pillared wall body variant
    boulder = stealth(st, 9, 1)
    rubble = stealth(st, 0, 2)
    arch = stealth(st, 1, 6)         # dark dome arch
    frame = stealth(st, 1, 7)        # dark framed module

    return [
        stack_v(console, wall_a),    # outpost: console top, module body
        stack_v(console, wall_b),    # lab: console top, alt body
        stack_v(boulder, rubble),    # ruins: collapsed boulder pile
        stack_v(arch, frame),        # dome: arched module
        stack_v(pine_top, pine_mid), # spire / silica tree
    ]


def build_player() -> list[Image.Image]:
    """One Kenney astronaut, 8 frames: 4 facings x 2 step frames.

    Same character everywhere — left is a mirror, the step frame is a
    1-tile bob. Inverted to black-ink-on-white to sit on light terrain.
    """
    base = scale2(kenney(27, 3))  # helmeted astronaut

    def invert(im: Image.Image) -> Image.Image:
        from PIL import ImageOps

        return ImageOps.invert(im.convert("L")).convert("RGB")

    def bob(im: Image.Image, px: int = 2) -> Image.Image:
        out = Image.new("RGB", (32, 32), (255, 255, 255))
        out.paste(im.crop((0, px, 32, 32)), (0, 0))
        return out

    down = invert(base)
    left = invert(base.transpose(Image.FLIP_LEFT_RIGHT))

    return [
        down, bob(down),   # down
        down, bob(down),   # up
        left, bob(left),   # left
        down, bob(down),   # right
    ]


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
    make_table_alpha([to_playdate_1bit(t) for t in build_player()], OUT / "player-table-32-32.png")
    make_table([to_playdate_1bit(t) for t in build_creatures()], OUT / "creatures-table-32-32.png")
    build_system_assets(st)
    print("Pack import complete (deterministic).")


if __name__ == "__main__":
    main()
