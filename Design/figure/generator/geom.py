"""Geometry helpers for the WOQ muscle-figure generator (pure python, no deps)."""
import math

W, H = 120, 260


def fmt(v):
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    if s == "-0":
        s = "0"
    return s


def pt(p, dx=0.0):
    return f"{fmt(p[0] + dx)},{fmt(p[1])}"


# ---------------------------------------------------------------- segments
# A path is a list of segments: ('M',p) ('L',p) ('C',c1,c2,p) ('Q',c,p) ('Z',)

def path_d(segs, dx=0.0):
    out = []
    for s in segs:
        k = s[0]
        if k == 'M':
            out.append('M' + pt(s[1], dx))
        elif k == 'L':
            out.append('L' + pt(s[1], dx))
        elif k == 'C':
            out.append('C' + pt(s[1], dx) + ' ' + pt(s[2], dx) + ' ' + pt(s[3], dx))
        elif k == 'Q':
            out.append('Q' + pt(s[1], dx) + ' ' + pt(s[2], dx))
        elif k == 'Z':
            out.append('Z')
    return ' '.join(out)


def mx(p):
    return (W - p[0], p[1])


def mirror(segs):
    r = []
    for s in segs:
        k = s[0]
        if k in ('M', 'L'):
            r.append((k, mx(s[1])))
        elif k == 'C':
            r.append(('C', mx(s[1]), mx(s[2]), mx(s[3])))
        elif k == 'Q':
            r.append(('Q', mx(s[1]), mx(s[2])))
        else:
            r.append(s)
    return r


def reverse_open(segs):
    """segs = [('M',p0), seg, seg, ...]; returns segments (no M) tracing back to p0."""
    cur = segs[0][1]
    items = []
    for s in segs[1:]:
        if s[0] == 'L':
            items.append(('L', [], s[1], cur)); cur = s[1]
        elif s[0] == 'C':
            items.append(('C', [s[1], s[2]], s[3], cur)); cur = s[3]
        elif s[0] == 'Q':
            items.append(('Q', [s[1]], s[2], cur)); cur = s[2]
    out = []
    for t, ctrls, end, start in reversed(items):
        if t == 'L':
            out.append(('L', start))
        elif t == 'C':
            out.append(('C', ctrls[1], ctrls[0], start))
        elif t == 'Q':
            out.append(('Q', ctrls[0], start))
    return out


# ---------------------------------------------------------------- bezier eval
def bez(p0, c1, c2, p3, t):
    u = 1 - t
    return (u*u*u*p0[0] + 3*u*u*t*c1[0] + 3*u*t*t*c2[0] + t*t*t*p3[0],
            u*u*u*p0[1] + 3*u*u*t*c1[1] + 3*u*t*t*c2[1] + t*t*t*p3[1])


def bez_d(p0, c1, c2, p3, t):
    u = 1 - t
    return (3*u*u*(c1[0]-p0[0]) + 6*u*t*(c2[0]-c1[0]) + 3*t*t*(p3[0]-c2[0]),
            3*u*u*(c1[1]-p0[1]) + 6*u*t*(c2[1]-c1[1]) + 3*t*t*(p3[1]-c2[1]))


class Chain:
    """Named open chain of segments (used for the silhouette half)."""

    def __init__(self, start):
        self.start = start
        self.segs = []      # (name, kind, pts)
        self.starts = {}    # name -> start point
        self._cur = start

    def add(self, name, kind, *pts):
        self.starts[name] = self._cur
        self.segs.append((name, kind, pts))
        self._cur = pts[-1]

    def seg(self, name):
        for n, k, p in self.segs:
            if n == name:
                return k, p
        raise KeyError(name)

    def as_path_segs(self):
        out = [('M', self.start)]
        for n, k, p in self.segs:
            out.append((k,) + tuple(p))
        return out

    def samples(self, name, n=80):
        """list of (point, unit-left-normal) along segment, forward direction."""
        k, p = self.seg(name)
        s0 = self.starts[name]
        res = []
        if k == 'L':
            p1 = p[0]
            tx, ty = p1[0]-s0[0], p1[1]-s0[1]
            L = math.hypot(tx, ty) or 1
            nrm = (-ty/L, tx/L)
            for i in range(n+1):
                t = i/n
                res.append(((s0[0]+t*tx, s0[1]+t*ty), nrm))
        elif k == 'C':
            c1, c2, p3 = p
            for i in range(n+1):
                t = i/n
                q = bez(s0, c1, c2, p3, t)
                d = bez_d(s0, c1, c2, p3, t)
                L = math.hypot(*d) or 1
                res.append((q, (-d[1]/L, d[0]/L)))
        else:
            raise ValueError(k)
        return res

    def edge(self, names, a, b, d, n, axis='y'):
        """n points offset by d along the left normal, between coordinate a and b
        (axis 'x' or 'y') measured along the chain of the named segments; ordered from a to b."""
        if isinstance(names, str):
            names = [names]
        allp = []
        for nm in names:
            allp.extend(self.samples(nm))
        ax = 0 if axis == 'x' else 1
        def idx(v):
            best, bi = 1e9, 0
            for i, (q, _) in enumerate(allp):
                e = abs(q[ax] - v)
                if e < best:
                    best, bi = e, i
            return bi
        ia, ib = idx(a), idx(b)
        out = []
        for j in range(n):
            i = round(ia + (ib - ia) * j / (n - 1)) if n > 1 else ia
            q, nrm = allp[i]
            out.append((q[0] + d*nrm[0], q[1] + d*nrm[1]))
        return out


# ---------------------------------------------------------------- smoothing
def smooth_closed(points, corners=(), tension=1.0):
    """Catmull-Rom through points (closed loop) -> cubic path segs.
    corners: indices whose adjacent handles collapse (sharp vertex)."""
    n = len(points)
    P = points
    segs = [('M', P[0])]
    cs = set(corners)
    for i in range(n):
        p0 = P[(i-1) % n]; p1 = P[i]; p2 = P[(i+1) % n]; p3 = P[(i+2) % n]
        if i in cs:
            h1 = p1
        else:
            h1 = (p1[0] + (p2[0]-p0[0]) / 6 * tension, p1[1] + (p2[1]-p0[1]) / 6 * tension)
        if ((i+1) % n) in cs:
            h2 = p2
        else:
            h2 = (p2[0] - (p3[0]-p1[0]) / 6 * tension, p2[1] - (p3[1]-p1[1]) / 6 * tension)
        segs.append(('C', h1, h2, p2))
    segs.append(('Z',))
    return segs


def ellipse(cx, cy, rx, ry):
    k = 0.5523
    return [('M', (cx, cy-ry)),
            ('C', (cx+rx*k, cy-ry), (cx+rx, cy-ry*k), (cx+rx, cy)),
            ('C', (cx+rx, cy+ry*k), (cx+rx*k, cy+ry), (cx, cy+ry)),
            ('C', (cx-rx*k, cy+ry), (cx-rx, cy+ry*k), (cx-rx, cy)),
            ('C', (cx-rx, cy-ry*k), (cx-rx*k, cy-ry), (cx, cy-ry)),
            ('Z',)]


def round_segs(segs):
    """Snap every coordinate to 1 decimal so the file and the checks agree."""
    out = []
    for s in segs:
        if s[0] in ('M', 'L'):
            out.append((s[0], (round(s[1][0], 1), round(s[1][1], 1))))
        elif s[0] == 'C':
            out.append(('C',) + tuple((round(p[0], 1), round(p[1], 1)) for p in s[1:]))
        elif s[0] == 'Q':
            out.append(('Q',) + tuple((round(p[0], 1), round(p[1], 1)) for p in s[1:]))
        else:
            out.append(s)
    return out


# ---------------------------------------------------------------- validation
def flatten(segs, n=14):
    """Flatten to list of polylines (one per subpath)."""
    polys = []
    cur = None
    poly = []
    for s in segs:
        k = s[0]
        if k == 'M':
            if poly:
                polys.append(poly)
            poly = [s[1]]; cur = s[1]
        elif k == 'L':
            poly.append(s[1]); cur = s[1]
        elif k == 'C':
            for i in range(1, n+1):
                poly.append(bez(cur, s[1], s[2], s[3], i/n))
            cur = s[3]
        elif k == 'Q':
            c1 = (cur[0] + 2/3*(s[1][0]-cur[0]), cur[1] + 2/3*(s[1][1]-cur[1]))
            c2 = (s[2][0] + 2/3*(s[1][0]-s[2][0]), s[2][1] + 2/3*(s[1][1]-s[2][1]))
            for i in range(1, n+1):
                poly.append(bez(cur, c1, c2, s[2], i/n))
            cur = s[2]
        elif k == 'Z':
            pass
    if poly:
        polys.append(poly)
    return polys


def point_in_poly(p, poly):
    x, y = p
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]; x2, y2 = poly[(i+1) % n]
        if (y1 > y) != (y2 > y):
            xi = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
            if xi > x:
                inside = not inside
    return inside


def _orient(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])


def seg_intersect(a, b, c, d):
    o1, o2, o3, o4 = _orient(a, b, c), _orient(a, b, d), _orient(c, d, a), _orient(c, d, b)
    return (o1*o2 < 0) and (o3*o4 < 0)


def polys_cross(P, Q):
    n, m = len(P), len(Q)
    for i in range(n):
        a, b = P[i], P[(i+1) % n]
        for j in range(m):
            c, d = Q[j], Q[(j+1) % m]
            if seg_intersect(a, b, c, d):
                return True
    return False


def pt_seg_dist(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx-ax, by-ay
    L2 = dx*dx + dy*dy
    if L2 == 0:
        return math.hypot(px-ax, py-ay)
    t = max(0, min(1, ((px-ax)*dx + (py-ay)*dy) / L2))
    return math.hypot(px - (ax + t*dx), py - (ay + t*dy))


def poly_min_dist(P, Q):
    best = 1e9
    m = len(Q)
    for p in P:
        for j in range(m):
            d = pt_seg_dist(p, Q[j], Q[(j+1) % m])
            if d < best:
                best = d
    n = len(P)
    for q in Q:
        for i in range(n):
            d = pt_seg_dist(q, P[i], P[(i+1) % n])
            if d < best:
                best = d
    return best


def validate(view, outline_segs, regions):
    """regions: list of (id, segs). Returns list of problem strings."""
    probs = []
    outline = flatten(outline_segs)[0]
    polys = []
    for rid, segs in regions:
        for poly in flatten(segs):
            polys.append((rid, poly))
    for rid, poly in polys:
        outside = [p for p in poly if not point_in_poly(p, outline)]
        if outside:
            probs.append(f"{rid}: {len(outside)} pts outside silhouette e.g. {outside[0][0]:.1f},{outside[0][1]:.1f}")
        if polys_cross(poly, outline):
            probs.append(f"{rid}: crosses silhouette")
        d = poly_min_dist(poly, outline)
        if d < 0.9:
            probs.append(f"{rid}: only {d:.2f} from silhouette")
    for i in range(len(polys)):
        for j in range(i+1, len(polys)):
            ra, A = polys[i]; rb, B = polys[j]
            if ra == rb:
                continue
            if polys_cross(A, B):
                probs.append(f"{ra} x {rb}: overlap (edges cross)")
                continue
            if point_in_poly(A[0], B) or point_in_poly(B[0], A):
                probs.append(f"{ra} x {rb}: one inside the other")
                continue
            d = poly_min_dist(A, B)
            if d < 0.9:
                probs.append(f"{ra} x {rb}: gap only {d:.2f}")
    return probs
