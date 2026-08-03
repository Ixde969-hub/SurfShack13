# SurfShack13 External Feature Port Backlog

This file is the source of truth for features proposed for import from SS13 codebases other than the current `/tg/station` upstream, including HippieStation/Hippiecode, BeeStation, Paradise, Goonstation, and historical forks.

Chat discussions and temporary research notes are advisory only. An external port is considered approved, active, blocked, declined, or complete only when that status is recorded here and linked to repository work.

Last reviewed: 2026-08-03

## Relationship to other backlogs

- Merged `/tg/station` reversals belong in [`RESTORATION_BACKLOG.md`](RESTORATION_BACKLOG.md).
- Original SurfShack13 designs belong in [`CUSTOM_FEATURE_BACKLOG.md`](CUSTOM_FEATURE_BACKLOG.md).
- Shared development rules are recorded in [`PROJECT_INSTRUCTIONS.md`](PROJECT_INSTRUCTIONS.md).

## Source eligibility

A proposed external feature must have an immutable, reviewable source. At least one of the following is required:

1. A merged pull request in the source repository.
2. A specific commit reachable from the source repository's default branch.
3. A tagged release containing the feature.
4. An archived historical branch paired with a specific commit SHA.

A floating branch name, screenshot, wiki description, chat recollection, or unmerged proposal is not enough by itself.

## Provenance and licensing gate

Before approval, every port must record:

- source repository;
- source PR, commit, tag, or archived branch and commit;
- original authors when identifiable;
- the source license at the referenced revision;
- compatibility with SurfShack13's license and notice requirements;
- provenance for copied sprites, sounds, fonts, maps, and other assets;
- required attribution or retained notices;
- dependencies on systems that SurfShack13 does not contain.

If licensing or asset provenance is unclear, set the item to `blocked`. Do not copy uncertain code or assets into an implementation branch.

## Status definitions

| Status | Meaning |
|---|---|
| `candidate` | A concrete source exists, but compatibility and design have not been reviewed. |
| `reviewing` | Source code, provenance, dependencies, and current-code compatibility are being investigated. |
| `approved` | Approved for a SurfShack13 implementation. |
| `in-progress` | A dedicated `agent/port-*` branch or pull request exists. |
| `blocked` | Waiting on licensing, provenance, design, dependency, or technical resolution. |
| `completed` | The port has been merged into the authoritative SurfShack13 branch. |
| `declined` | Reviewed and intentionally rejected. |
| `superseded` | Replaced by another implementation or later feature. |

## Port queue

No external ports are currently recorded. Add a row only after identifying a specific feature and immutable source reference.

| Feature | Source repository | Source reference | License/provenance | Status | SurfShack13 work | Notes |
|---|---|---|---|---|---|---|

## Required intake record

Use this structure when adding an item:

```markdown
### Feature name

- **Source repository:** `owner/repository`
- **Source reference:** merged PR, commit SHA, tag, or archived branch plus commit
- **Original authors:**
- **Source license:**
- **Asset provenance:**
- **Historical behavior:**
- **Desired SurfShack13 behavior:**
- **Known dependencies:**
- **Intentional differences:**
- **Status:** `candidate`
- **SurfShack13 branch/PR:** none
- **Validation:** not started
```

## Required implementation workflow

For each approved item:

1. Inspect the exact source revision and surrounding implementation history.
2. Confirm licensing, attribution, and asset provenance.
3. Identify the smallest coherent feature boundary and all required dependencies.
4. Check whether SurfShack13 already contains equivalent or conflicting behavior.
5. Port the behavior into current SurfShack13 architecture rather than blindly cherry-picking historical commits.
6. Preserve unrelated modern fixes and improvements.
7. Use one `agent/port-<feature>` branch and one pull request per feature.
8. Add automated tests where practical and run relevant compile and CI checks.
9. Record intentional differences from the source implementation.
10. Update this file with the branch, pull request, validation result, limitations, and final status.

## Command shorthand

Once this file is merged, requests may use concise instructions such as:

- `Add this Hippiecode feature to the external port backlog.`
- `Investigate the source and dependencies for the next port candidate.`
- `Approve the reviewed external port.`
- `Implement the next approved external port on its own branch.`
- `Update external-port statuses from the current pull requests.`

The repository state and this file take precedence over prior chat descriptions.