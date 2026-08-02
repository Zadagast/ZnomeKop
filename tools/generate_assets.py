#!/usr/bin/env python3
"""
Generate Playdate-friendly 1-bit art for ZnomeKop.

Visual direction (from Designing for Playdate + community research):
- Comfortable tiles ~32x32 (not tiny 8/16)
- Player sprite ~32x32 minimum for readability
- Tall building sprites for a light 2.5D / depth read
- Strong silhouettes + dither for "material" on 1-bit
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "source" / "images"
TILE = 32


def new_img(w: int, h: int, color: int = 1) -> Image.Image:
    return Image.new("1", (w, h), color=color)


def bayer4(x: int, y: int) -> int:
    m = (
        (0, 8, 2, 10),
        (12, 4, 14, 6),
        (3, 11, 1, 9),
        (15, 7, 13, 5),
    )
    return m[y & 3][x & 3]


def dither_rect(d: ImageDraw.ImageDraw, box, threshold: int = 8) -> None:
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if bayer4(x, y) < threshold:
                d.point((x, y), fill=0)


def px(d: ImageDraw.ImageDraw, pts, v: int = 0) -> None:
    for x, y in pts:
        d.point((x, y), fill=v)


# --- Ground tiles (32x32) -------------------------------------------------

def tile_empty() -> Image.Image:
    return new_img(TILE, TILE, 1)


def tile_path() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    # packed path with edge wear
    d.rectangle((0, 0, 31, 31), outline=0)
    for x, y in ((4, 6), (12, 10), (20, 7), (27, 14), (8, 22), (18, 25), (25, 20), (6, 15)):
        d.point((x, y), fill=0)
    # subtle center groove
    d.line((15, 2, 15, 29), fill=0)
    return img


def tile_dust() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 0, 31, 31), threshold=5)
    # sparse rocks
    d.ellipse((6, 8, 11, 12), outline=0)
    d.ellipse((20, 18, 26, 23), outline=0)
    return img


def tile_canyon() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    for y in (4, 10, 16, 22, 28):
        d.line((0, y, 31, y), fill=0)
    d.line((8, 0, 6, 31), fill=0)
    d.line((22, 0, 24, 31), fill=0)
    return img


def tile_lava() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 0, 31, 31), threshold=6)
    d.ellipse((4, 5, 14, 14), outline=0)
    d.ellipse((16, 15, 28, 26), outline=0)
    d.line((10, 12, 18, 18), fill=0)
    px(d, [(8, 8), (22, 20), (12, 22)])
    return img


def tile_frost() -> Image.Image:
    """Brine pool — water-like checker."""
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    for y in range(TILE):
        for x in range(TILE):
            if (x + y) % 2 == 0:
                d.point((x, y), fill=0)
    # highlight ripples
    for x in range(0, TILE, 6):
        d.point((x, 8), fill=1)
        d.point((x + 2, 18), fill=1)
        d.point((x + 1, 26), fill=1)
    d.ellipse((2, 2, 29, 29), outline=0)
    return img


def tile_colony() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 31, 31), outline=0)
    d.rectangle((1, 1, 30, 30), outline=0)
    d.line((0, 16, 31, 16), fill=0)
    d.line((16, 0, 16, 31), fill=0)
    # rivets
    for x, y in ((4, 4), (28, 4), (4, 28), (28, 28), (16, 4), (16, 28), (4, 16), (28, 16)):
        d.point((x, y), fill=0)
    return img


def tile_wall() -> Image.Image:
    """Cliff / mountain face with ridge highlights."""
    img = new_img(TILE, TILE, 0)
    d = ImageDraw.Draw(img)
    d.line((0, 10, 8, 4, 16, 12, 24, 3, 31, 9), fill=1)
    d.line((0, 18, 10, 14, 20, 20, 31, 15), fill=1)
    px(d, [(5, 22), (12, 26), (19, 23), (27, 28), (8, 8), (22, 7)], 1)
    return img


def tile_outpost_pad() -> Image.Image:
    """Ground under building (tilemap cell). Building drawn as tall sprite."""
    img = tile_colony()
    d = ImageDraw.Draw(img)
    d.rectangle((10, 20, 21, 30), outline=0)
    return img


def tile_lab_pad() -> Image.Image:
    return tile_outpost_pad()


def tile_tube() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 0, 31, 31), threshold=4)
    d.ellipse((4, 4, 27, 27), fill=0)
    d.ellipse((8, 8, 23, 23), fill=1)
    d.ellipse((12, 12, 19, 24), fill=0)
    return img


def tile_ruins_pad() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 0, 31, 31), threshold=5)
    d.rectangle((3, 10, 14, 30), outline=0)
    d.rectangle((16, 6, 28, 30), outline=0)
    d.line((3, 18, 14, 18), fill=0)
    px(d, [(6, 26), (20, 24), (24, 28)])
    return img


def tile_grass() -> Image.Image:
    """Dustreed encounter field — tall stalks, classic RPG grass cue."""
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 20, 31, 31), threshold=6)
    for x in range(2, 32, 4):
        h = 14 + (x * 3) % 10
        d.line((x, 30 - h, x, 30), fill=0)
        d.line((x, 30 - h, x + 1, 30 - h - 2), fill=0)
        d.point((x - 1, 30 - h + 4), fill=0)
    return img


def tile_dome_pad() -> Image.Image:
    img = tile_colony()
    d = ImageDraw.Draw(img)
    d.arc((4, 4, 27, 27), 200, 340, fill=0)
    return img


def tile_walkway() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    for y in range(0, TILE, 4):
        d.line((0, y, 31, y), fill=0)
    d.line((0, 0, 0, 31), fill=0)
    d.line((31, 0, 31, 31), fill=0)
    d.line((15, 0, 15, 31), fill=0)
    return img


def tile_crater() -> Image.Image:
    img = new_img(TILE, TILE, 1)
    d = ImageDraw.Draw(img)
    dither_rect(d, (0, 0, 31, 31), threshold=4)
    d.ellipse((2, 4, 29, 28), outline=0)
    d.ellipse((8, 10, 23, 22), outline=0)
    return img


def tile_spire_stump() -> Image.Image:
    """Ground marker; tall crystal drawn as overlay sprite."""
    img = tile_dust()
    d = ImageDraw.Draw(img)
    d.rectangle((13, 18, 18, 30), fill=0)
    return img


TILES = [
    tile_empty,        # 1
    tile_path,         # 2 ROCK
    tile_dust,         # 3 DUST
    tile_canyon,       # 4 CANYON
    tile_lava,         # 5 LAVA
    tile_frost,        # 6 FROST
    tile_colony,       # 7 COLONY
    tile_wall,         # 8 WALL
    tile_outpost_pad,  # 9 OUTPOST
    tile_lab_pad,      # 10 LAB
    tile_tube,         # 11 TUBE
    tile_ruins_pad,    # 12 RUINS
    tile_grass,        # 13 ENCOUNTER
    tile_dome_pad,     # 14 DOME
    tile_walkway,      # 15 WALKWAY
    tile_crater,       # 16 CRATER
    tile_spire_stump,  # 17 SPIRE
]


# --- Tall 2.5D props (32 wide x 48 tall) -----------------------------------

def prop_outpost() -> Image.Image:
    img = new_img(32, 48, 1)
    d = ImageDraw.Draw(img)
    # roof
    d.polygon([(2, 18), (16, 4), (29, 18)], fill=0)
    d.polygon([(4, 18), (16, 7), (27, 18)], fill=1)
    d.line([(4, 18), (16, 7), (27, 18)], fill=0)
    # body
    d.rectangle((4, 18, 27, 45), outline=0)
    d.rectangle((5, 19, 26, 44), fill=1)
    # windows
    d.rectangle((8, 24, 12, 28), fill=0)
    d.rectangle((19, 24, 23, 28), fill=0)
    # door
    d.rectangle((13, 32, 18, 45), fill=0)
    # antenna
    d.line((16, 4, 16, 0), fill=0)
    d.point((16, 0), fill=0)
    return img


def prop_lab() -> Image.Image:
    img = new_img(32, 48, 1)
    d = ImageDraw.Draw(img)
    d.rectangle((3, 10, 28, 45), outline=0)
    d.rectangle((4, 11, 27, 16), fill=0)
    d.rectangle((4, 17, 27, 44), fill=1)
    d.rectangle((4, 17, 27, 44), outline=0)
    # dish
    d.arc((10, 0, 22, 12), 0, 180, fill=0)
    d.line((16, 12, 16, 10), fill=0)
    # windows
    d.rectangle((7, 22, 11, 28), outline=0)
    d.rectangle((20, 22, 24, 28), outline=0)
    d.line((9, 22, 9, 28), fill=0)
    d.line((22, 22, 22, 28), fill=0)
    # door
    d.rectangle((13, 33, 18, 45), fill=0)
    return img


def prop_ruins() -> Image.Image:
    img = new_img(32, 48, 1)
    d = ImageDraw.Draw(img)
    d.rectangle((2, 16, 14, 45), outline=0)
    d.rectangle((16, 8, 29, 45), outline=0)
    d.line((2, 28, 14, 28), fill=0)
    d.line((16, 22, 29, 22), fill=0)
    # broken top
    d.line((16, 8, 22, 14), fill=0)
    px(d, [(5, 40), (10, 42), (20, 38), (26, 43)])
    return img


def prop_dome() -> Image.Image:
    img = new_img(32, 48, 1)
    d = ImageDraw.Draw(img)
    d.ellipse((2, 8, 29, 40), outline=0)
    d.arc((2, 8, 29, 40), 200, 340, fill=0)
    d.rectangle((12, 30, 19, 45), outline=0)
    d.line((2, 28, 29, 28), fill=0)
    return img


def prop_spire() -> Image.Image:
    img = new_img(32, 48, 1)
    d = ImageDraw.Draw(img)
    d.polygon([(16, 2), (8, 30), (24, 30)], fill=0)
    d.polygon([(16, 6), (11, 28), (21, 28)], fill=1)
    d.line([(16, 6), (11, 28), (21, 28), (16, 6)], fill=0)
    d.rectangle((13, 30, 18, 45), fill=0)
    return img


PROPS = {
    "outpost": prop_outpost,
    "lab": prop_lab,
    "ruins": prop_ruins,
    "dome": prop_dome,
    "spire": prop_spire,
}


# --- Player (32x32, 8 frames) ---------------------------------------------

def player_frames() -> list[Image.Image]:
    frames = []

    def draw(facing: str, step: int) -> Image.Image:
        img = new_img(32, 32, 1)
        d = ImageDraw.Draw(img)
        # drop shadow
        d.ellipse((8, 26, 23, 31), fill=0)
        # backpack
        if facing == "up":
            d.rectangle((11, 14, 20, 23), fill=0)
        else:
            d.rectangle((9, 15, 11, 22), fill=0)
            d.rectangle((20, 15, 22, 22), fill=0)
        # torso
        d.rectangle((11, 13, 20, 23), fill=0)
        # helmet
        d.ellipse((10, 4, 21, 16), outline=0)
        d.ellipse((11, 5, 20, 15), fill=0)
        if facing == "down":
            d.rectangle((12, 8, 19, 12), fill=1)
            d.point((14, 10), fill=0)
            d.point((17, 10), fill=0)
        elif facing == "up":
            d.rectangle((12, 6, 19, 10), fill=0)
        elif facing == "left":
            d.rectangle((10, 8, 15, 12), fill=1)
            d.point((11, 10), fill=0)
        else:
            d.rectangle((16, 8, 21, 12), fill=1)
            d.point((20, 10), fill=0)
        # legs
        if step == 0:
            d.rectangle((12, 23, 14, 29), fill=0)
            d.rectangle((17, 23, 19, 29), fill=0)
        else:
            d.rectangle((11, 23, 13, 28), fill=0)
            d.rectangle((18, 23, 20, 30), fill=0)
        # arms
        if facing in ("down", "up"):
            d.rectangle((8, 15, 10, 20), fill=0)
            d.rectangle((21, 15, 23, 20), fill=0)
        return img

    for facing in ("down", "up", "left", "right"):
        for step in (0, 1):
            frames.append(draw(facing, step))
    return frames


def make_table(tiles: list[Image.Image], path: Path) -> None:
    w, h = tiles[0].size
    sheet = Image.new("1", (w * len(tiles), h), color=1)
    for i, tile in enumerate(tiles):
        sheet.paste(tile, (i * w, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(f"wrote {path} ({sheet.size[0]}x{sheet.size[1]}, {len(tiles)} frames)")


def card_image() -> Image.Image:
    img = new_img(350, 155, 1)
    d = ImageDraw.Draw(img)
    d.rectangle((6, 6, 343, 148), outline=0, width=3)
    # mini map with 32-scale chunks
    for y in range(20, 130, 20):
        for x in range(18, 150, 20):
            d.rectangle((x, y, x + 18, y + 18), outline=0)
    for x in range(30, 120, 4):
        d.line((x, 90, x, 120), fill=0)
    d.polygon([(60, 50), (80, 30), (100, 50)], fill=0)
    d.rectangle((64, 50, 96, 80), outline=0)
    d.rectangle((170, 40, 330, 78), outline=0, width=2)
    d.rectangle((170, 90, 300, 112), outline=0)
    return img


def launch_image() -> Image.Image:
    img = new_img(400, 240, 1)
    d = ImageDraw.Draw(img)
    d.line((0, 150, 399, 150), fill=0)
    for x in range(0, 400, 32):
        d.rectangle((x, 150, x + 31, 239), outline=0)
    for x in range(24, 200, 5):
        d.line((x, 110, x, 149), fill=0)
    d.polygon([(250, 105), (290, 70), (330, 105)], fill=0)
    d.rectangle((258, 105, 322, 150), outline=0)
    d.rectangle((120, 28, 280, 70), outline=0, width=2)
    return img


def main() -> None:
    IMG.mkdir(parents=True, exist_ok=True)
    make_table([t() for t in TILES], IMG / "tiles-table-32-32.png")
    make_table(player_frames(), IMG / "player-table-32-32.png")

    prop_frames = [PROPS[k]() for k in ("outpost", "lab", "ruins", "dome", "spire")]
    # sequential-style via matrix table 32x48
    make_table(prop_frames, IMG / "props-table-32-48.png")

    # remove old 16px sheets if present so pdc doesn't get confused
    for stale in (
        IMG / "tiles-table-16-16.png",
        IMG / "player-table-16-16.png",
    ):
        if stale.exists():
            stale.unlink()
            print(f"removed stale {stale.name}")

    sys_assets = ROOT / "source" / "SystemAssets"
    sys_assets.mkdir(parents=True, exist_ok=True)
    card_image().save(sys_assets / "card.png")
    launch_image().save(sys_assets / "launchImage.png")
    print(f"wrote {sys_assets / 'card.png'}")
    print(f"wrote {sys_assets / 'launchImage.png'}")


if __name__ == "__main__":
    main()
