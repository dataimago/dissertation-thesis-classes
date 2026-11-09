# dataimago-thesis: the house thesis class

One well-built LaTeX class plus a small, checkable **profile** per institution. Converting a
school's formatting guide means filling in a profile (`../../profiles/<id>.yaml`), not writing a
class. The contract is [`docs/house-class-spec.md`](../../docs/house-class-spec.md); this page says
what the build does, how to run it and where it departs from or leaves open the spec.

**Status.** Built (house class step 2) and registered (step 3): `registry.json` lists the class
as `available` and each institution's profile selects its rules. The hub offers it through the
`shipped` and `generated` modes once its matching dissertation-ai PR merges.

| | |
|---|---|
| Class | `dataimago-thesis.cls`, LPPL 1.3c |
| Companions (LPPL 1.3c) | `thesis-profile.lua` (YAML to `.cfg` generator), `thesis-divs.lua` (Quarto filter), Quarto partials `doc-class.tex`, `title.tex`, `before-body.tex`, `toc.tex` and the emptied `fonts.latex`, `font-settings.latex` |
| Profiles, schema, checks, docs (MIT) | `../../profiles/`, `../../tools/`, this README |
| Engines | LuaLaTeX (house default, tagged PDF, PDF/UA-2) and XeLaTeX (supported, untagged) |
| Fonts | TeX Gyre (Termes, Heros, Cursor, Termes Math) from TeX Live; never committed |
| Feature reference | the CU Boulder thesis class v1.14 (John P. Weiss 1997, Bruce Fast, Steven V. Penton, E. Joshua Rigler, Hongcheng Ni, Ken Anderson): feature reference only, no code derived |

## Use in a Quarto book

`example/` is a complete synthetic book. Its `_quarto.yml` shows the whole interface: the
`thesis:` metadata namespace, `thesis.profile`, and the `format: pdf:` block that loads the
partials and the filter. Copy this directory whole (plus `../../profiles/<id>.cfg`) into the
project, or point `template-partials` and `filters` at it as the example does.

```sh
classes/dataimago-thesis/example/render.sh house lualatex        # -> example/_build/house-lualatex/thesis.pdf
classes/dataimago-thesis/example/render.sh cu-boulder xelatex
```

`render.sh` regenerates `profiles/<id>.cfg`, puts the class and the profiles on `TEXINPUTS`, and
renders. Outside Quarto the class also works from plain LaTeX with `\documentclass[profile=house]{dataimago-thesis}`
and the `\thesis...` setters of `title.tex`.

Prose pages are markdown: the abstract is the Pandoc `abstract:` field in `index.qmd`;
dedication, acknowledgments, preface, abbreviations and symbols are `::: {.dedication}`-style divs
(the example keeps them in `chapters/00-front.qmd`). For PDF the filter lifts them into metadata
and drops the emptied host chapter; HTML is untouched.

## Profiles

`profiles/<id>.yaml` holds facts about a guide. `thesis-profile.lua` merges the house defaults in
and compiles `profiles/<id>.cfg`, the only file the class reads (never hand-edit it; CI regenerates
and diffs it). YAML is a strict subset (block and flow maps and lists, plain and quoted scalars).
Quote values YAML 1.1 would turn into booleans or numbers: `tagged: "on"`, `pdfa: "4"`.

```sh
texlua classes/dataimago-thesis/thesis-profile.lua profiles house       # or: quarto pandoc lua ...
python tools/check_profile.py                                           # schema, sources, drift, T19a
```

## What the build checks (CI: `.github/workflows/house-class.yml`)

`tools/check_profile.py` (T1, T19a, R14a) and `tools/check_pdf.py` (T3 to T13, T15, T19b, T11),
per profile and engine; `tools/negative_tests.sh` (T16 broken math font, T17 unsupported keys).
Tolerances live in `profiles/<id>.test.yaml`; first-page snapshots in `profiles/snapshots/<id>/`
(update deliberately with `check_pdf.py --update-snapshots`). T14 runs veraPDF 1.30.1 in CI (installed by `tools/install-verapdf.sh`, pinned and checksummed): PDF/A-4f and PDF/UA-2 pass for both profiles on LuaLaTeX; locally it runs when `verapdf` is on the path.

## Behavior worth knowing

* The PDF standard is built from `submission.pdfa` and `accessibility.pdfua`. PDF/A-2b cannot
  be combined with tagging and PDF/UA-2 (tagging forces PDF 2.0), so the house default is `4f`
  (decision 2, recorded in `profiles/house.yaml`). A school that wants `2b` gets PDF 1.7 and, when
  tagged, `ua-1`.
* The class owns geometry, fonts, spacing, headings, the contents and lists, page numbers
  (drawn at an exact distance from the page edge) and the front matter. Quarto keys it replaces
  (`geometry`, `mainfont`, `fontsize`, `toc`, `colorlinks`, ...) are reported as warnings.
* Lists with `mode: auto` appear from the second pass on; `latexmk` (Quarto's default) reruns.
* `mode: auto` for the lists comes from the filter, which knows which floats have captions (Quarto's table and figure floats); an uncaptioned markdown table does not create a List of Tables (`tools/negative_tests.sh lot`). Outside Quarto the class falls back to noting `\caption` calls on the previous pass.
* Chapter headings are tagged (H1; sections H2, ...) on LaTeX 2026-11 and later by calling the kernel's heading sockets from the profile-driven chapter head; `check_pdf.py` T15 fails if chapter titles are missing from the structure tree or heading levels jump.
* Known gaps are listed in the pull request that introduced the class ("Spec questions").
