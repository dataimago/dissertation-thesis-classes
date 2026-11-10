# Moving an older dissertation repository to the house class

**For authors.** If dissertation.ai set up your dissertation repository before
2026-11-09, its thesis PDF is built with the framework's earlier default class (the
`thesis.cls` copied into your book folder at setup), and the AI instructions in it read
this registry the old way: they look for a ready-made format on the registry's
classes, but institutions are now listed under its profiles (a profile with `mode:
shipped` is ready-made). One thing is wrong as
a result: asked about your institution's ready-made format, your AI may say there is
none when there is (a ready-made profile; CU Boulder has one today). Nothing is broken and your PDF has not
changed; moving is your choice, and nothing changes until you agree.

To move: open your dissertation repository in your AI tool (Claude Code, Codex,
Cursor, or another tool that can read files and run commands) and say:

> Read https://raw.githubusercontent.com/dataimago/dissertation-thesis-classes/main/docs/move-to-house-class.md and follow it.

Your AI shows you every change first and waits for your yes. It never commits or
pushes: at the end it shows you the `git` commands, and you run them.

---

## For the AI

You are helping the author move their repository's thesis build to the dataimago house
class. These rules hold throughout:

- **Ask first.** Change nothing until the author has seen the change and said yes.
- **The author commits.** Never run `git add`, `git commit`, `git push` or `gh pr create`;
  show the commands instead.
- **The words are the author's.** Move text where the steps say so; never rewrite it.
- **Stay out of private files.** Never open `raw/private/`, `.env*`, keys or tokens.
- **Run each command block from the repository root.** Each block stands alone; do not
  rely on a variable set in an earlier block.

### 1. Check that the move applies

Find the **book folder** (the folder holding `_quarto.yml` for the thesis):

- content-only: `thesis/`, if `thesis/_quarto.yml` exists;
- R package: `packages/r-packages/<name>/<quartoRoot>/`, with `<name>` and `<quartoRoot>`
  from `source.rPackage.name` and `source.rPackage.quartoRoot` in `dataimago-spec.yaml`
  (`quartoRoot` is `ui/www` by default).

Then stop, and tell the author why, in any of these cases:

- `<book folder>/thesis-class/sync.py` exists: the repository is already on the house
  class. Nothing to move.
- `vertical.dissertation.thesis.classFile.type` in `dataimago-spec.yaml` is `vendored`: the book uses the
  author's own institution class, which the move does not touch.
- `<book folder>/thesis.cls` does not exist: this is not the layout this guide knows.
  Ask the author to contact the dissertation.ai maintainer.
- `git status` shows uncommitted changes: ask the author to commit or set them aside
  first, so the move is one clean change they can review.

### 2. Update the repository's thesis skills (with a yes)

The old skills fetch the live `registry.json` but read it as `schemaVersion` 1, looking for
an `institution` on `classes`; version 2 lists institutions under `profiles` (`mode:
shipped`), so they report no ready-made format. Replacing the skills is what fixes that.
There is no registry copy in the repository to refresh. The book's `thesis.cls` is the
framework's earlier default class, not this registry's legacy `classes/cu-boulder/`
class, which is never fetched or offered.

The repository's `.claude/skills/thesis-build/`, `.claude/skills/thesis-format/` and
`.claude/agents/thesis-build-agent.md` predate the house class. The current ones carry the
move. Tell the author you will replace those two folders and that file with the copies in
the public template
`dataimago/dissertation-app-template` (in an R-package dissertation they live in this
main repository too, not in the package), and show what changes:

```sh
S="$(mktemp -d)"
git clone --depth 1 https://github.com/dataimago/dissertation-app-template "$S/app"
for k in thesis-build thesis-format; do
  if [ -d ".claude/skills/$k" ]; then diff -ru ".claude/skills/$k" "$S/app/.claude/skills/$k"; else echo "new: .claude/skills/$k"; fi
done
A=.claude/agents/thesis-build-agent.md
if [ -f "$A" ]; then diff -u "$A" "$S/app/$A"; else echo "new: $A"; fi
```

If the author edited any of these themselves, point those edits out; they are lost
unless the author keeps a copy. After the author's yes:

```sh
S="$(mktemp -d)"
git clone --depth 1 https://github.com/dataimago/dissertation-app-template "$S/app"
for k in thesis-build thesis-format; do
  [ -f "$S/app/.claude/skills/$k/SKILL.md" ] || { echo "missing in the template: $k (stop and tell the author)"; exit 1; }
done
[ -f "$S/app/.claude/agents/thesis-build-agent.md" ] || { echo "missing in the template: thesis-build-agent.md (stop and tell the author)"; exit 1; }
mkdir -p .claude/skills .claude/agents
for k in thesis-build thesis-format; do
  rm -rf ".claude/skills/$k"
  cp -a "$S/app/.claude/skills/$k" ".claude/skills/$k"
done
cp "$S/app/.claude/agents/thesis-build-agent.md" .claude/agents/thesis-build-agent.md
```

### 3. Move, by the updated skill

Read `.claude/skills/thesis-build/SKILL.md` (the copy you just put in place) and follow
its section **"Moving an older repository to the house class"**, from its step 1 (which
proposes the whole move and waits for a yes) to its step 7 (render, then show the
commit commands). Use the book folder from step 1 here. That section copies the class
and profiles, edits `_quarto.yml`, moves the abstract, acknowledgments and dedication,
replaces `build-thesis.yml` and deletes the old class last.

When you show the commit commands, include what step 2 updated (the two skill folders
and the agent file):
content-only, in the same branch and pull request; R package, in the pull request in
this main repository (the one that updates the package's submodule pointer), since the
skills live here.

### 4. After the move

The book now builds on the `house` profile, or on the author's own profile if
`profiles/` held one. If the author's institution has a ready-made profile in this
registry (`registry.json`, `profiles` with `mode: shipped`; CU Boulder today), tell them,
and offer the skill's **"Setting up a shipped profile"** as a separate step, only if they
want it.

A repository set up before 2026-10-04 may also lack the `/ingest` and
`/import-manuscript` skills. This guide does not add them; if the author wants them,
point them to the dissertation.ai maintainer.
