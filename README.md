# dissertation-thesis-classes

A registry of **thesis/dissertation output-format templates** (LaTeX document
classes and their companions) for the **dissertation vertical** of the dataimago
ecosystem.

A dissertation's terminal deliverable is an institution-formatted PDF. This repo
is the shared home for the institutional `.cls` files (and macros/examples) that
produce it, so that a dissertation author's AI can:

1. **Discover** whether a class already exists for their institution,
2. **Use** it as-is (the common case), or
3. **Modify / generate** an acceptable one when none exists — and contribute it
   back.

This realizes the **3-mode `thesis.cls` strategy** (`shipped` / `vendored` /
`generated`) recorded in the dissertation hub wiki and the dataimago framework
wiki: this registry is the `shipped` source, and the canonical place a `vendored`
or `generated` class is normalized and (optionally) shared.

## Where it sits

```
~/GitHub/dataimago/dissertation/
├─ dissertation-ai            Level-2 onboarding hub (consumes this registry)
├─ dissertation-rpkg          LEGACY
├─ dissertation-thesis-classes  ◀── this repo
└─ dissertation-wiki? (no — hub wiki is dissertation-ai/wiki)
```

It is a **dissertation-level** asset (sibling of `dissertation-ai`). Other
verticals (e.g. SGPc) do not use thesis classes today; if thesis output ever
becomes cross-vertical, this can be promoted to an ecosystem-level repo without
changing the contract.

## Structure

```
registry.json                     machine-readable index of available classes
docs/discovery-contract.md        how an L3 build + the author's AI find/select/modify a class
classes/<institution-id>/
  ├─ thesis.cls                   the document class
  ├─ macros.tex                   companion macros (if any)
  ├─ README.md                    institution notes, version, source, engine
  └─ example/                     a buildable, synthetic sample document
```

## Consumers

- **`dissertation-ai` onboarding** — the interview's thesis-class question
  ("How should we format the dissertation PDF?") builds its options from
  `registry.json`: a ready-made class for the author's institution
  (`shipped`, naming the institutions listed here), their institution's own
  `.cls` (`vendored`), or a custom layout from written guidelines
  (`generated`). The hub reads a byte-identical copy; see `CLAUDE.md` for
  keeping it in step.
- **Level-3 generated apps** — the per-user dissertation repo's PDF build
  (`build-thesis.yml`, Quarto + XeLaTeX) pulls the selected class from here.
- **The author's AI (the Level-3 author harness)** — consults the discovery
  contract to use, adapt, or draft a class within the author's own repo.

## Privacy

This registry ships **only** document classes, macros, and **synthetic** example
documents. **Never commit a real author's manuscript prose** here. (The included
`cu-boulder/example/` is the class's own upstream demonstration document — "a fake
thesis document" — not anyone's dissertation.)

## Contributing a class

Add `classes/<institution-id>/` with the `.cls` (+ macros + a synthetic
`example/`), add a `README.md`, and append an entry to `registry.json`. See
`docs/discovery-contract.md`.

## Licensing

- **dataimago's own files** (this README, `CLAUDE.md`, `registry.json`,
  `docs/`, and each class directory's `README.md`) are MIT-licensed; see
  [`LICENSE`](LICENSE).
- **Classes contributed to the registry** from now on are licensed under the
  [LaTeX Project Public License 1.3c](https://www.latex-project.org/lppl/lppl-1-3c/)
  unless the class's own `README.md` says otherwise.
- **Third-party classes** keep their own terms. The repository license does
  not cover them, and dataimago does not relicense them. Each class's
  `README.md` records where it came from and what terms, if any, it carries
  (e.g. [`classes/cu-boulder/`](classes/cu-boulder/README.md)).
