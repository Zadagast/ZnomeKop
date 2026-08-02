"""Curate generated art sheets into clean 1-bit game sprites.

Authoring-time helper: takes a drawn sheet, splits it into cells, and
converts each to a centered 1-bit PNG at the target size. The committed
PNGs are the canonical art; the build itself never runs this.

Usage:
    python3 tools/extract_art.py <sheet.png> <outdir> name1 name2 ... \
        [--size 32] [--fit 30] [--threshold 170] [--cells N] [--grid COLSxROWS]
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def load_ink(path: Path, threshold: int) -> tuple[Image.Image, np.ndarray]:
    im = Image.open(path).convert("L")
    ink = np.array(im) < threshold
    return im, ink


def split_by_gaps(ink: np.ndarray, want: int) -> list[tuple[int, int]]:
    """Column ranges for `want` sprites, splitting merged blobs at ink valleys."""
    colink = ink.any(axis=0)
    cols = np.where(colink)[0]
    if len(cols) == 0:
        raise SystemExit("sheet has no ink")

    def clusters(gap: int) -> list[tuple[int, int]]:
        out = []
        start = prev = cols[0]
        for c in cols[1:]:
            if c - prev > gap:
                out.append((int(start), int(prev)))
                start = c
            prev = c
        out.append((int(start), int(prev)))
        return out

    # Widest gap threshold that still yields enough groups
    best = clusters(4)
    for gap in range(4, 80):
        cl = clusters(gap)
        if len(cl) < want:
            break
        best = cl
    regions = best

    # Merged groups get split at lowest-ink-density columns
    while len(regions) < want:
        widest = max(range(len(regions)), key=lambda i: regions[i][1] - regions[i][0])
        x0, x1 = regions[widest]
        density = ink[:, x0:x1 + 1].sum(axis=0).astype(float)
        density = np.convolve(density, np.ones(15) / 15, mode="same")
        w = x1 - x0
        lo, hi = int(w * 0.30), int(w * 0.70)
        if hi <= lo:
            break
        cut = x0 + int(np.argmin(density[lo:hi]) + lo)
        regions[widest:widest + 1] = [(x0, cut), (cut + 1, x1)]
        regions.sort()

    if len(regions) > want:
        # keep the widest `want` regions, in left-to-right order
        regions = sorted(sorted(regions, key=lambda r: r[0] - r[1])[:want])
    return regions


def split_by_grid(ink: np.ndarray, cols: int, rows: int) -> list[tuple[int, int, int, int]]:
    h, w = ink.shape
    cw, ch = w // cols, h // rows
    return [(c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)
            for r in range(rows) for c in range(cols)]


def cell_to_sprite(im: Image.Image, ink: np.ndarray, box, size: tuple[int, int],
                   fit: tuple[int, int], threshold: int,
                   anchor: str = "center") -> Image.Image | None:
    """Tight-crop the ink in `box`, fit inside `fit`, place in a `size` cell."""
    x0, y0, x1, y1 = box
    sub = ink[y0:y1, x0:x1]
    if not sub.any():
        return None
    rows = np.where(sub.any(axis=1))[0]
    cols = np.where(sub.any(axis=0))[0]
    cx0, cx1 = x0 + int(cols[0]), x0 + int(cols[-1])
    cy0, cy1 = y0 + int(rows[0]), y0 + int(rows[-1])

    crop = im.crop((cx0, cy0, cx1 + 1, cy1 + 1))
    w, h = crop.size
    scale = min(fit[0] / w, fit[1] / h)
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    small = crop.resize((nw, nh), Image.LANCZOS)
    bit = small.point(lambda p: 0 if p < threshold else 255, mode="L").convert("1")

    out = Image.new("1", size, 1)
    ox = (size[0] - nw) // 2
    oy = (size[1] - nh) if anchor == "bottom" else (size[1] - nh) // 2
    out.paste(bit, (ox, oy))
    return out


def extract(sheet: Path, outdir: Path, names: list[str], size: tuple[int, int],
            fit: tuple[int, int], threshold: int, grid: tuple[int, int] | None,
            anchor: str = "center") -> list[Path]:
    im, ink = load_ink(sheet, threshold=128)
    outdir.mkdir(parents=True, exist_ok=True)
    written = []

    if grid:
        boxes = split_by_grid(ink, grid[0], grid[1])
    else:
        regions = split_by_gaps(ink, len(names))
        boxes = [(x0, 0, x1 + 1, ink.shape[0]) for x0, x1 in regions]

    for i, name in enumerate(names):
        if i >= len(boxes):
            print(f"  ! no cell for {name}")
            continue
        sprite = cell_to_sprite(im, ink, boxes[i], size, fit, threshold, anchor)
        if sprite is None:
            print(f"  ! empty cell for {name}")
            continue
        path = outdir / f"{name}.png"
        sprite.save(path)
        written.append(path)
        print(f"  wrote {path}")
    return written


def contact_sheet(paths: list[Path], out: Path, scale: int = 4) -> None:
    from PIL import ImageDraw

    imgs = [Image.open(p).convert("1") for p in paths]
    if not imgs:
        return
    w, h = imgs[0].size
    if w * scale > 400:
        scale = max(1, 400 // w)
    cell_w, cell_h = w * scale + 10, h * scale + 22
    sheet = Image.new("RGB", (cell_w * len(imgs), cell_h), (190, 190, 190))
    d = ImageDraw.Draw(sheet)
    for i, (im, p) in enumerate(zip(imgs, paths)):
        sheet.paste(im.resize((w * scale, h * scale), Image.NEAREST).convert("RGB"),
                    (i * cell_w + 5, 16))
        d.text((i * cell_w + 5, 3), p.stem[:14], fill=0)
    sheet.save(out)
    print(f"  preview -> {out}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet", type=Path)
    ap.add_argument("outdir", type=Path)
    ap.add_argument("names", nargs="+")
    ap.add_argument("--size", type=str, default="32", help="N or WxH")
    ap.add_argument("--fit", type=str, default=None, help="N or WxH (default: size-2)")
    ap.add_argument("--threshold", type=int, default=170)
    ap.add_argument("--grid", type=str, default=None, help="COLSxROWS")
    ap.add_argument("--anchor", choices=["center", "bottom"], default="center")
    ap.add_argument("--preview", type=Path, default=None)
    args = ap.parse_args()

    def pair(value: str) -> tuple[int, int]:
        if "x" in value.lower():
            a, b = value.lower().split("x")
            return int(a), int(b)
        return int(value), int(value)

    size = pair(args.size)
    fit = pair(args.fit) if args.fit else (size[0] - 2, size[1] - 2)

    grid = None
    if args.grid:
        grid = pair(args.grid)

    print(f"extracting {len(args.names)} sprites from {args.sheet}")
    written = extract(args.sheet, args.outdir, args.names, size,
                      fit, args.threshold, grid, args.anchor)
    if args.preview:
        contact_sheet(written, args.preview)


if __name__ == "__main__":
    main()
