#!/usr/bin/env python3
"""Build the Depth bird keyframes from the supplied 3x3 raster sheet.

This is intentionally a stepped nine-image jump cut.  The source image is
read in normal order as Depth 0, 8, 16, 24, 32, 40, 48, 56 and 64.  Each
keyframe is held for eight Depth values; Depth 64 selects the ninth image.
There is no path interpolation, alpha crossfade, old/new composition,
redrawing or runtime sprite-sheet animation in this generator.  The nine
source cells are exported as nine independent runtime images, preserving the
source ordering and all authored feather/detail changes.
"""

from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path


FRAME_WIDTH = 50
FRAME_HEIGHT = 50
KEYFRAME_COUNT = 9
DEPTHS_PER_KEYFRAME = 8
KEYFRAME_DEPTHS = (0, 8, 16, 24, 32, 40, 48, 56, 64)
SOURCE_KEYFRAME_COORDINATES = (
    (0, 0), (0, 1), (0, 2),
    (1, 0), (1, 1), (1, 2),
    (2, 0), (2, 1), (2, 2),
)
REVIEW_COLUMNS = 9
REVIEW_ROWS = 8
KEYFRAME_PREFIX = "depth-bird-keyframe-"

# Move each complete keyframe upward so the leg included in the supplied
# artwork is naturally visible above the Depth value box.  These offsets are
# calibrated per source leg so every keyframe's actual foot bottom lands on
# the same runtime row; they are not a leg overlay or a shape deformation.
KEYFRAME_VERTICAL_OFFSETS = (-4, -4, -4, -3, -4, -4, -2, -2, -2)

# The supplied 1254x1254 review sheet has nonuniform divider placement.  These
# crops remove the divider lines while retaining each complete source cell.
# Each crop is then placed in the same 418x418 canvas and resized with one
# common scale, so no frame is reconstructed or blended with another.
SOURCE_CELL_SIZE = 418
SOURCE_X = (0, 414, 820)
SOURCE_WIDTH = (411, 402, 434)
SOURCE_Y = (0, 421, 841)
SOURCE_HEIGHT = (419, 417, 413)
SOURCE_BACKGROUND = "#e1dedf"
SOURCE_FUZZ = "6%"


def run(*args: str) -> None:
    subprocess.run([*args], check=True)


def keyframe_index(depth: int) -> int:
    """Map Depth 0..64 to nine held raster states."""
    return min(max(depth, 0) // DEPTHS_PER_KEYFRAME, KEYFRAME_COUNT - 1)


def write_text_if_changed(path: Path, content: str) -> None:
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def extract_keyframe(
    source: Path,
    output: Path,
    keyframe: int,
    scale: int,
) -> None:
    row, column = SOURCE_KEYFRAME_COORDINATES[keyframe]
    output_size = FRAME_WIDTH * scale
    vertical_offset = KEYFRAME_VERTICAL_OFFSETS[keyframe] * scale
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        "magick",
        str(source),
        "-crop",
        f"{SOURCE_WIDTH[column]}x{SOURCE_HEIGHT[row]}+"
        f"{SOURCE_X[column]}+{SOURCE_Y[row]}",
        "+repage",
        "-fuzz",
        SOURCE_FUZZ,
        "-transparent",
        SOURCE_BACKGROUND,
        "-background",
        "none",
        "-gravity",
        "center",
        "-extent",
        f"{SOURCE_CELL_SIZE}x{SOURCE_CELL_SIZE}",
        "-filter",
        "Lanczos",
        "-resize",
        f"{output_size}x{FRAME_HEIGHT * scale}",
    ]

    # ImageMagick -roll is deliberately not used here: it wraps the leg from
    # the bottom of the canvas back to the top when moving the bird upward.
    # Crop the source edge that leaves the canvas, then place the remaining
    # complete bird against the opposite edge with transparent padding.
    if vertical_offset < 0:
        command.extend(
            [
                "-gravity",
                "northwest",
                "-crop",
                f"{output_size}x{output_size + vertical_offset}+0+{-vertical_offset}",
                "+repage",
                "-gravity",
                "north",
                "-background",
                "none",
                "-extent",
                f"{output_size}x{output_size}",
            ]
        )
    elif vertical_offset > 0:
        command.extend(
            [
                "-crop",
                f"{output_size}x{output_size - vertical_offset}+0+0",
                "+repage",
                "-gravity",
                "south",
                "-background",
                "none",
                "-extent",
                f"{output_size}x{output_size}",
            ]
        )

    command.extend(["-strip", str(output)])
    run(*command)


def make_review_sheets(
    keyframe_paths: list[Path],
    output_dir: Path,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="circulate-bird-review-") as name:
        temp_dir = Path(name)

        keyframe_rows: list[Path] = []
        for row in range(3):
            row_path = temp_dir / f"keyframe-row-{row}.png"
            run(
                "magick",
                *(str(keyframe_paths[row * 3 + column]) for column in range(3)),
                "+append",
                str(row_path),
            )
            keyframe_rows.append(row_path)
        run(
            "magick",
            *(str(path) for path in keyframe_rows),
            "-append",
            "-background",
            "#c3c3c3",
            "-alpha",
            "remove",
            "-alpha",
            "off",
            "-resize",
            "500%",
            "-strip",
            str(output_dir / "depth-bird-review-3x3.png"),
        )

        frame_paths = [keyframe_paths[keyframe_index(depth)] for depth in range(65)]
        review_rows: list[Path] = []
        for row in range(REVIEW_ROWS):
            row_path = temp_dir / f"review-row-{row:02d}.png"
            depths = [row * 8 + column for column in range(REVIEW_COLUMNS)]
            run(
                "magick",
                *(str(frame_paths[depth]) for depth in depths),
                "+append",
                str(row_path),
            )
            review_rows.append(row_path)
        run(
            "magick",
            *(str(path) for path in review_rows),
            "-append",
            "-background",
            "#c3c3c3",
            "-alpha",
            "remove",
            "-alpha",
            "off",
            "-resize",
            "500%",
            "-strip",
            str(output_dir / "depth-bird-review-9x8.png"),
        )


def write_svg_manifest(output: Path) -> None:
    groups = []
    for keyframe in range(KEYFRAME_COUNT):
        start = KEYFRAME_DEPTHS[keyframe]
        end = 64 if keyframe == KEYFRAME_COUNT - 1 else KEYFRAME_DEPTHS[keyframe + 1] - 1
        groups.append(
            f'  <image id="keyframe-{keyframe:02d}" data-depth-range="{start}-{end}" '
            f'data-source-cell="{keyframe}" href="{KEYFRAME_PREFIX}{keyframe:02d}.png" '
            f'x="{keyframe * FRAME_WIDTH}" y="0" width="{FRAME_WIDTH}" '
            f'height="{FRAME_HEIGHT}" />'
        )
    content = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{KEYFRAME_COUNT * FRAME_WIDTH}" '
        f'height="{FRAME_HEIGHT}" viewBox="0 0 {KEYFRAME_COUNT * FRAME_WIDTH} '
        f'{FRAME_HEIGHT}">\n'
        '  <!-- Nine independent raster keyframes; each image is held for eight Depth values. -->\n'
        '  <!-- This manifest documents the runtime mapping and is not an animation atlas. -->\n'
        + "\n".join(groups)
        + '\n</svg>\n'
    )
    write_text_if_changed(output, content)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "resource" / "bird",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=None,
        help="3x3 source sheet; defaults to resource/bird/depth-bird-keyframes-source.png",
    )
    parser.add_argument(
        "--review-dir",
        type=Path,
        help="Optional directory for 3x3 and stepped 9x8 review sheets",
    )
    args = parser.parse_args()

    output_dir = args.output_dir.resolve()
    source = (args.source or output_dir / "depth-bird-keyframes-source.png").resolve()
    if not source.exists():
        raise SystemExit(f"keyframe source does not exist: {source}")
    if subprocess.call(["which", "magick"], stdout=subprocess.DEVNULL) != 0:
        raise SystemExit("ImageMagick 'magick' is required to build raster keyframes")

    output_dir.mkdir(parents=True, exist_ok=True)
    write_svg_manifest(output_dir / "depth-bird-keyframes.svg")

    for scale in range(1, 5):
        keyframe_paths = []
        for keyframe in range(KEYFRAME_COUNT):
            suffix = "" if scale == 1 else f"#{scale}x"
            path = output_dir / f"{KEYFRAME_PREFIX}{keyframe:02d}{suffix}.png"
            extract_keyframe(source, path, keyframe, scale)
            keyframe_paths.append(path)

        if args.review_dir is not None and scale == 1:
            make_review_sheets(keyframe_paths, args.review_dir.resolve())

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
