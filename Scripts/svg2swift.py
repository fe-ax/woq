#!/usr/bin/env python3
"""Generate WOQ/Figure/FigurePaths.swift from Design/figure/{front,back}.svg.

Python 3 standard library only (xml.etree + re). Run from the repo root:

    python3 Scripts/svg2swift.py

The output is byte-stable across runs: region order is document order within a
kind bucket, and numbers are formatted with a fixed rule. Never hand-edit
WOQ/Figure/FigurePaths.swift; change the SVGs or this script instead.
"""

from __future__ import annotations

import os
import re
import sys
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG_DIR = os.path.join(REPO_ROOT, "Design", "figure")
OUT_PATH = os.path.join(REPO_ROOT, "WOQ", "Figure", "FigurePaths.swift")

# SVG group name -> Muscle case (raw values in WOQ/Model/Muscle.swift).
# Keep this table in sync with the doc comment in WOQ/Figure/FigureRegion.swift.
MUSCLE_FOR_GROUP = {
    "traps-upper": "traps",
    "traps": "traps",
    "deltoid-front": "deltoidFront",
    "deltoid-side": "deltoidSide",
    "deltoid-rear": "deltoidRear",
    "chest": "chest",
    "biceps": "biceps",
    "triceps": "triceps",
    "forearm-front": "forearms",
    "forearm-back": "forearms",
    "abs": "abs",
    "obliques": "obliques",
    "rhomboids-upper-back": "upperBack",
    "lats": "lats",
    "lower-back": "lowerBack",
    "glutes": "glutes",
    "quads": "quads",
    "hamstrings": "hamstrings",
    "adductors": "adductors",
    "calves": "calves",
}

# Every Muscle case. All 18 have at least one region; `deltoid-side` is the only
# group that appears in both views (the lateral head of the shoulder cap).
MUSCLE_CASES = [
    "chest", "deltoidFront", "deltoidSide", "deltoidRear", "biceps", "triceps",
    "forearms", "abs", "obliques", "traps", "upperBack", "lats", "lowerBack",
    "glutes", "quads", "hamstrings", "adductors", "calves",
]

# Anatomy without a Muscle case: drawn as plain body.
BODY_GROUPS = {"tibialis"}
# Stroke-only decoration, omitted at thumbnail size.
DECORATION_GROUPS = {"abs.lines"}
# Container / background ids that carry no drawable region.
IGNORED_GROUPS = {"paper", "body", "regions"}
OUTLINE_GROUP = "outline"

VIEW_BOX = (0.0, 0.0, 120.0, 260.0)

TOKEN_RE = re.compile(r"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
SUPPORTED_COMMANDS = "MLCQHVZ"


class GeneratorError(Exception):
    """Anything the generator refuses to guess about."""


def fail(message: str) -> None:
    raise GeneratorError(message)


def fmt(value: float) -> str:
    """Format a coordinate deterministically: 60.0 -> '60', 55.5 -> '55.5'."""
    rounded = round(value, 4)
    if rounded == int(rounded):
        return str(int(rounded))
    text = f"{rounded:.4f}".rstrip("0").rstrip(".")
    return text


def point(x: float, y: float) -> str:
    return f"CGPoint(x: {fmt(x)}, y: {fmt(y)})"


def parse_path(d: str, path_id: str) -> list[str]:
    """Turn an SVG `d` attribute into Swift Path builder statements."""
    tokens = TOKEN_RE.findall(d)
    consumed = "".join(tokens)
    stripped = re.sub(r"[\s,]", "", d)
    if consumed != stripped:
        fail(f"{path_id}: could not tokenise the whole `d` attribute ({d!r})")

    lines: list[str] = []
    index = 0
    command: str | None = None
    current = (0.0, 0.0)
    subpath_start = (0.0, 0.0)

    def number() -> float:
        nonlocal index
        if index >= len(tokens) or re.fullmatch(r"[A-Za-z]", tokens[index]):
            fail(f"{path_id}: expected a number at token {index} in {d!r}")
        value = float(tokens[index])
        index += 1
        return value

    while index < len(tokens):
        token = tokens[index]
        if re.fullmatch(r"[A-Za-z]", token):
            command = token
            index += 1
            if command.islower():
                fail(f"{path_id}: relative command '{command}' is not supported")
            if command not in SUPPORTED_COMMANDS:
                fail(f"{path_id}: unsupported command '{command}'")
            if command == "Z":
                lines.append("p.closeSubpath()")
                current = subpath_start
                continue
        elif command is None:
            fail(f"{path_id}: `d` does not start with a command ({d!r})")
        elif command == "M":
            # Implicit repetition after a moveto is a lineto (SVG spec).
            command = "L"

        if command == "M":
            x, y = number(), number()
            lines.append(f"p.move(to: {point(x, y)})")
            current = (x, y)
            subpath_start = (x, y)
        elif command == "L":
            x, y = number(), number()
            lines.append(f"p.addLine(to: {point(x, y)})")
            current = (x, y)
        elif command == "H":
            x = number()
            lines.append(f"p.addLine(to: {point(x, current[1])})")
            current = (x, current[1])
        elif command == "V":
            y = number()
            lines.append(f"p.addLine(to: {point(current[0], y)})")
            current = (current[0], y)
        elif command == "C":
            x1, y1, x2, y2, x, y = (number() for _ in range(6))
            lines.append(
                f"p.addCurve(to: {point(x, y)}, "
                f"control1: {point(x1, y1)}, control2: {point(x2, y2)})"
            )
            current = (x, y)
        elif command == "Q":
            x1, y1, x, y = (number() for _ in range(4))
            lines.append(f"p.addQuadCurve(to: {point(x, y)}, control: {point(x1, y1)})")
            current = (x, y)
        else:
            fail(f"{path_id}: unsupported command '{command}'")

    if not lines:
        fail(f"{path_id}: empty path")
    return lines


def swift_name(path_id: str) -> str:
    """front.traps-upper.r -> frontTrapsUpperR"""
    words = re.split(r"[.\-]", path_id)
    head, *rest = [w for w in words if w]
    return head + "".join(w[:1].upper() + w[1:] for w in rest)


def classify(path_id: str, view: str) -> tuple[str, str] | None:
    """Return (kindSwift, sortBucket) or None when the id is ignored."""
    if not path_id.startswith(view + "."):
        fail(f"{path_id}: id does not start with '{view}.'")
    rest = path_id[len(view) + 1:]
    parts = rest.split(".")
    if len(parts) > 1 and parts[-1] in ("l", "r"):
        group = ".".join(parts[:-1])
    else:
        group = rest

    if group in IGNORED_GROUPS:
        return None
    if group == OUTLINE_GROUP:
        return ".outline", "outline"
    if group in DECORATION_GROUPS:
        return ".decoration", "decoration"
    if group in BODY_GROUPS:
        return ".body", "body"
    if group in MUSCLE_FOR_GROUP:
        muscle = MUSCLE_FOR_GROUP[group]
        if muscle not in MUSCLE_CASES:
            fail(f"{path_id}: '{muscle}' is not a Muscle case")
        return f".muscle(.{muscle})", "muscle"
    fail(f"{path_id}: unknown group '{group}' - add it to the mapping table")
    return None


def read_svg(view: str) -> list[dict[str, object]]:
    svg_path = os.path.join(SVG_DIR, f"{view}.svg")
    tree = ET.parse(svg_path)
    root = tree.getroot()

    view_box = [float(v) for v in re.split(r"[\s,]+", root.get("viewBox", "").strip())]
    if tuple(view_box) != VIEW_BOX:
        fail(f"{view}.svg: viewBox {view_box} != {list(VIEW_BOX)}")

    regions: list[dict[str, object]] = []
    for element in root.iter():
        path_id = element.get("id")
        d = element.get("d")
        if path_id is None:
            continue
        if d is None:
            classify(path_id, view)  # validates container ids too
            continue
        kind = classify(path_id, view)
        if kind is None:
            continue
        regions.append({
            "id": path_id,
            "name": swift_name(path_id),
            "kind": kind[0],
            "bucket": kind[1],
            "lines": parse_path(d, path_id),
        })

    order = {"body": 0, "muscle": 1, "decoration": 2, "outline": 3}
    regions.sort(key=lambda r: order[str(r["bucket"])])  # stable: document order inside
    return regions


def emit(front: list[dict[str, object]], back: list[dict[str, object]]) -> str:
    out: list[str] = []
    add = out.append
    add("// GENERATED FILE - DO NOT EDIT BY HAND.")
    add("//")
    add("// Produced by Scripts/svg2swift.py from Design/figure/front.svg and")
    add("// Design/figure/back.svg. Change the SVGs or the generator, then run:")
    add("//")
    add("//     python3 Scripts/svg2swift.py")
    add("")
    add("import SwiftUI")
    add("")
    add("/// Figure geometry in SVG user units (see `viewBox`).")
    add("///")
    add("/// Order within each array: body shapes, muscle regions, decoration, outline.")
    add("nonisolated enum FigurePaths {")
    x, y, w, h = VIEW_BOX
    add(f"    static let viewBox = CGRect(x: {fmt(x)}, y: {fmt(y)}, "
        f"width: {fmt(w)}, height: {fmt(h)})")
    add("")
    for name, regions in (("front", front), ("back", back)):
        add(f"    static let {name}: [FigureRegion] = [")
        for region in regions:
            add(f"        {region['name']},")
        add("    ]")
        add("")
    if out[-1] == "":
        out.pop()
    add("}")

    for view, regions in (("Front", front), ("Back", back)):
        add("")
        add(f"// MARK: - {view} regions")
        add("")
        add("private nonisolated extension FigurePaths {")
        for index, region in enumerate(regions):
            if index > 0:
                add("")
            add(f"    static let {region['name']} = FigureRegion(")
            add(f"        id: \"{region['id']}\",")
            add(f"        side: .{view.lower()},")
            add(f"        kind: {region['kind']},")
            add("        path: Path { p in")
            for line in region["lines"]:  # type: ignore[union-attr]
                add(f"            {line}")
            add("        }")
            add("    )")
        add("}")
    add("")
    return "\n".join(out)


def main() -> int:
    try:
        front = read_svg("front")
        back = read_svg("back")
        source = emit(front, back)
    except GeneratorError as error:
        print(f"svg2swift: error: {error}", file=sys.stderr)
        return 1
    with open(OUT_PATH, "w", encoding="utf-8") as handle:
        handle.write(source)
    print(f"svg2swift: wrote {OUT_PATH} "
          f"({len(front)} front regions, {len(back)} back regions)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
