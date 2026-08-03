# SurfShack13 Restoration Backlog

This file is the source of truth for reviewing and reversing controversial upstream `/tg/station` changes in SurfShack13.

Chat discussions, temporary notes, and reaction rankings are informational only. A restoration is considered approved, active, or complete only when its status is recorded here and linked to repository work.

Last reviewed: 2026-08-03

## Relationship to other backlogs

- Features imported from Hippiecode or another codebase belong in [`FEATURE_PORT_BACKLOG.md`](FEATURE_PORT_BACKLOG.md).
- Original SurfShack13 designs belong in [`CUSTOM_FEATURE_BACKLOG.md`](CUSTOM_FEATURE_BACKLOG.md).
- The feature-work entry point is [`FEATURE_INDEX.md`](FEATURE_INDEX.md).
- Shared development rules are recorded in [`PROJECT_INSTRUCTIONS.md`](PROJECT_INSTRUCTIONS.md).

## Eligibility rules

An upstream change may enter this backlog only when all of the following are true:

1. The source is a **merged** pull request in `tgstation/tgstation`.
2. The change is relevant to the current SurfShack13 codebase.
3. Restoring or reversing it would produce a concrete gameplay, content, balance, interface, or visual change.
4. Implementation is performed as a current-code port or targeted reversal, not as an unreviewed historical commit revert.

Closed-unmerged, rejected, abandoned, draft-only, and joke proposals are excluded.

## Status definitions

| Status | Meaning |
|---|---|
| `candidate` | Eligible merged upstream PR; impact and current-code compatibility still need review. |
| `reviewing` | Historical behavior, later refactors, and current-code compatibility are being investigated. |
| `approved` | User approved implementation after review. |
| `in-progress` | A dedicated SurfShack13 branch or PR exists. |
| `blocked` | Requires a design decision, dependency, missing asset, or upstream investigation. |
| `completed` | Implemented and merged into the authoritative SurfShack13 branch. |
| `declined` | Reviewed and intentionally not being reversed. |
| `superseded` | Replaced by another implementation or later feature. |

## Required workflow

For each approved item:

1. Inspect the merged upstream PR and its merge commit.
2. Identify the exact behavior before and after the change.
3. Check whether later upstream or SurfShack13 work already supersedes it.
4. Write an implementation note describing direct restoration versus modernization.
5. Use one `agent/restore-*` branch and one pull request per item.
6. Compile and run the relevant automated tests.
7. Record the SurfShack13 PR, test result, and final status in this file.

## Active restoration

| Original rank | Upstream PR | Change | Status | SurfShack13 work | Notes |
|---:|---|---|---|---|---|
| 2 | [tgstation/tgstation#48668](https://github.com/tgstation/tgstation/pull/48668) | Completely removes cloning | `in-progress` | [SurfShack13#6](https://github.com/Ixde969-hub/SurfShack13/pull/6) | Functional modern cloning port; full CI reported passing on commit `8f594d04db6b22f631f55c9740ce6f0253ca49e8`. |
| 21 | [tgstation/tgstation#55663](https://github.com/tgstation/tgstation/pull/55663) | Makes shotguns specialist weapons and removes common ammo access | `in-progress` | Draft [SurfShack13#8](https://github.com/Ixde969-hub/SurfShack13/pull/8), branch `agent/restore-cheap-shotgun-ammo` | Restores slug and buckshot printing in all supported lathes at the historical equivalent of two iron sheets per shell. Seven-shell slug and buckshot boxes cost fourteen sheets. Existing 50-damage slugs, buckshot-loaded combat shotguns, and the faster riot-shotgun delay are preserved. Full CI Suite passed on commit `29616c58f25bb2563d045404ed779cd5010315ed` in Actions run `30786025762`; manual in-game lathe UI verification remains pending. |

## Merged upstream candidates from the original top 50

These entries are ordered by their position in the original all-PR thumbs-down ranking. Inclusion means **reviewable candidate**, not automatic approval to revert.

| Rank | Upstream PR | Change | Review class | Status |
|---:|---|---|---|---|
| 1 | [#85491](https://github.com/tgstation/tgstation/pull/85491) | Wallening / tall 3/4-perspective walls | Visual-system reversal | `candidate` |
| 3 | [#52873](https://github.com/tgstation/tgstation/pull/52873) | Removes or disables Tesla, singularity, TEG, and Mrs. Pacman content | Feature restoration | `candidate` |
| 11 | [#92872](https://github.com/tgstation/tgstation/pull/92872) | Downgrades the CE toolbelt from T2 to T1 tools | Balance reversal | `candidate` |
| 13 | [#77169](https://github.com/tgstation/tgstation/pull/77169) | Replaces the Mosin theme with the Sakhno rifle family | Flavor/visual reversal | `candidate` |
| 14 | [#77456](https://github.com/tgstation/tgstation/pull/77456) | Cargo clothing and job resprite | Visual reversal | `candidate` |
| 15 | [#73492](https://github.com/tgstation/tgstation/pull/73492) | Restricts stunbaton stun mode to red alert | Balance reversal | `candidate` |
| 16 | [#94182](https://github.com/tgstation/tgstation/pull/94182) | Removes printable defibrillators and makes compact defib CMO-exclusive | Availability reversal | `candidate` |
| 20 | [#75785](https://github.com/tgstation/tgstation/pull/75785) | Crate resprite | Visual reversal | `candidate` |
| 23 | [#65795](https://github.com/tgstation/tgstation/pull/65795) | Arconomy price, paycheck, gas-export, and lathe-tax overhaul | System redesign review | `candidate` |
| 24 | [#80703](https://github.com/tgstation/tgstation/pull/80703) | Replaces natural beheading with cranial fissures | Mechanic reversal | `candidate` |
| 25 | [#41108](https://github.com/tgstation/tgstation/pull/41108) | Removes integrated circuits | Feature restoration | `candidate` |
| 26 | [#62987](https://github.com/tgstation/tgstation/pull/62987) | Adds pride pins | Content review | `candidate` |
| 27 | [#45377](https://github.com/tgstation/tgstation/pull/45377) | Stunbaton and classic baton rework | Combat-system reversal | `candidate` |
| 28 | [#61917](https://github.com/tgstation/tgstation/pull/61917) | Removes radiation collectors and moves power generation to Tesla coils | Feature/mechanic restoration | `candidate` |
| 29 | [#64280](https://github.com/tgstation/tgstation/pull/64280) | Replaces Cargo autorifles with thermal pistols | Equipment reversal | `candidate` |
| 30 | [#83616](https://github.com/tgstation/tgstation/pull/83616) | Changeling fire vulnerability and armblade nerf | Antagonist balance reversal | `candidate` |
| 31 | [#54533](https://github.com/tgstation/tgstation/pull/54533) | Removes fixed high-value maintenance loot | Map/content reversal | `candidate` |
| 32 | [#76621](https://github.com/tgstation/tgstation/pull/76621) | Reduces station smuggler satchels from ten to two | Availability reversal | `candidate` |
| 34 | [#44530](https://github.com/tgstation/tgstation/pull/44530) | Adds gender-neutral character preferences | Preference/content review | `candidate` |
| 35 | [#71023](https://github.com/tgstation/tgstation/pull/71023) | Routes miner equipment orders through Cargo | Job-loop reversal | `candidate` |
| 36 | [#60473](https://github.com/tgstation/tgstation/pull/60473) | Removes nanites | Feature restoration | `candidate` |
| 37 | [#92486](https://github.com/tgstation/tgstation/pull/92486) | Removes the Justice mech | Feature restoration | `candidate` |
| 41 | [#67181](https://github.com/tgstation/tgstation/pull/67181) | Makes silver-slime food toxic | Balance/content reversal | `candidate` |
| 42 | [#42930](https://github.com/tgstation/tgstation/pull/42930) | Removes most ranged stuns and replaces tasers with disablers | Combat-system reversal | `candidate` |
| 44 | [#54327](https://github.com/tgstation/tgstation/pull/54327) | Removes silver from chemistry dispensers | Resource reversal | `candidate` |
| 45 | [#58407](https://github.com/tgstation/tgstation/pull/58407) | Gives insulating gloves the chunky-fingers restriction | Equipment balance reversal | `candidate` |
| 48 | [#92519](https://github.com/tgstation/tgstation/pull/92519) | Replaces public-garden trays with soil and removes Botany sinks | Map/resource reversal | `candidate` |
| 49 | [#44324](https://github.com/tgstation/tgstation/pull/44324) | Deletes null crates | Feature/content restoration | `candidate` |

## Excluded original top-50 entries

The remaining 20 entries from the original ranking are excluded because they were not merged upstream. They must not be added to this restoration queue unless a different merged PR is identified as the actual source of the live change.

## Command shorthand

Once this file is merged, requests can use concise instructions such as:

- `Review the next restoration candidate.`
- `Approve tgstation/tgstation#60473 for restoration.`
- `Implement the next approved restoration on its own branch.`
- `Update the restoration backlog from the latest SurfShack13 PR state.`

The repository state and this file take precedence over prior chat descriptions.