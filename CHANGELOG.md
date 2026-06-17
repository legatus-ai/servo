# Changelog — legatus-ai/servo fork

All notable changes to **this fork's `legatus-svg` branch** are documented here.
The `main` branch mirrors upstream `servo/servo:master` and is not tracked here
— see upstream's commit history for `main` activity.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Pending
- 38 WPT expectation (`.ini`) files added by the SVG CSS work — each represents
  an upstream WPT that regressed when SVG presentation attributes were enabled.
  Tracked in <https://github.com/legatus-ai/servo/issues>; see FORK.md for the
  acceptance policy. Categories:
  - **css-conditional** container-queries: container-units-svglength
  - **css-masking** clip-path: descendant-text-mutated-001,
    transform-mutated-002
  - **css-variables**: variable-presentation-attribute
  - **css fill-stroke** animation: fill-interpolation
  - **css filter-effects**: feimage-circular-reference-foreign-object-crash,
    feimage-reference-foreign-object-crash (these are **crash tests** — high
    priority)
  - **intersection-observer**: svg-intersection-with-fractional-bounds-2,
    svg-viewbox, v2/simple-occlusion-svg-foreign-object (MUI virtualization
    impact)
  - **pointerevents**: pointerevent_touch-action-svg-none-test_touch
  - **svg/animations**: short-simple-duration-and-fractional-repeatcount,
    svginteger-animation-1, svginteger-animation-2
  - **svg/painting/animations**: stroke-dasharray-composition,
    stroke-dashoffset-composition, stroke-width-composition
  - **svg/painting**: fill-rule-no-interpolation,
    svg-child-will-change-transform-invalidation
  - **svg/pservers/scripted**: svg-fill-currentcolor-visited-getComputedStyle
  - **svg/render**: foreignObject-in-non-rendered-getComputedStyle
  - **svg/styling**: css-selectors-case-sensitivity,
    presentation-attributes-special-cases, use-element-attr-selector (+ transition
    tentative), use-element-class-selector (+ transition tentative),
    use-element-id-selector (+ transition tentative),
    use-element-transitions (-dom-mutation tentative, .tentative)
  - **trusted-types**: script-enforcement-003, -004, -013, -015, -017

## [legatus-svg] — 2026-06-12

### Added
- **SVG presentation attributes** (`Script: Enable SVG presentation attributes
  with updated stylo dependency`, `740db8e`). Depends on the matching
  `legatus-ai/stylo` `legatus-svg` patch (`feat(style): enable basic SVG CSS
  properties for Servo`, stylo `5699496`).
- **Baked computed styles into serialized inline SVG** (`feat(script): bake
  computed styles into serialized inline SVG (LEG-264)`, `3df3ed8`). The
  LEG-264 use case: when SVG content is serialized out for IPC or snapshot, the
  computed CSS styles are inlined so the result renders standalone.
- **Fourth xml_serialize call site** updated (`fix(script): update the fourth
  xml_serialize call site`, `4f623b6`).

### Known regressions introduced
- 38 WPT expectations added (see `[Unreleased] / Pending` above). Each is a test
  that passed on upstream `main` and now fails on `legatus-svg` due to the SVG
  CSS changes. They are marked as expected failures to keep CI green; the
  underlying behavior gaps are follow-up work.

### Upstream sync history
- 2026-06-12: initial branch creation; synced with `servo/servo@8c0a551` (main
  as of 2026-06-12T19:23Z).
- 2026-06-17: PR
  [#1](https://github.com/legatus-ai/servo/pull/1) opened to merge 97 upstream
  commits (`servo/servo@7bc6f39`).
