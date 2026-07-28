"""Convert the supplied Black cat sheets into project-ready Flame sprites."""

from pathlib import Path
import sys

import cv2
import numpy as np
from PIL import Image


FRAME = 256
PADDING = 16
ALPHA_THRESHOLD = 12


def remove_checkerboard(image: Image.Image) -> Image.Image:
    rgba = np.array(image.convert("RGBA"))
    rgb = rgba[:, :, :3]
    neutral = rgb.max(axis=2) - rgb.min(axis=2) < 20
    light = rgb.min(axis=2) > 180
    background = (neutral & light).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(background, 8)
    border_labels = {
        index
        for index, (x, y, width, height, _area) in enumerate(stats)
        if index != 0
        and (x == 0 or y == 0 or x + width == image.width or y + height == image.height)
    }
    rgba[np.isin(labels, list(border_labels)), 3] = 0
    return Image.fromarray(rgba)


def detect_boxes(image: Image.Image) -> list[tuple[int, int, int, int]]:
    alpha = np.array(image.getchannel("A"))
    mask = (alpha > ALPHA_THRESHOLD).astype(np.uint8) * 255
    # Keep nearby frames separate; detached motion marks are optional for these assets.
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    grouped = cv2.morphologyEx(cv2.dilate(mask, kernel), cv2.MORPH_CLOSE, kernel)
    count, labels, stats, centroids = cv2.connectedComponentsWithStats(grouped, 8)
    candidates = [
        (index, centroids[index])
        for index in range(1, count)
        if stats[index, cv2.CC_STAT_AREA] >= 3000
    ]
    candidates.sort(key=lambda item: (item[1][1], item[1][0]))
    boxes = []
    for index, _center in candidates:
        actual = (labels == index) & (mask > 0)
        ys, xs = np.where(actual)
        boxes.append((int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)))
    return boxes


def write_sheet(image: Image.Image, boxes: list[tuple[int, int, int, int]], output: Path) -> None:
    sheet = Image.new("RGBA", (FRAME * len(boxes), FRAME), (0, 0, 0, 0))
    for frame_index, box in enumerate(boxes):
        sprite = image.crop(box)
        sprite.thumbnail((FRAME - PADDING * 2, FRAME - PADDING * 2), Image.Resampling.LANCZOS)
        x = frame_index * FRAME + (FRAME - sprite.width) // 2
        y = (FRAME - sprite.height) // 2
        sheet.alpha_composite(sprite, (x, y))
    sheet.save(output, "PNG", optimize=True)
    print(f"{output.name}: {len(boxes)} frames, {sheet.size}")


def prepare(source: Path, output_dir: Path, name: str, select: tuple[int, int] | None = None) -> None:
    image = remove_checkerboard(Image.open(source))
    boxes = detect_boxes(image)
    if select is not None:
        boxes = boxes[select[0] : select[1]]
    if not boxes:
        raise ValueError(f"{source.name}: no sprite boxes found")
    write_sheet(image, boxes, output_dir / name)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: prepare_black_assets.py <clipboard-directory>")
    root = Path(sys.argv[1])
    output = Path("assets/images/Cat/Black")
    output.mkdir(parents=True, exist_ok=True)

    # The eight supplied sheets are mapped by their visible action and frame count.
    prepare(root / "codex-clipboard-919eb21d-1062-403e-9346-6b33e5993316.png", output, "cat-black-drop-success.png")
    prepare(root / "codex-clipboard-ebac7103-66b7-4ad9-a7e2-1dc22b88f02d.png", output, "cat-black-panic.png")
    prepare(root / "codex-clipboard-f4de43a5-3568-492f-b393-726692d9203d.png", output, "cat-black-dragged.png")
    prepare(root / "codex-clipboard-f8354478-fc5a-46af-b03d-e7d79dc997c7.png", output, "cat-black-run.png")
    prepare(root / "codex-clipboard-15ab82de-f7cd-4e9a-95dd-17310f9ed980.png", output, "cat-black-walk.png")
    prepare(root / "codex-clipboard-a459ed17-b05b-4da2-9edc-71019c6bc17f.png", output, "cat-black-dash-escape.png")
    prepare(root / "codex-clipboard-e05ca588-cca3-4857-8ab1-4e4276b1d8e2.png", output, "cat-black-idle.png")

    mixed = remove_checkerboard(Image.open(root / "codex-clipboard-038cc58e-a0f0-4a62-bb92-bc8fa7df5cc7.png"))
    mixed_boxes = detect_boxes(mixed)
    if len(mixed_boxes) != 10:
        raise ValueError(f"Mixed sheet: expected 10 boxes, found {len(mixed_boxes)}")
    write_sheet(mixed, mixed_boxes[:5], output / "cat-black-celebrate.png")
    write_sheet(mixed, mixed_boxes[5:], output / "cat-black-drop-wrong.png")

    vanish = remove_checkerboard(
        Image.open(root / "codex-clipboard-44b57750-2616-416d-a0e9-4e1b397a33ad.png")
    )
    vanish_boxes = detect_boxes(vanish)
    if len(vanish_boxes) != 6:
        raise ValueError(f"Vanish sheet: expected 6 boxes, found {len(vanish_boxes)}")
    write_sheet(vanish, vanish_boxes, output / "cat-black-vanish.png")

    # Requested playback order: source frames 1, 3, 5, 6, 4, 2.
    vanish_path = output / "cat-black-vanish.png"
    vanish_sheet = Image.open(vanish_path).convert("RGBA")
    frame_order = [0, 2, 4, 5, 3, 1]
    reordered = Image.new("RGBA", (FRAME * 6, FRAME), (0, 0, 0, 0))
    for target_index, source_index in enumerate(frame_order):
        frame = vanish_sheet.crop((source_index * FRAME, 0, (source_index + 1) * FRAME, FRAME))
        reordered.alpha_composite(frame, (target_index * FRAME, 0))
    reordered.save(vanish_path, "PNG", optimize=True)

    # Use the first vanish frame as the canonical Black cat pose for idle.
    idle_path = output / "cat-black-idle.png"
    idle = Image.open(idle_path).convert("RGBA")
    canonical = Image.open(output / "cat-black-vanish.png").convert("RGBA").crop((0, 0, FRAME, FRAME))
    fixed_idle = Image.new("RGBA", (FRAME * 6, FRAME), (0, 0, 0, 0))
    for frame_index in range(6):
        fixed_idle.alpha_composite(canonical, (frame_index * FRAME, 0))
    fixed_idle.save(idle_path, "PNG", optimize=True)
