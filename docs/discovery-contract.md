# Discovery Contract — how a class is found, used, or created

This contract governs how the three consumers (the `dissertation-ai` onboarding
interview, a Level-3 generated app's PDF build, and the Level-3 author harness)
interact with this registry. It implements the **3-mode `thesis.cls` strategy** as the house class plus a
profile per institution (`docs/house-class-spec.md`, F12).

## The registry is the source of truth

`registry.json` (`schemaVersion` 2) lists what is available in two arrays.
Consumers read this file; they do not hard-code paths.

- `classes`: the LaTeX classes. Each has `id`, `path`, `companions`, `example`,
  `engine` (and `engineFallback` where one is supported), `documentclass`,
  `classOptions`, `version`, `license` and `status`. There is one current class,
  the house class `dataimago-thesis` (`status: available`). The CU Boulder class
  `cu-boulder` stays in the tree with `status: legacy`: an unlicensed feature
  reference that is never offered to authors and never fetched by a build.
- `profiles`: one per institution, plus the neutral `house` profile. Each has
  `id`, `class` (the id of a class above), `yaml`, `cfg`, `classOptions`
  (`profile=<id>`), `status` and `mode`. A profile for an institution also has
  `institution`, `graduateSchool` and `credentials`.

`status` is `available` (current and buildable: the class or profile builds its
synthetic example; a profile is offered to authors only when it is also
`mode: shipped`, so `house` is `available` with `mode: generated`), `legacy` (kept for reference, never offered), `contributed` (an author's own
class, archived here with consent and not offered) or `generated` (a profile
not yet reviewed for shipping: contributed by an author's AI with the author's
consent, or seeded by a maintainer from a public guide; its `notes` say which.
Human review promotes it to `available`).

A profile's `.yaml` holds facts about the institution's guide, each cited to a
section or marked `inferred`; the fields the guide does not state are listed
under `unstated` and keep the house value. `.cfg` is compiled from the `.yaml`
and is the only file the class reads. A consumer must not claim an institution's
guide is fully met: read the profile's `unstated` list.

## The three modes

```
            ┌─ institution has an available profile
author ─────┤  with mode "shipped" in the registry?
            └─ no
                 │
   yes → SHIPPED │  no → does the author have their institution's own .cls?
   house class +  │
   that profile   ├─ yes → VENDORED: normalize into classes/<id>/,
                  │         optionally contribute back
                  └─ no  → GENERATED: the author's AI starts from the house
                            profile and adapts it from the written guidelines,
                            validates by building the synthetic example
```

### SHIPPED (use the house class with the institution's profile)
1. Look up the institution in `profiles` (`mode: shipped`).
2. If `status: available`, resolve the profile's `class` in `classes`
   and fetch **both** halves, which live in different directories: the class
   bundle (the class's `path` and `companions`, under `classes/<class>/`) **and**
   the profile's `cfg` (under `profiles/`; fetch the `yaml` too so the author's
   AI can read what the guide states). Build with the class's `engine`, selecting
   the profile with the profile's `classOptions` (`profile=<id>`).
3. The class's `example/` is the contract test: it must build to a PDF with the
   class and the profile unchanged.

### VENDORED (use the author's own)
1. The author chooses `vendored` during onboarding (the interview's
   thesis-class question) and adds their institution's `.cls` to their
   Level-3 repo after setup.
2. The author harness normalizes it (records `engine`, `documentclass`,
   `classOptions`, required macros) and, with consent, opens a PR adding
   `classes/<institution-id>/` here (`status: contributed`). The author's path is
   unchanged by the house class: they bring their own class and it builds as it
   did.
3. Until contributed, it lives only in the author's repo, never copied here
   without consent.
4. A contributed class is an archive entry: the hub does not offer it, and it
   has no profile (`profile=` and `.cfg` belong to the house class). The next
   author at that institution is offered `shipped` only once a profile for the
   institution is added to `profiles` (adapted from its guide, as in GENERATED);
   until then they use `generated`, or bring the class themselves.

### GENERATED (adapt the house profile)
1. When no profile exists and the author supplies **written formatting
   guidelines** (the interview's `generated` option), the author harness copies
   the `house` profile (`profiles/house.yaml`) and adapts it to the guidelines,
   citing each value to its section or marking it `inferred`, and listing what
   the guidelines do not state under `unstated`. It does not write a class.
2. It validates by compiling the synthetic `example/` with the new profile (never
   the author's prose).
3. The result may be contributed back, with consent, as a new
   `profiles/<id>.yaml` (+ compiled `.cfg`) in a profile PR (spec R21, which
   leaves `registry.json` alone). After it merges, a maintainer adds a `profiles`
   entry with `status: generated` and `mode: generated` in a separate pull
   request (`CONTRIBUTING.md`, maintainer step 6). The hub does not offer it. Human
   review promotes it to `status: available`, `mode: shipped`, which is the
   point at which it becomes `shipped` for that institution.

### `shipped` is never the framework default

`shipped` always names a profile listed in this registry for the author's
institution (`vertical.dissertation.institution` in their spec). The `house`
profile is not `shipped`: it is the starting draft that `generated` adapts until
the author's guidelines arrive, and the onboarding interview's default answer is
`generated` for that reason. A profile with `id: house` is never a shipped option. (Reconciled 2026-11-07; the interview had offered `shipped` as "the
framework's default layout".)

## What a consumer may rely on

- Every `available` class has a buildable, **synthetic** `example/`.
- `engine` names the LaTeX engine: `lualatex` for the house class (tagged PDF),
  with `engineFallback: xelatex` (supported, untagged); the legacy CU class is
  `xelatex`.
- Class capability is discoverable from the `notes`/example, not assumed.
- `schemaVersion` 2 replaced version 1, whose `classes` entries each carried an
  `institution` and a `mode`. Those now sit on `profiles`; a consumer reads
  `profiles` to find what an institution is offered.

## Readers of the live registry

Some consumers fetch `main/registry.json` live rather than from a vendored copy.
Repos already generated from `dissertation-app-template` carry a thesis-build
skill (`.claude/skills/thesis-build/SKILL.md`, step 2) that looks for a `classes`
entry whose `institution` is the author's and whose `status` is `available`.
`schemaVersion` 2 carries no `institution` on any `classes` entry, so that
version-1 reader finds no match for any institution and takes its documented
"no ready-made class" path: it tells the author the registry has none yet and
offers `generated`. That is graceful (no crash, and it can never select the
`legacy` CU class, which is neither `available` nor named by an institution), but
it is a behaviour change for CU authors until the templates read `profiles`
(`wi-20261108-house-class-templates`). A new reader must check
`schemaVersion` and read `profiles`, not `classes`, to find an institution.

## Privacy invariant

No real manuscript prose enters this repo. Examples are synthetic. The author's
unpublished work stays in the author's own (Level-3) repo. This mirrors the
data-sovereignty rule in the Level-3 author harness.

## Related

- `dissertation-ai/wiki/decisions/001-irtc-l3-and-thesis-output-template.md`
- The 3-mode `thesis.cls` strategy + two-template provisioning topology in the
  dataimago framework wiki (`dataimago-design/wiki`).
