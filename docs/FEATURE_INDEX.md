# SurfShack13 Feature Work Index

This index routes proposed work to the correct repository-backed source of truth.

| Work type | Authoritative file | Source requirement | Branch prefix |
|---|---|---|---|
| Reverse or restore a merged `/tg/station` change | [`RESTORATION_BACKLOG.md`](RESTORATION_BACKLOG.md) | Merged `tgstation/tgstation` pull request | `agent/restore-` |
| Import a feature from Hippiecode or another SS13 codebase | [`FEATURE_PORT_BACKLOG.md`](FEATURE_PORT_BACKLOG.md) | Immutable source reference plus license and provenance review | `agent/port-` |
| Build an original SurfShack13 feature | [`CUSTOM_FEATURE_BACKLOG.md`](CUSTOM_FEATURE_BACKLOG.md) | Recorded design, scope, controls, and tests | `agent/feature-` |

Shared workflow and status rules are in [`PROJECT_INSTRUCTIONS.md`](PROJECT_INSTRUCTIONS.md).

## Classification rule

Classify by the implementation's primary origin:

- A reversal of a merged `/tg/station` change remains a restoration even when modernized.
- A feature substantially based on another codebase is an external port even when rewritten for compatibility.
- A new design created for SurfShack13 is a custom feature.

When a task combines multiple origins, split it into separate backlog entries and pull requests whenever they can be reviewed and merged independently.

## Current active work

- Cloning restoration: [`RESTORATION_BACKLOG.md`](RESTORATION_BACKLOG.md), SurfShack13 PR #6.
- Hyper Adrenaline: [`CUSTOM_FEATURE_BACKLOG.md`](CUSTOM_FEATURE_BACKLOG.md), SurfShack13 PR #2.

GitHub documentation and linked pull requests take precedence over prior chat descriptions.