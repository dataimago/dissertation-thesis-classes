# CU Boulder — `thesis` class

The University of Colorado Boulder Graduate School dissertation/thesis LaTeX class.

| Field | Value |
|-------|-------|
| `id` | `cu-boulder` |
| Institution | University of Colorado Boulder (Graduate School) |
| `documentclass` | `thesis` (options: `defaultstyle, 11pt`) |
| Engine | XeLaTeX (this third-party class only; the house class builds under LuaLaTeX, with XeLaTeX as fallback) — also builds under pdfLaTeX |
| Version | 1.14 (Ken Anderson, 2020-08) |
| Lineage | John P. Weiss (1997) → hyperref-compatible (Hongcheng Ni, 2014) → signature page removed, committee on title page (Anderson, 2020) |
| Conforms to | CU Boulder Graduate School Specifications (April 2010) |
| Status | `legacy`: an unlicensed feature reference for the house class, never offered to authors. CU Boulder's `shipped` option is the house class `dataimago-thesis` with `profiles/cu-boulder.yaml`. |

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

## Provenance and license

`thesis.cls` is a third-party file, not dataimago's work. Its header credits
John P. Weiss (v1.00, 1997), Bruce Fast (1998–2008), Steven V. Penton (1999),
E. Joshua Rigler (2003), Hongcheng Ni (2014) and Ken Anderson (v1.14, 2020).
It is redistributed here as CU Boulder publishes it, from the CU OIT TeX/LaTeX
page its header points to
([colorado.edu/oit/software-hardware/tex-latex](https://www.colorado.edu/oit/software-hardware/tex-latex),
which now redirects to the OIT software catalog). It carries no explicit
license. The repository's `LICENSE` does not cover it, and dataimago does not
relicense it.

`macros.tex` and `example/` come from the same upstream distribution, except
`example/appendixA.tex` and `example/appendixB.tex`: their filler text was
replaced in 2026 with text written for this repository.
