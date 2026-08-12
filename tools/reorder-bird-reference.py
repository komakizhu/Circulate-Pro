#!/usr/bin/env python3
"""Reorder the supplied 6x7 bird reference sheet into one monotonic sequence.

This tool deliberately does not redraw, blend, interpolate or alter any bird
cell.  It only crops the 42 existing cells and places them in a new order so
the visual detail increases continuously from left to right, top to bottom.
The order is kept explicit for visual review and can be revised without
changing the production 65-frame generator.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


SOURCE_COLUMNS = 7
SOURCE_ROWS = 6
CELL_WIDTH = 190
SOURCE_CELL_HEIGHT = 197
SOURCE_CROP_HEIGHT = 190
OUTPUT_CELL_HEIGHT = 197
TOP_OVERLAP = 20
CELL_COUNT = SOURCE_COLUMNS * SOURCE_ROWS

# Source coordinates are (row, column).  This is a manual visual ordering of
# the supplied sheet: the first cells are flat, then crest/wing detail grows,
# and the final cells contain the fullest head, chest, wing and tail layering.
SOURCE_ORDER: tuple[tuple[int, int], ...] = (
    # Flat silhouette / no visible feather layering.
    (0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (2, 0), (3, 0),
    # First crest and first internal feather marks.
    (0, 3), (1, 2), (2, 1), (3, 1), (4, 0),
    # One clear wing/tail layer.
    (0, 4), (1, 3), (2, 2), (3, 2), (4, 1), (5, 0),
    # Chest and tail detail become continuous.
    (0, 5), (1, 4), (2, 3), (3, 3), (4, 2), (5, 1),
    # Several wing rows and stronger head detail.
    (0, 6), (1, 5), (2, 4), (3, 4), (4, 3), (5, 2),
    # Dense feather layering.
    (1, 6), (2, 5), (3, 5), (4, 4), (5, 3),
    # Final rich head, chest, wing and tail states.
    (2, 6), (3, 6), (4, 5), (5, 4), (5, 5), (4, 6), (5, 6),
)


def run(*args: str) -> None:
    subprocess.run(args, check=True)


def validate_order() -> None:
    if len(SOURCE_ORDER) != CELL_COUNT:
        raise ValueError("the reordered sheet must contain all 42 source cells")
    if len(set(SOURCE_ORDER)) != CELL_COUNT:
        raise ValueError("the reordered sheet contains a duplicate source cell")
    for row, column in SOURCE_ORDER:
        if not (0 <= row < SOURCE_ROWS and 0 <= column < SOURCE_COLUMNS):
            raise ValueError(f"source cell out of range: {(row, column)}")


def make_sheet(source: Path, output: Path, labels: bool = False) -> None:
    validate_order()
    output.parent.mkdir(parents=True, exist_ok=True)

    try:
        cell_paths: list[Path] = []
        for index, (row, column) in enumerate(SOURCE_ORDER):
            x = column * CELL_WIDTH
            y = max(0, row * SOURCE_CELL_HEIGHT - TOP_OVERLAP)
            cell_path = output.parent / f".reordered-cell-{index:02d}.png"
            command = [
                "magick", str(source), "-crop",
                f"{CELL_WIDTH}x{SOURCE_CROP_HEIGHT}+{x}+{y}", "+repage",
                "-background", "#f2f0f0", "-gravity", "center",
                "-extent", f"{CELL_WIDTH}x{OUTPUT_CELL_HEIGHT}",
            ]
            if labels:
                command.extend([
                    "-gravity", "South", "-font", "/System/Library/Fonts/Menlo.ttc",
                    "-fill", "#333333", "-stroke", "white", "-strokewidth", "1",
                    "-pointsize", "15", "-annotate", "+0+4", f"D{index:02d}",
                ])
            command.append(str(cell_path))
            run(*command)
            cell_paths.append(cell_path)

        rows: list[Path] = []
        for row in range(SOURCE_ROWS):
            row_path = output.parent / f".reordered-row-{row:02d}.png"
            first = row * SOURCE_COLUMNS
            run("magick", *(str(path) for path in cell_paths[first:first + SOURCE_COLUMNS]), "+append", str(row_path))
            rows.append(row_path)
        run("magick", *(str(path) for path in rows), "-append", "-strip", str(output))
    finally:
        for path in output.parent.glob(".reordered-*.png"):
            path.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--labels", action="store_true")
    args = parser.parse_args()
    make_sheet(args.source.resolve(), args.output.resolve(), args.labels)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
