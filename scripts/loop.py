#!/usr/bin/env python3
import math
import random

from PIL import Image
from tqdm import tqdm

# ===== hardcoded config =====
LOGO_PATH = "../gen/logo_square.png"
BACKGROUND_PATH = "../gradient.png"
OUTPUT_PATH = "../variants/loop.png"

OUTPUT_SIZE = 7000
LOGO_COUNT = 270
SEED = None  # e.g. 42

# size variation for the logos
MIN_SCALE = 0.6
MAX_SCALE = 0.85

# density / spacing
BASE_CELL = 220  # smaller = denser
PADDING = 10  # extra gap between logos
MAX_ATTEMPTS = 50000
# ===========================


def paste_wrapped(canvas, img, x, y):
    size = canvas.width
    w, h = img.size

    for dx in (-size, 0, size):
        for dy in (-size, 0, size):
            px = x + dx
            py = y + dy
            if px < size and py < size and px + w > 0 and py + h > 0:
                canvas.alpha_composite(img, (px, py))


def torus_distance(x1, y1, x2, y2, size):
    dx = abs(x1 - x2)
    dy = abs(y1 - y2)
    dx = min(dx, size - dx)
    dy = min(dy, size - dy)
    return math.hypot(dx, dy)


def main():
    random.seed(SEED)

    logo = Image.open(LOGO_PATH).convert("RGBA")
    background = Image.open(BACKGROUND_PATH).convert("RGBA")
    background = background.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)

    canvas = background.copy()

    base_ratio = BASE_CELL / max(logo.width, logo.height)
    placed = []
    attempts = 0

    pbar = tqdm(total=LOGO_COUNT, desc="Placing logos", unit="logo")

    while len(placed) < LOGO_COUNT and attempts < MAX_ATTEMPTS:
        attempts += 1

        scale = base_ratio * random.uniform(MIN_SCALE, MAX_SCALE)
        new_w = max(1, round(logo.width * scale))
        new_h = max(1, round(logo.height * scale))
        resized = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)

        angle = random.uniform(0, 360)
        rotated = resized.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)

        radius = math.hypot(rotated.width, rotated.height) / 2

        cx = random.uniform(0, OUTPUT_SIZE)
        cy = random.uniform(0, OUTPUT_SIZE)

        ok = True
        for other in placed:
            d = torus_distance(cx, cy, other["cx"], other["cy"], OUTPUT_SIZE)
            if d < radius + other["radius"] + PADDING:
                ok = False
                break

        if not ok:
            if attempts % 200 == 0:
                pbar.set_postfix(attempts=attempts, placed=len(placed))
            continue

        x = round(cx - rotated.width / 2)
        y = round(cy - rotated.height / 2)

        paste_wrapped(canvas, rotated, x, y)

        placed.append(
            {
                "cx": cx,
                "cy": cy,
                "radius": radius,
            }
        )

        pbar.update(1)
        pbar.set_postfix(attempts=attempts, placed=len(placed))

    pbar.close()
    canvas.save(OUTPUT_PATH, "PNG")
    print(f"Created: {OUTPUT_PATH}")
    print(f"Placed: {len(placed)} / {LOGO_COUNT}")


if __name__ == "__main__":
    main()
