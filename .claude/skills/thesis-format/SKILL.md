---
name: thesis-format
description: Maintainer use inside this registry: turn an institution's formatting guide into profiles/<id>.yaml (each value cited to the guide's page or section, inferred values marked, unstated fields listed and never guessed), validate it and build the sample book with it, as the profile half of seeding an institution (registering it in registry.json is a separate maintainer step, CONTRIBUTING.md step 6). The method is the dissertation-app-template skill of the same name; this file adds only what differs in this repository.
---

# /thesis-format (registry copy)

**One canonical copy.** The method lives in the template repository, which is
what authors get:
`https://raw.githubusercontent.com/dataimago/dissertation-app-template/main/.claude/skills/thesis-format/SKILL.md`
(`.claude/skills/thesis-format/SKILL.md` there). Fetch that file and follow its
Rules and Steps 1, 3, 4, 5 and 6. Do not keep a second copy of the method here:
two copies drift, and this repository's CI would not notice. What follows is only
what differs when you run it inside this repository.

## What differs here

- **Work in place.** The schema, `profiles/house.yaml`, the generator and the
  checks are in this checkout, so skip the template's Step 2 (the scratch clone).
  Write `profiles/<id>.yaml` directly, with `extends: house`. Install
  `jsonschema==4.23.0 pyyaml==6.0.2` (and `tools/requirements.txt` for the PDF
  checks).
- **The guide is not committed.** Read it from wherever the maintainer points you
  (a path or a URL) and cite it by page or section; never copy it into the
  repository. The template skill's "no files from raw/" lines do not apply.
- **No Step 7.** The maintainer is seeding the registry; there is no author
  consent to ask for. The privacy rules still apply (CONTRIBUTING.md,
  "Privacy"): facts about the guide only, no manuscript content, no names, and
  `inferred` values only from a sample the institution published.
- **Generate the extras CI wants.** The sample book picks its profile from an
  overlay named after it: create `classes/dataimago-thesis/example/_quarto-<id>.yml`
  containing `thesis:` and `  profile: <id>` (plus `  institution: <the profile's institution.name>`
  if the profile sets one; otherwise the book's synthetic "Example University" stays).
  Then create the test config **before** any PDF check, because T19 reads its
  exclusions: copy `profiles/house.test.yaml` to `profiles/<id>.test.yaml` (required by
  R21), keep the `math-scripts`, `footnote-markers` and `citation-markers` exclusions the
  sample book needs, remove `folios` unless the guide exempts running heads, and exempt
  nothing else the guide does not exempt. After the profile validates:

  ```sh
  cp profiles/house.test.yaml profiles/<id>.test.yaml                              # then edit as above
  texlua classes/dataimago-thesis/thesis-profile.lua profiles <id>                 # profiles/<id>.cfg
  python tools/check_profile.py <id>
  classes/dataimago-thesis/example/render.sh <id> lualatex
  python tools/check_pdf.py --pdf classes/dataimago-thesis/example/_build/<id>-lualatex/thesis.pdf \
    --profile <id> --engine lualatex --update-snapshots profiles/snapshots/<id>      # snapshots come from the LuaLaTeX PDF only
  classes/dataimago-thesis/example/render.sh <id> xelatex
  python tools/check_pdf.py --pdf classes/dataimago-thesis/example/_build/<id>-xelatex/thesis.pdf \
    --profile <id> --engine xelatex                                                  # check only; no snapshots
  ```
- **Touch only the profile's files** (spec R21): `profiles/<id>.yaml`, `.cfg`,
  `profiles/snapshots/<id>/`, `profiles/<id>.test.yaml`, and the overlay
  above (all R21).
  Never `registry.json`, `docs/discovery-contract.md` or any file under
  `classes/` other than that one overlay, from this skill. The profile is not
  offered until a maintainer registers it in `registry.json` in a separate pull
  request (CONTRIBUTING.md, maintainer step 6), followed by the dissertation-ai
  `registry:sync` pull request; say so to the maintainer when you finish.
- **Confirm with the maintainer**, who stands in for the author: show the
  checklist (inferred, unstated, cannot be expressed) and change nothing they
  have not accepted. Commit on a branch and open a pull request; the maintainer
  merges.
