# Discovery Contract — how a class is found, used, or created

This contract governs how the three consumers (the `dissertation-ai` onboarding
interview, a Level-3 generated app's PDF build, and the Level-3 author harness)
interact with this registry. It implements the **3-mode `thesis.cls` strategy**.

## The registry is the source of truth

`registry.json` lists every available class with: `id`, `institution`, `path`,
`companions`, `example`, `engine`, `documentclass`, `classOptions`, `version`,
`status`, and `mode`. Consumers read this file; they do not hard-code class paths.

## The three modes

```
            ┌─ institution in registry?
author ─────┤
            └─ no
                 │
   yes → SHIPPED │  no → does the author have their institution's .cls?
   use classes/<id>/      │
   thesis.cls as-is       ├─ yes → VENDORED: normalize into classes/<id>/,
                          │         set mode "vendored", optionally contribute back
                          └─ no  → GENERATED: the author's AI drafts a .cls from
                                    written guidelines, validates by building the
                                    synthetic example, sets mode "generated"
```

### SHIPPED (use)
1. Look up the institution in `registry.json`.
2. If `status: available`, fetch `path` (+ `companions`) and build with `engine`.
3. The `example/` directory is the contract test: it must build to a PDF with the
   class unchanged.

### VENDORED (use the author's own)
1. The author uploads their institution's `.cls` during onboarding (interview Q15
   `vendored`), or drops it into their Level-3 repo.
2. The author harness normalizes it (records `engine`, `documentclass`,
   `classOptions`, required macros) and, with consent, opens a PR adding
   `classes/<institution-id>/` here so the next author at that institution gets
   `shipped`.
3. Until contributed, it lives only in the author's repo — never copied here
   without consent.

### GENERATED (draft a new one)
1. When no class exists and the author supplies **written formatting guidelines**
   (interview Q15 `generated`), the author harness drafts a `.cls`.
2. It validates by compiling a synthetic `example/` (never the author's prose).
3. The result may be contributed back as a new `classes/<id>/` (status:
   `generated`, flagged for human review before promotion to `available`).

## What a consumer may rely on

- Every `available` class has a buildable, **synthetic** `example/`.
- `engine` names the LaTeX engine (`xelatex` for the dataimago thesis chain).
- Class capability is discoverable from the `notes`/example, not assumed.

## Privacy invariant

No real manuscript prose enters this repo. Examples are synthetic. The author's
unpublished work stays in the author's own (Level-3) repo. This mirrors the
data-sovereignty rule in the Level-3 author harness.

## Related

- `dissertation-ai/wiki/decisions/001-irtc-l3-and-thesis-output-template.md`
- The 3-mode `thesis.cls` strategy + two-template provisioning topology in the
  dataimago framework wiki (`dataimago-design/wiki`).
