# SurfShack13 Project Instructions

These instructions define the repository-backed workflow for restoring, porting, and creating SurfShack13 features.

GitHub is the source of truth. Chat discussions are advisory only. A feature's official category, source, status, implementation branch, testing result, and completion state must be recorded in the repository documentation.

## Work categories

Every feature request must be classified into exactly one primary category.

### 1. `/tg/station` restoration

A restoration reverses or restores behavior changed by an upstream `tgstation/tgstation` pull request.

Eligibility requirements:

- The source `/tg/station` pull request must have been merged.
- Closed-unmerged, rejected, abandoned, draft-only, and joke proposals are excluded.
- The change must be relevant to the current SurfShack13 codebase.
- Historical behavior must be ported to current code rather than blindly reverted.

Track these items in [`RESTORATION_BACKLOG.md`](RESTORATION_BACKLOG.md).

Use branches named `agent/restore-<feature>`.

### 2. External feature port

An external port imports a feature from another SS13 codebase, including HippieStation/Hippiecode, BeeStation, Paradise, Goonstation, or a historical fork.

An external source is acceptable when the feature can be tied to at least one of:

- a merged pull request;
- a specific commit reachable from the source repository's default branch;
- a release or version tag;
- an archived historical branch paired with a specific commit.

For every external port, record:

- source repository;
- immutable source reference;
- original authors when identifiable;
- source license and required notices;
- provenance for code and assets;
- historical behavior being preserved;
- intentional SurfShack13 differences;
- dependencies on systems not present in SurfShack13.

Do not blindly cherry-pick large historical commits. Inspect the feature, identify its required systems, and port it cleanly into the current SurfShack13 architecture.

Track these items in [`FEATURE_PORT_BACKLOG.md`](FEATURE_PORT_BACKLOG.md).

Use branches named `agent/port-<feature>`.

### 3. Custom SurfShack13 feature

A custom feature is designed specifically for SurfShack13 and does not directly restore or port an existing implementation.

Before implementation, record:

- intended gameplay behavior;
- configuration and administrator controls;
- affected systems;
- expected interactions;
- explicit non-goals;
- balance assumptions;
- failure and cleanup behavior;
- testing requirements.

Track these items in [`CUSTOM_FEATURE_BACKLOG.md`](CUSTOM_FEATURE_BACKLOG.md).

Use branches named `agent/feature-<feature>`.

## Required implementation workflow

For every approved item:

1. Read the relevant backlog entry.
2. Inspect all linked source material.
3. Confirm whether current SurfShack13 code already contains some or all of the functionality.
4. Identify later refactors and compatibility concerns.
5. Produce a current-code implementation rather than a blind historical revert or cherry-pick.
6. Preserve unrelated modern fixes and improvements.
7. Use one feature per branch and one feature per pull request.
8. Add automated tests where practical.
9. Compile and run relevant checks.
10. Record the branch, pull request, validation results, limitations, and final status in the appropriate backlog.

## Shared status values

Use these statuses consistently:

- `candidate` — identified but not yet reviewed;
- `reviewing` — source, design, provenance, or compatibility is being investigated;
- `approved` — approved for implementation;
- `in-progress` — an implementation branch or pull request exists;
- `blocked` — waiting on a decision, dependency, asset, provenance answer, or technical prerequisite;
- `completed` — merged into the authoritative SurfShack13 branch;
- `declined` — reviewed and intentionally rejected;
- `superseded` — replaced by another implementation or later feature.

## Scope and write rules

- Do not merge changes without explicit instruction.
- Default implementation pull requests to draft.
- Do not combine unrelated restorations, ports, or custom features.
- Do not remove modern functionality unless the feature specifically requires it and the removal is documented.
- Do not assume code from another SS13 repository is compatible.
- Verify licensing, attribution, and asset provenance before copying external code or assets.
- Clearly distinguish historical behavior from SurfShack13-specific modernization.
- Keep unrelated user changes out of feature branches.
- Update GitHub documentation whenever implementation status changes.

## Pull request body requirements

Whenever a pull request is opened or the user is given a manual upstream PR link, also generate a completed pull request body using the target repository's template. Do not leave placeholder comments or unused changelog prefixes in the finished body.

Use this structure:

```markdown
## About The Pull Request

Describe every gameplay, code, asset, map, configuration, or administrator-facing change included in the pull request. Include the historical source for restorations and ports, intentional SurfShack13 differences, and any known limitations.

## Why It's Good For The Game

Explain the player-facing or administrator-facing benefit and why the change improves SurfShack13. Address balance or compatibility concerns when relevant.

## Changelog

:cl:
<only the applicable changelog entries>
/:cl:
```

Choose only applicable changelog prefixes from `add`, `del`, `qol`, `balance`, `fix`, `sound`, `image`, `map`, `spellcheck`, `code`, `refactor`, `config`, `admin`, or `server`. Changelog wording should describe observable player or administrator impact rather than merely restating implementation details.

## Command shorthand

Requests may use concise instructions such as:

- `Review the next merged /tg/ restoration candidate.`
- `Add this Hippiecode feature to the external port backlog.`
- `Investigate whether this external implementation can be ported cleanly.`
- `Approve the next reviewed external port.`
- `Implement the next approved item on its own branch.`
- `Update all backlog statuses from the current pull requests.`

Repository documentation takes precedence over prior chat descriptions.