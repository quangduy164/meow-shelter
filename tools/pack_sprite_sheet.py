"""Pack separated alpha sprites into centered square frames."""

from pathlib import Path
import sys

import cv2
import numpy as np
from PIL import Image


FRAME_SIZE = 256
PADDING = 16
ALPHA_THRESHOLD = 12


def remove_border_black(image: Image.Image) -> Image.Image:
    rgba = np.array(image)
    rgb = rgba[:, :, :3]
    dark = (rgb.max(axis=2) < 45).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(dark, 8)
    border_labels = set()
    for index, (x, y, width, height, _area) in enumerate(stats):
        if index != 0 and (x == 0 or y == 0 or x + width == image.width or y + height == image.height):
            border_labels.add(index)
    background = np.isin(labels, list(border_labels))
    rgba[background, 3] = 0
    return Image.fromarray(rgba, "RGBA")


def find_sprite_boxes(image: Image.Image, frame_count: int) -> list[tuple[int, int, int, int]]:
    alpha = np.array(image.getchannel("A"))
    mask = (alpha > ALPHA_THRESHOLD).astype(np.uint8) * 255

    # Join small detached effects (sparkles, motion marks) to their nearby cat.
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    grouped = cv2.dilate(mask, kernel, iterations=1)
    grouped = cv2.morphologyEx(grouped, cv2.MORPH_CLOSE, kernel)
    count, labels, stats, centroids = cv2.connectedComponentsWithStats(grouped, 8)

    candidates = []
    for index in range(1, count):
        x, y, width, height, area = stats[index]
        if area >= 3000:
            candidates.append((index, x, y, width, height, area, centroids[index]))

    if len(candidates) != frame_count:
        raise ValueError(
            f"Expected {frame_count} sprite groups, detected {len(candidates)}"
        )

    # Reading order: group centers into rows, then sort each row by x.
    candidates.sort(key=lambda item: (item[6][1], item[6][0]))
    rows: list[list[tuple]] = []
    row_tolerance = image.height * 0.25
    for candidate in candidates:
        if not rows or abs(candidate[6][1] - np.mean([c[6][1] for c in rows[-1]])) > row_tolerance:
            rows.append([candidate])
        else:
            rows[-1].append(candidate)

    ordered = [candidate for row in rows for candidate in sorted(row, key=lambda item: item[6][0])]
    boxes = []
    for index, x, y, width, height, _area, _center in ordered:
        actual = (labels == index) & (mask > 0)
        ys, xs = np.where(actual)
        if len(xs) == 0:
            raise ValueError("Detected sprite group has no opaque pixels")
        boxes.append((int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)))
    return boxes


def pack(input_path: Path, output_path: Path, frame_count: int, scale: float = 1.0) -> None:
    image = Image.open(input_path).convert("RGBA")
    boxes = find_sprite_boxes(image, frame_count)
    output = Image.new("RGBA", (FRAME_SIZE * frame_count, FRAME_SIZE), (0, 0, 0, 0))

    for frame_index, box in enumerate(boxes):
        sprite = image.crop(box)
        sprite.thumbnail((FRAME_SIZE - PADDING * 2, FRAME_SIZE - PADDING * 2), Image.Resampling.LANCZOS)
        if scale != 1.0:
            sprite = sprite.resize(
                (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
                Image.Resampling.LANCZOS,
            )
        x = frame_index * FRAME_SIZE + (FRAME_SIZE - sprite.width) // 2
        y = (FRAME_SIZE - sprite.height) // 2
        output.alpha_composite(sprite, (x, y))

    output.save(output_path, "PNG", optimize=True)
    print(f"{input_path.name}: detected {len(boxes)} frames -> {output.size} -> {output_path}")


def pack_fixed_grid(input_path: Path, output_path: Path, frame_count: int, scale: float) -> None:
    image = Image.open(input_path).convert("RGBA")
    if image.size != (FRAME_SIZE * frame_count, FRAME_SIZE):
        raise ValueError(f"Expected {(FRAME_SIZE * frame_count, FRAME_SIZE)}, got {image.size}")
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    for frame_index in range(frame_count):
        frame = image.crop((frame_index * FRAME_SIZE, 0, (frame_index + 1) * FRAME_SIZE, FRAME_SIZE))
        alpha = np.array(frame.getchannel("A"))
        ys, xs = np.where(alpha > ALPHA_THRESHOLD)
        if len(xs) == 0:
            continue
        sprite = frame.crop((int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)))
        sprite = sprite.resize(
            (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
            Image.Resampling.LANCZOS,
        )
        x = frame_index * FRAME_SIZE + (FRAME_SIZE - sprite.width) // 2
        y = (FRAME_SIZE - sprite.height) // 2
        output.alpha_composite(sprite, (x, y))
    output.save(output_path, "PNG", optimize=True)
    print(f"{input_path.name}: resized {frame_count} fixed frames -> {output.size} -> {output_path}")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(
            "Usage: pack_sprite_sheet.py <input> <output> <frame_count> "
            "[--remove-border-black] [--scale <factor>]"
        )
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    frame_count = int(sys.argv[3])
    scale = 1.0
    source = Image.open(input_path).convert("RGBA")
    options = sys.argv[4:]
    if "--remove-border-black" in options:
        source = remove_border_black(source)
    if "--scale" in options:
        scale_index = options.index("--scale")
        scale = float(options[scale_index + 1])
    temporary = output_path.with_suffix(".sprite-source.png")
    source.save(temporary, "PNG")
    if "--fixed-grid" in options:
        pack_fixed_grid(temporary, output_path, frame_count, scale)
    else:
        pack(temporary, output_path, frame_count, scale)
    temporary.unlink()
