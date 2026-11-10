#!/usr/bin/env python3
"""Check docs/registry-sync-log.md against registry.json.

The newest row must carry the git blob of the current registry.json and name the
dissertation-ai pull request that syncs the hub's copy. Given a base ref, rows are
append-only, and a change to registry.json since the base must append exactly one row.

usage: check_sync_log.py [--base <ref>]      check this tree (against <ref> when given)
       check_sync_log.py --selftest          run the built-in cases first (CI does)
Exit status 1 when any check fails. MIT licensed.
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOG = "docs/registry-sync-log.md"
ROW = re.compile(
    r"^\| (\d{4}-\d{2}-\d{2}) \| `([0-9a-f]{40})` \| ([^|]+?) \| dataimago/dissertation-ai#([1-9][0-9]*) \|$"
)


def parse(text):
    """Return (rows, errors). A row is (date, blob, change, hub PR number)."""
    rows, errors = [], []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.startswith("| 2"):
            continue
        m = ROW.match(line)
        if m:
            rows.append((m[1], m[2], m[3], int(m[4])))
        else:
            errors.append(f"{LOG}:{n}: not a row of the form | date | `blob` | change | dataimago/dissertation-ai#N |")
    return rows, errors


def check(head_text, head_blob, base_text=None, base_blob=None):
    """Errors for the log at head; base_text None means no base, or no log at the base."""
    rows, errors = parse(head_text)
    if not rows:
        return errors + [f"{LOG} has no rows"]
    if rows[-1][1] != head_blob:
        errors.append(
            f"the newest row's blob is {rows[-1][1][:12]}, but registry.json is {head_blob[:12]}: "
            f"append a row (or, before merge, update this PR's row) naming the hub PR that copies it"
        )
    prs = [r[3] for r in rows]
    if len(set(prs)) != len(prs):
        errors.append("a hub sync PR is named by more than one row")
    if [r[0] for r in rows] != sorted(r[0] for r in rows):
        errors.append("rows are not in date order")
    if base_text is not None:
        base_rows, _ = parse(base_text)
        if rows[: len(base_rows)] != base_rows:
            errors.append("rows that are already on the base branch were changed or removed")
        added = len(rows) - len(base_rows)
        if head_blob != base_blob and added != 1:
            errors.append(f"registry.json changed, so this PR appends exactly one row (it appends {added})")
        if head_blob == base_blob and added != 0:
            errors.append(f"registry.json did not change, so this PR appends no row (it appends {added})")
    return errors


def selftest():
    a, b, c = "a" * 40, "b" * 40, "c" * 40
    r = lambda d, blob, pr: f"| {d} | `{blob}` | x | dataimago/dissertation-ai#{pr} |"
    one = r("2026-11-01", a, 1)
    two = one + "\n" + r("2026-11-02", b, 2)
    cases = [
        ("current, no base", check(one, a), True),
        ("stale newest blob", check(one, b), False),
        ("no rows", check("text only", a), False),
        ("malformed row", check(one + "\n| 2026-11-02 | b | x | #2 |", a), False),
        ("other repo named", check(one.replace("dissertation-ai", "dissertation-app"), a), False),
        ("change + one row", check(two, b, one, a), True),
        ("change, no row", check(one, b, one, a), False),
        ("change, two rows", check(two + "\n" + r("2026-11-03", b, 3), b, one, a), False),
        ("no change, row added", check(two, b, one, b), False),
        ("old row edited", check(r("2026-11-01", c, 1) + "\n" + r("2026-11-02", b, 2), b, one, a), False),
        ("old row removed", check(r("2026-11-02", b, 2), b, one, a), False),
        ("hub PR reused", check(one + "\n" + r("2026-11-02", b, 1), b, one, a), False),
        ("dates out of order", check(one + "\n" + r("2026-10-31", b, 2), b, one, a), False),
        ("no change, nothing added", check(two, b, two, b), True),
    ]
    bad = [name for name, errs, ok in cases if (not errs) != ok]
    if bad:
        sys.exit("check_sync_log selftest failed: " + ", ".join(bad))
    print(f"check_sync_log selftest: {len(cases)} cases pass")


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)


def main(argv):
    if argv[:1] == ["--selftest"]:
        selftest()
        argv = argv[1:]
    base = argv[1] if argv[:1] == ["--base"] and len(argv) == 2 else None
    if argv and base is None:
        sys.exit(__doc__)
    head_text = (ROOT / LOG).read_text(encoding="utf-8")
    head_blob = git("hash-object", "registry.json").stdout.strip()
    base_text = base_blob = None
    if base:
        shown = git("show", f"{base}:{LOG}")
        base_text = shown.stdout if shown.returncode == 0 else None  # no log at the base: the PR that adds it
        base_blob = git("rev-parse", f"{base}:registry.json").stdout.strip()
        if base_text is not None and not base_blob:
            sys.exit(f"cannot read registry.json at {base}")
    errors = check(head_text, head_blob, base_text, base_blob)
    for e in errors:
        print(f"::error::{e}")
    if errors:
        return 1
    print(f"{LOG}: newest row names registry.json {head_blob[:12]}" + (f" (checked against {base})" if base else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
