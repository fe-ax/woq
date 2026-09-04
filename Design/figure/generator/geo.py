#!/usr/bin/env python3
"""Optional 'geometric' style variant of the FRONT view: mannequin built only from capsules and ellipses."""
import math, os
from geom import W, H, path_d, ellipse, round_segs, mirror, mx

OUT = os.path.dirname(os.path.abspath(__file__))
PAPER, BODY, INK = "#F7F3E8", "#FBF8F0", "#111111"
K = 0.5523


def capsule(p0, p1, r):
    """Stadium between centre points p0 -> p1 with radius r (rotated to the axis)."""
    dx, dy = p1[0]-p0[0], p1[1]-p0[1]
    L = math.hypot(dx, dy)
    ux, uy = dx/L, dy/L          # axis direction
    nx, ny = -uy, ux             # normal
    def P(c, a, b):              # point c + a*axis + b*normal
        return (c[0] + a*ux + b*nx, c[1] + a*uy + b*ny)
    segs = [('M', P(p0, 0, r)),
            ('L', P(p1, 0, r)),
            ('C', P(p1, r*K, r), P(p1, r, r*K), P(p1, r, 0)),
            ('C', P(p1, r, -r*K), P(p1, r*K, -r), P(p1, 0, -r)),
            ('L', P(p0, 0, -r)),
            ('C', P(p0, -r*K, -r), P(p0, -r, -r*K), P(p0, -r, 0)),
            ('C', P(p0, -r, r*K), P(p0, -r*K, r), P(p0, 0, r)),
            ('Z',)]
    return segs


def el(cx, cy, rx, ry):
    return ellipse(cx, cy, rx, ry)


# body parts (x>=60 side ones get mirrored)
CENTRE_BODY = [
    ('head', el(60, 22, 12.5, 16.5)),
    ('neck', capsule((60, 36), (60, 46), 6)),
    ('torso', capsule((60, 62), (60, 106), 19)),
    ('pelvis', el(60, 114, 20, 10)),
]
SIDE_BODY = [
    ('shoulder', el(86, 57, 8, 8.5)),
    ('upper-arm', capsule((87, 62), (92.5, 96), 5.5)),
    ('forearm', capsule((93, 100), (97, 136), 4.6)),
    ('hand', el(97.5, 149, 5, 11)),
    ('thigh', capsule((72.5, 126), (73.5, 180), 9.5)),
    ('shin', capsule((73.5, 186), (73.5, 240), 6.5)),
    ('foot', el(74, 249, 8.5, 5.5)),
]
# muscle regions on the x>=60 side (front view => figure's LEFT side => '.l')
SIDE_REGIONS = [
    ('traps-upper', capsule((69.5, 48.5), (79, 51), 1.8)),
    ('deltoid-front', el(86.5, 57.5, 5.6, 6.2)),
    ('chest', el(70, 62.5, 8, 9.5)),
    ('biceps', capsule((88, 68), (91.5, 91), 3.5)),
    ('forearm-front', capsule((93.5, 105), (96.5, 131), 3)),
    ('obliques', capsule((70.5, 80), (70.5, 114), 3.3)),
    ('quads', capsule((74, 133), (74.5, 175), 5)),
    ('adductors', capsule((65, 131), (66.5, 156), 2.4)),
    ('tibialis', capsule((75, 192), (75, 236), 2.9)),
]
CENTRE_REGIONS = [
    ('abs', capsule((60, 80), (60, 113), 6)),
]
ABS_LINES = [('M', (55.5, 87)), ('L', (64.5, 87)), ('M', (55.5, 97.5)), ('L', (64.5, 97.5)), ('M', (55.5, 108)), ('L', (64.5, 108))]


def main():
    L = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
         f'<path id="front.paper" d="M0,0 L{W},0 L{W},{H} L0,{H} Z" fill="{PAPER}"/>',
         f'<g id="front.body" fill="{BODY}" stroke="{INK}" stroke-width="1" stroke-linejoin="round">']
    for name, segs in CENTRE_BODY:
        L.append(f'<path id="front.body.{name}" d="{path_d(round_segs(segs))}"/>')
    for name, segs in SIDE_BODY:
        L.append(f'<path id="front.body.{name}.r" d="{path_d(round_segs(mirror(segs)))}"/>')
        L.append(f'<path id="front.body.{name}.l" d="{path_d(round_segs(segs))}"/>')
    L.append('</g>')
    L.append(f'<g id="front.regions" fill="{BODY}" stroke="{INK}" stroke-width="1" stroke-linejoin="round" stroke-linecap="round">')
    for name, segs in SIDE_REGIONS:
        L.append(f'<path id="front.{name}.r" d="{path_d(round_segs(mirror(segs)))}"/>')
        L.append(f'<path id="front.{name}.l" d="{path_d(round_segs(segs))}"/>')
    for name, segs in CENTRE_REGIONS:
        L.append(f'<path id="front.{name}" d="{path_d(round_segs(segs))}"/>')
    L.append(f'<path id="front.abs.lines" d="{path_d(ABS_LINES)}" fill="none"/>')
    L.append('</g>')
    L.append('</svg>')
    with open(os.path.join(OUT, 'geometric-front.svg'), 'w') as f:
        f.write('\n'.join(L) + '\n')
    print('wrote geometric-front.svg')


if __name__ == '__main__':
    main()
