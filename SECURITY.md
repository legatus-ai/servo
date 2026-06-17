# Security Policy

> **Fork notice (legatus-ai/servo).** This is a fork of
> [servo/servo](https://github.com/servo/servo) carrying the
> [`legatus-svg`](../../tree/legatus-svg) patches. Vulnerability handling for
> **this fork's patches** is described below. Upstream servo vulnerabilities
> are still handled by the upstream project.

## Supported branches

| Branch | Supported | EOL |
|---|---|---|
| `legatus-svg` | ✅ Active development | When superseded by upstream or abandoned |
| `main` | ❌ Mirror only | n/a (mirrors upstream `servo/servo:master`) |
| Other branches | ❌ | n/a |

## Reporting a vulnerability in this fork

If you find a vulnerability **specifically introduced by the `legatus-svg`
patches** (the SVG presentation attribute work, the baked-computed-styles
serialization, or any legatus-specific glue):

1. **Preferred:** open a private security advisory —
   https://github.com/legatus-ai/servo/security/advisories/new
2. **Alternative:** email `security@legatus.ai` with reproduction details.

Please **do not** open a public issue for fork-specific vulnerabilities.

## Reporting a vulnerability in upstream servo

Please submit security-related issues to the upstream project:
[GitHub security reports](https://github.com/servo/servo/security/advisories/new).

We will backport upstream security fixes to `legatus-svg` within **7 days** of
the upstream public disclosure, generally via the next
`fork-upstream-sync.yml` run.

## What this fork does not change

- The network stack, sandbox, or process model are inherited unchanged from
  upstream servo on the `main` branch.
- The `legatus-svg` patches only touch SVG CSS handling and inline-SVG
  serialization in `components/script/` — they do not modify anything in the
  network, storage, or IPC layers.
