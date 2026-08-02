"""Procedural sprite generation for Znome creatures.

Port of the mask/mirror/outline algorithm from
zfedoran/pixel-sprite-generator (MIT, (c) 2014 Zelimir Fedoran),
which implements Dave Bollinger's "Pixel Spaceships" technique:
half-masks are randomized, mirrored, and outlined to produce endless
coherent symmetric sprites.

Mask cell values:
    0  always empty
    1  randomly empty or body
    2  randomly body or border
   -1  always border
"""

from __future__ import annotations

import random

from PIL import Image

# 6-wide half-masks, mirrored on X to 12 wide.

QUADRUPED = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1],
    [0, 0, 0, 1, 1, 2],
    [0, 0, 1, 1, 2, 2],
    [0, 0, 1, 2, 2, 2],
    [0, 1, 1, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 0, 1, 2, 2, 2],
    [0, 0, 1, 1, 2, 2],
    [0, 0, 0, 1, 0, 1],
    [0, 0, 0, 1, 0, 1],
]

FLYER = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1],
    [0, 1, 1, 0, 1, 2],
    [1, 1, 2, 1, 2, 2],
    [1, 2, 2, 2, 2, 2],
    [1, 2, 2, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 0, 1, 1, 2, 2],
    [0, 0, 0, 1, 1, 2],
    [0, 0, 0, 0, 1, 1],
    [0, 0, 0, 0, 0, 1],
    [0, 0, 0, 0, 0, 0],
]

BLOB = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 1, 1, 2, 2],
    [0, 1, 1, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 1, 2, 2, 2, 2],
    [0, 1, 1, 2, 2, 2],
    [0, 0, 1, 1, 2, 2],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 0, 0, 0],
]

MASKS = {
    "quadruped": QUADRUPED,
    "flyer": FLYER,
    "blob": BLOB,
}


def _generate(mask: list[list[int]], rng: random.Random) -> list[list[int]]:
    """Randomize a half-mask and mirror it on X. 1=body, -1=border, 0=empty."""
    h = len(mask)
    half_w = len(mask[0])
    w = half_w * 2
    grid = [[0] * w for _ in range(h)]

    for y in range(h):
        for x in range(half_w):
            v = mask[y][x]
            if v == 1:
                v = 1 if rng.random() > 0.5 else 0
            elif v == 2:
                v = 1 if rng.random() > 0.5 else -1
            grid[y][x] = v
            grid[y][w - 1 - x] = v

    # Outline: empty neighbors of body become border
    for y in range(h):
        for x in range(w):
            if grid[y][x] == 1:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and grid[ny][nx] == 0:
                        grid[ny][nx] = -1
    return grid


def creature_sprite(seed: str, mask_name: str, size: int = 32) -> Image.Image:
    """Render a deterministic creature: black outline, white body, white bg.

    Returned as mode '1' image (white background; caller may alpha-key white).
    """
    rng = random.Random(seed)
    mask = MASKS[mask_name]
    # A couple of rerolls so thin/degenerate bodies are rare
    best = None
    best_mass = -1
    for _ in range(3):
        grid = _generate(mask, rng)
        mass = sum(1 for row in grid for v in row if v == 1)
        if mass > best_mass:
            best_mass = mass
            best = grid
    grid = best

    h = len(grid)
    w = len(grid[0])
    im = Image.new("1", (w, h), 1)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if grid[y][x] == -1:
                px[x, y] = 0

    scale = max(1, size // max(w, h) )
    im = im.resize((w * scale, h * scale), Image.NEAREST)
    out = Image.new("1", (size, size), 1)
    out.paste(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out
