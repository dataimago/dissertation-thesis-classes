# Contributing to dissertation-thesis-classes

This registry holds the house thesis class (`classes/dataimago-thesis/`) with one
small **profile** per institution (`profiles/<id>.yaml`), and the legacy
third-party class `classes/cu-boulder/` (`status: legacy`, never offered). What
the hub and Level-3 builds offer is read from `registry.json`: today the only
`mode: shipped` profile is `cu-boulder` (the house class with
`profiles/cu-boulder.yaml`). A profile file is not offered until it has a
`profiles` entry there; a profile PR leaves `registry.json` alone, and a
maintainer adds the entry afterwards (step 6 of the maintainer section). Profiles are what the
house class is built to take, and they are the contribution that scales. The most useful one
is a profile for an institution that has none: a list of facts from the
institution's formatting guide, each cited to the guide's page or section. The
format is section 6 of [`docs/house-class-spec.md`](docs/house-class-spec.md).

## Privacy: what a contribution may contain

A profile holds **facts about a guide only**. It must not contain:

- any part of a manuscript: titles, abstracts, chapter names, or quotes from the
  author's writing;
- the names of real people, including the contributor, or email addresses;
- a value taken from the contributor's own thesis or drafts. A value read from
  a sample is marked `inferred` and the sample must be one the institution
  published (a template or sample document);
- a quote from the guide longer than one short line (guides are the school's
  copyright; facts and short citations are fine).

A contribution is made with the contributor's explicit consent. Profiles are MIT
licensed (see `README.md`) and public once merged.

## How to contribute a profile

The easy way is the `thesis-format` skill. Authors get it in their dissertation
repository (from `dissertation-app-template`), where it reads the guide, fills
the profile, validates it, builds the sample book with it, and gives the author a
checklist to confirm against the guide. It then asks, once, whether the author
wants to contribute the result. By hand, the same rules apply:

1. Read the guide. Write `profiles/<id>.yaml` (`id` is lowercase letters, digits
   and hyphens) from `profiles/house.yaml`, with `extends: house`. Set only what
   the guide states.
2. **Cite every value that differs from the house value** in `sources`, keyed by
   the dotted field path, with the guide's page or section. Mark a value read from
   a sample `{inferred: true, from: "...", note: "..."}`.
3. **List what the guide does not state** under `unstated`, and leave those fields
   out so the house value applies. Do not guess, and do not copy values from
   another institution's profile.
4. Fill `guide:` (`title`, `retrieved`, and `issuer`, `version`, `date`, `url` if
   known). `retrieved` is the ISO date (YYYY-MM-DD) you read the guide; a
   profile pull request must carry one. The schema also accepts
   `retrieved: unretrieved`, but only for a local draft or a negative test, never
   in a contribution: read the guide first.
5. Validate and build (see the class README for the full commands). The sample
   book picks its profile from an overlay named after it, so a new profile needs
   `classes/dataimago-thesis/example/_quarto-<id>.yml` containing
   `thesis:` and `  profile: <id>`, plus `  institution: <the profile's institution.name>`
   if the profile sets one (an institution's name, never a person's). Create the
   test config first, since T19 reads its exclusions (see step 6 for what to keep):

   ```sh
   cp profiles/house.test.yaml profiles/<id>.test.yaml                    # then edit; see step 6
   texlua classes/dataimago-thesis/thesis-profile.lua profiles <id>       # writes profiles/<id>.cfg
   python tools/check_profile.py <id>                                     # schema, sources, drift
   classes/dataimago-thesis/example/render.sh <id> lualatex               # and xelatex
   ```

6. Open a pull request that changes only the profile's files (spec R21):
   `profiles/<id>.yaml`, its generated `profiles/<id>.cfg`, the first-page
   snapshots `profiles/snapshots/<id>/`, the test config `profiles/<id>.test.yaml`
   (required: copy `profiles/house.test.yaml`, keep its `math-scripts`,
   `footnote-markers` and `citation-markers` exclusions, and keep `folios` only if
   the guide exempts running heads; without it T19 fails on the sample book),
   and the example overlay `classes/dataimago-thesis/example/_quarto-<id>.yml`
   from step 5. `render.sh` sets only `QUARTO_PROFILE`, so without the overlay
   the example keeps `thesis.profile: house` and the new id would be checked
   against the house book.
   The snapshots need a full TeX Live (`python tools/check_pdf.py ... --update-snapshots`).
   If you cannot produce them, send the YAML, the `.cfg` and the overlay (never leave the
   overlay out): the snapshot check (T11) fails until the maintainer adds the
   snapshots in the re-push below, and that failure is not a defect in your profile. Do not edit `registry.json`
   (a maintainer registers the profile after it merges), `docs/`, the rest of
   `classes/`, or another institution's profile.
7. Say in the pull request body that you contribute the profile with your
   consent, name the guide (title, issuer, version, date), and list the
   `inferred` and `unstated` fields.

Contributors cannot push to this repository, so a profile arrives as a **pull
request from a fork**.

## Maintainers: reviewing a contribution (fork pull requests)

GitHub withholds secrets from workflows that run for fork pull requests, on
purpose, so the Grok review (`composer-review.yml`) does not run on them. Those
are exactly the pull requests that carry outside text. A maintainer, or the maintainer's agent, re-pushes the
contribution:

1. **Check consent.** The fork pull request body (or the thread) says the author
   contributes the profile; if it does not, ask before doing anything else.
2. **Check privacy**, reading the diff (it should be the profile's files only: `profiles/<id>.yaml`,
   `.cfg`, the overlay `classes/dataimago-thesis/example/_quarto-<id>.yml`, the test config, and perhaps snapshots): no manuscript content, no names or emails, no
   `inferred` value drawn from the contributor's own work, no quote over one short line, no
   local paths. If a line fails, ask the contributor to remove it, or remove it
   in the re-push commit and say so in the pull request. Do not run anything
   from the fork: read the files, and regenerate the `.cfg` from the YAML
   yourself in the next step.
3. **Re-push to a branch in this repository**, keeping the contributor's commits and authorship. `gh pr checkout` fetches the fork's commits and switches your worktree to them, so treat the
   checkout as untrusted text and run nothing from it:

   Every gate below stops the script; run it as a whole (`sh -eu`), not line by
   line, and set the two variables first:

   ```sh
   set -eu
   ID=<id>                 # the profile id: lowercase letters, digits, hyphens
   PR=<fork-pr-number>
   printf '%s' "$ID" | LC_ALL=C grep -Eqx '[a-z0-9]+(-[a-z0-9]+)*' \
     || { echo "HARD STOP: bad profile id"; exit 1; }

   gh pr checkout "$PR" --branch "contrib/$ID"

   # Gate 1: every changed path must be an R21 file for this id.
   BAD=$(git diff --name-only origin/main...HEAD \
     | grep -v -E "^(profiles/$ID\.(yaml|cfg|test\.yaml)|profiles/snapshots/$ID/.+|classes/dataimago-thesis/example/_quarto-$ID\.yml)\$" || true)
   if [ -n "$BAD" ]; then echo "HARD STOP: paths outside R21:"; echo "$BAD"; exit 1; fi

   # Gate 2: regenerate the .cfg with main's generator, never the fork's. The copy
   # must keep the name thesis-profile.lua: the script only runs when arg[0] ends in it.
   GEN="$(mktemp -d)"
   git show origin/main:classes/dataimago-thesis/thesis-profile.lua > "$GEN/thesis-profile.lua"
   rm -f "profiles/$ID.cfg"
   texlua "$GEN/thesis-profile.lua" profiles "$ID"
   test -s "profiles/$ID.cfg" || { echo "HARD STOP: no .cfg written"; exit 1; }

   # Gate 3: what is pushed is main's output, committed, not the fork's file.
   if [ -n "$(git status --porcelain -- "profiles/$ID.cfg")" ]; then
     git add "profiles/$ID.cfg"
     git commit -m "profiles: regenerate $ID.cfg with main's generator"
   fi
   test -z "$(git status --porcelain)" || { echo "HARD STOP: uncommitted changes"; exit 1; }

   git push -u origin "contrib/$ID"
   ```

4. **Open a same-repository pull request** from `contrib/<id>` to `main` whose
   body credits the author ("Contributed by @<username> in #<fork-pr>, with
   their consent") and keeps the contributor's commits (so the author line stays
   theirs). Add a `Co-authored-by` trailer if you squash. Check that the overlay `_quarto-<id>.yml` is present (add it first if not), then add the snapshots and test
   config as a maintainer commit if the author could not (`python tools/check_pdf.py ... --update-snapshots`).
   This pull request gets the normal Grok review and the `House class` CI.
5. **Close the fork pull request** with a comment linking to the new one and
   thanking the author. The new pull request is where review continues.
6. **Register the profile** once the profile pull request has merged, in a
   separate maintainer pull request: append a `profiles` entry to
   `registry.json` with the same fields as the `cu-boulder` entry: `id`,
   `institution`, `graduateSchool`, `credentials` (e.g. `["PhD dissertation",
   "Master's thesis"]`), `class: dataimago-thesis`, `yaml: profiles/<id>.yaml`,
   `cfg: profiles/<id>.cfg`, `classOptions: ["profile=<id>"]`, `guide` and
   `notes`, with `status: generated` and `mode: generated`, and leave
   `schemaVersion` at 2. Say in `notes` whether the profile was contributed by an
   author (with consent) or seeded by a maintainer from a public guide. The hub does not offer it yet. Human review
   promotes it to `status: available`, `mode: shipped` (see
   [`docs/discovery-contract.md`](docs/discovery-contract.md), GENERATED). After
   any change to `registry.json`, open the matching dissertation-ai pull request
   (`registry:sync`, see `CLAUDE.md`); until it merges, the hub and its drift
   check still see the old copy.

If the contributor withdraws, or consent is unclear, close without re-pushing.

A label-triggered review of the fork pull request itself (a workflow on `main`
that never executes the fork's code, with a read-only reviewer) is planned. The
re-push stays the route until it ships, and this section is updated then.

## Adding a class

A class that is not a profile (rare now; the house class is meant to cover
institutions) follows the steps in `README.md` ("Contributing a class") and
`docs/discovery-contract.md`.
