#!/usr/bin/env python3
"""ZnomeKop art generator — GB-Pokemon-clean 1-bit Mars tileset.

Style rules (enforced, not vibes):
  1. Ground tiles are ~95% white with small fixed-position marks
  2. Three textures only: solid black, solid white, 25% checker dither
  3. Bold 2px outlines on objects, no stray single pixels
  4. One repeated motif per tile, ordered placement
  5. Buildings are 96x64 (3x2 tiles) with dithered roof, white walls, black door

All output is deterministic. This is the single source of game art.
Creature sprites come from tools/psg.py (pixel-sprite-generator port, MIT).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

import psg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "source" / "images"
SYS = ROOT / "source" / "SystemAssets"

T = 32  # tile size

BLACK, WHITE = 0, 1


def new(w: int = T, h: int = T) -> Image.Image:
    return Image.new("1", (w, h), WHITE)


def checker(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    """25% dither: dot at every (even, even) position."""
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if x % 2 == 0 and y % 2 == 0:
                d.point((x, y), BLACK)


def outline_rect(d: ImageDraw.ImageDraw, box, width: int = 2) -> None:
    d.rectangle(box, outline=BLACK, width=width)


# ---------------------------------------------------------------- terrain --

def tile_empty() -> Image.Image:
    return new()


def tile_ground() -> Image.Image:
    """Regolith plain: white with two small fixed marks."""
    img = new()
    d = ImageDraw.Draw(img)
    # small three-dot rock marks, Route-101 style sparse texture
    for bx, by in ((6, 8), (20, 22)):
        d.line((bx, by, bx + 3, by), fill=BLACK)
        d.point((bx + 1, by - 1), BLACK)
    return img


def tile_route() -> Image.Image:
    """Path: clean white with dotted edge rows top and bottom."""
    img = new()
    d = ImageDraw.Draw(img)
    for x in range(2, T, 6):
        d.line((x, 2, x + 1, 2), fill=BLACK)
        d.line((x, 29, x + 1, 29), fill=BLACK)
    return img


def tile_dustreed() -> Image.Image:
    """Tall-grass analog: 2x2 ordered reed tufts."""
    img = new()
    d = ImageDraw.Draw(img)

    def tuft(cx: int, cy: int) -> None:
        # three bold blades
        d.line((cx, cy + 8, cx, cy + 2), fill=BLACK, width=2)
        d.line((cx - 4, cy + 8, cx - 4, cy + 4), fill=BLACK, width=2)
        d.line((cx + 4, cy + 8, cx + 4, cy + 4), fill=BLACK, width=2)
        # seed head
        d.point((cx - 1, cy + 1), BLACK)
        d.point((cx + 1, cy + 1), BLACK)
        # base
        d.line((cx - 5, cy + 9, cx + 5, cy + 9), fill=BLACK)

    tuft(8, 2)
    tuft(24, 2)
    tuft(8, 18)
    tuft(24, 18)
    return img


def tile_cliff() -> Image.Image:
    """GB cliff: white top face, dithered south face, strong edges."""
    img = new()
    d = ImageDraw.Draw(img)
    d.line((0, 0, 31, 0), fill=BLACK, width=2)          # top edge
    checker(d, (0, 20, 31, 29))                         # south face shading
    d.line((0, 30, 31, 30), fill=BLACK, width=2)        # bottom edge
    d.line((6, 6, 12, 6), fill=BLACK)                   # small crack mark
    d.point((12, 7), BLACK)
    return img


def tile_strata() -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)
    for bx, by in ((4, 9), (18, 21)):
        d.line((bx, by, bx + 10, by), fill=BLACK)
        d.line((bx + 2, by + 2, bx + 8, by + 2), fill=BLACK)
    return img


def tile_vent() -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)
    d.ellipse((11, 11, 20, 20), outline=BLACK, width=2)
    d.point((15, 15), BLACK)
    d.point((16, 15), BLACK)
    for px, py in ((7, 8), (24, 12), (10, 24)):
        d.point((px, py), BLACK)
    return img


def tile_frost() -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)
    for bx, by in ((8, 8), (20, 20)):
        d.line((bx - 3, by, bx + 3, by), fill=BLACK)
        d.line((bx, by - 3, bx, by + 3), fill=BLACK)
    return img


def tile_plaza() -> Image.Image:
    """Town pavement: white with small corner ticks."""
    img = new()
    d = ImageDraw.Draw(img)
    for cx, cy in ((2, 2), (28, 2), (2, 28), (28, 28)):
        d.line((cx, cy, cx + 2, cy), fill=BLACK)
        d.line((cx, cy, cx, cy + 2), fill=BLACK)
    return img


def tile_walkway() -> Image.Image:
    """Boardwalk plating: three clean horizontal lines."""
    img = new()
    d = ImageDraw.Draw(img)
    for y in (8, 16, 24):
        d.line((2, y, 29, y), fill=BLACK)
    return img


def tile_cave() -> Image.Image:
    """Lava tube mouth: black arch on rock base."""
    img = new()
    d = ImageDraw.Draw(img)
    d.rectangle((4, 14, 27, 31), fill=BLACK)
    d.ellipse((4, 4, 27, 24), fill=BLACK)
    d.ellipse((6, 6, 25, 24), outline=WHITE)
    d.rectangle((13, 16, 18, 31), fill=WHITE)  # entrance gap
    d.rectangle((14, 18, 17, 31), fill=BLACK)  # dark interior
    return img


def tile_rubble() -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)
    d.ellipse((5, 18, 12, 25), outline=BLACK, width=2)
    d.ellipse((18, 8, 26, 16), outline=BLACK, width=2)
    d.point((15, 26), BLACK)
    d.point((26, 22), BLACK)
    return img


def tile_pad() -> Image.Image:
    """Landing pad marker."""
    img = new()
    d = ImageDraw.Draw(img)
    d.ellipse((5, 5, 26, 26), outline=BLACK, width=2)
    d.rectangle((14, 12, 17, 19), fill=BLACK)
    return img


def tile_crater() -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)
    d.ellipse((6, 10, 25, 23), outline=BLACK, width=2)
    d.arc((9, 13, 22, 20), 20, 160, fill=BLACK)
    return img


def tile_spire() -> Image.Image:
    """Silica spire (tree analog): full-tile crystal, tiles into rows."""
    img = new()
    d = ImageDraw.Draw(img)
    # crystal canopy
    d.polygon([(15, 1), (16, 1), (27, 14), (22, 25), (9, 25), (4, 14)],
              outline=BLACK, width=2)
    # facet line
    d.line((15, 3, 12, 24), fill=BLACK)
    # shaded right facet
    checker(d, (18, 8, 24, 22))
    # trunk
    d.rectangle((13, 25, 18, 30), fill=BLACK)
    return img


def tile_pool(corner: str) -> Image.Image:
    """One corner of a 2x2 rounded brine pool."""
    full = new(64, 64)
    d = ImageDraw.Draw(full)
    d.rounded_rectangle((4, 4, 59, 59), radius=14, outline=BLACK, width=2)
    # inner shade rim (top-left)
    d.arc((7, 7, 56, 56), 150, 300, fill=BLACK)
    # wave dashes
    for y in (24, 36, 46):
        for x in range(14, 50, 12):
            d.line((x, y, x + 5, y), fill=BLACK)
    boxes = {
        "tl": (0, 0, 32, 32),
        "tr": (32, 0, 64, 32),
        "bl": (0, 32, 32, 64),
        "br": (32, 32, 64, 64),
    }
    return full.crop(boxes[corner])


def tile_under_building() -> Image.Image:
    """Footprint tile hidden by building props — plain white."""
    return new()


# --------------------------------------------------------------- buildings --

def building_outpost() -> Image.Image:
    img = new(96, 64)
    d = ImageDraw.Draw(img)
    # dome roof
    d.ellipse((10, 2, 85, 46), outline=BLACK, width=2)
    d.chord((10, 2, 85, 46), 180, 360, outline=BLACK, width=2)
    checker(d, (16, 6, 79, 22))
    # walls
    d.rectangle((12, 24, 83, 61), fill=WHITE)
    d.rectangle((12, 24, 83, 61), outline=BLACK, width=2)
    # windows
    d.rectangle((22, 32, 34, 44), outline=BLACK, width=2)
    d.rectangle((61, 32, 73, 44), outline=BLACK, width=2)
    d.line((28, 32, 28, 44), fill=BLACK)
    d.line((67, 32, 67, 44), fill=BLACK)
    # door (centered, black)
    d.rectangle((42, 40, 53, 61), fill=BLACK)
    d.point((51, 51), WHITE)
    # antenna
    d.line((47, 2, 47, 0), fill=BLACK)
    return img


def building_lab() -> Image.Image:
    img = new(96, 64)
    d = ImageDraw.Draw(img)
    # flat roof band
    d.rectangle((8, 10, 87, 24), outline=BLACK, width=2)
    checker(d, (10, 12, 85, 22))
    # dish
    d.arc((14, 0, 34, 14), 200, 360, fill=BLACK)
    d.line((24, 10, 24, 12), fill=BLACK)
    # walls
    d.rectangle((12, 24, 83, 61), fill=WHITE)
    d.rectangle((12, 24, 83, 61), outline=BLACK, width=2)
    # window band
    d.rectangle((20, 30, 75, 38), outline=BLACK, width=2)
    for x in (34, 48, 62):
        d.line((x, 30, x, 38), fill=BLACK)
    # door
    d.rectangle((42, 40, 53, 61), fill=BLACK)
    d.point((51, 51), WHITE)
    return img


def building_ruin() -> Image.Image:
    img = new(96, 64)
    d = ImageDraw.Draw(img)
    # broken silhouette walls
    d.polygon([(12, 61), (12, 26), (24, 26), (28, 14), (40, 14), (44, 26),
               (66, 26), (70, 18), (83, 22), (83, 61)],
              outline=BLACK, width=2)
    # cracks + rubble
    d.line((30, 26, 30, 40), fill=BLACK)
    d.line((58, 30, 62, 44), fill=BLACK)
    checker(d, (14, 48, 81, 59))
    # dark doorway gap
    d.rectangle((42, 38, 53, 61), fill=BLACK)
    return img


# ------------------------------------------------------------------ player --

def _player_base(d: ImageDraw.ImageDraw) -> None:
    """Shared suit body for all facings (arms + torso)."""
    # torso
    d.rectangle((10, 16, 21, 25), fill=WHITE)
    d.rectangle((10, 16, 21, 25), outline=BLACK, width=2)
    # arms
    d.rectangle((6, 17, 9, 23), outline=BLACK)
    d.rectangle((22, 17, 25, 23), outline=BLACK)


def _legs(d: ImageDraw.ImageDraw, step: int) -> None:
    if step == 0:
        d.rectangle((11, 26, 14, 31), fill=BLACK)
        d.rectangle((17, 26, 20, 31), fill=BLACK)
    else:
        d.rectangle((10, 25, 13, 30), fill=BLACK)
        d.rectangle((18, 27, 21, 31), fill=BLACK)


def player_frame(facing: str, step: int) -> Image.Image:
    img = new()
    d = ImageDraw.Draw(img)

    # helmet: big GB-proportion dome
    d.ellipse((8, 1, 23, 16), fill=WHITE)
    d.ellipse((8, 1, 23, 16), outline=BLACK, width=2)

    if facing == "down":
        d.rectangle((11, 7, 20, 12), outline=BLACK)
        d.rectangle((13, 9, 14, 10), fill=BLACK)
        d.rectangle((17, 9, 18, 10), fill=BLACK)
    elif facing == "up":
        # backpack visible from behind
        d.rectangle((11, 6, 20, 13), fill=BLACK)
        d.line((13, 7, 13, 12), fill=WHITE)
        d.line((18, 7, 18, 12), fill=WHITE)
    elif facing == "left":
        d.rectangle((9, 7, 16, 12), outline=BLACK)
        d.rectangle((11, 9, 12, 10), fill=BLACK)

    _player_base(d)

    if facing == "left":
        # backpack hump on the right side
        d.rectangle((21, 17, 24, 24), fill=BLACK)

    _legs(d, step)
    return img


def player_frames() -> list[Image.Image]:
    down0 = player_frame("down", 0)
    down1 = player_frame("down", 1)
    up0 = player_frame("up", 0)
    up1 = player_frame("up", 1)
    left0 = player_frame("left", 0)
    left1 = player_frame("left", 1)
    right0 = left0.transpose(Image.FLIP_LEFT_RIGHT)
    right1 = left1.transpose(Image.FLIP_LEFT_RIGHT)
    return [down0, down1, up0, up1, left0, left1, right0, right1]


# ---------------------------------------------------------------- creatures --

CREATURES = [
    ("gritmite", "blob"),
    ("basaltusk", "quadruped"),
    ("cindrel", "flyer"),
    ("frostil", "blob"),
    ("voxbat", "flyer"),
    ("rustling", "quadruped"),
]


def creature_frames() -> list[Image.Image]:
    return [psg.creature_sprite(f"znome:{cid}", mask) for cid, mask in CREATURES]


# ------------------------------------------------------------------- tables --

def save_table(frames: list[Image.Image], path: Path) -> None:
    w, h = frames[0].size
    sheet = Image.new("1", (w * len(frames), h), WHITE)
    for i, fr in enumerate(frames):
        if fr.size != (w, h):
            raise SystemExit(f"frame {i} size {fr.size} != {(w, h)} in {path.name}")
        sheet.paste(fr, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path.name} ({sheet.size[0]}x{sheet.size[1]}, {len(frames)} frames)")


def save_table_alpha(frames: list[Image.Image], path: Path) -> None:
    """White becomes transparent (sprites float over terrain)."""
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        src = fr.load()
        cell = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        dst = cell.load()
        for y in range(h):
            for x in range(w):
                if src[x, y] == 0:
                    dst[x, y] = (0, 0, 0, 255)
        sheet.paste(cell, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path.name} (alpha, {sheet.size[0]}x{sheet.size[1]}, {len(frames)} frames)")


def build_tile_list() -> list[Image.Image]:
    # Order must match Tiles ids in source/data/tiles.lua
    return [
        tile_empty(),          # 1 EMPTY
        tile_route(),          # 2 ROCK route
        tile_ground(),         # 3 DUST regolith
        tile_strata(),         # 4 CANYON
        tile_vent(),           # 5 LAVA
        tile_frost(),          # 6 FROST
        tile_plaza(),          # 7 COLONY
        tile_cliff(),          # 8 WALL
        tile_plaza(),          # 9 OUTPOST door pad
        tile_plaza(),          # 10 LAB door pad
        tile_cave(),           # 11 TUBE
        tile_rubble(),         # 12 RUINS door pad
        tile_dustreed(),       # 13 ENCOUNTER
        tile_pad(),            # 14 DOME landing pad
        tile_walkway(),        # 15 WALKWAY
        tile_crater(),         # 16 CRATER
        tile_spire(),          # 17 SPIRE (full-tile tree analog)
        tile_pool("tl"),       # 18 POOL_TL
        tile_pool("tr"),       # 19 POOL_TR
        tile_pool("bl"),       # 20 POOL_BL
        tile_pool("br"),       # 21 POOL_BR
        tile_under_building(), # 22 BUILDING footprint
    ]


# ------------------------------------------------------------ system assets --

def diorama(width: int, height: int) -> Image.Image:
    """Shared marketing/boot scene built from the real tiles."""
    img = Image.new("1", (width, height), WHITE)
    tiles = build_tile_list()
    ground = tiles[2]
    reed = tiles[12]
    spire = tiles[16]
    horizon = height - 96

    for y in range(horizon, height, T):
        for x in range(0, width, T):
            img.paste(ground, (x, y))
    # spire tree row along the horizon
    for x in range(0, width, T):
        img.paste(spire, (x, horizon - T))
    # dustreed field left
    for y in (height - 64, height - 32):
        for x in (0, 32, 64):
            img.paste(reed, (x, y))
    # outpost right
    outpost = building_outpost()
    img.paste(outpost, (width - 120, height - 76))
    # player + a znome
    img.paste(player_frame("down", 0), (width // 2 - 32, height - 60))
    znome = psg.creature_sprite("znome:gritmite", "blob")
    img.paste(znome, (width // 2 + 8, height - 60))
    return img


def make_system_assets() -> None:
    SYS.mkdir(parents=True, exist_ok=True)

    card = diorama(350, 155)
    d = ImageDraw.Draw(card)
    d.rectangle((0, 0, 349, 154), outline=BLACK, width=2)
    d.rectangle((55, 12, 295, 48), fill=WHITE)
    d.rectangle((55, 12, 295, 48), outline=BLACK, width=2)
    d.rectangle((58, 15, 292, 45), outline=BLACK)
    card.save(SYS / "card.png")

    launch = diorama(400, 240)
    d = ImageDraw.Draw(launch)
    d.rectangle((70, 24, 330, 72), fill=WHITE)
    d.rectangle((70, 24, 330, 72), outline=BLACK, width=2)
    d.rectangle((73, 27, 327, 69), outline=BLACK)
    launch.save(SYS / "launchImage.png")
    print("wrote card.png, launchImage.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # remove stale sheets so pdc can't pick up old art
    for stale in OUT.glob("*-table-*.png"):
        stale.unlink()

    save_table(build_tile_list(), OUT / "tiles-table-32-32.png")
    save_table([building_outpost(), building_lab(), building_ruin()],
               OUT / "buildings-table-96-64.png")
    save_table_alpha(player_frames(), OUT / "player-table-32-32.png")
    save_table_alpha(creature_frames(), OUT / "creatures-table-32-32.png")
    make_system_assets()
    print("Art generation complete (deterministic).")


if __name__ == "__main__":
    main()
