#!/bin/bash
# Render every Design/icon/icon-*.svg to PNG and build the comparison sheet.
#
#   ./Design/icon/render.sh
#
# Uses only tools that ship with macOS: qlmanage (SVG -> PNG through WebKit),
# sips (downscale) and python3 (base64-embeds the small PNGs into the sheet).
# Everything lands in Design/icon/renders/.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/renders"
mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/preview-sheet.svg

VARIANTS=()
for svg in "$DIR"/icon-*.svg; do
  name="$(basename "$svg" .svg)"
  VARIANTS+=("$name")

  # 1024 master (qlmanage -s sets the longest edge; the sources are square)
  qlmanage -t -s 1024 -o "$OUT" "$svg" >/dev/null 2>&1
  mv "$OUT/$name.svg.png" "$OUT/$name-1024.png"

  for size in 180 120 60; do
    cp "$OUT/$name-1024.png" "$OUT/$name-$size.png"
    sips -z "$size" "$size" "$OUT/$name-$size.png" >/dev/null
  done

  echo "rendered $name -> $name-1024.png, $name-180.png, $name-120.png, $name-60.png"
done

# ---- comparison sheet -------------------------------------------------------
# A, B and C side by side at 180 / 120 / 60 px with the corners rounded to
# approximate the iOS icon mask (radius = 22.37% of the side).
python3 - "$OUT" "${VARIANTS[@]}" <<'PYEOF'
import base64, os, sys

out, names = sys.argv[1], sys.argv[2:]
BIG, MED, SMALL, GAP, MARGIN = 180, 120, 60, 30, 30
W = MARGIN * 2 + len(names) * BIG + (len(names) - 1) * GAP
H = W  # qlmanage always writes a square thumbnail, so author the sheet square


def uri(path):
    with open(path, "rb") as fh:
        return "data:image/png;base64," + base64.b64encode(fh.read()).decode()


p = ['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
     'viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H),
     '<rect width="%d" height="%d" fill="#FFFFFF"/>' % (W, H), '<defs>']
for tag, side in (("Big", BIG), ("Med", MED), ("Small", SMALL)):
    p.append('<clipPath id="m%s"><rect width="%d" height="%d" rx="%.2f"/></clipPath>'
             % (tag, side, side, side * 0.2237))
p.append('</defs>')
p.append('<text x="%d" y="30" font-family="Helvetica,Arial" font-size="16" fill="#111111">'
         'WOQ app icon variants (iOS corner mask approximated)</text>' % MARGIN)


def row(y, side, tag, caption):
    for i, name in enumerate(names):
        cx = MARGIN + i * (BIG + GAP) + BIG / 2.0
        p.append('<g transform="translate(%.1f,%d)"><image width="%d" height="%d" '
                 'clip-path="url(#m%s)" xlink:href="%s"/>'
                 '<rect width="%d" height="%d" rx="%.2f" fill="none" stroke="#111111" '
                 'stroke-width="1" stroke-opacity="0.3"/></g>'
                 % (cx - side / 2.0, y, side, side, tag,
                    uri(os.path.join(out, "%s-%d.png" % (name, side))),
                    side, side, side * 0.2237))
        if side == BIG:
            p.append('<text x="%.1f" y="%d" text-anchor="middle" font-family="Helvetica,Arial" '
                     'font-size="15" fill="#111111">%s</text>' % (cx, y + side + 22, name))
    p.append('<text x="%.1f" y="%d" text-anchor="middle" font-family="Helvetica,Arial" '
             'font-size="12" fill="#6B665C">%s</text>'
             % (W / 2.0, y + side + (44 if side == BIG else 22), caption))


row(56, BIG, "Big", "180 px - home screen @3x")
row(340, MED, "Med", "120 px - Spotlight @3x")
row(510, SMALL, "Small", "60 px - the size it is actually judged at")
p.append('</svg>')

with open(os.path.join(out, "preview-sheet.svg"), "w") as fh:
    fh.write("\n".join(p))
print("sheet %dx%d" % (W, H))
PYEOF

SHEET_W=$(sed -n 's/.* width="\([0-9]*\)".*/\1/p' "$OUT/preview-sheet.svg" | head -1)
qlmanage -t -s "$SHEET_W" -o "$OUT" "$OUT/preview-sheet.svg" >/dev/null 2>&1
mv "$OUT/preview-sheet.svg.png" "$OUT/preview-sheet.png"
echo "rendered preview-sheet.png (${SHEET_W}px)"

# ---- flatten -----------------------------------------------------------------
# qlmanage always writes RGBA. Every pixel here is fully opaque (the sources have
# a full-bleed paper background), and App Store / Xcode icons must not carry an
# alpha channel at all, so rewrite each PNG as plain 8-bit RGB.
python3 - "$OUT" <<'PYEOF'
import binascii, os, struct, subprocess, sys, zlib

out = sys.argv[1]


def flatten(path):
    bmp = path[:-4] + ".bmp"
    subprocess.run(["sips", "-s", "format", "bmp", path, "--out", bmp],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    d = open(bmp, "rb").read()
    os.remove(bmp)
    off = struct.unpack_from("<I", d, 10)[0]
    w, h = struct.unpack_from("<ii", d, 18)
    bpp = struct.unpack_from("<H", d, 28)[0]
    if bpp not in (24, 32):
        raise SystemExit("unexpected bmp depth %d for %s" % (bpp, path))
    step, H = bpp // 8, abs(h)
    stride = ((w * step) + 3) // 4 * 4
    raw = bytearray()
    for y in range(H):
        src = off + (H - 1 - y if h > 0 else y) * stride
        raw.append(0)                                  # filter: none
        for x in range(w):
            p = src + x * step
            raw += bytes((d[p + 2], d[p + 1], d[p]))   # BGR -> RGB

    def chunk(tag, body):
        c = tag + body
        return struct.pack(">I", len(body)) + c + struct.pack(">I", binascii.crc32(c) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, H, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
           + chunk(b"IEND", b""))
    open(path, "wb").write(png)


for name in sorted(os.listdir(out)):
    if name.endswith(".png"):
        flatten(os.path.join(out, name))
        print("flattened %s (no alpha channel)" % name)
PYEOF

