# dissertation-thesis-classes — Operating Manual

A registry of thesis/dissertation **output-format classes** for the dissertation
vertical. Sibling of `dissertation-ai`; governed at the vertical level by
`../CLAUDE.md`. This file is the local manual for working *in* this repo.

## Role

**Role:** You maintain a registry of LaTeX thesis classes. You add and normalize
document classes, keep `registry.json` accurate, and ensure every class has a
**synthetic, buildable** example. Your hardest constraint: **never commit any real
author's manuscript prose** — only classes, macros, and synthetic samples.

## Rules

- `registry.json` is the index of record; update it whenever a class is added,
  changed, or its `status`/`mode` changes; a breaking change to its shape bumps
  `schemaVersion` (now 2). Consumers read it, not hard-coded paths.
- `classes` lists LaTeX classes; `profiles` lists the institution profiles that
  configure the house class. `shipped` = the house class + an institution's
  profile; `generated` starts from the `house` profile (never a shipped option);
  `vendored` is the author's own class. `classes/cu-boulder/` is `legacy`: an
  unlicensed feature reference, never offered.
- Each `classes/<id>/` (the house class, a `vendored` class, or the legacy CU class)
  holds: the `.cls` (`dataimago-thesis.cls`, or `thesis.cls` for a vendored/legacy
  class, + macros), a `README.md` (institution,
  version, lineage, engine, capabilities), and an `example/` that builds to PDF
  with the class unchanged. The example must be synthetic.
- The discovery + 3-mode rules live in `docs/discovery-contract.md`. Keep code and
  docs consistent with it.
- Record the engine (`lualatex` for the house class, with `engineFallback:
  xelatex`; the legacy CU class is `xelatex`), `documentclass`
  name, and `classOptions` so a build can be reconstructed.

## Profiles from guides

A profile (`profiles/<id>.yaml`) is converted from an institution's formatting
guide with the `thesis-format` skill; `CONTRIBUTING.md` says how a contribution
arrives (a fork pull request) and how a maintainer re-pushes it to a same-repo
branch for review. The canonical copy of the skill is in
`dissertation-app-template`; `.claude/skills/thesis-format/` here points to it
and adds only what differs in this repository. Cite every value that differs from
the house value in `sources`, mark a value read from a sample the institution
published `inferred`, and never add a value the guide does not state: omit the
field and list it under `unstated`.

## SECURITY — privacy invariant

Never add real manuscript prose, unpublished claims, or an identifiable author's
thesis content. Examples are synthetic. A `vendored` class or a `generated` profile from
an author is contributed here only with the author's explicit consent, and even
then only the class or profile machinery — not their writing. A profile a
maintainer seeds from a public guide involves no author and no consent step; it
holds facts about the guide only, and its registry `notes` say it was seeded.

## Consumers (don't break these)

- `dissertation-ai` onboarding: the interview's thesis-class question
  (`citationAndClass` → `classFile`) builds its options from `registry.json`:
  one per key of `modes`, and the `shipped` option names the institutions of
  the `available` shipped profiles (`profiles`, `mode: shipped`). The hub reads a **byte-identical copy**
  (`apps/hub/src/lib/thesis-classes/registry.json`; it builds on Vercel from its
  own repo). After changing `registry.json`, run
  `pnpm --filter @dataimago/dissertation-hub registry:sync` in `dissertation-ai`
  against your branch and open a PR there, then append a row naming that PR to
  `docs/registry-sync-log.md` (`tools/check_sync_log.py` in CI). The hub PR's
  `registry:check` compares with this repository's `main`, so it stays red until
  this PR merges; re-run it then. Adding,
  renaming or changing the meaning of a mode also needs the interview's words for it in
  `dissertation.yaml`, or the hub's contract test fails.
- Level-3 generated apps' `build-thesis.yml` fetches the selected class: for
  `shipped`, the class bundle (`classes/dataimago-thesis/`) **and** the profile's
  `.cfg` (`profiles/`).
- The Level-3 author harness uses `docs/discovery-contract.md` to use a shipped profile, adapt the house profile, or vendor a class.
