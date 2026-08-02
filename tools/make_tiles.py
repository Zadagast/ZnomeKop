#!/usr/bin/env python3
"""ZnomeKop art generator — GB-Pokemon-clean 1-bit Mars tileset.

Style rules (enforced, not vibes):
  1. Ground tiles are ~95% white with small fixed-position marks
  2. Three textures only: solid black, solid white, 25% checker dither
  3. Bold 2px outlines on objects, no stray single pixels
  4. One repeated motif per tile, ordered placement
  5. Buildings are 96x64 (3x2 tiles) with dithered roof, white walls, black door

Art sources, all committed and deterministic:
  assets/player/     curated 4-facing sprites (walk frames derived)
  assets/terrain/    curated terrain objects
  assets/buildings/  curated 96x64 structures
  assets/creatures/  curated Znome sprites
  tools/sprites.py   hand-authored seamless fill tiles and cliffs

Regenerate curated PNGs with tools/extract_art.py (authoring-time only).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

import sprites

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "source" / "images"
SYS = ROOT / "source" / "SystemAssets"
ASSETS = ROOT / "assets"
CREATURE_DIR = ASSETS / "creatures"
TERRAIN_DIR = ASSETS / "terrain"
BUILDING_DIR = ASSETS / "buildings"


def load_asset(path: Path, size: tuple[int, int]) -> Image.Image:
    if not path.is_file():
        raise SystemExit(f"Missing art asset: {path}\nRun tools/extract_art.py to rebuild it.")
    im = Image.open(path).convert("1")
    if im.size != size:
        raise SystemExit(f"{path} must be {size}, got {im.size}")
    return im


def terrain(name: str) -> Image.Image:
    return load_asset(TERRAIN_DIR / f"{name}.png", (T, T))

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


def tile_ground(variant: int = 0) -> Image.Image:
    """Regolith plain. Three variants keep open fields from gridding."""
    return sprites.ground_variants()[variant]


def tile_route(mask: int = 15) -> Image.Image:
    """mask 15 (fully connected) is the plain surface used mid-generation."""
    return sprites.route_tile_for_mask(mask)


def tile_plaza() -> Image.Image:
    return sprites.plaza_tile()


def tile_cliff_top() -> Image.Image:
    return sprites.cliff_top_tile()


def tile_cliff_face() -> Image.Image:
    return sprites.cliff_face_tile()


def tile_dustreed() -> Image.Image:
    """Tall-grass analog: a reed clump, dense enough to read as a field."""
    return terrain("reeds")


def tile_spire() -> Image.Image:
    return terrain("spire")


def tile_boulder() -> Image.Image:
    return terrain("boulder")


def tile_crater() -> Image.Image:
    return terrain("crater")


def tile_cave() -> Image.Image:
    return terrain("cave")


def tile_strata() -> Image.Image:
    """Canyon shelf: walkable ground marked with erosion layers."""
    return sprites.strata_tile()


def tile_pad() -> Image.Image:
    """Supply crate stack on plaza decking (town landmark, not a button)."""
    img = tile_plaza()
    d = ImageDraw.Draw(img)
    # big crate
    d.rectangle((4, 12, 19, 27), fill=WHITE)
    d.rectangle((4, 12, 19, 27), outline=BLACK, width=2)
    d.line((4, 19, 19, 19), fill=BLACK)
    d.line((11, 12, 11, 27), fill=BLACK)
    # small crate behind
    d.rectangle((20, 17, 29, 27), fill=WHITE)
    d.rectangle((20, 17, 29, 27), outline=BLACK, width=2)
    d.line((20, 22, 29, 22), fill=BLACK)
    return img


def tile_pool(corner: str) -> Image.Image:
    """One corner of a 2x2 brine pool."""
    full = new(64, 64)
    d = ImageDraw.Draw(full)
    d.rounded_rectangle((3, 3, 60, 60), radius=16, outline=BLACK, width=3)
    d.rounded_rectangle((8, 8, 55, 55), radius=12, outline=BLACK)
    for y in (22, 34, 45):
        for x in range(16, 48, 11):
            d.line((x, y, x + 5, y), fill=BLACK, width=2)
    boxes = {
        "tl": (0, 0, 32, 32),
        "tr": (32, 0, 64, 32),
        "bl": (0, 32, 32, 64),
        "br": (32, 32, 64, 64),
    }
    return full.crop(boxes[corner])


def tile_under_building() -> Image.Image:
    """Footprint hidden behind building props."""
    return new()


# --------------------------------------------------------------- buildings --

def building(name: str) -> Image.Image:
    return load_asset(BUILDING_DIR / f"{name}.png", (96, 64))


def building_outpost() -> Image.Image:
    return building("outpost")


def building_lab() -> Image.Image:
    return building("lab")


def building_ruin() -> Image.Image:
    return building("ruin")


# ------------------------------------------------------------------ player --

def player_frames() -> list[Image.Image]:
    """Hand-authored pixel maps, see tools/sprites.py."""
    return sprites.player_frames()


# ---------------------------------------------------------------- creatures --

# Order must match Creatures.list in source/data/creatures.lua
CREATURES = ["gritmite", "basaltusk", "cindrel", "frostil", "voxbat", "rustling"]


def creature_frames() -> list[Image.Image]:
    frames = []
    for cid in CREATURES:
        path = CREATURE_DIR / f"{cid}.png"
        if not path.is_file():
            raise SystemExit(f"Missing creature sprite: {path}")
        frames.append(Image.open(path).convert("1"))
    return frames


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


def _outside_mask(frame: Image.Image) -> list[list[bool]]:
    """White pixels reachable from the border, i.e. background around the sprite.

    White enclosed by ink (a helmet interior, a suit panel) is *not* outside,
    so it stays opaque and terrain cannot show through the character.
    """
    w, h = frame.size
    px = frame.load()
    outside = [[False] * w for _ in range(h)]
    stack = []

    for x in range(w):
        for y in (0, h - 1):
            if px[x, y] != 0 and not outside[y][x]:
                outside[y][x] = True
                stack.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if px[x, y] != 0 and not outside[y][x]:
                outside[y][x] = True
                stack.append((x, y))

    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not outside[ny][nx] and px[nx, ny] != 0:
                outside[ny][nx] = True
                stack.append((nx, ny))
    return outside


def save_table_alpha(frames: list[Image.Image], path: Path) -> None:
    """Only the background around each sprite is transparent."""
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        outside = _outside_mask(fr)
        src = fr.load()
        cell = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        dst = cell.load()
        for y in range(h):
            for x in range(w):
                if outside[y][x]:
                    continue
                dst[x, y] = (0, 0, 0, 255) if src[x, y] == 0 else (255, 255, 255, 255)
        sheet.paste(cell, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path.name} (alpha, {sheet.size[0]}x{sheet.size[1]}, {len(frames)} frames)")


def build_tile_list() -> list[Image.Image]:
    # Order must match Tiles ids in source/data/tiles.lua
    return [
        tile_empty(),           # 1  EMPTY
        tile_route(),           # 2  ROCK route
        tile_ground(0),         # 3  DUST regolith (plain)
        tile_strata(),          # 4  CANYON
        tile_boulder(),         # 5  BOULDER
        tile_plaza(),           # 6  COLONY
        tile_cliff_top(),       # 7  WALL cliff top
        tile_plaza(),           # 8  OUTPOST door pad
        tile_plaza(),           # 9  LAB door pad
        tile_cave(),            # 10 TUBE
        tile_ground(2),         # 11 RUINS door pad
        tile_dustreed(),        # 12 ENCOUNTER
        tile_pad(),             # 13 DOME supply crates
        tile_crater(),          # 14 CRATER
        tile_spire(),           # 15 SPIRE
        tile_pool("tl"),        # 16 POOL_TL
        tile_pool("tr"),        # 17 POOL_TR
        tile_pool("bl"),        # 18 POOL_BL
        tile_pool("br"),        # 19 POOL_BR
        tile_under_building(),  # 20 BUILDING footprint
        tile_ground(1),         # 21 DUST_B
        tile_ground(2),         # 22 DUST_C
        tile_cliff_face(),      # 23 CLIFF_FACE
        # 24..39 ROUTE_VARIANT + mask: kerbs on sides open to terrain
        *[tile_route(mask) for mask in range(16)],
    ]


# ------------------------------------------------------------ system assets --

def diorama(width: int, height: int) -> Image.Image:
    """Shared marketing/boot scene built from the real tiles."""
    img = Image.new("1", (width, height), WHITE)
    grounds = sprites.ground_variants()
    reed = tile_dustreed()
    spire = tile_spire()
    horizon = height - 96

    for row, y in enumerate(range(horizon, height, T)):
        for col, x in enumerate(range(0, width, T)):
            img.paste(grounds[(row * 3 + col) % 3], (x, y))
    # spire ridge line along the horizon
    for x in range(0, width, T):
        img.paste(spire, (x, horizon - T))
    # dustreed field left
    for y in (height - 64, height - 32):
        for x in (0, 32, 64):
            img.paste(reed, (x, y))
    # outpost right
    img.paste(building_outpost(), (width - 120, height - 76))
    # player + a znome
    img.paste(player_frames()[0], (width // 2 - 40, height - 60))
    img.paste(creature_frames()[0], (width // 2 + 8, height - 60))
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
