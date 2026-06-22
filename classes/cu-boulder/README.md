# CU Boulder — `thesis` class

The University of Colorado Boulder Graduate School dissertation/thesis LaTeX class.

| Field | Value |
|-------|-------|
| `id` | `cu-boulder` |
| Institution | University of Colorado Boulder (Graduate School) |
| `documentclass` | `thesis` (options: `defaultstyle, 11pt`) |
| Engine | XeLaTeX (dataimago thesis chain) — also builds under pdfLaTeX |
| Version | 1.14 (Ken Anderson, 2020-08) |
| Lineage | John P. Weiss (1997) → hyperref-compatible (Hongcheng Ni, 2014) → signature page removed, committee on title page (Anderson, 2020) |
| Conforms to | CU Boulder Graduate School Specifications (April 2010) |
| Status | available (`shipped`) |

## Files

- `thesis.cls` — the document class.
- `macros.tex` — companion macros the example `\input`s.
- `example/` — the class's upstream **synthetic** demonstration document
  ("a fake thesis document", I.~B. Scriptor) — not anyone's real dissertation.
  `example/sample-output.pdf` is its rendered output.

## Title-page / front-matter macros

`\title`, `\author{first}{last}`, `\otherdegrees`, `\degree{long}{short}`,
`\dept{designation}{name}`, `\advisor{title}{name}`, `\reader`, `\readerThree`,
`\abstract`, `\dedication`, `\acknowledgements`, optional `\IRBprotocol`, and the
one-page toggles `\ToCisShort` / `\LoFisShort` / `\LoTisShort`.

## Building the example

From `example/`, make `thesis.cls` + `macros.tex` visible to the engine and build
`main.tex`, e.g.:

```bash
cd example
TEXINPUTS=..: xelatex main.tex   # run twice for ToC/refs; bibtex refs if citing
```

(Or copy `../thesis.cls` into `example/` first.) The example is the contract test:
it must build unchanged whenever the class is updated.
