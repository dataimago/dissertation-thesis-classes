# Bugbot review rules - dissertation-thesis-classes (thesis-class registry)

Review the PR diff for changed-code correctness, contract drift, licensing and
privacy violations. This repo is a public registry of thesis/dissertation LaTeX
classes and institution profiles, consumed by the dissertation-ai onboarding
hub, Level-3 PDF builds, and the author's AI. Report concrete, actionable
defects; do not turn style preferences or speculative redesigns into findings.

## P1 - privacy invariant

- No real manuscript prose, unpublished claims, real student or committee data,
  or identifiable author content anywhere: examples are **synthetic only**.
  Never quote suspected real prose in a finding; name the file and say why.
- A `vendored` or `generated` class is contributed only with the author's
  explicit consent, and only the class machinery, never their writing.
- Report credentials or keys without quoting the value.

## P1 - licensing

- The house class `dataimago-thesis.cls` is **new LPPL 1.3c code**. NO code may
  be copied or closely paraphrased from `classes/cu-boulder/thesis.cls`, which
  states no license. Describing its behavior is fine; copying its code is not.
- dataimago's own files (README, CLAUDE.md, `registry.json`, `docs/`, profiles,
  per-class READMEs) are MIT. Third-party files keep their own terms and must
  say where they came from in the class `README.md`; never relicense them.
- New classes need a license statement in their `README.md` and file headers.

## P1 - contract

- `registry.json`, `docs/discovery-contract.md`, and the house-class spec
  (`docs/house-class-spec.md`) move together. A change to one that makes the
  others false is a finding.
- A breaking registry change (renamed or removed field, changed meaning of
  `mode`/`status`, removed mode) needs a `schemaVersion` bump.
- dissertation-ai vendors a **byte-identical copy** of `registry.json` and
  fails its `registry:check` on drift. Any `registry.json` change needs a
  matching dissertation-ai PR (`registry:sync`); flag a PR that does not
  mention one. Adding or renaming a mode also needs the hub interview's words.
- Every `available` class keeps a buildable synthetic `example/` and records
  `engine`, `documentclass`, and `classOptions`.

## P2 - institution profiles (per the spec)

- Every value that differs from the house value cites the guide's page or
  section in `sources`, or is marked `inferred`.
- Fields the guide does not state are listed under `unstated`, not guessed.
- The YAML profile and its generated `.cfg` stay in step (no hand-edited `.cfg`).
- Profiles validate against the JSON Schema.

## P2 - class code

- Builds under both LuaLaTeX and XeLaTeX (the dataimago chain uses xelatex).
- One-argument `\author{Full Name}` as Quarto emits it.
- Defines no environments Quarto also defines (for example `theorem`); does not
  redefine `\newtheorem`, `\em`, or kernel internals.
- The math font has an OpenType MATH table (check with `pdffonts`); a silent
  fallback to another math font is a defect.
- No Quarto metadata keys are silently ignored: unsupported ones warn or error.

## P2 - docs

- README, CLAUDE.md, the discovery contract and the spec agree with the code
  and with each other (modes, fields, engine, licensing, consumers).
- No iteration-status ledgers or new `*handoff*.md` files in manuals.

## Alignment concern format

When a changed line conflicts with an explicit commitment, title the finding
`Alignment concern: <dimension_slug>` with `Dimension:` one of
`foundation_traceability`, `emancipatory_usefulness`, `ai_in_culture_fit`,
`democratic_revisability`, `dignity_accessibility_equity`, or
`anti_domination_human_capability`, plus `Location:`, `Contract/evidence:`,
`Impact:`, and `Corrective action:` lines. PR-level feedback only, never a
score or release decision.

## Boundaries

- Review the PR diff. Read unchanged code only when narrowly necessary to
  verify a contract used by a changed line. Never read `.env*` or keys.
- This repo does not own the hub (dissertation-ai) or the Level-3 templates
  (dissertation-rpkg-template and the app template). Point to those repos
  instead of flagging their code or behavior.
- Do not approve, merge, publish, or deploy.

This file sets review instructions only. It is consumed by Bugbot (on-demand)
and the Grok fast-layer workflow (`.github/workflows/composer-review.yml`).
