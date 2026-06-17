# Fork: legatus-ai/servo

This is a **fork of [servo/servo](https://github.com/servo/servo)** maintained by
[legatus-ai](https://github.com/legatus-ai) to carry patches that have not yet
been (and in some cases cannot be) upstreamed.

## Branch layout

| Branch | Tracks | Purpose |
|---|---|---|
| `main` | `servo/servo:master` | Mirror of upstream. Updated by the `fork-upstream-sync.yml` workflow. **Never commit here directly** — every change to `main` should come from an upstream merge. |
| `legatus-svg` | `main` + our patches | The supported engine line. Pinned by `legatus-ai/versoview-shim` via git `rev`. |

`legatus-svg` currently carries **3 commits** ahead of `main`:

1. `740db8e` — Enable SVG presentation attributes with updated stylo dependency
2. `3df3ed8` — Bake computed styles into serialized inline SVG (LEG-264)
3. `4f623b6` — Update the fourth xml_serialize call site

Companion repo: [`legatus-ai/stylo`](https://github.com/legatus-ai/stylo) — the
stylo fork the SVG patches depend on.

## How the engine is consumed

`legatus-ai/versoview-shim` builds this fork as a `git` dependency pinned by
`rev`. It is **not** published to crates.io. Every build (local or CI) resolves
the exact engine snapshot via the pinned rev, which is what makes the published
`versoview` release asset reproducible.

To advance the engine line:

1. Land changes on `legatus-svg` (direct push or PR).
2. Bump the `servo` `rev` in
   [`versoview-shim/Cargo.toml`](https://github.com/legatus-ai/versoview-shim/blob/main/Cargo.toml)
   to the new `legatus-svg` HEAD.
3. Run the `build-engine.yml` workflow in `versoview-shim` to publish new
   per-platform release assets.
4. Bump the `ENGINE_RELEASE_TAG` in
   [`legatus-desktop-tauri/src-tauri/crates/legatus-tauri/build.rs`](https://github.com/legatus-ai/legatus-desktop-tauri/blob/main/src-tauri/crates/legatus-tauri/build.rs)
   if you want app bundles to fetch the new engine.

## Upstream sync

Automated by `.github/workflows/fork-upstream-sync.yml`:

- Runs weekly (Sun 09:05 UTC) and on manual dispatch.
- Merges `servo/servo:master` into a dated `sync/auto-YYYY-MM-DD` branch off
  `legatus-svg`.
- Opens a PR against `legatus-svg` with a generated summary.
- On non-trivial conflict, opens an issue instead of a PR — manual resolution
  required.

Manual sync helper: `scripts/fork-sync.sh`.

## What this fork will and will not accept

**Will accept** (open a PR against `legatus-svg`):

- Backports of specific upstream servo fixes that have not yet shipped in a
  `main` sync, with a clear test case or issue link.
- Patches required to keep `versoview-shim` building against current libservo.
- Fixes for the 38 WPT regressions introduced by the SVG CSS work (see
  `CHANGELOG.md`).

**Will not accept**:

- General servo feature work — that belongs upstream.
- Patches unrelated to the SVG CSS / LEG-264 line.

## Reporting bugs

- Engine bugs in this fork: open an issue here.
- Engine bugs in upstream servo: report at
  [servo/servo](https://github.com/servo/servo/issues).
- Bugs in the `versoview` wire-protocol shim:
  [`legatus-ai/versoview-shim`](https://github.com/legatus-ai/versoview-shim/issues).
- Bugs in the desktop app:
  [`legatus-ai/legatus-desktop-tauri`](https://github.com/legatus-ai/legatus-desktop-tauri/issues).

## License

Inherits servo's licensing (`MPL-2.0`). See `LICENSE` files in the upstream
tree.
