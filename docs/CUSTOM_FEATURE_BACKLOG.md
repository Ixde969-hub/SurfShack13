# SurfShack13 Custom Feature Backlog

This file is the source of truth for features designed specifically for SurfShack13 that are neither reversals of merged `/tg/station` pull requests nor ports from another codebase.

Chat discussions and temporary design notes are advisory only. A custom feature is considered approved, active, blocked, declined, or complete only when its status is recorded here and linked to repository work.

Last reviewed: 2026-08-03

## Relationship to other backlogs

- Merged `/tg/station` reversals belong in [`RESTORATION_BACKLOG.md`](RESTORATION_BACKLOG.md).
- Features imported from Hippiecode or another codebase belong in [`FEATURE_PORT_BACKLOG.md`](FEATURE_PORT_BACKLOG.md).
- Shared development rules are recorded in [`PROJECT_INSTRUCTIONS.md`](PROJECT_INSTRUCTIONS.md).

## Status definitions

| Status | Meaning |
|---|---|
| `candidate` | Proposed but not yet reviewed in enough detail for approval. |
| `reviewing` | Design, interactions, configuration, and implementation scope are being investigated. |
| `approved` | Approved for implementation. |
| `in-progress` | A dedicated `agent/feature-*` branch or pull request exists. |
| `blocked` | Waiting on a design decision, dependency, asset, or technical prerequisite. |
| `completed` | Merged into the authoritative SurfShack13 branch. |
| `declined` | Reviewed and intentionally rejected. |
| `superseded` | Replaced by another design or implementation. |

## Active custom features

| Feature | Status | SurfShack13 work | Required behavior | Validation/notes |
|---|---|---|---|---|
| Hyper Adrenaline | `in-progress` | [SurfShack13#2](https://github.com/Ixde969-hub/SurfShack13/pull/2), branch `agent/hyper-adrenaline` | While enabled: 2× global damage and healing, thrown-object force, embedding chance, chemical processing/effect speed, wound input, and explosion ranges; 0.5× shared action-bar durations; no maximum-health or default movement-speed changes. | Internal validation PR exists. Keep status `in-progress` until the implementation and checks are reviewed and the authoritative branch receives the change. |

## Candidate custom features

| Feature | Summary | Status | SurfShack13 work | Notes |
|---|---|---|---|---|

## Required design record

Before approving a custom feature, record:

```markdown
### Feature name

- **Problem or opportunity:**
- **Intended gameplay behavior:**
- **Configuration and admin controls:**
- **Affected systems:**
- **Expected interactions:**
- **Explicit non-goals:**
- **Balance assumptions:**
- **Failure and cleanup behavior:**
- **Automated test requirements:**
- **Manual validation requirements:**
- **Status:** `candidate`
- **SurfShack13 branch/PR:** none
```

## Required implementation workflow

For each approved item:

1. Read the recorded design and explicit non-goals.
2. Inspect current SurfShack13 systems affected by the feature.
3. Resolve configuration, administrator controls, lifecycle cleanup, and failure behavior before implementation.
4. Use one `agent/feature-<feature>` branch and one pull request per feature.
5. Keep unrelated balance and refactor changes out of the branch.
6. Add automated tests where practical.
7. Compile and run relevant checks.
8. Record the branch, pull request, validation results, limitations, and final status in this file.

## Command shorthand

Once this file is merged, requests may use concise instructions such as:

- `Add this idea to the custom feature backlog.`
- `Review the Hyper Adrenaline implementation against its recorded requirements.`
- `Approve the next reviewed custom feature.`
- `Implement the next approved custom feature on its own branch.`
- `Update custom-feature statuses from the current pull requests.`

The repository state and this file take precedence over prior chat descriptions.