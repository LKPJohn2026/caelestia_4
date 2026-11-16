.pragma library

// caelestia4: the maths behind Display > Arrangement (MonitorLayout.qml), kept apart so it can be tested without a
// screen. All sizes and positions are Hyprland's layout units (logical pixels: a screen at 200 % takes half its
// device pixels in the layout). A rect is { x, y, w, h }.

// The share of an edge two screens must have in common so the pointer can cross between them
const MIN_SHARED = 50;

// The size a screen takes in the layout: its mode divided by its scale, turned on its side by a 90° or 270° rotation
function logicalSize(m) {
    const scale = m.scale > 0 ? m.scale : 1;
    const w = Math.round(m.width / scale);
    const h = Math.round(m.height / scale);
    return (m.transform & 1) ? { w: h, h: w } : { w: w, h: h };
}

function overlaps(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

// caelestia4: how much edge a and b have in common (0 when they don't sit right next to each other, or overlap)
function shared(a, b) {
    if (overlaps(a, b))
        return 0;
    if (a.x + a.w === b.x || b.x + b.w === a.x)
        return Math.max(0, Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y));
    if (a.y + a.h === b.y || b.y + b.h === a.y)
        return Math.max(0, Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x));
    return 0;
}

// Shares a stretch of edge (not just a corner) with b, without overlapping it
function touches(a, b) {
    return shared(a, b) > 0;
}

// caelestia4: shares enough edge with b for the pointer to cross easily: MIN_SHARED, or all of the shorter side
function joins(a, b) {
    const s = shared(a, b);
    if (s <= 0)
        return false;
    const sideBySide = a.x + a.w === b.x || b.x + b.w === a.x;
    const need = sideBySide ? Math.min(MIN_SHARED, a.h, b.h) : Math.min(MIN_SHARED, a.w, b.w);
    return s >= need;
}

// caelestia4: every screen can be reached from every other one by moving the pointer across shared edges
function connected(rects) {
    if (rects.length < 2)
        return true;
    const seen = [0];
    for (let i = 0; i < seen.length; i++)
        for (let j = 0; j < rects.length; j++)
            if (seen.indexOf(j) < 0 && touches(rects[seen[i]], rects[j]))
                seen.push(j);
    return seen.length === rects.length;
}

// The value in `candidates` nearest to v, if it is within `threshold`; else v
function nearest(v, candidates, threshold) {
    let best = v, dist = threshold + 1;
    for (const c of candidates) {
        const d = Math.abs(c - v);
        if (d < dist) {
            best = c;
            dist = d;
        }
    }
    return dist <= threshold ? best : v;
}

// Lines up r's edges with the other screens' edges when they are within `threshold`
function snapEdges(r, others, threshold) {
    const xs = [], ys = [];
    for (const o of others) {
        xs.push(o.x, o.x + o.w, o.x - r.w, o.x + o.w - r.w);
        ys.push(o.y, o.y + o.h, o.y - r.h, o.y + o.h - r.h);
    }
    return { x: nearest(r.x, xs, threshold), y: nearest(r.y, ys, threshold), w: r.w, h: r.h };
}

// Where r may go nearest to where it was dropped: right next to another screen, sharing part of an edge with it, and
// on top of none. Along the shared edge it lines up with nearby edges (within `threshold`)
function place(r, others, threshold) {
    if (!others.length)
        return { x: 0, y: 0, w: r.w, h: r.h };
    const s = snapEdges(r, others, threshold);
    // caelestia4: only when it shares enough edge (a snap can leave just a few pixels in common)
    if (others.some(o => joins(s, o)) && !others.some(o => overlaps(s, o)))
        return s;
    const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
    const alongX = [], alongY = [];
    for (const o of others) {
        alongX.push(o.x, o.x + o.w - r.w);
        alongY.push(o.y, o.y + o.h - r.h);
    }
    const candidates = [];
    for (const o of others) {
        const shareX = Math.min(MIN_SHARED, o.w, r.w), shareY = Math.min(MIN_SHARED, o.h, r.h);
        const y = clamp(nearest(s.y, alongY, threshold), o.y - r.h + shareY, o.y + o.h - shareY);
        const x = clamp(nearest(s.x, alongX, threshold), o.x - r.w + shareX, o.x + o.w - shareX);
        candidates.push({ x: o.x - r.w, y: y }, { x: o.x + o.w, y: y }, { x: x, y: o.y - r.h }, { x: x, y: o.y + o.h });
    }
    let best = null, dist = Infinity;
    for (const c of candidates) {
        const cand = { x: Math.round(c.x), y: Math.round(c.y), w: r.w, h: r.h };
        if (others.some(o => overlaps(cand, o)))
            continue;
        const d = Math.hypot(cand.x - r.x, cand.y - r.y);
        if (d < dist) {
            best = cand;
            dist = d;
        }
    }
    if (best)
        return best;
    // Boxed in on every side (can't happen with real screens): to the right of everything
    return { x: Math.max(...others.map(o => o.x + o.w)), y: others[0].y, w: r.w, h: r.h };
}

// Moves the whole layout so its top-left corner is 0, 0 (positions = { name: { x, y } })
function normalise(positions) {
    const names = Object.keys(positions);
    if (!names.length)
        return positions;
    const minX = Math.min(...names.map(n => positions[n].x));
    const minY = Math.min(...names.map(n => positions[n].y));
    const out = {};
    for (const n of names)
        out[n] = { x: positions[n].x - minX, y: positions[n].y - minY };
    return out;
}

// The smallest rect around all of them
function bounds(rects) {
    if (!rects.length)
        return { x: 0, y: 0, w: 1, h: 1 };
    const x = Math.min(...rects.map(r => r.x)), y = Math.min(...rects.map(r => r.y));
    return { x: x, y: y, w: Math.max(...rects.map(r => r.x + r.w)) - x, h: Math.max(...rects.map(r => r.y + r.h)) - y };
}
