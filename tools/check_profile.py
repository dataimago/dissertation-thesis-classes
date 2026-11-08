#!/usr/bin/env python3
"""T1 (schema, sources, cfg drift) and T19(a) for every profile, plus the R14a cross-field rules.

usage: check_profile.py [profile-id ...]        (default: every profiles/*.yaml)
Exit status 1 when any check fails. MIT licensed.
"""
import json
import pathlib
import subprocess
import sys

import jsonschema

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from profiles_lib import PROFILES, ROOT, flatten, load_raw, load_resolved  # noqa: E402

GEN = ROOT / "classes" / "dataimago-thesis" / "thesis-profile.lua"


def texlua():
    for exe in ("texlua", "quarto"):
        pass
    import shutil
    if shutil.which("texlua"):
        return ["texlua"]
    if shutil.which("quarto"):
        return ["quarto", "pandoc", "lua"]
    raise SystemExit("neither texlua nor quarto found; cannot run the Lua generator")


def sources_cover(path, sources):
    parts = path.split(".")
    return any(".".join(parts[: i + 1]) in sources for i in range(len(parts)))


def check(pid):
    errs = []
    raw = load_raw(pid)
    schema = json.loads((PROFILES / "profile.schema.json").read_text())
    for e in sorted(jsonschema.Draft7Validator(schema).iter_errors(raw), key=lambda e: list(e.path)):
        errs.append(f"schema: {'/'.join(map(str, e.path)) or '(root)'}: {e.message}")
    if raw.get("id") != pid:
        errs.append(f"id '{raw.get('id')}' must equal the file name '{pid}'")
    res = load_resolved(pid)
    house = load_resolved("house")

    # P1: every value that differs from the house value needs a sources entry; P3 shape
    sources = raw.get("sources") or {}
    if pid != "house":
        flat, hflat = flatten({k: v for k, v in raw.items() if k not in ("sources", "unstated", "guide", "extends", "schemaVersion", "id")}), flatten(house)
        for path, val in sorted(flat.items()):
            if hflat.get(path) != val and not sources_cover(path, sources):
                errs.append(f"P1: {path} differs from the house value and has no `sources` entry")
        for path, ent in sources.items():
            if isinstance(ent, dict) and ent.get("inferred") and not (ent.get("from") and ent.get("note")):
                errs.append(f"P3: sources.{path} is inferred but lacks `from`/`note`")
        for path in raw.get("unstated") or []:
            if path in flat:
                errs.append(f"P2: {path} is listed under `unstated` but also set")
    # R14a
    fm = res["frontmatter"]
    order = fm["order"]
    plc = fm["committee"]["placement"]
    if plc == "separate-page" and "committee" not in order:
        errs.append("R14a: committee.placement separate-page requires `committee` in frontmatter.order")
    if plc in ("title-page", "none") and "committee" in order:
        errs.append(f"R14a: committee.placement {plc} requires `committee` absent from frontmatter.order")
    if "committee" in fm["titlePage"]["layout"] and plc != "title-page":
        errs.append("R14a: the committee block in titlePage.layout needs committee.placement title-page")
    if fm["approval"]["enabled"] and "approval" not in order:
        errs.append("R14a: approval.enabled requires `approval` in frontmatter.order")
    if fm["copyright"]["enabled"] and "copyright" not in order:
        errs.append("R14a: copyright.enabled requires `copyright` in frontmatter.order")
    # T19(a)
    t = res["type"]
    for k in ("size", "footnoteSize", "captionSize"):
        if t[k] < t["minimumSize"]:
            errs.append(f"T19a: type.{k} ({t[k]}) is below type.minimumSize ({t['minimumSize']})")
    # P6
    if pid != "house" and raw.get("extends") != "house":
        errs.append("P6: a profile other than house must have `extends: house`")
    # math font rule (M1) can only be verified against the installed font in the PDF check (M3)
    # cfg drift: regenerate and compare
    cfg = PROFILES / f"{pid}.cfg"
    gen = subprocess.run(texlua() + [str(GEN), str(PROFILES), pid, "/dev/stdout"], capture_output=True, text=True)
    if gen.returncode != 0:
        errs.append(f"generator failed: {gen.stderr.strip()[:300]}")
    elif not cfg.exists():
        errs.append(f"{cfg.name} is missing; run the generator")
    elif cfg.read_text() != gen.stdout:
        errs.append(f"{cfg.name} drifted from {pid}.yaml; regenerate it (never hand-edit)")
    # Lua parser parity with PyYAML (types included)
    jl = subprocess.run(texlua() + [str(GEN), "--json", str(PROFILES / f"{pid}.yaml")], capture_output=True, text=True)
    if jl.returncode == 0:
        if json.loads(jl.stdout) != json.loads(json.dumps(raw)):
            errs.append("the Lua YAML reader and PyYAML disagree about this file (use the plain YAML subset)")
    else:
        errs.append(f"Lua YAML reader failed: {jl.stderr.strip()[:300]}")
    return errs


def main():
    ids = sys.argv[1:] or sorted(p.stem for p in PROFILES.glob("*.yaml") if not p.name.endswith(".test.yaml"))
    bad = 0
    for pid in ids:
        errs = check(pid)
        print(f"{'FAIL' if errs else 'ok  '} {pid}")
        for e in errs:
            print(f"     - {e}")
        bad += bool(errs)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
