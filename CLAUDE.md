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
  changed, or its `status`/`mode` changes. Consumers read it, not hard-coded paths.
- Each `classes/<id>/` holds: `thesis.cls` (+ macros), a `README.md` (institution,
  version, lineage, engine, capabilities), and an `example/` that builds to PDF
  with the class unchanged. The example must be synthetic.
- The discovery + 3-mode rules live in `docs/discovery-contract.md`. Keep code and
  docs consistent with it.
- Record the engine (`xelatex` for the dataimago thesis chain), `documentclass`
  name, and `classOptions` so a build can be reconstructed.

## Profiles from guides

A profile (`profiles/<id>.yaml`) is converted from an institution's formatting
guide with the `thesis-format` skill; `CONTRIBUTING.md` says how a contribution
arrives (a fork pull request) and how a maintainer re-pushes it to a same-repo
branch for review. The canonical copy of the skill is in
`dissertation-app-template`; `.claude/skills/thesis-format/` here points to it
and adds only what differs in this repository. Never add a profile value the
guide does not state: list the field under `unstated`.

## SECURITY — privacy invariant

Never add real manuscript prose, unpublished claims, or an identifiable author's
thesis content. Examples are synthetic. A `vendored` or `generated` class is
contributed here only with the author's explicit consent, and even then only the
class machinery — not their writing.

## Consumers (don't break these)

- `dissertation-ai` onboarding: the interview's thesis-class question
  (`citationAndClass` → `classFile`) builds its options from `registry.json`:
  one per key of `modes`, and the `shipped` option names the institutions of
  the `available` shipped classes. The hub reads a **byte-identical copy**
  (`apps/hub/src/lib/thesis-classes/registry.json`; it builds on Vercel from its
  own repo). After changing `registry.json`, run
  `pnpm --filter @dataimago/dissertation-hub registry:sync` in `dissertation-ai`
  and open a PR there; its `registry:check` fails until you do. Adding or
  renaming a mode also needs the interview's words for it in
  `dissertation.yaml`, or the hub's contract test fails.
- Level-3 generated apps' `build-thesis.yml` fetches the selected class.
- The Level-3 author harness uses `docs/discovery-contract.md` to use/adapt/draft.
