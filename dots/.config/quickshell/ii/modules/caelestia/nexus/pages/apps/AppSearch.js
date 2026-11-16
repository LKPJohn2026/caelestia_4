.pragma library

// caelestia4: filter for the All apps page. Plain substring match on folded text (lower case, accents removed,
// "đ" -> "d"), so "trinh duyet" finds "Trình duyệt". Every word of the query must match one of the fields.
// Searcher.qml is not used: it is a Singleton root (one list per instance) and its fuzzy accent strip keeps "đ".

function fold(s) {
    return String(s ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d");
}

// Rank of one app for the folded words, or -1 when a word matches nothing. Lower is better:
// name starts with the query, then name, generic name, keywords, comment
function rank(app, words, whole) {
    const name = fold(app.name);
    const fields = [name, fold(app.genericName), fold((app.keywords ?? []).join(" ")), fold(app.comment)];
    let worst = 0;
    for (const w of words) {
        const i = fields.findIndex(f => f.includes(w));
        if (i < 0)
            return -1;
        worst = Math.max(worst, i + 1);
    }
    return name.startsWith(whole) ? 0 : worst;
}

// apps: sorted by name. Returns the apps that match `query`, best first (name order within a rank)
function filter(apps, query) {
    const whole = fold(query).trim().replace(/\s+/g, " ");
    if (!whole)
        return apps;
    const words = whole.split(" ");
    const out = [];
    for (const a of apps) {
        const r = rank(a, words, whole);
        if (r >= 0)
            out.push({ a, r });
    }
    return out.sort((x, y) => x.r - y.r).map(o => o.a); // stable: keeps name order within a rank
}
