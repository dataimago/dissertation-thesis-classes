#!/usr/bin/env python3
"""Per-profile PDF checks T3-T13, T15, T18, T19(b) (docs/house-class-spec.md section 7.2).

usage: check_pdf.py --pdf thesis.pdf --profile house [--engine lualatex|xelatex]
                    [--example classes/dataimago-thesis/example] [--snapshots DIR | --update-snapshots DIR]
Exit status 1 when any check fails. MIT licensed.
"""
import argparse
import os
import re
import shutil
import statistics
import subprocess
import sys
from pathlib import Path

import fitz  # PyMuPDF
import numpy as np
import pypdf
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from profiles_lib import PROFILES, ROOT, load_resolved, load_tests  # noqa: E402

RESULTS = []


def rec(tid, ok, msg=""):
    RESULTS.append((tid, ok, msg))
    print(f"{'ok  ' if ok else 'FAIL'} {tid}{': ' + msg if msg else ''}")


def lengths_pt(v):
    if isinstance(v, (int, float)):
        return float(v)
    m = re.fullmatch(r"([0-9.]+)\s*(in|cm|pt|mm|em)?", str(v).strip())
    num, unit = float(m.group(1)), m.group(2) or "pt"
    return num * {"in": 72.0, "cm": 72.0 / 2.54, "pt": 1.0, "mm": 72.0 / 25.4, "em": 12.0}[unit]


SINGLE_PITCH = {10: 12.0, 11: 13.6, 12: 14.5}  # the book class's baselineskip per size


def expected_pitch(p):
    body = p["spacing"]["body"]
    if isinstance(body, dict):
        return lengths_pt(body["pitch"])
    size = int(p["type"]["size"]) if int(p["type"]["size"]) in SINGLE_PITCH else 11
    factor = {"single": 1.0, "onehalf": 1.5, "double": 2.0}.get(body, body if isinstance(body, (int, float)) else 2.0)
    return SINGLE_PITCH[size] * float(factor)


def paper_pt(p):
    g = p["geometry"]
    if g["paper"] == "letter":
        return 612.0, 792.0
    if g["paper"] == "a4":
        return 595.276, 841.89
    return lengths_pt(g["paperWidth"]), lengths_pt(g["paperHeight"])


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def fill(template, slots):
    return re.sub(r"\{(\w+)\}", lambda m: slots.get(m.group(1), m.group(0)), template)


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", required=True)
    ap.add_argument("--profile", required=True)
    ap.add_argument("--engine", default="lualatex")
    ap.add_argument("--example", default=str(ROOT / "classes/dataimago-thesis/example"))
    ap.add_argument("--snapshots")
    ap.add_argument("--update-snapshots")
    ap.add_argument("--release", action="store_true", help="fail when thesis.draft is true")
    ap.add_argument("--profiles-dir", default=str(PROFILES))
    a = ap.parse_args()

    p = load_resolved(a.profile, a.profiles_dir)
    tcfg = load_tests(a.profile, a.profiles_dir)
    meta = yaml.safe_load((Path(a.example) / "_quarto.yml").read_text())
    th = meta["thesis"]
    overlay = Path(a.example) / f"_quarto-{a.profile}.yml"
    if overlay.exists():
        ov = yaml.safe_load(overlay.read_text()) or {}
        th = {**th, **ov.get("thesis", {})}
    doc = fitz.open(a.pdf)
    reader = pypdf.PdfReader(a.pdf)
    W, H = paper_pt(p)
    n = doc.page_count
    tagged_expected = a.engine == "lualatex" and p["accessibility"]["tagged"] == "on"

    if a.release and th.get("draft"):
        rec("draft", False, "thesis.draft is true on a release build")

    # ---- T3 fonts
    out = run(["pdffonts", a.pdf]).stdout.splitlines()
    rows = [l for l in out[2:] if l.strip()]
    names, bad = [], []
    for l in rows:
        parts = l.split()
        name = parts[0]
        names.append(name)
        # columns from the right: object id, id, uni, sub, emb
        emb = parts[-5]
        if emb != "yes":
            bad.append(f"{name} not embedded")
        if "Type 3" in l:
            bad.append(f"{name} is Type 3")
    math = p["type"]["math"]
    squeeze = lambda s: re.sub(r"[^A-Za-z0-9]", "", s)
    if math != "latex-default":
        if any("LatinModernMath" in n_ for n_ in names):
            bad.append("LatinModernMath is embedded: the math font silently fell back (M2/M3a)")
        if not any(squeeze(math) in squeeze(n_) for n_ in names):
            bad.append(f"the math font '{math}' is not among the embedded fonts (M3b)")
    if p["type"]["main"] != "latex-default" and not any(squeeze(p["type"]["main"]) in squeeze(n_) for n_ in names):
        bad.append(f"the main font '{p['type']['main']}' is not among the embedded fonts")
    rec("T3 fonts (S1, S2, M3)", not bad, "; ".join(bad))

    # ---- T4 page size
    info = run(["pdfinfo", "-box", "-f", "1", "-l", str(n), a.pdf]).stdout
    sizes = re.findall(r"Page\s+(\d+) size:\s+([0-9.]+) x ([0-9.]+) pts", info)
    badp = []
    landscape = set()
    for pg, w, h in sizes:
        w, h = float(w), float(h)
        if abs(w - W) < 0.3 and abs(h - H) < 0.3:
            continue
        if abs(w - H) < 0.3 and abs(h - W) < 0.3:
            landscape.add(int(pg) - 1)
            continue
        badp.append(f"p{pg} {w}x{h}")
    landscape |= {i for i in range(n) if doc[i].rotation in (90, 270)}
    rec("T4 page size (S9)", len(sizes) == n and not badp, f"expected {W:.1f}x{H:.1f}: {badp}")

    # ---- page labels (T9) and page index helpers
    labels = reader.page_labels
    texts = [doc[i].get_text() for i in range(n)]
    first_main = next((i for i, t in enumerate(texts) if re.search(r"^(Chapter\s+1|Front matter)\s*$", t, re.M)), None)

    def roman(k):
        vals = [(10, "x"), (9, "ix"), (5, "v"), (4, "iv"), (1, "i")]
        s = ""
        for v, r in vals:
            while k >= v:
                s += r
                k -= v
        return s

    errs = []
    if first_main is None:
        errs.append("could not find the first chapter page")
    else:
        pn = p["pagenumber"]
        front = list(range(first_main))
        style = pn["front"]["style"]
        start = 0
        if not pn["front"]["titleCounts"]:
            start = 1
            if labels[0] in ("i", "1"):
                errs.append("title page does not count (titleCounts false) but has a numbered label")
        for k, i in enumerate(front[start:], 1):
            want = {"roman": roman(k), "arabic": str(k), "none": None}[style]
            if want is not None and labels[i] != want:
                errs.append(f"front page {i + 1}: label {labels[i]!r}, expected {want!r}")
        for k, i in enumerate(range(first_main, n)):
            want = str(pn["main"]["start"] + k)
            if labels[i] != want:
                errs.append(f"main page {i + 1}: label {labels[i]!r}, expected {want!r}")
                break
    rec("T9 page labels", not errs, "; ".join(errs[:4]))

    # ---- T6 page-number position
    band = lambda y: y < 0.12 * H or y > 0.88 * H
    num_tol = tcfg.get("pageNumber", {}).get("tolerancePt", 2.0)
    d = lengths_pt(p["geometry"]["headerFooter"]["numberDistance"])
    m_in, m_out = lengths_pt(p["geometry"]["margins"]["inside"]) + lengths_pt(p["geometry"]["binding"]["gutter"]), lengths_pt(p["geometry"]["margins"]["outside"])
    tw = W - m_in - m_out
    allowed = {p["pagenumber"]["position"]}
    if p["pagenumber"]["chapterFirstPage"] == "bottom-center":
        allowed.add("bottom-center")
    seen = {}
    found = {}
    for i in range(n):
        if i in landscape:
            continue
        for b in doc[i].get_text("dict")["blocks"]:
            for l in b.get("lines", []):
                for s in l["spans"]:
                    t = s["text"].strip()
                    if t == labels[i] and t and band(s["origin"][1]) and s["bbox"][3] - s["bbox"][1] < 30:
                        found[i] = (s["origin"][1], s["bbox"][0], s["bbox"][2])
    errs = []
    for i, (by, x0, x1) in found.items():
        pos = None
        for cand in allowed:
            vert, hor = cand.split("-")
            ey = d if vert == "top" else H - d
            ex = {"left": m_in, "center": m_in + tw / 2, "right": m_in + tw}[hor]
            xx = {"left": x0, "center": (x0 + x1) / 2, "right": x1}[hor]
            if abs(by - ey) <= num_tol and abs(xx - ex) <= num_tol:
                pos = cand
        if pos is None:
            errs.append(f"p{i + 1} number at y={by:.1f}, x={x0:.1f}-{x1:.1f} matches none of {sorted(allowed)}")
    hide_front = set(p["pagenumber"]["front"]["hideOn"])
    if first_main is not None and p["pagenumber"]["chapterFirstPage"] != "hide":
        for i in range(first_main, n):
            if i not in landscape and i not in found:
                errs.append(f"p{i + 1}: expected a page number, found none")
    if not found:
        errs.append("no page number found anywhere")
    if not p["pagenumber"]["front"]["titleShown"] and 0 in found:
        errs.append("the title page shows a number")
    rec("T6 page-number position", not errs, "; ".join(errs[:4]))

    # ---- T5 margins (ink bounding box on rasterized pages)
    mt = tcfg.get("margins", {}).get("tolerancePt", 1.0)
    mg = p["geometry"]["margins"]
    exp = dict(top=lengths_pt(mg["top"]), bottom=lengths_pt(mg["bottom"]), left=m_in, right=m_out)
    errs = []
    for i in range(n):
        if i in landscape:
            continue
        pg = doc[i]
        pix = pg.get_pixmap(dpi=144, alpha=False)
        img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, pix.n)[:, :, :3].astype(int)
        sc = 144 / 72.0
        if i in found:  # white out the page number (exempt)
            by, x0, x1 = found[i]
            y0 = int((by - 14) * sc); y1 = int((by + 5) * sc)
            img[max(y0, 0):y1, int((x0 - 2) * sc):int((x1 + 2) * sc)] = 255
        ink = (img.sum(axis=2) < 3 * 245)
        ys, xs = np.where(ink)
        if len(ys) == 0:
            continue
        got = dict(left=xs.min() / sc, right=W - (xs.max() + 1) / sc, top=ys.min() / sc, bottom=H - (ys.max() + 1) / sc)
        for k in got:
            extra = tcfg.get("margins", {}).get("bottomDescenderPt", 3.0) if k == "bottom" else 0.0
            if got[k] < exp[k] - mt - extra:
                errs.append(f"p{i + 1} {k}: ink {got[k]:.1f}pt from the edge, margin {exp[k]:.1f}pt")
    rec("T5 margins", not errs, "; ".join(errs[:4]))

    # ---- T7 line pitch
    pt = tcfg.get("linePitch", {}).get("tolerancePt", 0.5)
    want = expected_pitch(p)
    best = []
    ind = lengths_pt(p["spacing"]["paragraph"]["indent"])
    for i in range((first_main or 0), n):
        if i in landscape:
            continue
        lines = []
        for b in doc[i].get_text("dict")["blocks"]:
            for l in b.get("lines", []):
                sp = l["spans"]
                txt = "".join(s_["text"] for s_ in sp)
                if len(txt) > 45 and abs(sp[0]["size"] - float(p["type"]["size"])) < 0.6 and "Math" not in sp[0]["font"] \
                        and sp[0]["bbox"][0] < m_in + ind + 2:
                    lines.append(round(sp[0]["origin"][1], 1))
        lines = sorted(set(lines))
        best += [round(b_ - a_, 2) for a_, b_ in zip(lines, lines[1:]) if b_ - a_ < 1.5 * want]
    got = statistics.median(best) if best else None
    rec("T7 line pitch (R13)", got is not None and abs(got - want) <= pt, f"measured {got}, expected {want:.2f}pt")

    # ---- T8 front-matter order, T10 wording
    slots = dict(title=meta["book"]["title"], author=meta["book"]["author"], degreeName=th["degree"]["name"],
                 degreeAbbr=th["degree"]["abbreviation"], field=th["degree"]["field"], documentType=th["type"],
                 department=th["department"], institution=th.get("institution") or p["institution"]["name"],
                 graduateSchool=th.get("graduate-school") or p["institution"]["graduateSchool"], year=str(th["year"]))
    heads = {
        "title": slots["title"], "abstract": "Abstract", "dedication": "For the imaginary readers",
        "acknowledgments": p["frontmatter"]["acknowledgments"]["heading"],
        "toc": r"(Table of contents|Contents)", "lof": "List of Figures", "lot": "List of Tables",
        "abbreviations": "List of Abbreviations", "preface": "Preface", "symbols": "List of Symbols",
        "copyright": re.escape(fill(p["frontmatter"]["copyright"]["template"], slots)),
        "committee": p["frontmatter"]["committee"]["heading"],
    }
    order = p["frontmatter"]["order"]
    pages = []
    errs = []
    last = -1
    for pid in order:
        if pid == "approval":
            continue
        if pid == "committee" and p["frontmatter"]["committee"]["placement"] != "separate-page":
            continue
        pat = heads[pid]
        hit = next((i for i, t in enumerate(texts[: first_main or n]) if re.search(pat if pid in ("toc", "copyright") else re.escape(pat), norm(t))), None)
        if hit is None:
            errs.append(f"{pid}: no page carries '{pat}'")
        else:
            if hit < last:
                errs.append(f"{pid} (page {hit + 1}) comes before the previous page of frontmatter.order")
            last = max(last, hit)
    rec("T8 front-matter order", not errs, "; ".join(errs))
    title_text = norm(texts[0])
    expect = norm(fill(p["frontmatter"]["titlePage"]["statement"].replace("\n", " "), slots))
    byline = norm(fill(p["frontmatter"]["titlePage"]["byline"], slots))
    errs = []
    if expect not in title_text:
        errs.append(f"statement not found; expected '{expect}'")
    if byline not in title_text:
        errs.append(f"byline '{byline}' not found")
    rec("T10 wording", not errs, "; ".join(errs))

    # ---- T12 metadata and bookmarks
    xmp = reader.trailer["/Root"]["/Metadata"].get_object().get_data().decode("utf-8", "replace") if "/Metadata" in reader.trailer["/Root"] else ""
    info_d = reader.metadata or {}
    errs = []

    def field(tag, key):
        m = re.search(r"<%s[^>]*>(.*?)</%s>" % (tag, tag), xmp, re.S)
        return norm(re.sub(r"<[^>]+>", " ", m.group(1))) if m else (info_d.get(key) or "")

    for tag, key, needle in (("dc:title", "/Title", slots["title"]), ("dc:creator", "/Author", slots["author"]),
                             ("dc:description", "/Subject", slots["degreeName"])):
        if needle not in field(tag, key):
            errs.append(f"{key[1:]} missing or wrong")
    if "Example University" not in field("dc:description", "/Subject") and a.profile == "house":
        errs.append("Subject lacks the institution")
    kw = " ".join([field("dc:subject", "/Keywords"), field("pdf:Keywords", "/Keywords")])
    if th.get("keywords") and not all(k in kw for k in th["keywords"]):
        errs.append("Keywords missing")
    lang = reader.trailer["/Root"].get("/Lang")
    if not lang or str(lang) != "en-US":
        errs.append(f"/Lang is {lang!r}")
    vp = reader.trailer["/Root"].get("/ViewerPreferences") or {}
    if not vp.get("/DisplayDocTitle"):
        errs.append("DisplayDocTitle is not set (A6)")
    outline = reader.outline

    def depth(o, lvl=1):
        m_ = lvl
        for x in o:
            if isinstance(x, list):
                m_ = max(m_, depth(x, lvl + 1))
        return m_

    bd = p["submission"]["bookmarkDepth"]
    if bd and not outline:
        errs.append("no bookmarks")
    elif outline and depth(outline) > bd + 1:
        errs.append(f"bookmarks nest {depth(outline)} deep, bookmarkDepth is {bd}")
    rec("T12 metadata and bookmarks (S6, S7)", not errs, "; ".join(errs))

    # ---- T13 security
    errs = []
    if reader.is_encrypted:
        errs.append("the PDF is encrypted")
    if shutil.which("qpdf"):
        q = run(["qpdf", "--show-encryption", a.pdf]).stdout
        if "not encrypted" not in q.lower():
            errs.append("qpdf reports encryption")
    rec("T13 security (S3)", not errs, "; ".join(errs))

    # ---- T14 PDF/A and PDF/UA via veraPDF (optional locally; CI sets REQUIRE_VERAPDF=1)
    flavours = []
    pdfa = p["submission"]["pdfa"]
    if pdfa != "none":
        flavours.append(pdfa)
    if tagged_expected:
        ua = p["accessibility"]["pdfua"]
        if ua == "auto":
            ua = "ua-1" if pdfa in ("1b", "2b", "3b") else "ua-2"
        if ua != "none":
            flavours.append(ua.replace("-", ""))
    if flavours and shutil.which("verapdf"):
        bad = []
        for fl in flavours:
            r = run(["verapdf", "--flavour", fl, "--format", "text", a.pdf])
            if not r.stdout.startswith("PASS"):
                d = run(["verapdf", "--flavour", fl, "--format", "text", "-v", a.pdf]).stdout
                bad.append(f"{fl}: " + " | ".join(l.strip() for l in d.splitlines()[1:6]))
        if bad and a.engine != "lualatex":
            # R19: PDF/A is not guaranteed on XeLaTeX (xdvipdfmx writes no file ID for PDF/A-4; rules 6.1.3-4/-5)
            print(f"WARN T14 veraPDF ({', '.join(flavours)}) on {a.engine}: " + "; ".join(bad) + " (not guaranteed on XeLaTeX)")
        else:
            rec(f"T14 veraPDF ({', '.join(flavours)})", not bad, "; ".join(bad))
    elif flavours and os.environ.get("REQUIRE_VERAPDF"):
        rec("T14 veraPDF", False, "veraPDF is required (REQUIRE_VERAPDF) but not installed")
    else:
        print("skip T14 veraPDF: not installed" if flavours else "skip T14: no PDF standard requested")

    # ---- T15 tagging
    if tagged_expected:
        root = reader.trailer["/Root"]
        errs = []
        if "/StructTreeRoot" not in root:
            errs.append("no structure tree")
        else:
            figs = []

            def walk(node, seen=0):
                node = node.get_object()
                if seen > 10000:
                    return
                if isinstance(node, dict):
                    if node.get("/S") == "/Figure":
                        figs.append(node)
                    k = node.get("/K")
                    if k is not None:
                        k = k.get_object() if hasattr(k, "get_object") else k
                        for c in (k if isinstance(k, list) else [k]):
                            c = c.get_object() if hasattr(c, "get_object") else c
                            if isinstance(c, dict):
                                walk(c, seen + 1)

            walk(root["/StructTreeRoot"])
            # headings: resolve each element's role through its namespace's role map to H1..H6
            st = root["/StructTreeRoot"]
            def _nm(v):
                v = v.get_object() if hasattr(v, "get_object") else v
                if isinstance(v, list):
                    v = v[0]
                return str(v)

            nsmaps = {}
            for nsref in st.get("/Namespaces", []):
                nso = nsref.get_object()
                rmn = nso.get("/RoleMapNS")
                nsmaps[nsref.idnum] = {str(k): _nm(v) for k, v in rmn.get_object().items()} if rmn else {}
            flat_rm = {str(k): _nm(v) for k, v in (st.get("/RoleMap") or {}).items()}
            levels = []

            def walk_h(node, depth=0):
                node = node.get_object()
                if depth > 200 or not isinstance(node, dict):
                    return
                s = node.get("/S")
                if s is not None:
                    role = str(s)
                    nsid = node.raw_get("/NS").idnum if "/NS" in node else None
                    for _ in range(4):
                        nxt = nsmaps.get(nsid, {}).get(role) or flat_rm.get(role)
                        if not nxt or nxt == role:
                            break
                        role = nxt
                    m = re.fullmatch(r"/H([1-6])", role)
                    if m:
                        levels.append(int(m.group(1)))
                k = node.get("/K")
                if k is not None:
                    k = k.get_object() if hasattr(k, "get_object") else k
                    for ch in (k if isinstance(k, list) else [k]):
                        ch = ch.get_object() if hasattr(ch, "get_object") else ch
                        if isinstance(ch, dict):
                            walk_h(ch, depth + 1)

            walk_h(st)
            n_chap = len(re.findall(r"^(?:Chapter\s+\d+|Appendix\s+[A-Z])\s*$", "\n".join(texts), re.M))
            if levels.count(1) < max(n_chap, 1):
                errs.append(f"only {levels.count(1)} H1 heading(s) in the structure tree for {n_chap} chapter pages: chapter titles are not tagged as headings (PDF/UA)")
            for a_, b_ in zip(levels, levels[1:]):
                if b_ > a_ + 1:
                    errs.append(f"heading levels jump from H{a_} to H{b_}")
                    break
            if not figs:
                errs.append("no Figure elements in the structure tree")
            for f in figs:
                if not f.get("/Alt"):
                    errs.append("a Figure element has no alt text")
        if not str(reader.trailer["/Root"].get("/MarkInfo", "")):
            errs.append("no /MarkInfo")
        rec("T15 tagging (A1, A2)", not errs, "; ".join(errs[:3]))
    else:
        print(f"skip T15 tagging: engine {a.engine} / accessibility.tagged {p['accessibility']['tagged']}")

    # ---- T18 size
    mx = p["submission"].get("maxMB")
    size_mb = Path(a.pdf).stat().st_size / 1e6
    if mx and size_mb > mx:
        print(f"WARN T18: {size_mb:.1f} MB exceeds submission.maxMB {mx}")

    # ---- T19(b) minimum text size
    mcfg = tcfg.get("minimumText", {})
    tol = mcfg.get("tolerancePt", 0.3)
    excl = set(mcfg.get("exclude", []))  # math-scripts, footnote-markers, citation-markers, folios (R20)
    mn = float(p["type"]["minimumSize"])
    small = []
    for i in range(n):
        for b in doc[i].get_text("dict")["blocks"]:
            for l in b.get("lines", []):
                for s in l["spans"]:
                    t = s["text"].strip()
                    if not t or s["size"] >= mn - tol:
                        continue
                    if "math-scripts" in excl and "Math" in s["font"]:
                        continue
                    if ({"footnote-markers", "citation-markers"} & excl) and re.fullmatch(r"[0-9\u00b9\u00b2\u00b3\u2070-\u2079*\u2020\u2021]+", t):
                        continue
                    if "folios" in excl and t == labels[i]:
                        continue
                    small.append(f"p{i + 1} {s['size']:.1f}pt '{t[:20]}'")
    rec("T19b minimum text size", not small, "; ".join(small[:4]))

    # ---- T11 snapshots
    snapdir = a.snapshots or a.update_snapshots
    if snapdir:
        sd = Path(snapdir)
        sd.mkdir(parents=True, exist_ok=True)
        cfg = tcfg.get("snapshot", {})
        errs = []
        for i in range(min(cfg.get("firstPages", 8), n)):
            pix = doc[i].get_pixmap(dpi=cfg.get("dpi", 80), alpha=False)
            f = sd / f"p{i + 1:02d}.png"
            if a.update_snapshots:
                pix.save(f)
                continue
            if not f.exists():
                errs.append(f"{f.name} missing (update deliberately with --update-snapshots)")
                continue
            old = fitz.Pixmap(str(f))
            cur = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, pix.n).astype(int)
            prev = np.frombuffer(old.samples, dtype=np.uint8).reshape(old.height, old.width, old.n).astype(int)
            if cur.shape != prev.shape:
                errs.append(f"{f.name}: size differs")
                continue
            frac = float((np.abs(cur - prev).max(axis=2) > 64).mean())
            if frac > cfg.get("tolerance", 0.02):
                errs.append(f"{f.name}: {frac:.1%} of pixels differ")
        if a.update_snapshots:
            print(f"snapshots written to {sd}")
        else:
            rec("T11 first-pages snapshot", not errs, "; ".join(errs))

    failed = [r for r in RESULTS if not r[1]]
    print(f"\n{len(RESULTS) - len(failed)} passed, {len(failed)} failed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
