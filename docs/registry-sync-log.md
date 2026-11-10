# registry.json sync log

dataimago/dissertation-ai keeps a byte-identical copy of `registry.json`
(`apps/hub/src/lib/thesis-classes/registry.json`), copied by its `registry:sync`
and checked by its `registry:check`. That repository is private, so neither this
repository's CI nor its reviewer can see the hub's pull requests. This log is how a
registry change names the hub pull request that copies it.

**Rules** (checked by `tools/check_sync_log.py` in CI):

- A pull request that changes `registry.json` appends one row. Rows above it never change.
- The newest row's blob is `git hash-object registry.json` for the `registry.json`
  this pull request leaves, and it names the dissertation-ai pull request whose copy
  has that blob.
- The order follows from that: push the registry branch, run `registry:sync` in
  dissertation-ai against that branch and open its pull request, then add the row
  here. If `registry.json` changes again before merge, update the hub pull request
  and the newest row's blob.

The hub's `registry:check` compares its copy with this repository's `main`, so the hub
pull request passes only after this one merges; re-run its failed check then.

The first four rows were backfilled on 2026-11-10 by matching each `registry.json` blob
in this repository's history with the blob of the hub's copy at each hub merge.

| Date | registry.json blob | Change | Hub sync PR |
|---|---|---|---|
| 2026-11-07 | `3f7a1e74ae03644e8db07b3b4d5e8cda9247e024` | the initial registry (f1ae0db) | dataimago/dissertation-ai#261 |
| 2026-11-09 | `9647e241ae8ddd1861c17c2fde006e728e200a75` | schemaVersion 2 for the house class and profiles (#6) | dataimago/dissertation-ai#272 |
| 2026-11-10 | `81dfb7a7d65fba15d29caac630da613c980dbff7` | CU sources cited, house serif kept (#19) | dataimago/dissertation-ai#283 |
| 2026-11-10 | `2b88eb5aba4a4083ea254a5e708cde954ab0af8c` | CU notes say which entries name their document (#21) | dataimago/dissertation-ai#285 |
