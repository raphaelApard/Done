#!/usr/bin/env python3
"""Regenerates the raster app icons from the Done logo geometry.

The geometry is the one in assets/logo/logo.svg (100 x 100 grid). Only the
PNG files are produced here; the Android vector layers, the Contents.json
files and the launch screens are plain files kept in the repository.

Usage, from the repository root:

    pip install pillow
    python3 tool/generate_icons.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

INK = (0x20, 0x1E, 0x1D)
PAPER = (0xF3, 0xF2, 0xF2)
CYAN_LIGHT = (0x62, 0xC5, 0xEE)
TINT = (0x45, 0x41, 0x41)

STROKE = 11.0
SUPERSAMPLE = 4
RING_START, RING_END, RING_RADIUS = (78, 26), (84, 60), 36
CHECK = [(34, 52), (50, 68), (90, 22)]


def arc(p1, p2, r, large, sweep):
    """SVG endpoint arc -> (cx, cy, start angle, sweep angle), radians (F.6.5)."""
    (x1, y1), (x2, y2) = p1, p2
    x1p, y1p = (x1 - x2) / 2, (y1 - y2) / 2
    lam = (x1p**2 + y1p**2) / r**2
    if lam > 1:
        r *= math.sqrt(lam)
    coef = math.sqrt(max(0.0, (r**4 - r**2 * (x1p**2 + y1p**2)) / (r**2 * (x1p**2 + y1p**2))))
    if large == sweep:
        coef = -coef
    cxp, cyp = coef * y1p, -coef * x1p
    cx, cy = cxp + (x1 + x2) / 2, cyp + (y1 + y2) / 2
    ux, uy = (x1p - cxp) / r, (y1p - cyp) / r
    vx, vy = (-x1p - cxp) / r, (-y1p - cyp) / r
    start = math.atan2(uy, ux)
    delta = math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    if not sweep and delta > 0:
        delta -= 2 * math.pi
    if sweep and delta < 0:
        delta += 2 * math.pi
    return cx, cy, start, delta, r


def mark_layers(side, ring_alpha=1.0):
    """Returns (ring mask, check mask) as 'L' images of side x side pixels.

    The mask coordinates are the 100 x 100 grid scaled to `side`.
    """
    s = side * SUPERSAMPLE
    k = s / 100

    def dot(draw, x, y):
        r = STROKE / 2 * k
        draw.ellipse((x * k - r, y * k - r, x * k + r, y * k + r), fill=255)

    ring = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(ring)
    cx, cy, a0, da, r = arc(RING_START, RING_END, RING_RADIUS, large=True, sweep=False)
    steps = 720
    angles = [a0 + da * i / steps for i in range(steps + 1)]
    outer = [((cx + (r + STROKE / 2) * math.cos(a)) * k, (cy + (r + STROKE / 2) * math.sin(a)) * k) for a in angles]
    inner = [((cx + (r - STROKE / 2) * math.cos(a)) * k, (cy + (r - STROKE / 2) * math.sin(a)) * k) for a in reversed(angles)]
    d.polygon(outer + inner, fill=255)
    dot(d, *RING_START)
    dot(d, *RING_END)

    check = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(check)
    half = STROKE / 2
    for (x1, y1), (x2, y2) in zip(CHECK, CHECK[1:]):
        length = math.hypot(x2 - x1, y2 - y1)
        nx, ny = -(y2 - y1) / length * half, (x2 - x1) / length * half
        d.polygon([((x1 + nx) * k, (y1 + ny) * k), ((x2 + nx) * k, (y2 + ny) * k),
                   ((x2 - nx) * k, (y2 - ny) * k), ((x1 - nx) * k, (y1 - ny) * k)], fill=255)
    for p in CHECK:
        dot(d, *p)

    if ring_alpha < 1:
        ring = ring.point(lambda v: round(v * ring_alpha))
    return ring, check


def tile(size, bg, ring_rgb, check_rgb, ring_alpha=1.0, radius=0.0, inset=1.0, logo=0.62, lift=0.02):
    """A square icon: rounded background tile with the mark on top.

    size    edge of the canvas in pixels
    radius  corner radius as a share of the tile edge (0 = square)
    inset   share of the canvas taken by the tile (macOS keeps a margin)
    logo    share of the tile taken by the 100 x 100 mark box
    lift    the mark is moved up by this share of its own height
    """
    s = size * SUPERSAMPLE
    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    edge = s * inset
    left = (s - edge) / 2
    if radius:
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle((left, left, left + edge - 1, left + edge - 1), radius=radius * edge, fill=255)
    else:
        mask = Image.new("L", (s, s), 255)
    canvas.paste(Image.new("RGBA", (s, s), bg + (255,)), (0, 0), mask)

    box = edge * logo
    box_px = round(box / SUPERSAMPLE)
    ring, check = mark_layers(max(box_px, 1), ring_alpha)
    ring = ring.resize((round(box), round(box)), Image.LANCZOS)
    check = check.resize((round(box), round(box)), Image.LANCZOS)
    x = round(left + (edge - box) / 2)
    y = round(left + (edge - box) / 2 - lift * box)
    for layer, rgb in ((ring, ring_rgb), (check, check_rgb)):
        ink = Image.new("RGBA", layer.size, rgb + (255,))
        canvas.paste(ink, (x, y), layer)
    return canvas.resize((size, size), Image.LANCZOS)


def principal(size, **kw):
    return tile(size, INK, PAPER, CYAN_LIGHT, **kw)


def save(image, relative, opaque=False, gray=False):
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    if opaque:
        flat = Image.new("RGB", image.size, INK)
        flat.paste(image, mask=image.split()[3])
        image = flat
    if gray:
        image = image.convert("L").convert("RGB")
    image.save(path, optimize=True)
    print("wrote", relative)


def ios():
    base = "ios/Runner/Assets.xcassets/AppIcon.appiconset/"
    save(principal(1024), base + "AppIcon-1024.png", opaque=True)
    save(principal(1024), base + "AppIcon-Dark-1024.png", opaque=True)
    tinted = tile(1024, TINT, PAPER, PAPER, ring_alpha=0.6)
    save(tinted, base + "AppIcon-Tinted-1024.png", opaque=True, gray=True)


def android():
    for folder, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
        save(principal(px, radius=0.225), f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png")


def web():
    save(principal(32, radius=0.225), "web/favicon.png")
    for px in (192, 512):
        save(principal(px, radius=0.225), f"web/icons/Icon-{px}.png")
        save(principal(px), f"web/icons/Icon-maskable-{px}.png", opaque=True)


def macos():
    for px in (16, 32, 64, 128, 256, 512, 1024):
        # 824 of 1024 px: the margin macOS expects around a Big Sur style icon.
        save(principal(px, radius=0.225, inset=824 / 1024), f"macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{px}.png")


if __name__ == "__main__":
    ios()
    android()
    web()
    macos()
