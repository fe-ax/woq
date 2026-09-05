#!/usr/bin/env python3
"""Generates front.svg, back.svg, preview.svg, demo-highlight.svg, regions.json, regions.md"""
import json, os, sys
from geom import *

# Outputs land next to the generator's parent: Design/figure/.
OUT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAPER, BODY, INK = "#F7F3E8", "#FBF8F0", "#111111"
PASTEL = {"red": "#F4A6A6", "blue": "#A8C8F0", "yellow": "#F6E3A1", "green": "#B5DFB0"}

# ------------------------------------------------------------ silhouette (right half, x>=60)
S = Chain((60, 5.5))
S.add('head_top',    'C', (66.9, 5.5), (72.5, 12.9), (72.5, 22))
S.add('head_side',   'C', (72.5, 28), (70, 33.6), (66, 36.5))
S.add('neck',        'C', (66, 39.5), (66.3, 42.8), (67, 45))
S.add('trap_slope',  'C', (72, 46), (80, 47.5), (85, 49))
S.add('delt_cap',    'C', (89, 50.5), (92.5, 55), (92.5, 61))
S.add('uarm_outer',  'C', (93.5, 72), (96, 86), (97.5, 97))
S.add('farm_outer',  'C', (100, 104), (100, 120), (100.5, 136))
S.add('thumb',       'C', (102.5, 139), (104, 144), (103.5, 149))
S.add('thumb2',      'C', (103, 151), (101.5, 152), (101.5, 155))
S.add('fingers',     'C', (101.5, 161), (92.5, 161), (92.5, 155))
S.add('palm_in',     'L', (92.5, 150))
S.add('wrist_in',    'C', (92.5, 144), (93.5, 140), (94, 136))
S.add('farm_inner',  'C', (92, 124), (89.5, 110), (88.5, 98))
S.add('uarm_inner',  'C', (87.5, 88), (85.5, 78), (82.5, 69))
S.add('armpit',      'C', (81.5, 67.5), (80, 67.5), (79.5, 69))
S.add('torso_side',  'C', (78.5, 80), (75.5, 90), (75, 98))
S.add('hip',         'C', (75.5, 108), (79, 114), (80.5, 122))
S.add('thigh_top',   'C', (81.5, 125), (82, 128), (82, 132))
S.add('thigh_outer', 'C', (82, 148), (80, 168), (78, 182))
S.add('calf_outer',  'C', (78.5, 190), (80.5, 196), (80.5, 203))
S.add('shin_outer',  'C', (80.5, 215), (78.5, 230), (77, 240))
S.add('foot_outer',  'C', (78, 245), (81, 248.5), (82.5, 252))
S.add('toe_outer',   'C', (83, 253.5), (81.5, 254), (80, 254))
S.add('sole',        'L', (70, 254))
S.add('toe_inner',   'C', (68, 254), (67.5, 253), (68, 251.5))
S.add('foot_inner',  'C', (68.5, 248), (69.2, 244), (69.5, 240))
S.add('shin_inner',  'C', (68.5, 232), (67, 218), (66.5, 203))
S.add('knee_inner',  'C', (66.5, 195), (66.5, 188), (67, 182))
S.add('thigh_inner', 'C', (66, 168), (63.5, 150), (62, 136))
S.add('crotch',      'C', (61.5, 130), (60.5, 125), (60, 122))

half = S.as_path_segs()
OUTLINE = round_segs(half + reverse_open(mirror(half)) + [('Z',)])

E = S.edge  # shorthand
M = 1.6     # margin from silhouette


def mid(a, b, dx=0, dy=0):
    return ((a[0]+b[0])/2 + dx, (a[1]+b[1])/2 + dy)


def lozenge(outer_names, inner_names, y0, y1, n=5, cap=1.6, m=M):
    """Limb muscle following silhouette on both sides between y0 (top) and y1 (bottom)."""
    outer = E(outer_names, y0, y1, m, n)
    inner = E(inner_names, y1, y0, m, n)
    pts = outer + [mid(outer[-1], inner[0], 0, cap)] + inner + [mid(inner[-1], outer[0], 0, -cap)]
    return smooth_closed(pts)


# The shoulder cap is split along its length into two regions with the usual
# ~1 unit seam. The medial ~55% is the anterior head on the front view and the
# posterior head on the back view; the lateral ~45% is the side delt, which is
# the same shape in both views (Muscle.deltoidSide).
def delt_medial():
    """Medial ~55% of the shoulder cap: deltoid-front / deltoid-rear."""
    return smooth_closed([(84.2, 52.3), (84.8, 54.5), (85.1, 57), (85.3, 59.5), (85.6, 62),
                          (85.9, 64.4), (85.3, 66.4), (83.5, 67), (80.5, 62.5), (79.8, 57),
                          (80.8, 53), (83.5, 51.4)])


def delt_lateral():
    """Lateral ~45% of the shoulder cap: deltoid-side, identical in both views."""
    outer = E(['delt_cap', 'uarm_outer'], 50.5, 65, M, 6)
    return smooth_closed(outer + [(90.4, 67), (88.5, 67.7), (87.1, 65.2), (86.8, 62),
                                  (86.5, 59.5), (86.3, 57), (86, 54.5), (85.6, 52.6)])


# ------------------------------------------------------------ FRONT regions (x>=60 side)
def front_regions():
    R = {}
    # upper traps: thin band on the neck/shoulder slope
    slope = E('trap_slope', 68.5, 78.5, 1.7, 5, axis='x')
    R['traps-upper'] = smooth_closed(slope + [(78.6, 53.0), (74.5, 52.4), (70.5, 51.4)], corners=(0,))
    # shoulder cap: anterior head medial, side delt lateral
    R['deltoid-front'] = delt_medial()
    R['deltoid-side'] = delt_lateral()
    # chest plate
    R['chest'] = smooth_closed([(62, 55.5), (70, 55), (77, 55.8), (77.8, 60.5), (77.6, 65.5), (76.5, 69.2), (73, 73.2), (66, 74), (62, 72.5)], corners=(0, 8))
    # obliques: strip between abs and torso side
    side = E(['torso_side', 'hip'], 78.5, 116.5, M, 7)
    R['obliques'] = smooth_closed([(68.5, 78.5)] + side + [(68.5, 117)], corners=(0, len(side)+1))
    # arms
    R['biceps'] = lozenge('uarm_outer', 'uarm_inner', 72.5, 94)
    R['forearm-front'] = lozenge('farm_outer', 'farm_inner', 101, 133)
    # quads
    q_out = E(['thigh_top', 'thigh_outer'], 126, 176, M, 7)
    R['quads'] = smooth_closed([(76, 124.8)] + q_out + [(75.5, 178.6), (71.5, 177), (71.8, 160), (72.2, 145), (71.8, 132), (70.6, 126.5)])
    # adductors: inner thigh teardrop
    ad_in = E(['thigh_inner', 'crotch'], 154, 129.5, M, 4)
    R['adductors'] = smooth_closed([(63.6, 128), (66.5, 126.3), (69.4, 129.5), (70, 140), (69.3, 148), (68.4, 154), (66.8, 156.5)] + ad_in)
    # tibialis: outer shin
    t_out = E(['calf_outer', 'shin_outer'], 191, 236, M, 6)
    R['tibialis'] = smooth_closed([(75.6, 190.2)] + t_out + [(75.3, 237.8), (73.0, 236), (72.5, 222), (72.8, 206), (74.0, 193)])
    return R


FRONT_ABS = smooth_closed([(54, 77.5), (60, 76.6), (66, 77.5), (66.3, 95), (66, 113), (63, 119), (57, 119), (54, 113), (53.7, 95)])
FRONT_ABS_LINES = [('M', (55.5, 87)), ('L', (64.5, 87)), ('M', (55.5, 97.5)), ('L', (64.5, 97.5)), ('M', (55.5, 108)), ('L', (64.5, 108))]


# ------------------------------------------------------------ BACK regions (x>=60 side)
def back_regions():
    R = {}
    slope = E('trap_slope', 69.5, 78.5, 1.7, 4, axis='x')
    R['traps'] = smooth_closed([(61.5, 47), (67.5, 46.7)] + slope + [(79, 52.8), (74.5, 58.2), (68, 65.5), (61.5, 71)], corners=(0, 5 + len(slope)))
    R['deltoid-rear'] = delt_medial()
    R['deltoid-side'] = delt_lateral()
    R['rhomboids-upper-back'] = smooth_closed([(61.5, 75), (66, 69.5), (71.5, 67), (73.5, 70), (72.5, 76.5), (68.5, 83), (61.5, 87)], corners=(0, 6))
    side = E(['torso_side', 'hip'], 75, 105, M, 6)
    R['lats'] = smooth_closed(side + [(70, 108.6), (66, 109.3), (65.8, 102), (66.5, 94), (72.2, 84.5)], corners=(len(side)+1, len(side)+3))
    R['triceps'] = lozenge('uarm_outer', 'uarm_inner', 72.5, 94)
    R['forearm-back'] = lozenge('farm_outer', 'farm_inner', 101, 133)
    g_side = E(['hip', 'thigh_top', 'thigh_outer'], 116, 134, M, 4)
    R['glutes'] = smooth_closed([(61.5, 114.5), (69, 113.3), (76.5, 114.2)] + g_side + [(77.5, 138), (70, 139.6), (64.5, 137.5), (62.3, 129), (61.5, 122)], corners=(0, 11))
    R['hamstrings'] = lozenge('thigh_outer', 'thigh_inner', 143, 176, n=5, cap=1.8)
    c_out = E(['calf_outer', 'shin_outer'], 191, 214, M, 5)
    c_in = E(['shin_inner', 'knee_inner'], 214, 191, M, 5)
    R['calves'] = smooth_closed(c_out + [(76.5, 224), (73.5, 229.5), (70.5, 224)] + c_in + [(73.4, 189.6)])
    return R


BACK_LOWER = smooth_closed([(56.8, 93), (60, 92.4), (63.2, 93), (63.5, 102.5), (63.2, 112), (60, 112.8), (56.8, 112), (56.5, 102.5)])

DISPLAY = {
    'traps-upper': 'Upper traps', 'deltoid-front': 'Front delts', 'deltoid-side': 'Side delts',
    'chest': 'Chest', 'biceps': 'Biceps',
    'forearm-front': 'Forearms (front)', 'abs': 'Abs', 'obliques': 'Obliques', 'adductors': 'Adductors',
    'quads': 'Quads', 'tibialis': 'Tibialis', 'calves-front-inner': 'Calves (inner head)',
    'traps': 'Traps', 'deltoid-rear': 'Rear delts', 'rhomboids-upper-back': 'Rhomboids / upper back',
    'lats': 'Lats', 'triceps': 'Triceps', 'forearm-back': 'Forearms (back)', 'lower-back': 'Lower back',
    'glutes': 'Glutes', 'hamstrings': 'Hamstrings', 'calves': 'Calves',
}

FRONT_ORDER = ['traps-upper', 'deltoid-front', 'deltoid-side', 'chest', 'biceps', 'forearm-front', 'obliques', 'adductors', 'quads', 'tibialis']
BACK_ORDER = ['traps', 'deltoid-rear', 'deltoid-side', 'rhomboids-upper-back', 'lats', 'triceps', 'forearm-back', 'glutes', 'hamstrings', 'calves']


def build_view(view):
    """Returns ordered list of (id, segs, kind) with kind in {'region','lines'}."""
    items = []
    if view == 'front':
        R = front_regions()
        # x>=60 side of the FRONT view is the figure's LEFT side
        for g in FRONT_ORDER:
            items.append((f'front.{g}.r', round_segs(mirror(R[g])), 'region'))
            items.append((f'front.{g}.l', round_segs(R[g]), 'region'))
        items.append(('front.abs', round_segs(FRONT_ABS), 'region'))
        items.append(('front.abs.lines', round_segs(FRONT_ABS_LINES), 'lines'))
    else:
        R = back_regions()
        # x>=60 side of the BACK view is the figure's RIGHT side
        for g in BACK_ORDER:
            items.append((f'back.{g}.l', round_segs(mirror(R[g])), 'region'))
            items.append((f'back.{g}.r', round_segs(R[g]), 'region'))
        items.append(('back.lower-back', round_segs(BACK_LOWER), 'region'))
    return items


def svg_view(view, items, dx=0.0, fills=None, standalone=True, stroke_w=1):
    fills = fills or {}
    L = []
    if standalone:
        L.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
        L.append(f'<path id="{view}.paper" d="M0,0 L{W},0 L{W},{H} L0,{H} Z" fill="{PAPER}"/>')
    L.append(f'<path id="{view}.body" d="{path_d(OUTLINE, dx)}" fill="{BODY}" stroke="none"/>')
    L.append(f'<g id="{view}.regions" stroke="{INK}" stroke-width="{stroke_w}" stroke-linejoin="round" stroke-linecap="round">')
    for rid, segs, kind in items:
        if kind == 'lines':
            L.append(f'<path id="{rid}" d="{path_d(segs, dx)}" fill="none"/>')
        else:
            fill = fills.get(rid, BODY)
            L.append(f'<path id="{rid}" d="{path_d(segs, dx)}" fill="{fill}"/>')
    L.append('</g>')
    L.append(f'<path id="{view}.outline" d="{path_d(OUTLINE, dx)}" fill="none" stroke="{INK}" stroke-width="{stroke_w}" stroke-linejoin="round" stroke-linecap="round"/>')
    if standalone:
        L.append('</svg>')
    return '\n'.join(L)


def write(name, text):
    p = os.path.join(OUT, name)
    with open(p, 'w') as f:
        f.write(text + '\n')
    return p


def main():
    front = build_view('front')
    back = build_view('back')
    # validation
    ok = True
    for view, items in (('front', front), ('back', back)):
        probs = validate(view, OUTLINE, [(rid, segs) for rid, segs, kind in items if kind == 'region'])
        probs += [p for p in validate(view, OUTLINE, [(rid, segs) for rid, segs, kind in items if kind == 'lines']) if 'silhouette' in p]
        for p in probs:
            print('PROBLEM', view, p)
        ok = ok and not probs
    # files
    write('front.svg', svg_view('front', front))
    write('back.svg', svg_view('back', back))
    # preview: both side by side (no transforms: coordinates are shifted)
    pv = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {2*W+10} {H}" width="{2*W+10}" height="{H}">',
          f'<path d="M0,0 L{2*W+10},0 L{2*W+10},{H} L0,{H} Z" fill="{PAPER}"/>',
          svg_view('front', front, 0, standalone=False),
          svg_view('back', back, W+10, standalone=False), '</svg>']
    write('preview.svg', '\n'.join(pv))
    fills = {}
    for side in 'lr':
        fills[f'front.chest.{side}'] = PASTEL['red']
        fills[f'front.deltoid-front.{side}'] = PASTEL['yellow']
        fills[f'back.triceps.{side}'] = PASTEL['blue']
        fills[f'back.lats.{side}'] = PASTEL['green']
    dm = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {2*W+10} {H}" width="{2*W+10}" height="{H}">',
          f'<path d="M0,0 L{2*W+10},0 L{2*W+10},{H} L0,{H} Z" fill="{PAPER}"/>',
          svg_view('front', front, 0, fills, standalone=False),
          svg_view('back', back, W+10, fills, standalone=False), '</svg>']
    write('demo-highlight.svg', '\n'.join(dm))
    # regions.json + markdown
    rows = []
    for items in (front, back):
        for rid, segs, kind in items:
            if kind != 'region':
                continue
            parts = rid.split('.')
            view, group = parts[0], parts[1]
            side = parts[2] if len(parts) > 2 else None
            rows.append({'id': rid, 'group': group, 'displayName': DISPLAY[group], 'view': view, 'side': side})
    write('regions.json', json.dumps(rows, indent=2))
    md = ['| group | display name | view | sided | ids |', '|---|---|---|---|---|']
    seen = []
    for r in rows:
        if r['group'] not in seen:
            seen.append(r['group'])
    for g in seen:
        rs = [r for r in rows if r['group'] == g]
        views = []
        for r in rs:
            if r['view'] not in views:
                views.append(r['view'])
        md.append(f"| {g} | {DISPLAY[g]} | {', '.join(views)} | {'yes' if rs[0]['side'] else 'no'} | {', '.join('`'+r['id']+'`' for r in rs)} |")
    write('regions.md', '\n'.join(md))
    print('groups:', len(seen), 'region paths:', len(rows), 'OK' if ok else 'WITH PROBLEMS')


if __name__ == '__main__':
    main()
