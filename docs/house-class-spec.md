# The house thesis class: requirements spec and institution-profile format

| | |
|---|---|
| Status | **Accepted 2026-11-08.** The maintainer took every recommendation in section 9. |
| Class name | `dataimago-thesis.cls` (LPPL 1.3c, new code) |
| Profiles | `profiles/<id>.yaml` (MIT), one per institution |
| Date | 2026-11-08 |
| Revision | 2026-11-09 (rev. 3): the three CU schema gaps (R22, S8) are implemented and the CU profile uses them; four corrections to rev. 2 (see "Changes in revision 2"). Rev. 2 answered the 19 spec questions of the build PR (#5) |

**Idea.** Few institutions publish a LaTeX class; authors bring a formatting guide.
So the registry's unit is ONE well-built class plus a small, checkable PROFILE per
institution. Converting a guide means filling in a profile, not writing a class.

**Status of this contract.** The registry step (`wi-20261108-house-class-registry`)
has landed: `registry.json` is `schemaVersion` 2 and `docs/discovery-contract.md` is
rewritten to match. The new mode meanings in F12, the `profiles/` directory, the house
class entry, the `engineFallback` field and the LuaLaTeX default are in force. The
hub's interview words for the modes (`dissertation.yaml`, the `classFile` question)
move in a matching dissertation-ai PR, since `registry:sync` copies only
`registry.json`.

**Reading rules.** MUST / SHOULD / MAY carry their RFC 2119 meaning. Each requirement
has a one-line reason. Items marked **[inferred]** were not stated by a source and
need a human check. Items marked **[verify]** are claims about tool behavior that the
build step must confirm against the pinned versions before relying on them.

**Changes in revision 2 (2026-11-09).** The build (`wi-20261108-house-class-build`, PR #5)
met clauses that were ambiguous or could not be met as written, chose the least surprising
reading, and listed 19 cases as spec questions (`wi-20261108-profile-spec-questions`). This
revision folds the answers into the clauses they concern, so the spec says what the class
does; where the build and an older clause disagreed, the clause now follows the build. The
places changed: 2.2 and R5a (`thesis.institution`), R9b (Quarto book structure), 2.4 (partial
headers, sub-partials) and R10 (keys the filter reads), R12 and 2.5 (where the files live), 3.5
to 3.11 and R17, R22 (what the class does not implement or enforce; heading text), S4, S8, A8,
6.1, P4a (quoted YAML values), 6.4 (notes, new fields, house `pdfa: 4f`, `pdfua: auto`), 6.5,
7.1, T5, T11, T14 and section 8 (headers and licences). Three fields were **specified here and implemented in the
follow-up PR** (revision 3, 2026-11-09): `submission.links: underline`, `frontmatter.toc.heading` and
`frontmatter.lists.<list>.heading` for the contents and the lists, and `abstract.heading`,
`abstract.align` and `abstract.headerWeight` (6.4, marked **[implemented]**). Revision 3 also
corrects four statements of revision 2: the 2.4 partials row (geometry is not a partial), the
`\typeout` claim (only `doc-class.tex` has one), R5a (the example overlay sets
`thesis.institution`) and S4 (its pointer for the `4f` default), and S8 now says the underline
is a link-annotation border, not text underlining. The CU "sans serif" sentence (question 16) is not a spec question;
the maintainer decided it on 2026-11-10: the CU profile keeps the house serif, reading the sentence by its own Times
New Roman example (recorded on `type.main` in `profiles/cu-boulder.yaml`, which now also cites the Digital
Accessibility Office's Thesis Accessibility Guidance and ProQuest's manuscript guide).

**Contents:** 1 Inventory · 2 Quarto integration · 3 What a profile covers ·
4 Submission · 5 Accessibility and engine · 6 Profile format · 7 Testing ·
8 Licensing · 9 Decisions · 10 Sources

---

## 1. Inventory of existing features

Sources read: CU Boulder `thesis.cls` v1.14 (`classes/cu-boulder/`), its `macros.tex`
and `example/main.tex`; the framework default `thesis.cls` v0.1.0, `dataimago.sty`,
`_quarto.yml`, `THESIS-CLS-README.md`, `build-thesis.yml` (all
`dissertation-rpkg-template/ui/www/` and `.github/`). CU code is described, never copied.

Decision vocabulary: **keep** (same behavior), **rename** (same idea, new name or
channel), **drop** (not carried over).

### 1.1 CU Boulder class (v1.14)

| # | Feature / command (CU) | What it does | Decision | House form | Why |
|---|---|---|---|---|---|
| C1 | Base class `report`, forced `letterpaper,oneside,onecolumn` | One-sided report, chapters as top level | **rename** | Base is `\LoadClass{book}` (it has `\frontmatter`/`\mainmatter`/`\backmatter`, which Quarto books emit). `book` defaults to `twoside`, so the class MUST pass `oneside` unless `geometry.sides: two`; the default lives in `geometry.sides` (house `one`). Paper from `geometry.paper`. | Quarto books emit `\chapter`, `\appendix`, `\mainmatter`; paper size varies by country (A4). Hard-coding letter blocks non-US use. |
| C2 | Warn-and-ignore options: `titlepage`, `notitlepage`, `twoside`, `twocolumn`, `landscape`, `legalpaper`, `a4paper`, `a5paper`, `b5paper`, `executivepaper`, `letterpaper`, `onecolumn`, `oneside` | Emit class warnings | **drop** | Replace with profile-driven `geometry.paper` / `geometry.sides`; `twocolumn`, `notitlepage` stay unsupported and raise an error naming the option | Silent-ish warnings are noise; the profile is the single place paper and sides are chosen. |
| C3 | Pass-through options `fleqn leqno openbib draft final openright openany 10pt 11pt 12pt` | Forwarded to `book` | **keep** (subset) | `draft`, `final`, `fleqn`, `leqno`, `openbib` pass through to `book`. `openany`/`openright` are NOT author options: the class sends the resolved `headings.chapter.newPage` value to `book`, and an author `classoption` for either warns and is ignored (R11); type size comes from the profile (`type.size`), with `10pt/11pt/12pt` still accepted as an override | Authors expect these; `11pt` is how CU is invoked today. |
| C4 | Style presets `defaultstyle`, `modernstyle`, `typewriterstyle` | Bundles of heading/numbering flags | **drop**, flags kept individually | Express as profile fields under `headings.*` and `numbering.*` | Presets hide what each flag does; a guide is converted field by field. |
| C5 | `consecutivenumbering` | Figure/table/equation numbers continue across chapters | **rename** | `numbering.floats: per-chapter \| continuous` (figures and tables) and `numbering.equations: per-chapter \| continuous` | Guides state this; make it data. |
| C6 | `inlineh4`, `nonumh4` | Level-4 heading inline or unnumbered | **rename** | `headings.level4.style: inline \| block`; unnumbered level 4 is `numbering.depth: 2` (no separate flag) | Same. |
| C7 | `centerh1`, `chapleft` (both set the same flag, oddly) | Center or left-align section headings | **rename** | `headings.section.align`, `headings.chapter.align` (independent) | One flag for two options is a bug; separate fields. |
| C8 | `chapup` | All-caps chapter and list titles | **rename** | `headings.chapter.case: as-typed \| upper`, `frontmatter.titlesCase` | Guides state caps for chapter titles and list headings separately. |
| C9 | `emph2underline` | `\emph` underlined instead of bold | **drop**, as an option | `type.emphasis: italic \| bold`, default `italic`. Underline is not supported. | CU's default turns `\emph` into bold, which breaks Quarto `*emphasis*` expectations; italic is the house default. Underline had no mechanism that avoids redefining `\em` (C16). |
| C10 | `plainhead`, `fixedheadsize`, hidden `varheadsize` | Non-bold headings, normalsize headings, graded heading sizes | **rename** | `headings.<level>.weight`, `.size` | Per-level data. |
| C11 | `numberchapteronly`, `allheadings`, `typewriterstyle` numbering variants | Roman chapter numerals, no section numbers, numbering to level 5 | **rename** | `numbering.chapter: arabic \| roman`, `numbering.depth` (0-5) | Same. |
| C12 | `\doublespacing`, `\singlespacing`, `\setstretch`, `singlespace`, `doublespace`, `spacing{}` | Custom spacing engine that does NOT use `setspace.sty` (redefines `\@setsize`) | **drop** the engine, **keep** the environments | Use `setspace`; keep `singlespace`, `doublespace`, `spacing` env names; line stretch from `spacing.body` | Reimplementing spacing breaks packages that load `setspace` (v1.10 already patched one clash). Env names are what authors type. |
| C13 | Footnotes, floats, captions forced single-spaced via redefined `\@xfloat`, `\@footnotetext`, `\@mpfootnotetext` | Per-guide exception | **keep behavior**, new mechanism | `spacing.footnotes`, `spacing.captions`, `spacing.tables`, `spacing.blockQuotes`, `spacing.bibliography` | The exceptions vary by guide, so each is a profile field. Use package hooks, not kernel patches. |
| C14 | `quote`, `quotation`, `verse` wrapped in `singlespace` | Single-spaced block quotes | **keep** | `spacing.blockQuotes` | Common requirement. |
| C15 | `\AtBeginDocument` geometry (topmargin -0.30in, textheight 9.10in, footskip 0, page number in header box) | 1in margins, number at top | **rename** | `geometry.*` through the `geometry` package, page number position from `pagenumber.*` | Raw length surgery is unreadable; guides state margins, not `\topmargin`. |
| C16 | `\EmphReset`, `ulem` loaded with `ULforem,normalbf` | Underline for emphasis, forces `\em` redefinitions | **drop** | none | Redefining `\em` globally conflicts with Pandoc/Quarto output and `hyperref`. |
| C17 | Bibliography wrapper (single-spaced, `\ULforem`, adds a `part`-level ToC entry) | Bibliography handling | **keep** (reworked) | `spacing.bibliography`, `toc.bibliography: true`; ToC entry via `\addcontentsline`, not `part` | Quarto/Pandoc emits `natbib` or `biblatex` bibliographies; the class must not wrap `thebibliography` only. |
| C18 | Redefined `\newtheorem` that keeps theorems upright; wrapper names `th@...` | Non-italic theorems | **drop** | Load `amsthm`; theorem styles are the author's; do NOT redefine `\newtheorem` | The redefinition forces authors' own `\newtheorem` through CU's wrapper. |
| C19 | `macros.tex`: `\newtheorem{theorem}{Theorem}` plus calculus shortcuts (`\diff`, `\twovec`, `\twochoices`, ...) | Companion macros, `\input` by the example | **drop** | Not shipped. The class defines no theorem environments. Shortcuts stay in the author's own macros. | Predefining `theorem` collides with Quarto's `theorem` cross-reference environments and with `amsthm` (the known clash). Domain macros are not a class concern. |
| C20 | `\title{}` | Stores title | **keep** | Standard `\title`, fed by Quarto | |
| C21 | `\author{first}{last}` (TWO arguments) | Stores "First Last" and "Last, First" | **rename** | Standard one-argument `\author{Full Name}` (Quarto emits this); optional `thesis.author-family` / `thesis.author-given` give the inverted form for the abstract header | Quarto writes `\author{...}` with one argument; the two-argument form fails to build. Name splitting is a content matter, supplied explicitly. |
| C22 | `\degree{long}{short}` | Full degree name and "abbr, subject" | **rename** | Metadata `thesis.degree.name` ("Doctor of Philosophy"), `thesis.degree.abbreviation` ("Ph.D."), `thesis.degree.field` | Three facts in two arguments; split them. |
| C23 | `\dept{designation}{name}` | "Department of" + "Rocket Science" | **rename** | `thesis.department` (full string, "Department of Rocket Science") | The designation split exists only for CU's line breaks. |
| C24 | `\advisor{title}{name}` | Advisor with title ("Prof.") | **rename** | `thesis.advisors[]` (`{name, title, role, affiliation}`, see 2.2) | Co-chairs exist; a list is general. |
| C25 | `\reader`, `\readerThree`...`\readerSix` | Up to 5 further committee members | **rename** | `thesis.committee[]` (`{name, title, role, affiliation}`, see 2.2) | Unbounded list, not numbered macros. |
| C26 | `\otherdegrees{...}` | Prior degrees on the title page | **keep** | `thesis.previous-degrees[]`, shown if `frontmatter.titlePage.previousDegrees` is true | CU-specific but cheap. |
| C27 | `\degreeyear{}` | Year (default: current year) | **rename** | `thesis.year`; default from `date` | Explicit beats `\year`. |
| C28 | `\IRBprotocol{}` | Prints an IRB protocol line on the approval page | **keep** | `thesis.irb-protocol`, shown on the approval page when `frontmatter.approval.irbLine` is true | Real requirement at some schools. |
| C29 | `\abstract[long\|short]{}` | Abstract page with header lines (Last, First (degree) / Title / "Thesis directed by ...") | **rename** | Pandoc/Quarto `abstract:`; header block is `frontmatter.abstract.header` in the profile | Quarto's native field. |
| C30 | `\dedication[title]{}`, `\acknowledgements{}` | Optional pages | **rename** | Markdown divs `.dedication`, `.acknowledgments` (see 2.3) | Prose belongs in markdown, not in a macro argument. |
| C31 | `\ToCisShort`, `\LoFisShort`, `\LoTisShort` | Put a page number on a one-page list | **rename** | `frontmatter.lists.<list>.numberFirstPage: auto \| show \| hide`; `auto` shows the number when the list fits one page. | A human toggle for something the class can detect after pass two. Keep the three names as deprecated aliases for the CU profile only. |
| C32 | `\emptyLoF`, `\emptyLoT` | Suppress a list | **rename** | `frontmatter.lists.<list>.mode: always \| auto \| never`; `auto` omits a list with no entries | `auto` is what authors want; no macro. |
| C33 | `\SuspendPrologue` | Skip all prologue pages | **rename** | metadata `thesis.frontmatter: full \| none` (for per-chapter test builds) | Useful in CI snapshots of single chapters. |
| C34 | `\OnePageChapter`, `\forcepageno` | Force a page number on the first page of a one-page chapter | **keep** | `\forcepageno`; `\OnePageChapter` as deprecated alias | The rule is profile-driven (`pagenumber.chapterFirstPage`). |
| C35 | Chapter first page unnumbered (`thispagestyle{empty}`) | Per-guide rule | **rename** | `pagenumber.chapterFirstPage: show \| bottom-center \| hide` | Varies by guide. |
| C36 | Title page: hard-coded "A thesis submitted to the Faculty of the Graduate School of the University of Colorado in partial fulfillment ..." (lines ~1035-1036) | Fixed wording | **rename** | `frontmatter.titlePage.statement` template with `{documentType}`, `{graduateSchool}`, `{institution}`, `{degreeName}` slots | The block hard-codes the institution and says "thesis" even for dissertations. Wording is the main thing that varies by school. |
| C37 | Committee members printed on the title page (v1.14) | Replaced the signature page | **keep as profile data** | `frontmatter.committee.placement: title-page \| separate-page \| none` | Decision 3. |
| C38 | Approval/signature page (`\th@Approvalpage`), disabled in v1.14 | Signature lines, date line, boilerplate | **keep as profile data** | `frontmatter.approval.enabled`, `frontmatter.approval.statement` | Other schools still require it; the CU profile sets `enabled: false`. |
| C39 | Prologue order (title, approval, abstract, dedication, acknowledgments, ToC, LoT, LoF; roman numerals; arabic from chapter 1) | Fixed order | **rename** | `frontmatter.order[]` | Order varies by school. |
| C40 | Lists: tables before figures (since v1.08); label rows "Chapter", "Figure", "Table" above entries | List layout | **keep** | `frontmatter.order` (the CU profile puts `lot` before `lof`; the house default is `lof, lot`), `toc.columnLabels: true` | Guide-driven. |
| C41 | `\appendix` wrapper: letters; adds an "Appendix" label to the ToC | Appendix handling | **keep** | `appendices.*` (see 3.9) | |
| C42 | `index`, `part`, `twocolumn` made unavailable (warn) | Restrict features | **drop** | `part` and `index` pass through to the base class | Theses with parts and indexes exist; the profile says whether `part` is allowed (`headings.part.allowed`). |
| C43 | Float placement parameters (`topfraction .4`, `textfraction .5`, ...) | Defaults | **keep as defaults** | Class defaults, not profile fields | Reasonable house default. |
| C44 | List label and margin overrides (`(1)`, `(a)`...) | CU list style | **drop** | House uses `enumitem`; labels not institution-specific | Rarely stated in guides. |
| C45 | Status messages via `\typeout`, `\ClassError` messages naming CU commands | Developer UX | **keep idea** | Errors name the missing metadata field and the `_quarto.yml` key | Helps authors and the AI. |

### 1.2 Framework default class (`thesis.cls` v0.1.0 + `dataimago.sty`)

| # | Feature / command | What it does | Decision | House form | Why |
|---|---|---|---|---|---|
| F1 | Loads `book` with `oneside,12pt`, passes all options through | Base | **rename** | Same base (`book`) as C1; `oneside` default and size from the profile (`geometry.sides`, `type.size`) | One model for both classes. |
| F2 | `geometry` with `margin=1in` set in the class; Quarto `geometry:` key must not be set (option clash) | Margins | **keep rule** | Class is the only owner of `geometry`; document that `geometry:` in `_quarto.yml` is unsupported | Known failure (`Option clash for package geometry`). |
| F3 | `\onehalfspacing` | 1.5 spacing | **rename** | House default `spacing.body: double`; guide-overridable | Most guides say double. |
| F4 | `\thesistitle{title}{author}{institution}{program}{year}` | Title page macro with 5 positional arguments | **drop** | Title page generated from metadata | Positional macros are not Quarto-native and the name collides with nothing useful. |
| F5 | `\signaturepage{...}`, `\sigline{...}` | Signature page and line | **rename** | Generated `approval` page (its own `frontmatter.order` entry) with signature lines built from `thesis.advisors[]` and `thesis.committee[]`, when `frontmatter.approval.enabled` | Same data, no macro. |
| F6 | `abstract` environment (`\newenvironment`, centered bold heading) | Abstract | **keep** | The class defines `abstract` with `\newenvironment` (`book` has none; `\renewenvironment` fails with `Environment abstract undefined`); `\thesisfrontmatter` wraps the `\thesisabstract{...}` text (from `$abstract$`, R6) in it, once, at the `abstract` slot of `frontmatter.order`. Quarto's own abstract output is gone because `before-body.tex` is replaced (2.4) | Prior fix recorded in the `thesis-build` skill. |
| F7 | `dataimago.sty`: `fontspec`, `\parindent 0`, `\parskip 0.6em` | Sans-serif look, block paragraphs | **drop** | Not loaded. Paragraph style from `spacing.paragraph.indent` and `.skip` | Block paragraphs plus double spacing is non-standard for theses and conflicts with most guides. |
| F8 | `mainfont`/`sansfont`/`mathfont: Noto Sans (Math)` in `_quarto.yml` | Fonts set by Quarto | **rename** | Fonts come from the profile (`type.*`); the Quarto font keys are unsupported; the Lua filter warns per R10 and the font partials are emptied so Pandoc does not apply them | One owner for fonts (see 2.4). |
| F9 | `include-in-header: text: \usepackage{dataimago}` | Package load | **drop** | None; the class is loaded by `doc-class.tex` | Known failure: file injection of a `.sty` truncates `index.tex`. |
| F10 | `fig-pos: H`, `keep-tex: true`, `pdf-engine: xelatex` | Quarto knobs | **keep `fig-pos`, `keep-tex`**; engine see section 5 | | |
| F11 | `build-thesis.yml`: installs Noto from apt, replaces Noto Sans Math 2.001 with 3.000, `tlmgr install ...`, renders, commits PDF, checks `pdffonts` for LatinModernMath | CI | **keep and generalize** | Per-profile CI in this repo (section 7); the template's workflow adds the same `pdffonts` check for the profile's math font | The math-font fallback is silent. |
| F12 | `THESIS-CLS-README.md` modes (`shipped`, `vendored`, `generated`) | Author docs | **rename** | `shipped` = house class + the institution's profile; `generated` = house profile adapted from the guide; `vendored` unchanged (author's own class). Since the registry step (registry `schemaVersion` 2), CU's shipped option is `dataimago-thesis` + `profiles/cu-boulder.yaml`; `classes/cu-boulder/thesis.cls` stays in the tree with `status: legacy` (an unlicensed feature reference the hub never offers). `id: house` is the starting profile for `generated`, never a shipped option, so `shipped` is still never the framework default (discovery contract). The hub interview's mode words (the `classFile` question in `dissertation.yaml`) change in the matching dissertation-ai PR (dissertation-ai#272), not in this repo. | `wi-20261108-house-class-registry`. |

---

## 2. Quarto integration

### 2.1 Principle

R1. The author MUST be able to describe the thesis in `_quarto.yml` alone (plus markdown
files). **Reason:** that is what the Level-3 template and the AI edit; macros in
`include-in-header` were the source of every past title-page build failure.

R2. The class MUST accept the standard one-argument `\author{...}`, `\title{...}`,
`\date{...}` exactly as Quarto's template writes them. **Reason:** CU's two-argument
`\author` breaks the first `shipped` build (see `thesis-build` skill, step 6).

R3. All thesis-specific metadata MUST live under one namespace key, `thesis:`
(not at top level). **Reason:** avoids collisions with Pandoc/Quarto keys
(`author`, `date`, `abstract`, `lang`, `toc`, `documentclass`).

R4. The class MUST NOT define `\newtheorem{theorem}` or any other environment Quarto
also defines. **Reason:** the `macros.tex` clash.

### 2.2 Metadata fields and their source

Quarto passes every YAML key to the Pandoc template; a partial reads it as `$key$`
and nested keys as `$thesis.degree.name$`; lists loop with `$for(...)$`
(Quarto docs: template partials, "Replacing Partials"; Pandoc template syntax).
**[verify]** that nested custom keys under `format: pdf:` and top-level keys are both
visible to partials in the pinned Quarto version.

| Field | `_quarto.yml` key | Spec source (`dataimago-spec.yaml`) | Required | Reaches class as |
|---|---|---|---|---|
| Title | `book.title` (Pandoc `title`) | `vertical.dissertation.thesis.workingTitle` (working title; the author finalizes) | MUST | `\title{}` via `title.tex` |
| Subtitle | `book.subtitle` | `thesis.workingSubtitle` | MAY | `\thesissubtitle{}` |
| Author | `book.author` (Pandoc `author`, a name or a list with one entry) | `user.name` | MUST | `\author{}` (one argument) |
| Author, inverted | `thesis.author-family`, `thesis.author-given` | none (derived by the AI from `user.name`) | SHOULD | `\thesisauthorfamily{}`, `\thesisauthorgiven{}` |
| Date (defense/submission) | `book.date` | `timeline.defenseDate` / `submissionDate` | SHOULD | `\date{}`; profile decides whether the title page shows month+year |
| Copyright year | `thesis.year` | `institution.expectedDefenseYear` | MUST (default: year of `date`) | `\thesisyear{}` |
| Degree name | `thesis.degree.name` ("Doctor of Philosophy") | **not in spec**: derive from `institution.degreeProgram`, confirm with author | MUST | `\thesisdegree{}` |
| Degree abbreviation | `thesis.degree.abbreviation` ("Ph.D.") | `institution.degreeProgram` ("Ph.D. ...") | SHOULD | `\thesisdegreeabbr{}` |
| Field / program | `thesis.degree.field` | `institution.degreeProgram` | SHOULD | `\thesisfield{}` |
| Document type | `thesis.type`: `dissertation` \| `thesis` | **not in spec**: `dissertation` for doctoral, else `thesis` | MUST (default from degree) | `\thesisdocumenttype{}` |
| Department | `thesis.department` | `institution.department` | MUST | `\thesisdepartment{}` |
| Institution | `thesis.institution` | `institution.name` | MUST, unless the profile sets `institution.name` (then that is the default) | `\thesisinstitution{}` |
| Graduate school | `thesis.graduate-school` | **not in spec**; profile default `institution.graduateSchool` | SHOULD | `\thesisgradschool{}` |
| Advisor(s) | `thesis.advisors[]` = `{name, title, role, affiliation}` (`role: chair` or `co-chair`) | `advisors.chair.name` (title and role not in spec) | MUST | `\thesisaddadvisor{name}{title}{role}{affiliation}` per entry |
| Committee | `thesis.committee[]` = `{name, title, role, affiliation}` (`role` optional, e.g. `member`, `external`) | `advisors.committee[]` | MUST | `\thesisaddmember{name}{title}{role}{affiliation}` per entry |
| Previous degrees | `thesis.previous-degrees[]` | none | MAY | `\thesisaddprevious{}` |
| IRB protocol | `thesis.irb-protocol` | none | MAY | `\thesisirb{}` |
| Keywords | `thesis.keywords[]` (or Pandoc `keywords`) | none | SHOULD | PDF metadata and ProQuest form |
| Language | `lang` (Pandoc), default `en-US` | none | MUST (default) | `\DocumentMetadata{lang=...}`; `babel`/`polyglossia` per engine |
| Abstract | `abstract:` (Pandoc) | none (prose) | MUST | `\thesisabstract{...}` via `before-body.tex` |
| Dedication | markdown div `::: {.dedication}` | none (prose) | MAY | `dedication` environment |
| Acknowledgments | markdown div `::: {.acknowledgments}` | none (prose) | MAY | `acknowledgments` environment |
| Preface, list of abbreviations, symbols | markdown divs `.preface`, `.abbreviations`, `.symbols` | none | MAY | corresponding environments (3.6) |
| Front matter on/off | `thesis.frontmatter`: `full` \| `none` (default `full`) | none | MAY | `\thesisfrontmatter` is skipped when `none` |
| Profile id | `thesis.profile` (default `house`) | derived from `institution.name` via `registry.json` | MUST (default) | selects `profiles/<id>` config file |
| Draft marking | `thesis.draft: true` | none | MAY | `draft` option and a "DRAFT" footer; MUST fail CI if set on a release build |

R5. A field marked plain **MUST** in the table above that is missing at build time MUST
produce one error that names the author-facing key and the file it belongs in, not the
LaTeX macro: `abstract:` in `index.qmd` for the abstract (R6), and `_quarto.yml` for the
`book.*` and `thesis.*` keys. A field marked
**MUST (default …)** (`thesis.year`, `thesis.type`, `lang`, `thesis.profile`) never errors:
when unset it takes the stated default, and the build logs one `quarto.log.info` line naming
the key and the value used. **Reason:** authors never see the macro layer, and a valid
document must not fail for a field the spec can fill.

R5a. `thesis.institution` is MUST only in that the build needs a value: the profile's
`institution.name` (6.4) is its default, and `thesis.institution` overrides it. The class
errors (R5) only when both are empty (as in `house`, whose `institution.name` is empty). The
example book's overlay sets it to the profile's `institution.name` when the profile has one;
otherwise the base book's synthetic "Example University" stays (7.1). **Reason:** a profile
for one school already knows the school's name; only a profile without one needs the author to
supply it.

R6. The abstract is the author's Pandoc `abstract:` field in `index.qmd` (the one
supported channel). Dedication and acknowledgments are markdown divs in files, never YAML
strings; and no prose of any kind is stored in this registry. **Reason:** the maintainer round-trips prose in a separate agent;
words live in MD/MDX files, and the privacy invariant keeps prose out of this repo.

R7. The spec fields marked "not in spec" are gaps in `dataimago-spec.yaml`
(degree name, document type, graduate school, advisor titles, committee titles).
The `-templates` step SHOULD add them to the spec; until then the AI derives them
and the author confirms. **Reason:** these are title-page facts the author knows
and the spec does not collect.

### 2.3 Dedication, acknowledgments, and other prose environments

R8. A Pandoc Lua filter (shipped with the class files, R12) MUST, for PDF output, lift
the divs `.dedication`, `.acknowledgments`, `.preface`, `.abbreviations`, `.symbols` whose
page id is in `frontmatter.order` out of the body into document metadata (for example
`thesis-front.dedication`), and remove them from the body. A non-empty div whose id is NOT in
`frontmatter.order` stays in the body where the author wrote it, and the filter warns through
`quarto.log.warning`, naming the id and `frontmatter.order`; the PDF never loses the only copy. A host chapter (such as `chapters/00-front.qmd`) left with no other content is
dropped from the body and from the ToC. `before-body.tex` / `\thesisfrontmatter` prints each
from that metadata, once, in the position `frontmatter.order` dictates. **Reason:**
`before-body.tex` is emitted before `$body$`, so content left in a chapter would print after
the front matter and `\mainmatter`, or twice. The abstract needs no lifting: it is already
metadata (`$abstract$`).

R9. For HTML output the filter MUST leave the divs and the host chapter in source order
and unchanged. `chapters/00-front.qmd` stays in `book.chapters` so HTML still gets it; the PDF
filter removes it. **Reason:** one markdown source builds both the website and the PDF. The
filter ships with the class files in this registry (R12); the build step writes it, and this
spec only fixes its contract.

R9b. Quarto book structure. An `index.qmd` that carries only an `abstract:` produces an
empty-titled first chapter and a `quarto-title-block` code block; for PDF the filter drops
both, and drops a host chapter emptied by R8. The filter MUST keep Quarto's
`<!-- quarto-file-metadata -->` markers, because Quarto's later filters number chapters from
them; removing them leaves the next chapter unnumbered. **Reason:** this is how Quarto books
are built; the filter works with it rather than around it.

R9a. Optional prose pages (`dedication`, `acknowledgments`, `preface`, `abbreviations`, `symbols`) are omitted when their lifted metadata is empty, even if listed in `frontmatter.order` (the same idea as lists with `mode: auto`). **Reason:** an author who writes no dedication must not get a blank page.

### 2.4 Partials overridden

Quarto LaTeX partials (documented): `doc-class.tex`, `title.tex`, `before-body.tex`,
`after-body.tex`, `toc.tex`, and `pandoc.tex` with its sub-partials (`tables.tex` and
others). A partial is selected by file name under `format: pdf: template-partials:`.
`pandoc.tex` "must always be included"; the other partials may be replaced or emptied
(Quarto docs, "Template Partials", "LaTeX Partials"). Sub-partial names beyond those
quoted in the docs **[verify]** against the pinned version.

| Partial | Override | What it does | Reason |
|---|---|---|---|
| `doc-class.tex` | **replace** | Emits `\DocumentMetadata{...}` (when tagging is on) BEFORE `\documentclass`, then `\documentclass[<options>]{dataimago-thesis}` with the profile id and engine-relevant options | `\DocumentMetadata` must precede `\documentclass` (tagging docs). Replacing this partial drops `font-size`, `paper-size`, `classoption` handling (Quarto docs say so), so the class MUST re-implement the ones it supports. |
| `title.tex` | **replace** | `\title{$title$}`, `\author{$for(author)$$author$$sep$ \and $endfor$}`, `\date{$date$}`, then the `\thesis...` setters from `$thesis.*$` | Keeps the one-argument `\author`; sets every metadata field in one place. |
| `before-body.tex` | **replace** | Calls `\thesisfrontmatter` (title, copyright, approval, committee, abstract, dedication, acknowledgments, preface, ToC, lists, in profile order), then `\mainmatter`. The dedication, acknowledgments and similar pages are read from the metadata the filter lifted (R8), never from `$body$`. | Quarto's default prints `\maketitle` and the abstract itself; the class owns the order. |
| `toc.tex` | **replace with empty** | Suppresses Quarto's own ToC and lists | The class prints them in `frontmatter.order`. Avoids a doubled ToC. |
| `after-body.tex` | keep (empty) | | Nothing to add; the class handles back matter itself. |
| `pandoc.tex` | **keep**, unedited. Its `hyperref`/`bookmark` load is a no-op because the package is already loaded (by the tagging code, or by the class on the untagged path). Its `\hypersetup{...}` is overridden: the class re-applies its own `\hypersetup{...}` (R18) in `\AddToHook{begindocument/before}`, which runs after the whole preamble, so the class's values win. Font loads are prevented by the emptied font sub-partials below; the geometry load by the filter, which drops the `geometry` key. **[verify]** in `-build` against the pinned Quarto's `pandoc.tex`. | | Required by Quarto; Pandoc features (highlighting, tables, citations) need it. |
| font sub-partials `fonts.latex` and `font-settings.latex` | **replace with empty** so Pandoc applies none of the font keys; the warning comes from the Lua filter (R10), not from these partials. Geometry is not a partial: it is `$if(geometry)$` in `template.tex`, and the filter drops the `geometry` key (below) | Fonts and geometry belong to the profile | The `Option clash for package geometry` failure and the Noto fallback both came from two owners. |

Partials are inlined into the main `.tex` by Pandoc, so a partial carries a version comment
(`$-- Version: ...`, with the LPPL notice above it) instead of `\ProvidesFile`; only `doc-class.tex`
also prints a `\typeout` line, because it is the one partial that emits TeX before the class loads. `\ProvidesFile` appears only in the
compiled `.cfg` (8). The font and geometry sub-partial names were confirmed on Quarto 1.11.9:
`fonts.latex` and `font-settings.latex` are emptied; the geometry load is **not** a partial
(it is `$if(geometry)$` in `template.tex`), so a `geometry:` key would emit
`\usepackage[...]{geometry}` and clash with the class. The filter therefore warns and then
removes `geometry` (and the other keys Pandoc's template would act on: `linestretch`, the
font keys, `fontsize`, `papersize`) from the metadata before Pandoc fills the template (R10);
T17 sets `geometry:` and requires both the warning and a PDF.
`common.latex` loads `parskip` unless `indent` is set, so the filter sets `indent: true`.

R10. Unsupported Quarto keys MUST be detected, not silently ignored: if `geometry`,
`mainfont`, `sansfont`, `monofont` (replaced by `type.mono`), `mathfont`, `fontsize`, `linestretch`, `papersize`,
`toc`, `lof`, `lot` (replaced by `frontmatter.order`), `toc-depth` (replaced by `toc.depth`),
`documentclass` when it is anything other than `dataimago-thesis` (the replaced `doc-class.tex`
always loads the house class; the institution is chosen by `thesis.profile`),
`colorlinks`, `linkcolor`, `urlcolor`, `citecolor` or `pdfstandard` (replaced by
`submission.pdfa` / `accessibility.pdfua`; it would clash with the class's `\DocumentMetadata`)
is set, the Lua filter (the one of R8) MUST warn through
`quarto.log.warning`, naming the key and the profile field that replaces it. It reads most keys
from `doc.meta`. **Exception:** Quarto consumes `toc`, `lof`, `lot` and `toc-depth` itself,
so they never reach `doc.meta` (and `-M` command-line flags do not reach the filter either);
the filter reads those four from `_quarto.yml` and from the active `_quarto-<profile>.yml`
files (`QUARTO_PROFILE`), and warns whenever one of them is written there, whatever its
value: a project file holds only what the author wrote. **Limit (keys read from
`doc.meta`):** Quarto injects some values itself (`colorlinks: true`, `linkcolor: blue`,
`papersize: letter`), and in `doc.meta` they cannot be told from author values, so a value
equal to Quarto's own default is not reported there; any other value is. The class and the
emptied partials cannot see these keys, so they are not the place for the warning. **Reason:** an author changing `fontsize` and seeing nothing happen
is the worst failure mode.

R11. `classoption` MAY carry only the pass-through options of C3 (`draft`, `final`, `fleqn`, `leqno`, `openbib`, and a type size), plus
`profile=<id>`; `openany`/`openright` in `classoption` warn and are ignored; the class passes the resolved `headings.chapter.newPage` to `book`. **Reason:** one way to select the profile; the `thesis.profile` key
is rendered into the same option by `doc-class.tex`.

R12. The partials, filter, class, and a sample `_quarto.yml` SHOULD ship as one
directory the template copies in whole (`classes/dataimago-thesis/`; a Quarto format
extension is an option, see decision 7), together with the profile's compiled `.cfg`,
which lives in `profiles/` beside its YAML (CI diffs it against the YAML, T1). The two
locations are therefore: the **bundle** (`.cls`, partials, filter, generator, `example/`) in
`classes/dataimago-thesis/`, and the **`.cfg`** in `profiles/<id>.cfg`. A build puts both
directories on `TEXINPUTS` (`render.sh` does this), and a shipped fetch copies both. The
example book is `classes/dataimago-thesis/example/`, not a top-level `example/`.
**Reason:** the template should not hand-assemble a dozen files, and the generated file
stays next to the YAML it must match.

### 2.5 What the author writes in `_quarto.yml`

```yaml
project:
  type: book
book:
  title: "A Synthetic Study of Imaginary Systems"
  author: "Ada Q. Example"
  date: "2027-05-01"
  output-file: thesis
  chapters: [index.qmd, chapters/00-front.qmd, chapters/01-intro.qmd, chapters/02-methods.qmd]
  appendices: [chapters/appendix-a.qmd]
bibliography: references.bib
lang: en-US

thesis:
  profile: cu-boulder          # or: house
  year: 2027
  type: dissertation
  author-family: Example
  author-given: Ada Q.
  degree:
    name: Doctor of Philosophy
    abbreviation: Ph.D.
    field: Applied Studies
  department: Department of Applied Studies
  institution: University of Colorado
  graduate-school: Graduate School
  advisors:
    - { name: Jordan Reader, title: Professor, role: chair }
  committee:
    - { name: Sam Placeholder, title: Associate Professor }
    - { name: Riley Sample, title: Professor }
  keywords: [measurement, synthetic example]

format:
  pdf:
    documentclass: dataimago-thesis
    pdf-engine: lualatex
    template-partials: [doc-class.tex, title.tex, before-body.tex, toc.tex, fonts.latex, font-settings.latex]
    filters: [thesis-divs.lua]
    keep-tex: true
```

Abstract goes in `index.qmd` front matter (`abstract:`); dedication and
acknowledgments are divs in `chapters/00-front.qmd`. That file stays in `book.chapters` so the
HTML book has it; for PDF the filter lifts the divs into metadata and drops the file (R8, R9). The YAML
carries only the profile id (`thesis.profile`); the profile's values live in
`profiles/cu-boulder.yaml`, compiled to `profiles/cu-boulder.cfg` beside the YAML (not beside
the class bundle in `classes/dataimago-thesis/`; both directories go on `TEXINPUTS`, and a
shipped fetch copies both, per the discovery contract and R12).

---

## 3. What a profile covers

A profile holds everything a school's guide decides. Each subsection lists the
fields and the guide topic they come from. Field names and types are fixed in
section 6; this section says WHAT must be expressible and why. Where this section names a
property that 6.4 does not list (for example per-entry heading text for every front-matter page,
ToC page-number alignment, caption label wording), it is a fixed house default of the class,
not a profile field, until 6.4 gains a field for it. 6.4 is the schema; 6.4 wins any conflict.

### 3.1 Geometry

| Requirement | Reason |
|---|---|
| MUST: paper (`letter`, `a4`, custom width/height), sides (`one`, `two`) | Page size and duplex differ by country and school. |
| MUST: top, bottom, inside/left, outside/right margins as lengths | Guides give four numbers. |
| MUST: binding gutter (extra inside margin) and side (`left`, `right`) | Guides such as 1.5in-left-for-binding exist. |
| MUST: whether margins differ on chapter-opening pages (extra top space) | Common ("start chapters 2in down"). |
| SHOULD: header/footer allowance expressed as distances from the page edge, not text-block lengths | Page numbers are placed relative to the edge. |
| MUST NOT: use raw `\topmargin`-style lengths; the class uses `geometry` | Readability; testable with `pdfinfo`. |

### 3.2 Type

| Requirement | Reason |
|---|---|
| MUST: body size (pt) and family (`main`) with fallback list | Guides name a face or accept a list (Times, Arial, ...). |
| MUST: `type.main`, `type.sans`, `type.mono`, `type.math` as OpenType font names, or `latex-default` | The engine needs a font, not a school's word "serif". |
| MUST: `type.math` resolves to a font with a real OpenType MATH table (section 4.4) or `latex-default` (Latin Modern Math). | The silent fallback. |
| SHOULD: footnote and caption sizes | Guides give minimum sizes (e.g. 10pt footnotes). |
| SHOULD: heading sizes per level | Often a rule. |
| MAY: `type.emphasis` (italic, bold) | CU made `\emph` bold in the 1990s. |
| MUST: minimum size check: no text smaller than `type.minimumSize` in CI (T19) | Many guides set a floor. |

### 3.3 Spacing

| Setting | House default | Notes |
|---|---|---|
| `spacing.body` | double (line stretch for the chosen size; stated as a multiple of single) | The common requirement. |
| `spacing.paragraph` | `indent` of 0.5in, no extra skip | |
| `spacing.blockQuotes` | single | Single-spaced exception. |
| `spacing.footnotes` | single | Exception. |
| `spacing.captions` | single | Exception. |
| `spacing.tables` | single | Exception; also table body font size. |
| `spacing.bibliography` | single within entries, one blank line between | Exception. |
| `spacing.headings` | space before/after per level (class default for now; no profile field until a guide needs one) | |
| `spacing.toc`, `spacing.lists` | single within entries, space between | Guides differ; CU double-spaces the lists. |
| `spacing.abstract` | double | |
| `spacing.code` | single | Code blocks (Quarto) are not prose. |

R13. "Double" MUST be defined as a line pitch (baseline to baseline) of twice the type
size's single pitch, and the profile MAY give an explicit pitch in points instead
(`{pitch: 24pt}`). **Reason:** guides measure the page, and `setspace`'s stretch factors
(for example 1.667 for `\doublespacing`) are approximations that differ by size. Test T7
measures the pitch. **[verify]** that `setspace`'s factor matches at the chosen size, else
compute the factor from the font's single pitch.

### 3.4 Headings and chapter style

| Requirement | Reason |
|---|---|
| MUST: chapter label style (`Chapter N`, `N.`, none), numbering (arabic, roman), alignment, case, size/weight, space above and below | Varies. |
| MUST: new chapter starts on a new page (`openany`, `openright`) | Two-sided guides need `openright`. |
| MUST: section, subsection, subsubsection: numbering on/off, alignment, weight, size, case, run-in (inline) for level 4 | CU has inline level 4. |
| MUST: `numbering.depth` (deepest numbered level) and `toc.depth` | Different values. |
| MUST: unnumbered chapters (`.unnumbered`) get ToC entries | Dedication, bibliography, acknowledgments. |
| SHOULD: `headings.part.allowed` | Some schools forbid parts. |

### 3.5 Page numbering and position

| Requirement | Reason |
|---|---|
| MUST: front-matter number style (`roman`, `arabic`, `none`) and start | |
| MUST: whether the title page counts (and is hidden) | CU counts the title page as i, shows no number. |
| MUST: which front-matter pages show a number (title, copyright, abstract, dedication) | Per-guide. |
| MUST: main-matter style (`arabic`) and start (1) | |
| MUST: position (`top-right`, `top-center`, `bottom-center`, `bottom-right`) and distance from the edge | CU puts it at the top right. |
| MUST: chapter-opening pages (and chapter-style front-matter pages such as the ToC): `show` the number at the normal position, move it to `bottom-center`, or `hide` it | CU hides it. |
| SHOULD: running heads (`none` by default). **Not implemented:** `pagenumber.runningHead: chapter` warns at build ("not supported yet") and no running head is printed. | Rare in theses. |

### 3.6 Front matter order and contents

R14. `frontmatter.order` is an ordered list drawn from a closed vocabulary:
`title`, `copyright`, `approval`, `committee`, `abstract`, `dedication`,
`acknowledgments`, `preface`, `toc`, `lot`, `lof`, `abbreviations`, `symbols`.
A page absent from the list is not printed. **Reason:** order is
the most common difference after margins; a closed vocabulary is checkable.

R14a. The placement fields MUST agree with `order`, and CI (T1) checks it:
`committee.placement: separate-page` requires `committee` in `order`;
`title-page` or `none` requires it absent, and the `committee` block in
`titlePage.layout` is allowed only for `title-page`. `approval.enabled: true` requires
`approval` in `order` (a separate page that carries the signature lines, date lines and IRB
line; the `committee` page lists the committee only, with no signatures), and
`copyright.enabled: true` requires `copyright`. Lists are
ordered by `order` alone (there is no separate list-order field). **Reason:** two fields
for one fact drift apart.

Heading text, by page. The profile gives heading text only for the pages 6.4 lists a
`heading` field for: `committee.heading`, `dedication.heading`, `acknowledgments.heading`,
`abstract.heading`, `toc.heading` and
`lists.<list>.heading` (R22). The heading text of every other generated page ("Preface", "List of
Abbreviations", "List of Symbols") is a fixed house default of the class, as the opening of
section 3 allows. Where a profile gives no contents or list heading, those pages use the
language's own names (`\contentsname`, `\listtablename`, `\listfigurename`), which read
"Table of contents", "List of Tables" and "List of Figures" in English. Whether a page is
numbered, listed in the ToC, starts a new page, or is single or double spaced is likewise the
class's fixed behaviour unless 6.4 names a field (`pagenumber.front.hideOn`,
`lists.<list>.numberFirstPage`, `spacing.*`).

### 3.7 Front-matter pages and their wording

Wording is a profile TEMPLATE with named slots. Paths in the table below are relative to `frontmatter` (so `committee.placement` is `frontmatter.committee.placement`). The class fills slots from section 2
metadata and never contains institution names.

Slots: `{title}` `{author}` `{authorInverted}` `{degreeName}` `{degreeAbbr}` `{field}`
`{documentType}` `{department}` `{institution}` `{graduateSchool}` `{year}`
`{date}` `{advisorName}` `{advisorTitle}` `{irb}`; per-member slots (in `committee.format`): `{name}` `{title}` `{role}` `{affiliation}`.

| Page | Fields | House wording template |
|---|---|---|
| **Title page** | `titlePage.layout[]` (ordered blocks: `title`, `byline`, `previousDegrees`, `statement`, `committee`, `date`), alignment, vertical spacing, case | Title; "by {author}"; the statement below; year |
| Title-page statement | `titlePage.statement` | `A {documentType} submitted to the Faculty of the {graduateSchool} of the {institution} in partial fulfillment of the requirements for the degree of {degreeName} in {field}` |
| **Copyright page** | `copyright.enabled`, `copyright.template`, position | `© {year} {author}. All rights reserved.` (SHOULD be offered; ProQuest supports registered copyright) |
| **Approval / signature page** | `approval.enabled`, `approval.statement`, `approval.signatureLines` (from advisors+committee), `approval.dateLine`, `approval.irbLine` | House fallback, written for the house: `Approved by the {documentType} committee, {department}, {institution}.` plus signature lines and a date line. A school's own sentences come from its guide, cited in its profile; never from a legacy class. |
| **Committee page / block** | `committee.placement: title-page \| separate-page \| none`, `committee.heading`, `committee.format` (name, title, role, affiliation, order) | `Committee` heading, then `{name}, {title}` per member, chair first |
| **Abstract page** | `abstract.header` (template), `abstract.wordLimit`, `abstract.keywords: true\|false`; `abstract.heading`, `abstract.align` and `abstract.headerWeight` (R22) | House fallback: `{title}` / `{author}, {degreeAbbr}` / `{institution}, {year}` |
| Dedication, acknowledgments | heading text, case, placement | |

R22. **[implemented]** The abstract page, the contents and
the lists MUST be able to carry school wording, so the profile gains the fields in 6.4 and
the fixed text of these pages stops being a house default. (a) `frontmatter.toc.heading`,
`frontmatter.lists.lot.heading`, `frontmatter.lists.lof.heading`: the page heading (and, for
the two lists, the PDF bookmark; the contents page has no bookmark of its own) use the string
when set and the language's own name otherwise (today's output).
They follow `titlesCase`. The names extend the existing `frontmatter.<page>.heading` fields
(`committee`, `dedication`, `acknowledgments`), with the lists under `lists.<list>` as
`mode` and `numberFirstPage` already are. (b)
`abstract.heading`: the text of the line below the header block, default `Abstract`; `""`
omits the line. (c) `abstract.align`: `center` (default) or `left`, applied to the header
block and the heading together. (d) `abstract.headerWeight`: `bold` (default, today's output)
or `normal`, the weight of the header lines. Defaults are chosen so that a profile that sets
none of them renders exactly as before. **Reason:** the CU sample prints "Contents",
"Tables", "Figures", and an abstract page with plain left-aligned header lines and no
"Abstract" heading; with the fixed text the CU profile cannot reproduce it.

R15. The class MUST treat the school's word for the document (`documentType`) as a
slot. **Reason:** the CU class says "thesis" in its wording for dissertations too.

R16. The title-page `statement` template MUST allow the line breaks the guide wants
(`\n` in the YAML string). **Reason:** some guides break lines at fixed points.

### 3.8 ToC depth and lists

| Requirement | Reason |
|---|---|
| MUST: `toc.depth` (house 2; typical range 1-3) | Differs by school. |
| MUST: lists `lot`, `lof` with `mode: always \| auto \| never`; MAY `abbreviations`, `symbols`. `auto` decides from the filter's count of captioned floats (it knows Quarto's float targets); outside Quarto the class only notes `\caption` calls for the next pass, so a captioned `longtable` outside Quarto is not noticed (an uncaptioned one is correctly ignored). The class does not hook inside `longtable`, whose alignment breaks its caption. | The `auto` mode drops empty lists. |
| MUST: order of the lists; column labels ("Chapter", "Figure", "Table", "Page") | CU lists tables before figures. |
| MUST: leader dots, page-number alignment, indent per level | Guide-driven. |
| SHOULD: ToC lists the front-matter pages that follow it, not those before it | Common rule. |
| MUST: ToC page numbers are correct after two passes without manual `\ToCisShort`-style flags | C31 reason. |

### 3.9 Appendices

| Requirement | Reason |
|---|---|
| MUST: appendix numbering (`A`, `Appendix A`, `I`), heading wording, ToC label | Varies. |
| MUST: whether appendices precede or follow the bibliography. **Not enforceable:** Quarto fixes the chapter order (references, then appendices), so `appendices.placement: before-bibliography` only warns at build and the order is unchanged. | Guides disagree. |
| MUST: whether appendix pages are numbered consecutively with the body | Yes in nearly all. |
| SHOULD: a single "Appendix" ToC divider entry (CU) or per-appendix entries. Quarto writes one "Appendices" part entry for `book.appendices`; that entry is the divider. `divider: true` keeps it, labelled `appendices.label`; `divider: false` drops it (the class recognises the English title "Appendices" only; the per-appendix entries stay). | |

### 3.10 Landscape pages

R17. The class MUST provide a `landscape` environment (page rotated, number kept in the
profile's position relative to the TEXT orientation or the PAGE, per `landscape.pageNumber:
upright-page \| rotated-with-text`). **Reason:** guides split between the two.
Margins for landscape pages come from `landscape.margins`. Under tagging the environment
MUST NOT break the structure tree (confirmed: T15 passes with landscape pages).

**What is implemented.** Only `upright-page`, and it means this: the number is drawn at the
profile's position on the **unrotated sheet**, the same place as on portrait pages, so on a
landscape page it reads sideways in a PDF viewer. `rotated-with-text` is **not implemented**:
it warns at build and the number stays as `upright-page`. `landscape.margins` is **not
implemented** either: it warns at build and landscape pages use the page margins of
`geometry.margins`. **Reason:** the build chose the behaviour that keeps the number where a
bound copy expects it; the other two need their own page styles and are left until a guide asks.

### 3.11 Floats, bibliography and other

| Requirement | Reason |
|---|---|
| MUST: caption position (tables above, figures below), caption label wording and separator, numbering (per chapter or continuous) | Guides differ; CU numbers per chapter. |
| SHOULD: float placement defaults | |
| MUST: bibliography heading text, ToC entry, hanging indent, spacing. The filter applies `bibliography.heading` and `toc.bibliography` to the references chapter, which MUST be `# References {.unnumbered}` with id `references` (as in the example): it sets the heading text and adds or removes `.unlisted`. A references chapter with another id is left as written. | CU single-spaces the bibliography. Citation style is the author's (CSL), not the profile's. |
| SHOULD: footnote numbering (per chapter or continuous), marker style | |
| MAY: page-count limit (`limits.pages`) and word limit for the abstract | Guides state them; CI warns. |

---

## 4. Submission

### 4.1 ProQuest/ETD

What ProQuest's guide ("Preparing your manuscript for submission to ProQuest") says:
embed all fonts; no password protection; security settings allow printing; avoid
Type 3 fonts; TrueType or Unicode fonts preferred; PDF/A is offered as one way to
get embedded fonts (the guide's Word and Acrobat steps check a "PDF/A-1a" box);
exporting bookmarks is optional ("you may also wish to"). Universities add their own
rules, which win over ProQuest's; some libraries tell authors NOT to use PDF/A.
See section 10 for links.

| # | Requirement | Reason |
|---|---|---|
| S1 | The PDF MUST embed every font (subset is fine); CI fails on any font with `emb = no`. | ProQuest rule; unembedded fonts lose characters in print. |
| S2 | The PDF MUST NOT contain Type 3 fonts. CI fails on `type = Type 3`. | ProQuest rule (renders poorly). Type 3 fonts creep in via bitmap fonts and some plot output. |
| S3 | The PDF MUST be unencrypted with no restrictions on printing, copying or modification. | ProQuest rule. |
| S4 | Profile field `submission.pdfa` in {`none`, `1b`, `2b`, `3b`, `4`, `4f`}; house default `4f` (decision 2 chose `2b`; the build spike showed it cannot be combined with tagging and PDF/UA-2, so decision 2's fallback applies; see decision 2 and the composition rule in 6.4). `2b` maps to `pdfstandard=a-2b`, `4` to `a-4`, `4f` to `a-4f` (the `f` level allows embedded files). The enum is the same in 6.4. | Schools differ; a level is a profile fact. |
| S5 | If `pdfa != none`, the class MUST set it via `\DocumentMetadata{pdfstandard=...}`, which also embeds an output intent. CI validates with veraPDF where available (T14). `pdfstandard` is built from BOTH fields as a list: the PDF/A entry from `submission.pdfa` (omitted if `none`) plus the UA entry from the resolved `accessibility.pdfua` (omitted if `none`); for example `pdfstandard={a-4f, ua-2}` (the house default). | The kernel's PDF management is the supported path. Which levels combine with tagging and `lualatex` on the pinned TeX Live is resolved in 6.4 (composition rule): `a-2b` cannot share a PDF version with `ua-2`. |
| S6 | Bookmarks MUST be generated from the ToC to the profile's depth (`submission.bookmarkDepth`, house 2), with open state per profile. | Not a ProQuest rule; a navigation and accessibility baseline, cheap with `hyperref`. |
| S7 | PDF metadata MUST be set from the document: Title, Author, Subject (degree and institution), Keywords, Creator, language. No default "Untitled" or empty values, except that Keywords is omitted (not empty) when `thesis.keywords` is absent; CI reads them with `pdfinfo`/`exiftool`. | Archives index these. |
| S8 | Links: `submission.links: hidden \| boxes \| color \| underline`, house `hidden` (no borders, no color; text remains clickable). `underline` **[implemented]**: the link text keeps the text color (black) and each link annotation is drawn with an underline border (`pdfborderstyle={/S/U/W 1}`, black, `colorlinks=false`); the text is not changed, so tagging and PDF/UA see the same content as with `hidden`. The annotation carries the Print flag, so viewers and printers draw the underline, and the link stays clickable; no box, no color. The build chose the annotation border over underlining the text (`ulem`, `\underline`, or a redefined `\em`, which C9 rejects) because text underlining re-sets the link text and breaks tagging and line breaking, and a border costs nothing in the tag tree. The underline is a viewer-drawn border: a tool that discards annotations (some print-to-image paths) shows no underline. Added because the CU guide says links are underlined. Existing profiles are unaffected: the default and every current value render as before. | Print and submission checks often object to colored link boxes; the profile may require color or underlining. |
| S9 | Page size MUST equal the profile's paper size to the nearest 0.1 pt tolerance; CI measures with `pdfinfo`. | Catches stray `geometry`. |
| S10 | File size SHOULD stay below the school/ProQuest limit (`submission.maxMB`); CI warns. | Upload limits. |
| S11 | Images SHOULD be embedded at 300 dpi at final size or as vector; CI warns on lower `pdfimages` resolution. | Print legibility. |
| S12 | The copyright page, if the profile has one, MUST be present when `copyright.enabled`. | ProQuest copyright options. |

### 4.2 PDF metadata map

| PDF field | Source |
|---|---|
| Title | `title` (+ subtitle) |
| Author | `author` |
| Subject | `{degreeName}, {field}, {institution}, {year}` |
| Keywords | `thesis.keywords` |
| Language | `lang` |
| Creator/Producer | engine (automatic) |

### 4.3 Link style

R18. `hyperref` has one owner, the class, and is configured with `pdftitle`,
`pdfauthor`, `pdfsubject`, `pdfkeywords`, `bookmarksnumbered=true`, `pdfusetitle`,
`pdfdisplaydoctitle=true` (A6), and S8 for colors. How it is loaded depends on the path:
* **Tagged (`\DocumentMetadata` active, the house default):** the tagging code loads
  `hyperref` itself. The class MUST NOT `\usepackage{hyperref}` or pass load-time options;
  it sets every key above with `\hypersetup{...}` after the class loads.
* **Untagged (XeLaTeX fallback, R19):** the class loads `hyperref` once with
  `\usepackage{hyperref}` and then applies the same `\hypersetup{...}`.
Pandoc's own hyperref load and `\hypersetup` in `pandoc.tex` are handled as the partials
table's `pandoc.tex` row says: the load is a no-op, and the class re-applies its settings in
`\AddToHook{begindocument/before}`. Quarto's `colorlinks`, `linkcolor`, `urlcolor`, `citecolor` are
unsupported (R10). **[verify]** in `-build` that `\hypersetup` after `\DocumentMetadata`
sets `pdfdisplaydoctitle` and the bookmark options on the pinned TeX Live.
**Reason:** one owner, and no option clash on the tagged path.

### 4.4 Math font

| # | Requirement | Reason |
|---|---|---|
| M1 | `type.math` MUST name a font that has an OpenType MATH table, or be `latex-default`. | `unicode-math` needs it. |
| M2 | Known trap: apt's **Noto Sans Math 2.001** has no MATH table; `unicode-math` then silently sets all equations in Latin Modern Math. Version 3.000 (google/fonts) has the table. | Already hit in `build-thesis.yml`. |
| M3 | CI MUST run `pdffonts` on the output and fail if (a) the profile's `type.math` is not `latex-default` and the PDF embeds `LatinModernMath`; (b) the profile's `type.math` is not in the embedded list at all when the sample has an equation. | Silent fallback detection. The sample document includes equations. |
| M4 | The class SHOULD also check at load: after `\setmathfont`, test the font for the MATH table (`luaotfload`/`fontspec` query) and warn on fallback. | Earlier than CI. **[verify]** the check is feasible per engine. |
| M5 | CI installs the math font from a pinned source with a checksum (as `build-thesis.yml` does today). | Reproducibility. |

---

## 5. Accessibility and engine

### 5.1 Requirements

| # | Requirement | Reason |
|---|---|---|
| A1 | Output SHOULD be a tagged PDF (structure tree) with the document language set. Profile: `accessibility.tagged: on \| off`, house `on` where the engine supports it. | Screen readers; accessibility mandates. Some schools now ask for it. |
| A2 | Every figure MUST have alt text or be marked decorative. Quarto: `fig-alt` for code-generated figures, `![caption](img){fig-alt="..."}` for images; the build MUST fail (or warn, per `accessibility.altTextEnforcement`) on a figure without it. | Tagging requires alt or artifact; also helps the HTML output. |
| A3 | Document language MUST be set (`lang`), and passages in other languages SHOULD be marked. | Pronunciation by readers. |
| A4 | Tables SHOULD have header rows marked (`longtable`/Pandoc tables with headers). | Tagged tables need header cells. |
| A5 | Math SHOULD carry a machine-readable form (MathML associated file or structure element). | Screen-reader math. |
| A6 | PDF title (not file name) shown in the title bar: `DisplayDocTitle`. | PDF/UA requirement. |
| A7 | The class MUST NOT break tagging with its own front-matter constructs (title page via ordinary paragraphs, not drawn-with-vspace hacks). | Structure tree integrity. |
| A8 | Chapter headings MUST be tagged as `H1` (sections `H2`, ...). The LaTeX 2026-11-01 kernel redefines `\chapter` and `\secdef` under tagging, bypassing `\@makechapterhead`, so the class restores the classic `\chapter` and its chapter head calls the kernel's heading sockets (`sec/end`, `sec/begin`, `sec/title/init\|begin\|end`); it does not instantiate a heading template. **On a kernel without those sockets (before 2026-11-01) the calls are skipped and the chapter title is untagged there**; the build does not fail. T15 fails the build when chapter titles are missing from the tree or heading levels jump on a kernel that has the sockets. | Structure tree integrity; screen-reader navigation by heading. |

### 5.2 Engine status (as found 2026-11-08)

* The LaTeX Project's tagging documentation names **pdfLaTeX and LuaLaTeX** as supported
  and calls **LuaLaTeX "the preferred engine recommended for new documents."** XeLaTeX is
  **not mentioned** as supported. Automatic MathML generation **requires LuaLaTeX**; other
  engines can only attach author-supplied MathML. Tagging is switched on with
  `\DocumentMetadata{...}` before `\documentclass`, with keys such as `lang`,
  `pdfstandard` (e.g. `ua-2`, `a-4f`), `tagging=on`. The default PDF version becomes 2.0.
* The `tagpdf` package (the core of this work) is loaded automatically by
  `\DocumentMetadata`; it supports pdfLaTeX and LuaLaTeX. It was released often through
  2026 (CTAN announcements), and must stay in sync with the kernel and `latex-lab`:
  a current TeX Live is required.
* Unresolved: whether Quarto/Pandoc's generated LaTeX tags cleanly (tables, lists,
  raw blocks, citations). **[verify]** by a spike in the build step.

### 5.3 Recommendation

**Recommend LuaLaTeX as the house default engine; keep XeLaTeX supported for building,
without tagging.** Reason: tagging and automatic MathML work only on LuaLaTeX.

| Cost of moving from XeLaTeX | Mitigation |
|---|---|
| `fontspec` and `unicode-math` work on both engines; font names stay the same | The profile's `type.*` fields do not change. |
| Slower builds (LuaLaTeX is slower than XeLaTeX on large books, plus font cache on first run) | Cache `~/.texlive*/texmf-var` in CI. |
| Needs a current TeX Live (tagging code is in rapid development; TinyTeX must be current) | CI pins the TeX Live year; the template's `tlmgr` step updates. |
| Some XeLaTeX-only packages (`xeCJK`, `xunicode`) | Use `luatexja` or `fontspec` fallbacks for CJK. |
| The CU class and `build-thesis.yml` use XeLaTeX today | The legacy CU class stays XeLaTeX (its registry entry says so). The house class builds under both; since the registry step (see Status of this contract), the registry entry for the house class records `engine: lualatex`, `engineFallback: xelatex`. |
| Existing authors whose chapters include XeLaTeX-specific raw LaTeX | Document in the migration notes; CI builds the sample under both engines. |

R19. The class MUST build under both engines; with XeLaTeX, `accessibility.tagged`
MUST degrade to a warning (not a failure) and the metadata/bookmark/PDF-A items still apply.
On XeLaTeX the class MUST never pass `tagging=on`, and the class MUST fall back to setting language, PDF/A and bookmarks without tagging. **[verify]** that `\DocumentMetadata` (with `pdfstandard` but no tagging) runs on XeLaTeX; if it does not, `doc-class.tex` omits it there, the class sets language, bookmarks and metadata through `hyperref`, and PDF/A is then not guaranteed on XeLaTeX (a warning says so). **Reason:** keeps old setups working while the tagged path matures.

---

## 6. The profile format

### 6.1 Decision

* One YAML file per institution at `profiles/<id>.yaml`. **Reason:** guides map to
  fields; YAML is readable by the maintainer, by the AI, and in diffs.
* A **generator** compiles each profile to a LaTeX key-value file
  (`profiles/<id>.cfg`, beside its YAML and not in the class bundle, R12) read by the class; the YAML is never read at run time.
  **Reason:** LaTeX cannot parse YAML. CI regenerates and fails on drift between
  the two files.
* A JSON Schema (`profiles/profile.schema.json`) validates every profile in CI.
  The YAML-to-`.cfg` generator is written in Lua (decision 11) so it runs inside Quarto with no
  extra runtime; only the schema-check tool in CI is the build step's choice.
* `schemaVersion` is part of every profile and bumps on breaking changes.

### 6.2 Rules

P1. **Every value converted from an institution's guide MUST carry a `source`
citation** (guide page or section) in the profile's `sources` map, keyed by the
dotted field path. A value without an entry in `sources` is taken as the house value.
CI fails if a field differs from the house value and has no `sources` entry.
**Reason:** the author checks the profile against the guide; the citation says where.

P2. **A field the guide does not state MUST be omitted**; it falls back to the house
value. The profile lists such omissions under `unstated:` (path list), so the author
sees what was defaulted. **Reason:** explicit about what the guide is silent on.

P3. A value inferred from a sample PDF, a template or a class (not stated in text) MUST
be recorded in `sources` as `{inferred: true, from: "...", note: "..."}`.
**Reason:** inference is weaker evidence; a human reads these first.

P4. Lengths use units (`in`, `cm`, `pt`, `mm`, `em`). Booleans are booleans. Text is
UTF-8. **Reason:** type-checkable.

P4a. YAML 1.1 reads the bare words `on`, `off`, `yes`, `no` as booleans, and PyYAML
(the CI schema check) follows it, so `tagged: on` is the boolean `true`, not the string the
schema's enum wants. A profile MUST quote such values (`tagged: "on"`), and MUST quote
numeric-looking enum values (`pdfa: "4"`, the schema enum is a string). The Lua reader and
the PyYAML check are compared for parity (T1). **Reason:** the same file must mean the same
thing to both readers.

P5. A profile contains facts about a guide only: no manuscript content, no author data,
no names of real people. **Reason:** the registry's privacy invariant; MIT license
(section 8).

P6. Profile inheritance: every profile except `house` itself extends `house` (`extends: house`, the default and
only allowed base); `id: house` is the root and has no `extends`. A profile MUST NOT extend a non-house profile. **Reason:** one
level keeps defaults traceable.

### 6.3 Top-level shape

```yaml
schemaVersion: 1
id: cu-boulder
extends: house
institution: { ... }
guide: { ... }
geometry: { ... }
type: { ... }
spacing: { ... }
headings: { ... }
numbering: { ... }
pagenumber: { ... }
frontmatter: { ... }
toc: { ... }
appendices: { ... }
landscape: { ... }
floats: { ... }
bibliography: { ... }
submission: { ... }
accessibility: { ... }
limits: { ... }
sources: { ... }
unstated: [ ... ]
```

### 6.4 Field schema

"Maps to" gives the generated key (`\thesisset{section/key=value}`-style) the class reads;
the class option or macro column says how an author can override it. House value is the
default when a field is omitted. "length" means a number with a unit.

#### `institution` and `guide` (metadata about the profile)

| Field | Type | Default | Allowed | Maps to |
|---|---|---|---|---|
| `id` | string | required | `[a-z0-9-]+`, equals file name | `profile=<id>` class option |
| `extends` | string | `house` (absent in `id: house`, the root) | `house` | loader |
| `institution.name` | string | required | | `{institution}` default |
| `institution.graduateSchool` | string | `Graduate School` | | `{graduateSchool}` default |
| `institution.short` | string | | | docs only |
| `guide.title` | string | required (except `house`) | | `sources` base |
| `guide.issuer`, `guide.version`, `guide.date`, `guide.url` | string | | date ISO 8601 | docs |
| `guide.retrieved` | date | required (except `house`) | ISO 8601 (the schema also accepts the literal `unretrieved`, for a profile whose guide has not been read: local drafts and negative tests only; no profile uses it now. CI does not reject it, so a maintainer rejects it in review of a contributed or registered profile; `CONTRIBUTING.md` says the same) | docs |

#### `geometry`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `paper` | enum | `letter` | `letter`, `a4`, `custom` | `geometry` paper |
| `paperWidth`, `paperHeight` | length | | only if `custom` | |
| `sides` | enum | `one` | `one`, `two` | `oneside`/`twoside`; (`openany`/`openright` are owned by `headings.chapter.newPage`) |
| `margins.top` | length | `1in` | > 0 | `geometry` `top` |
| `margins.bottom` | length | `1in` | | `bottom` |
| `margins.inside` | length | `1in` | | `inner` (left in oneside) |
| `margins.outside` | length | `1in` | | `outer` |
| `binding.gutter` | length | `0in` | ≥ 0 | `bindingoffset` |
| `binding.side` | enum | `left` | `left`, `right`, `top` | `bindingoffset` side |
| `chapterOpening.extraTop` | length | `0in` | | `\thesischaptertopskip` |
| `headerFooter.numberDistance` | length | `0.5in` | from the page edge | page-number baseline |

#### `type`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `size` | number (pt) | `12` | 10, 11, 12 implemented; `10.5` is in the schema but **not implemented** (the `book` class has no 10.5pt: the class warns at build and uses 11pt) | base size |
| `main` | string | `TeX Gyre Termes` | installed OTF name or `latex-default` | `\setmainfont` |
| `sans` | string | `TeX Gyre Heros` | | `\setsansfont` |
| `mono` | string | `TeX Gyre Cursor` | | `\setmonofont` |
| `math` | string | `TeX Gyre Termes Math` | must have a MATH table, or `latex-default` | `\setmathfont` |
| `fallback` | list | `[]` | font names | `luaotfload` fallbacks |
| `emphasis` | enum | `italic` | `italic`, `bold` | `\emph` |
| `footnoteSize` | number (pt) | `10` | | footnote size |
| `captionSize` | number (pt) | `10` | | |
| `minimumSize` | number (pt) | `10` | | CI floor |

(House fonts are free, widely packaged TeX Gyre fonts with a math companion that has a
MATH table, replacing the Noto default. Verified 2026-11-08: `TeX Gyre Termes Math`
ships in TeX Live 2026 and has the table; CI still checks it with `pdffonts`. See
decision 5.)

#### `spacing`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `body` | enum \| number \| `{pitch: length}` | `double` | `single`, `onehalf`, `double`, or a multiple, or `{pitch: 24pt}` | `\setstretch`/`\linespread` |
| `paragraph.indent` | length | `0.5in` | `0` allowed | `\parindent` |
| `paragraph.skip` | length | `0pt` | | `\parskip` |
| `blockQuotes` | enum | `single` | `single`, `inherit` | `quote`, `quotation`, `verse` |
| `footnotes` | enum | `single` | | |
| `captions` | enum | `single` | | |
| `tables` | enum | `single` | | |
| `bibliography.within` | enum | `single` | | |
| `bibliography.between` | length | `1em` | | `\bibitemsep` |
| `toc` | enum | `single-within` | `single`, `double`, `single-within`; the ToC only | |
| `lists` | enum | `single-within` | `single`, `double`, `single-within`; applies to LoT, LoF and the other lists (CU: `double`) | |
| `abstract` | enum | `double` | | |
| `code` | enum | `single` | | |

#### `headings` and `numbering`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `chapter.label` | enum | `chapter-number` | `chapter-number` ("Chapter 1"), `number`, `none` | |
| `chapter.align` | enum | `center` | `left`, `center` | |
| `chapter.case` | enum | `as-typed` | `as-typed`, `upper` | |
| `chapter.size`, `chapter.weight` | pt, enum | `14`, `bold` | `normal`, `bold` | |
| `chapter.newPage` | enum | `any` | `any`, `right` | `openany`/`openright` |
| `section.align`, `.size`, `.weight`, `.case` | | `left`, `12`, `bold`, `as-typed` | | likewise for `subsection`, `subsubsection` |
| `level4.style` | enum | `block` | `block`, `inline` | |
| `part.allowed` | bool | `true` | | |
| `numbering.chapter` | enum | `arabic` | `arabic`, `roman` | |
| `numbering.depth` | int | `2` | 0-5 | `secnumdepth`, on LaTeX's `book` scale: 0 chapter, 1 section, 2 subsection, 3 subsubsection, 4 paragraph, 5 subparagraph. Quarto's `#`/`##`/`###`/`####` are chapter/section/subsection/subsubsection, so "level 4" (`####`) is numbered iff depth ≥ 3. `toc.depth` uses the same scale. |
| `numbering.floats` | enum | `per-chapter` | `per-chapter`, `continuous` | |
| `numbering.footnotes` | enum | `continuous` | `per-chapter`, `continuous` | |
| `numbering.equations` | enum | `per-chapter` | `per-chapter`, `continuous` | `\counterwithin`/`\counterwithout{equation}{chapter}` |

#### `pagenumber`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `front.style` | enum | `roman` | `roman`, `arabic`, `none` | `\pagenumbering` |
| `front.titleCounts` | bool | `true` | | |
| `front.titleShown` | bool | `false` | | |
| `front.hideOn` | list | `[title, committee, copyright]` | page ids from R14; the number is hidden on the first page of each | |
| `main.style` | enum | `arabic` | | |
| `main.start` | int | `1` | | |
| `position` | enum | `bottom-center` | `top-right`, `top-center`, `top-left`, `bottom-center`, `bottom-right` | page style |
| `chapterFirstPage` | enum | `show` | `show`, `bottom-center`, `hide` | |
| `runningHead` | enum | `none` | `none`; `chapter` is **not implemented** (warns at build, prints no running head) | |

#### `frontmatter`

Paths are relative to `frontmatter` (e.g. `committee.placement` is `frontmatter.committee.placement`).

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `order` | list | `[title, committee, copyright, abstract, acknowledgments, dedication, preface, toc, lof, lot, abbreviations, symbols]` | closed vocabulary (R14); must agree with R14a | `\thesisfrontmatter` |
| `titlePage.layout` | list | `[title, byline, statement, date]` | blocks as in 3.7; `committee` only if `committee.placement: title-page` | |
| `titlePage.statement` | template string | see 3.7 | slots | |
| `titlePage.byline` | template string | `by {author}` | | |
| `titlePage.date` | enum | `year` | `year`, `month-year`, `none` | |
| `titlePage.case` | enum | `as-typed` | `as-typed`, `upper` | |
| `titlePage.previousDegrees` | bool | `false` | | |
| `copyright.enabled` | bool | `true` | | |
| `copyright.template` | template | `© {year} {author}. All rights reserved.` | | |
| `approval.enabled` | bool | `false` | | |
| `approval.statement` | template | see 3.7 | | |
| `approval.signatureLines` | enum | `advisors-and-committee` | | |
| `approval.dateLine` | bool | `true` | | |
| `approval.irbLine` | bool | `false` | | |
| `committee.placement` | enum | `separate-page` (decision 3) | `title-page`, `separate-page`, `none` | |
| `committee.heading` | string | `Committee` | | |
| `committee.format` | template | `{name}, {title}` | role appended for chair | |
| `abstract.header` | template | `{title}` / `{author}, {degreeAbbr}` / `{institution}, {year}` | | |
| `abstract.wordLimit` | int | none | | CI warning |
| `abstract.heading` | string | `Abstract` | any text; `""` prints no heading. **[implemented]** | the heading line below the header block |
| `abstract.align` | enum | `center` | `center`, `left`. **[implemented]** | alignment of the header block and of the heading |
| `abstract.headerWeight` | enum | `bold` | `bold`, `normal`. **[implemented]** | weight of the header lines |
| `frontmatter.toc.heading` (the `toc` here is the page, not the top-level `toc` table of depth and leaders) | string | none (the language's name: "Table of contents") | non-empty text. **[implemented]** | the contents page heading (the contents page has no PDF bookmark of its own) |
| `lists.lot.heading`, `lists.lof.heading` (under `frontmatter`) | string | none (the language's names: "List of Tables", "List of Figures") | non-empty text. **[implemented]** | the list page headings (also their bookmarks) |
| `dedication.heading` | string | none | | |
| `acknowledgments.heading` | string | `Acknowledgments` | | |
| `acknowledgments.maxPages` | int | none | | CI warning |
| `lists.lot.mode`, `lists.lof.mode` | enum | `auto` | `always`, `auto`, `never` | |
| `lists.<list>.numberFirstPage` | enum | `auto` | `auto`, `show`, `hide` | |
| `titlesCase` | enum | `as-typed` | `as-typed`, `upper` | |

#### `toc`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `depth` | int | `2` | 1-4 | `tocdepth` |
| `columnLabels` | bool | `true` | | |
| `leaders` | enum | `dots` | `dots`, `none` | |
| `bibliography` | bool | `true` | | ToC entry for the bibliography |
| `includesFrontmatter` | enum | `after` | `after`, `all`, `none` | |

#### `appendices`, `landscape`, `floats`, `bibliography`

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `appendices.numbering` | enum | `alpha` | `alpha`, `roman`, `arabic` | |
| `appendices.label` | string | `Appendix` | | |
| `appendices.divider` | bool | `false` | | single ToC entry; `false` drops Quarto's "Appendices" part entry (3.9) |
| `appendices.placement` | enum | `after-bibliography` | `after-bibliography`; `before-bibliography` is **not enforceable** (Quarto orders the chapters; the class warns at build and the order is unchanged; 3.9) | |
| `landscape.pageNumber` | enum | `upright-page` | `upright-page`; `rotated-with-text` is **not implemented** (warns at build, the number stays as `upright-page`; R17) | |
| `landscape.margins` | map | as `geometry.margins` | **Not implemented**: warns at build when set; landscape pages use `geometry.margins` (R17) | |
| `floats.captionPosition.table` | enum | `above` | `above`, `below` | |
| `floats.captionPosition.figure` | enum | `below` | | |
| `floats.labelSeparator` | string | `. ` | | |
| `bibliography.heading` | string | `Bibliography` | e.g. `References` | |
| `bibliography.hangingIndent` | length | `0.5in` | | |

**Warn-only options.** Every existing option marked above as not implemented or not
enforceable (`pagenumber.runningHead: chapter`, `landscape.pageNumber: rotated-with-text`,
`landscape.margins`, `type.size: 10.5`) is accepted by the schema, compiles into the `.cfg`,
and produces one class warning at build that names the key and what the build does instead.
A profile MAY set one of these to record what the guide says, but its value changes
nothing in the PDF until the option is implemented. The fields and values that
were **[specified, not yet implemented]** in revision 2 are now **[implemented]** (R22, S8): the schema accepts
them, the generator compiles them into the `.cfg`, and the class reads them with the defaults in
the table, so a profile that sets none of them renders as before. `toc.leaders`, `numbering.*`,
`spacing.*` and the other fields not marked are implemented.

#### `submission`, `accessibility`, `limits`

**Composition rule (resolved).** The class builds `\DocumentMetadata{pdfstandard={...}}` as one list from `submission.pdfa` (PDF/A entry, unless `none`) and the resolved `accessibility.pdfua` (UA entry, unless `none`). `auto` resolves to `ua-2` when the engine is lualatex and `accessibility.tagged` is `on` (`ua-1` when `submission.pdfa` is `1b`, `2b` or `3b`; see below), otherwise `none`. The build spike found that PDF/A-2b cannot be combined with tagging and UA-2 on the pinned TeX Live (tagging forces PDF 2.0; the kernel reports `PDF version 2.0 is too high for standard pdf/A-2B`), so the house `submission.pdfa` is `4f` (PDF 2.0), and the result is recorded in a `sources` note on that field in `profiles/house.yaml`. `a-4f` with `ua-2` builds without warnings. `a-2b` still works untagged, or with `ua-1` at PDF 1.7.

**`pdfua: auto`, exactly.** It resolves only on LuaLaTeX with `accessibility.tagged: "on"`; on XeLaTeX, or untagged, it resolves to `none`. When it does resolve, it gives `ua-2`, except that when `submission.pdfa` is `1b`, `2b` or `3b` it gives `ua-1` and the class sets the PDF version to 1.7 (1.4 for `1b`), because those levels cannot share a PDF version with `ua-2`. `4` and `4f` resolve to `ua-2`. An explicit `ua-1` or `ua-2` is passed through as written.

| Field | Type | House | Allowed | Maps to |
|---|---|---|---|---|
| `submission.pdfa` | enum | `4f` | `none`, `1b`, `2b`, `3b`, `4`, `4f` | PDF/A entry of `pdfstandard` (rule below) |
| `submission.embedFonts` | bool | `true` | MUST be true | CI |
| `submission.bookmarkDepth` | int | `2` | 0-4 | `hyperref` `bookmarksdepth` |
| `submission.bookmarksOpen` | bool | `false` | | |
| `submission.links` | enum | `hidden` | `hidden`, `boxes`, `color`, `underline` **[implemented]** | `hyperref` options (`underline`: `pdfborderstyle={/S/U/W 1}`, black border, text color unchanged) |
| `submission.linkColor` | color | `#1a4f8b` | only if `links: color` (`underline` keeps the text color: black) | |
| `submission.maxMB` | number | none | | CI warning |
| `accessibility.tagged` | enum | `on` (quote it: P4a) | `on`, `off` | `\DocumentMetadata{tagging=...}` |
| `accessibility.altTextEnforcement` | enum | `error` | `error`, `warn`, `off` | filter |
| `accessibility.pdfua` | enum | `auto` | `auto`, `ua-1`, `ua-2`, `none`; `auto` = `ua-2` when the engine is lualatex and `accessibility.tagged` is `on` (but `ua-1` when `submission.pdfa` is `1b`, `2b` or `3b`), else `none` | UA entry of `pdfstandard` (rule below) |
| `limits.pages` | int | none | | CI warning |
| `limits.abstractWords` | int | none | | CI warning |

#### `sources`, `unstated`

| Field | Type | Notes |
|---|---|---|
| `sources` | map | Key: dotted path (`geometry.margins.top`). Value: string (page or section, e.g. `"§2.3, p. 5"`) or `{section, page, quote?, inferred?, from?, note?}`. `quote` is at most one short line. |
| `unstated` | list of paths | Fields the guide does not state; the house value applies. |

### 6.5 Worked example 1: `profiles/house.yaml` (values only)

The neutral dataimago default. No guide, so no guide-derived `sources`; its one `sources`
note records the build spike's result for `submission.pdfa` (6.4, composition rule). House
values are choices, not institutional facts.

```yaml
schemaVersion: 1
id: house
institution:
  name: ""            # filled from thesis.institution
  graduateSchool: Graduate School
geometry:
  paper: letter
  sides: one
  margins: { top: 1in, bottom: 1in, inside: 1in, outside: 1in }
  binding: { gutter: 0in, side: left }
  chapterOpening: { extraTop: 0in }
  headerFooter: { numberDistance: 0.5in }
type:
  size: 12
  main: TeX Gyre Termes
  sans: TeX Gyre Heros
  mono: TeX Gyre Cursor
  math: TeX Gyre Termes Math
  emphasis: italic
  footnoteSize: 10
  captionSize: 10
  minimumSize: 10
spacing:
  body: double
  paragraph: { indent: 0.5in, skip: 0pt }
  blockQuotes: single
  footnotes: single
  captions: single
  tables: single
  bibliography: { within: single, between: 1em }
  toc: single-within
  abstract: double
  code: single
headings:
  chapter:    { label: chapter-number, align: center, case: as-typed, size: 14, weight: bold, newPage: any }
  section:    { align: left, size: 12, weight: bold, case: as-typed }
  subsection: { align: left, size: 12, weight: bold, case: as-typed }
  subsubsection: { align: left, size: 12, weight: normal, case: as-typed }
  level4: { style: block }
  part: { allowed: true }
numbering: { chapter: arabic, depth: 2, floats: per-chapter, footnotes: continuous, equations: per-chapter }
pagenumber:
  front: { style: roman, titleCounts: true, titleShown: false, hideOn: [title, committee, copyright] }
  main: { style: arabic, start: 1 }
  position: bottom-center
  chapterFirstPage: show
  runningHead: none
frontmatter:
  order: [title, committee, copyright, abstract, acknowledgments, dedication, preface, toc, lof, lot, abbreviations, symbols]
  titlePage:
    layout: [title, byline, statement, date]
    byline: "by {author}"
    statement: "A {documentType} submitted to the Faculty of the {graduateSchool} of the {institution} in partial fulfillment of the requirements for the degree of {degreeName} in {field}"
    date: year
    case: as-typed
    previousDegrees: false
  copyright: { enabled: true, template: "© {year} {author}. All rights reserved." }
  approval: { enabled: false, statement: "Approved by the {documentType} committee, {department}, {institution}.", signatureLines: advisors-and-committee, dateLine: true, irbLine: false }
  committee: { placement: separate-page, heading: Committee, format: "{name}, {title}" }
  abstract: { header: "{title}\n{author}, {degreeAbbr}\n{institution}, {year}" }
  acknowledgments: { heading: Acknowledgments }
  lists: { lot: { mode: auto }, lof: { mode: auto } }
toc: { depth: 2, columnLabels: true, leaders: dots, bibliography: true, includesFrontmatter: after }
appendices: { numbering: alpha, label: Appendix, divider: false, placement: after-bibliography }
landscape: { pageNumber: upright-page }
floats: { captionPosition: { table: above, figure: below }, labelSeparator: ". " }
bibliography: { heading: Bibliography, hangingIndent: 0.5in }
submission: { pdfa: 4f, embedFonts: true, bookmarkDepth: 2, bookmarksOpen: false, links: hidden }
accessibility: { tagged: "on", altTextEnforcement: error, pdfua: auto }
limits: {}
sources:
  submission.pdfa: { inferred: true, from: "build spike, TeX Live 2026 (2026-11-08)", note: "..." }
```

### 6.6 Worked example 2: `profiles/cu-boulder.yaml` (values only)

**Non-normative shape sketch. Do not copy this file into `profiles/`.** Its values come from
the legacy class, not the guide, and `sources` is abbreviated to one entry; the real profile needs
one `sources` entry per non-house path and guide-read decisions for `submission.*`,
`accessibility.*` and `type.*`.

Source: the CU Boulder class v1.14 as it implements the Graduate School
"Specifications for Preparation of Master's Thesis and Doctoral Dissertations" (April 2010,
as the class header cites; v1.14 mentions a May 2020 revision). The maintainer's
build step must compare against `classes/cu-boulder/example/sample-output.pdf`. Citation
page numbers are placeholders: we have not read the guide itself, only the class. All
values below come from the class, so each one is **[inferred]**; the build step turns each
into a real page citation after reading the guide (P1 forbids merging an uncited
value into the registry).

```yaml
schemaVersion: 1
id: cu-boulder
extends: house
institution: { name: University of Colorado, graduateSchool: Graduate School }
guide:
  title: "Specifications for Preparation of Master's Thesis and Doctoral Dissertations"
  issuer: "University of Colorado Boulder Graduate School"
  version: "April 2010 (class header also cites rev. May 2020)"
  retrieved: "(set when the guide is read)"
geometry:
  paper: letter
  sides: one
  margins: { top: 0.9in, bottom: 1in, inside: 1in, outside: 1in }   # inferred: top text area begins 0.9in; page number sits above it
  headerFooter: { numberDistance: 0.7in }                            # inferred
type:
  size: 11                       # registry classOptions: defaultstyle, 11pt
  footnoteSize: 9                # inferred: LaTeX \footnotesize at 11pt
  minimumSize: 9                 # inferred: lowers the house floor of 10 to fit the footnotes
spacing:
  body: { pitch: 24pt }          # inferred: stretch 1.771 on an 11pt base, near true double
  paragraph: { indent: 0.4in, skip: 0pt }
  blockQuotes: single
  footnotes: single
  captions: single
  tables: single
  bibliography: { within: single, between: 1em }
  toc: double
  lists: double                  # inferred: the class wraps \listoftables and \listoffigures in \doublespacing
  abstract: double
headings:
  chapter:    { label: chapter-number, align: center, case: as-typed, size: 12, weight: bold, newPage: any }
  section:    { align: left, size: 12, weight: bold }
  subsection: { align: left, size: 11, weight: bold }
  subsubsection: { align: left, size: 11, weight: bold }
  level4: { style: block }
  part: { allowed: false }
numbering: { chapter: arabic, depth: 3, floats: per-chapter, footnotes: continuous, equations: per-chapter }   # inferred: the class's secnumdepth is 3 (level 4 numbered)
pagenumber:
  front: { style: roman, titleCounts: true, titleShown: false, hideOn: [title, abstract, dedication] }   # inferred; chapter-style pages follow chapterFirstPage
  main: { style: arabic, start: 1 }
  position: top-right
  chapterFirstPage: hide
frontmatter:
  order: [title, abstract, dedication, acknowledgments, toc, lot, lof]
  titlePage:
    layout: [title, byline, previousDegrees, statement, date, committee]
    byline: "by {author}"
    statement: "A {documentType} submitted to the Faculty of the Graduate School of the {institution} in partial fulfillment of the requirements for the degree of {degreeName} {department}"
    date: year
    previousDegrees: true
  copyright: { enabled: false }
  approval:
    enabled: false               # removed in v1.14 (August 2020)
    signatureLines: advisors-and-committee
    dateLine: true
    irbLine: true
  committee: { placement: title-page, heading: "Committee Members", format: "{name}" }
  abstract:
    header: "{authorInverted} ({degreeAbbr}, {field})\n{title}\n{documentType} directed by {advisorTitle} {advisorName}"
  acknowledgments: { heading: Acknowledgements, maxPages: 1 }
  lists: { lot: { mode: auto }, lof: { mode: auto } }
toc: { depth: 2, columnLabels: true, leaders: dots, bibliography: true, includesFrontmatter: after }
appendices: { numbering: alpha, label: Appendix, divider: true, placement: after-bibliography }
bibliography: { heading: Bibliography }
floats: { captionPosition: { table: above, figure: below } }
sources:
  geometry.margins.top: { inferred: true, from: "thesis.cls v1.14 geometry block", note: "page number in top header box; verify with sample-output.pdf" }
  # ... one entry per non-house field above, each {inferred: true, from: ..., note: ...}
unstated: []   # left empty until the guide and the ETD instructions have been read (P2)
```

Notes on the CU example:
1. `statement` keeps "Graduate School of the {institution}" in the template and sets
   `institution.name: University of Colorado`, because the Graduate School's wording says
   "University of Colorado" without "Boulder". The house template uses `{graduateSchool}`. The
   difference is a profile fact.
2. The class says "thesis" for dissertations too. The profile uses `{documentType}`, so
   CU dissertations will say "dissertation". **That is a deliberate deviation. [inferred]** The
   Graduate School's text must be checked (decision 8).
3. `titlePage.statement` in the class ends with `{degreeName}`, then designation+department
   and year on separate lines; the `layout` blocks above (`statement`, then `date` with
   `titlePage.date: year`, then `committee`) reproduce that.
4. `acknowledgments.maxPages: 1` comes from a comment in the class's own `example/main.tex`
   (one page, "as required by the Grad School Specifications") **[inferred]**.
5. `type.footnoteSize: 9` is the LaTeX `\footnotesize` for 11pt, not a stated rule.
6. Fonts, emphasis, PDF/A, links and tagging are omitted, so the house defaults apply (tagged PDF, PDF/A `4f`, TeX Gyre). The 2010 class says nothing about them, but that is the class's silence, not the guide's, so `unstated` stays empty. The build step MUST read the guide and the school's ETD instructions and then either list these fields under `unstated` or set them with a citation (decision 2 notes that some libraries forbid PDF/A).
7. CU's title-page statement, abstract header and committee heading are CU wording taken from how the class behaves; they are `inferred` and must be re-sourced from the guide. The house defaults do not reuse them.

---

## 7. Testing

### 7.1 Fixtures

* One **synthetic** example book (`classes/dataimago-thesis/example/`): front matter, three chapters (one with
  a block quote, a footnote, a wide table, a figure with alt text, a figure that
  creates a float page, display equations including `\mathbb`, `\mathcal`, a Quarto theorem div (`::: {#thm-...}`; the sample defines no `theorem` of its own)),
  a bibliography, one appendix, one landscape page, a list of figures
  and tables, an abbreviations list. No real prose. The book is the same for every
  profile; only `thesis.profile` changes, through the overlay `_quarto-<id>.yml` (R21),
plus `thesis.institution` set to the profile's `institution.name` when it has one
(otherwise the book's synthetic "Example University" stays).
* CI runs the matrix `profile × engine`: `house`, `cu-boulder` × `lualatex`, `xelatex`.
  (Tagging checks run on `lualatex` only.)

### 7.2 Checks per profile

| # | Check | How | Fails when |
|---|---|---|---|
| T1 | **Schema and sources** | JSON Schema validation; every non-house field has `sources` or `inferred`; `.cfg` regenerated equals committed | invalid, uncited, or drifted |
| T2 | **Build succeeds** | `quarto render --to pdf`; no `LaTeX Error`, no overfull box wider than a threshold (house 5pt), no undefined references | any |
| T3 | **Fonts** | `pdffonts` | any `emb = no`; any Type 3; `LatinModernMath` when `type.math` is not `latex-default`; the profile's main and math font missing |
| T4 | **Page size** | `pdfinfo -box` for each page | any page not equal to the paper (and landscape swap) |
| T5 | **Margins, measured** | Rasterize pages (`pdftoppm`) and measure the ink bounding box per page; compare with `geometry.margins` plus gutter | any ink inside a margin by more than 1pt, on body pages; known exempt: page numbers, figures set to bleed (none in the sample). TeX sets the last baseline on the bottom margin line, so descenders hang below it: the test config allows `margins.bottomDescenderPt` (3 in `*.test.yaml`) on the bottom edge only (R20). |
| T6 | **Page-number position** | `pdftotext -bbox` finds the number's box; compare with `pagenumber.position` and `geometry.headerFooter.numberDistance` | outside 2pt |
| T7 | **Line pitch** | From `pdftotext -bbox`, median baseline distance on a body page | differs from `spacing.body` by more than 0.5pt |
| T8 | **Front-matter order** | `pdftotext` of pages 1-N for the profile's heading strings | order differs from `frontmatter.order` |
| T9 | **Page numbering** | extract page labels (`pdfinfo`/`qpdf --show-pages` or PyPDF) | the labels disagree with the profile: front-matter style vs `pagenumber.front.style` (including `none`), whether the title page counts vs `pagenumber.front.titleCounts`, and the main matter's style and first number vs `pagenumber.main.style` / `pagenumber.main.start` |
| T10 | **Wording** | Compare the rendered title page text to the template filled with the sample metadata | different |
| T11 | **First-pages snapshot** | Render pages 1-8 at 80 dpi to PNG; compare to the committed snapshot with a perceptual diff (tolerance per page) | difference above threshold: 2 % of pixels (`snapshot.tolerance: 0.02` in `*.test.yaml`, R20). Snapshots are updated deliberately in a PR; they were made locally and CI matches them, but a different TeX Live may need a deliberate update. |
| T12 | **Metadata and bookmarks** | `pdfinfo` Title/Author/Subject/Lang, and Keywords when `thesis.keywords` is set; count of bookmarks and their depth | missing or wrong |
| T13 | **Security** | `qpdf --show-encryption` | encrypted |
| T14 | **PDF/A** (optional but on by default when `pdfa != none`) | veraPDF with the profile matching the level; the job is skipped if veraPDF is not installed | any failure on LuaLaTeX. On XeLaTeX a PDF/A-4f failure is a warning, not a failure (veraPDF reports file-trailer rules 6.1.3-4 and 6.1.3-5), as R19 allows: PDF/A is not guaranteed there and the class warns. CI pins veraPDF (1.30.1, SHA-256 checked); PDF/A-4f and PDF/UA-2 pass for `house` and `cu-boulder` on LuaLaTeX. |
| T15 | **Tagging** (lualatex, `tagged: on`) | structure tree present (`qpdf --show-object` on StructTreeRoot or `pdfinfo` "Tagged: yes"); alt text on every Figure element; optional veraPDF PDF/UA profile | missing |
| T16 | **Math font check** | run once with a deliberately broken math font in a negative test; CI MUST turn red | the check does not catch it |
| T17 | **Unsupported keys** | negative test: set `geometry:`, `mainfont:`, `monofont:`, `linkcolor:`, `toc: false` and `toc-depth:` in `_quarto.yml`; the Lua filter MUST log a `quarto.log.warning` for each, naming the replacing profile field (R10) | no warning |
| T18 | **Size** | file size under `submission.maxMB` | warning |
| T19 | **Minimum text size** | (a) the profile's `type.size`, `type.footnoteSize` and `type.captionSize` are each at least `type.minimumSize` (a schema check); (b) extract text spans with font sizes from the sample PDF (e.g. PyMuPDF `page.get_text("dict")`) and require body, footnote-text and caption spans to be at least `type.minimumSize`, within the tolerance (R20). Reduced-size spans the floor is not about are excluded: math sub/superscripts, footnote and citation markers, and running heads/folios only if the guide exempts them; the exclusions are listed in `profiles/<id>.test.yaml` | fail |

R20. Measurement tolerances live in the profile test config (`profiles/<id>.test.yaml`),
not in the profile. **Reason:** tolerances are ours, the facts are the school's.

R21. A profile PR changes only `profiles/<id>.yaml`, its `.cfg`, its snapshot images,
the example book's overlay `classes/dataimago-thesis/example/_quarto-<id>.yml`, and its
test config `profiles/<id>.test.yaml`. The test config is required: the sample book has
math scripts and footnote and citation markers, and T19's exclusions for them live there
(start from `profiles/house.test.yaml`; keep `folios` excluded only if the guide exempts
running heads). The overlay sets `thesis.profile: <id>` and, when the profile
sets `institution.name`, `thesis.institution` to that name (section 7.1); nothing else,
so no titles, people's names or committee. Without it the example renders as the
house book. CI MUST run the full matrix for the changed
profile and the schema check for all. **Reason:** keeps contributions small and
reviewable.

---

## 8. Licensing

| Item | License | Notes |
|---|---|---|
| `dataimago-thesis.cls` and companion `.sty`/`.cfg` generators, filters, partials | **LPPL 1.3c** | Written fresh. Each file's header carries the LPPL notice, `\ProvidesClass` with version date, and maintainer status per LPPL convention. |
| `profiles/*.yaml`, JSON Schema, tests, docs, `registry.json` | **MIT** (repo `LICENSE`) | A profile states facts about a guide; it is not a derivative of the CU class. |
| CU Boulder `thesis.cls` v1.14 | Unlicensed third-party file; stays in `classes/cu-boulder/` as the legacy entry | The repo `LICENSE` does not cover it. |
| Fonts | Each font keeps its own license (TeX Gyre: GUST Font License) | Fonts are installed in CI, never committed. |

A partial is inlined into the main `.tex` by Pandoc, so its LPPL notice is a version comment
rather than `\ProvidesFile` (2.4; only `doc-class.tex` also prints a `\typeout` line). The compiled `profiles/<id>.cfg`
carries `\ProvidesFile` and a note that it is a compile of MIT profile data, so the `.cfg` is
MIT like its YAML even though the class that reads it is LPPL. `tests/negative/noto-math.yaml`
is a test-only profile outside `profiles/` (the T16 trap; never registered).

L1. **No code is copied from the CU class**, not as text, not as logic transliterated
line by line. The class is a feature reference only: this spec records WHAT it does.
**Reason:** it has no stated license (audit 2026-11-07).
L2. The author of the house class MUST write from this spec and the TeX documentation;
reviewers check the diff for resemblance to CU's internal names (`th@...`).
**Reason:** an independent implementation is the point.
L3. The class header MUST credit the CU Boulder class and its authors as the feature
reference: John P. Weiss (1997), Bruce Fast, Steven V. Penton, E. Joshua Rigler,
Hongcheng Ni, Ken Anderson (v1.14), as listed in that class's header. The credit says "feature reference; no code derived".
L4. Profiles cite guides by section and page and quote at most one short line.
**Reason:** guides are copyrighted by the school; facts and short citations are fine.
L5. Registry docs (`README.md`) state the dual licensing plainly (this repo's
README already says "classes contributed from now on are LPPL 1.3c unless the class's README says otherwise").
L6. LPPL asks that a modified version be distributed under a different name. So authors
adapting for a new institution SHOULD write a profile, not edit the class; that is the point
of this design. **Reason:** keeps the name `dataimago-thesis` meaningful.

---

## 9. Decisions (2026-11-08)

**Decided 2026-11-08: the maintainer accepted every recommendation below as written.** Item 9 adds fields to the spec schema; if that schema belongs to the L1 package, the change goes through the design agent.

| # | Question | Decision |
|---|---|---|
| 1 | **Engine.** LuaLaTeX default (tagging, MathML) or XeLaTeX (what CU and `build-thesis.yml` use)? | **LuaLaTeX default, XeLaTeX supported without tagging** (5.3). The cost is a current TeX Live and slower builds. The template's workflow changes in `-templates`. |
| 2 | **PDF/A level.** ProQuest does not require PDF/A; its guide offers it as a route to embedded fonts, and some libraries tell authors not to use it. Which default? | **`2b` for the house profile**, `none` allowed per profile, and a spike in `-build` to confirm it combines with tagging on the pinned TeX Live; if not, use `4f` (the tagging project's PDF/A-4 path, PDF 2.0), recording the spike's result in `sources`. Schools override. |
| 3 | **Committee: title page or separate page by default?** CU (since 2020) puts it on the title page; many schools use a signature page. | **House default: separate committee page (unnumbered, after the title page); signatures, when a school requires them, go on the separate approval page.** CU profile uses `title-page`. |
| 4 | **House paper size and margins.** Letter and 1in on all sides, or 1.5in binding? | **Letter, 1in, no gutter**; the gutter is a profile field. |
| 5 | **House fonts.** TeX Gyre (free, with a math companion that has a MATH table) or keep Noto Sans? | **TeX Gyre Termes** (Times-like serif, math: Termes Math) for body and math. Noto Sans body is unusual for a thesis and caused the math trap. Verified 2026-11-08: `texgyretermes-math.otf` ships in TeX Live 2026 (`tex-gyre-math`) and has an OpenType MATH table. |
| 6 | **Profile CI cost.** Full matrix per profile × engine on every PR? | Run the full matrix only for changed profiles and the class; nightly for all. |
| 7 | **Delivery shape.** Plain files copied into the template, or a Quarto format extension (`_extensions/dataimago/thesis`, `format: dataimago-thesis-pdf`)? | **Plain files first** (matches the current registry model: fetch files). Revisit an extension after the first conversions. |
| 8 | **CU `thesis` wording.** The class says "thesis" for doctoral dissertations too. Reproduce the wording, or use `{documentType}`? | **Use `{documentType}`**; the build step checks against the Graduate School's guide and the sample PDF and records the result in `sources`. |
| 9 | **Spec gaps.** Add `degree.name`, `documentType`, `graduateSchool`, advisor title, committee titles to `dataimago-spec.yaml`? | **Yes**, in the `-templates` step. Until then the AI derives and the author confirms. |
| 10 | **CU defaults to bold `\emph`.** Reproduce for CU or use italic? | **Italic in both.** A guide rarely mandates bold emphasis; mark as `inferred` and let the maintainer confirm against the PDF. |
| 11 | **Where the generator lives.** Which language for the YAML-to-`.cfg` generator and schema validator (Lua inside Pandoc, Node, R, Python)? | **Lua**, so it runs inside Quarto with no extra runtime; the schema check in CI may use any tool. |

---

## 10. Sources

Quarto (via Context7 `/websites/quarto`, from quarto.org/docs/journals/templates.html and
quarto.org/docs/output-formats/pdf-engine.html):

* [Template partials: replacing partials](https://quarto.org/docs/journals/templates.html):
  `format: pdf: template-partials:`, partial chosen by file name, an empty file opts out.
* [LaTeX partials](https://quarto.org/docs/journals/templates.html#latex-partials):
  `doc-class.tex` (overriding it drops `font-size`, `paper-size`, `classoption` support),
  `before-body.tex` (front matter, title page, abstract), `title.tex`, `toc.tex`
  (ToC, LoF, LoT), `after-body.tex`, `pandoc.tex` ("must always be included"; composed of
  sub-partials such as `tables.tex`).
* [PDF engine](https://quarto.org/docs/output-formats/pdf-engine.html): `pdf-engine`, `pdf-engine-opts`.

Submission:

* ProQuest, [Preparing your manuscript for submission to ProQuest](https://about.proquest.com/go/etd_preparingyourmanuscriptguide)
  (the PDF the link redirects to, read 2026-11-08): embed all fonts, no password protection,
  security allows printing, avoid Type 3 fonts, PDF/A offered as a route, bookmarks optional.
* Conflicting library guidance on PDF/A, found by web search: [Antioch University ETD fonts page](https://libguides-phd.antioch.edu/AUETDCentralallprograms/fonts) (do not use PDF/A or lock the PDF);
  [Mount Sinai deposit guide](https://icahn.mssm.edu/files/ISMMS/Assets/Education/DepositingYourDoctoralDissertation2015.pdf) (check PDF/A);
  [Tennessee Tech ProQuest slides](https://www.tntech.edu/graduatestudies/pdf/etd/ETD_ProQuest_slides_F25.pdf) ("No Security");
  [Spalding University conversion page](https://library.spalding.edu/dissertation/conversion) (the institution's rules supersede ProQuest's).

Accessibility:

* LaTeX Project, [Tagged PDF usage instructions](https://latex3.github.io/tagging-project/documentation/usage-instructions):
  pdfLaTeX and LuaLaTeX supported, LuaLaTeX preferred for new documents, XeLaTeX not
  mentioned, MathML generation requires LuaLaTeX, `\DocumentMetadata` keys (`lang`,
  `pdfstandard`, `tagging`), alt text via `alt=`/`artifact`, default PDF 2.0.
* CTAN, [tagpdf announcements](https://ctan.org/ctan-ann/pkg/tagpdf): 2026 releases;
  loaded automatically by `\DocumentMetadata`; must stay in sync with the kernel.

Internal:

* CU Boulder class v1.14 and README: `classes/cu-boulder/`.
* Framework default class and workflow: `dissertation-rpkg-template/ui/www/`,
  `.github/workflows/build-thesis.yml`; app template `thesis-build` skill.
* `docs/discovery-contract.md` (this repo).

Not verified in this session: the Graduate School's actual April 2010 / 2020 text
(only the class's reading of it), the exact set of Quarto LaTeX sub-partial names, and
the pdfstandard-with-tagging combinations on the current TeX Live. Each is marked
**[verify]** above.
