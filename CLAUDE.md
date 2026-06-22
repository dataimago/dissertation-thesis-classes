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

## SECURITY — privacy invariant

Never add real manuscript prose, unpublished claims, or an identifiable author's
thesis content. Examples are synthetic. A `vendored` or `generated` class is
contributed here only with the author's explicit consent, and even then only the
class machinery — not their writing.

## Consumers (don't break these)

- `dissertation-ai` onboarding interview Q15 (mode selection) reads `registry.json`.
- Level-3 generated apps' `build-thesis.yml` fetches the selected class.
- The Level-3 author harness uses `docs/discovery-contract.md` to use/adapt/draft.
