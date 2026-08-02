"""Hand-authored pixel art for ZnomeKop.

Sprites are authored as 16x16 text grids (GB proportions) and scaled
2x nearest-neighbor to 32x32. Every pixel is deliberate.

Legend: '#' = black ink, '.' = transparent/white
"""

from __future__ import annotations

from PIL import Image

# --- Player: Mars explorer, GB proportions (big helmet, chunky suit) -------
# 6 authored frames; right = mirrored left.

PLAYER_DOWN_0 = """
....########....
..##........##..
.#............#.
.#............#.
.#..##....##..#.
.#............#.
..#..........#..
...##########...
..#.########.#..
..#.#......#.#..
..#.#......#.#..
..###......###..
....#......#....
....########....
....##....##....
...###....###...
"""

PLAYER_DOWN_1 = """
....########....
..##........##..
.#............#.
.#............#.
.#..##....##..#.
.#............#.
..#..........#..
...##########...
..#.########.#..
..#.#......#.#..
..#.#......#.#..
..###......###..
....#......#....
....########....
...##.....##....
..###.....###...
"""

PLAYER_UP_0 = """
....########....
..##........##..
.#............#.
.#............#.
.#............#.
.#............#.
..#..........#..
...##########...
..#.########.#..
..#.#.####.#.#..
..#.#.#..#.#.#..
..###.####.###..
....#......#....
....########....
....##....##....
...###....###...
"""

PLAYER_UP_1 = """
....########....
..##........##..
.#............#.
.#............#.
.#............#.
.#............#.
..#..........#..
...##########...
..#.########.#..
..#.#.####.#.#..
..#.#.#..#.#.#..
..###.####.###..
....#......#....
....########....
....##.....##...
...###.....###..
"""

PLAYER_LEFT_0 = """
....########....
..##........##..
.#............#.
.#............#.
.#.#####......#.
.#............#.
..#..........#..
...##########...
...########.....
...#......###...
...#......###...
...#......###...
...#......#.....
...########.....
....##..##......
...###..###.....
"""

PLAYER_LEFT_1 = """
....########....
..##........##..
.#............#.
.#............#.
.#.#####......#.
.#............#.
..#..........#..
...##########...
...########.....
...#......###...
...#......###...
...#......###...
...#......#.....
...########.....
...##....##.....
..###....###....
"""


def parse(grid: str) -> Image.Image:
    """Text grid -> 16x16 mode '1' image (white bg, black ink)."""
    rows = [r for r in grid.strip().splitlines()]
    assert len(rows) == 16, f"need 16 rows, got {len(rows)}"
    img = Image.new("1", (16, 16), 1)
    px = img.load()
    for y, row in enumerate(rows):
        assert len(row) == 16, f"row {y} has {len(row)} cols"
        for x, ch in enumerate(row):
            if ch == "#":
                px[x, y] = 0
    return img


def scale2(im: Image.Image) -> Image.Image:
    return im.resize((im.width * 2, im.height * 2), Image.NEAREST)


def player_frames() -> list[Image.Image]:
    down0 = scale2(parse(PLAYER_DOWN_0))
    down1 = scale2(parse(PLAYER_DOWN_1))
    up0 = scale2(parse(PLAYER_UP_0))
    up1 = scale2(parse(PLAYER_UP_1))
    left0 = scale2(parse(PLAYER_LEFT_0))
    left1 = scale2(parse(PLAYER_LEFT_1))
    right0 = left0.transpose(Image.FLIP_LEFT_RIGHT)
    right1 = left1.transpose(Image.FLIP_LEFT_RIGHT)
    return [down0, down1, up0, up1, left0, left1, right0, right1]
