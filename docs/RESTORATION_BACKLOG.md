# SurfShack13 Restoration Backlog

This document is the authoritative tracker for current-code restorations of behavior removed or changed by merged `/tg/station` pull requests.

## Cloning machinery

| Field | Value |
| --- | --- |
| Status | `completed` |
| Source repository | `tgstation/tgstation` |
| Source pull request | `tgstation/tgstation#48668` — **Completely removes cloning** |
| Source merge commit | `a28b24f149702527f3eb22f5c686f06c836f2f99` |
| Implementation branch | `agent/restore-cloning-upstream` |
| Pull request | `peppyrmynt/SurfShack13#372` |
| Review mirror branch | `agent/readd-cloning-final` |
| Review mirror pull request | `Ixde969-hub/SurfShack13#6` |
| Final stabilization pull request | `Ixde969-hub/SurfShack13#16` |
| Authoritative merge commit | `a20db3146dd18082d4b16571d31ba5a31b1989d5` |

### Historical behavior restored

- Living crew can be scanned into persistent cloning records before death.
- A stored record becomes usable after its associated mind no longer has a living body.
- A cloning pod grows a replacement organic body and transfers the original mind into it.
- The clone matures over time, with emergency early ejection retaining unfinished growth trauma.
- Cloning machinery can be constructed through researched console and machine boards.

### Current-code implementation

- Uses the current DNA scanner, mind, DNA, species, machinery, stock-part, trait, power, and research APIs rather than reverting the historical removal commit.
- Preserves copied DNA/species, character name, underwear selections, factions, and mind-bound state.
- Rejects invalid, robotic, dead-at-scan, mindless, or unusable-DNA subjects.
- Prevents duplicate cloning and deletion or replacement of records while a pod cycle is active.
- Protects an immature clone while contained and clears temporary maturation traits on every exit or destruction path.
- Reuses the retained `icons/obj/machines/cloning.dmi` assets: `pod_0` while empty and the animated `pod_g` state while growing a clone.
- PR #16 adds the combined Codex follow-up fixes and usability stabilization for the DNA scanner, automatic cloning queue, pod maturation, and premature-release handling.

### Automated coverage

The cloning round-trip unit test checks record capture, living/dead eligibility, species preservation, body creation, mind transfer, duplicate prevention, maturation protection, healing, ejection, trait cleanup, required DMI state availability, and empty/occupied sprite transitions.

### Validation

- Full fork CI passed for the implementation before the sprite correction on commit `8f594d04db6b22f631f55c9740ce6f0253ca49e8`.
- The corrected sprite implementation and regression assertions passed the complete CI Suite in fork workflow run `30793347520`, including linters, DreamChecker, OpenDream, DMI checks, all-map compilation, Windows and BYOND builds, alternate tests, all station integration-test configurations, screenshot comparison, and the completion gate.
- Upstream workflow run `30793601304` was awaiting external-contributor approval and did not start jobs. This was an upstream permission gate rather than a test failure.
- The final combined stabilization head `c178b2d3c5d7742025374c7a01e0f4d7c1630ed2` passed CI Suite run `30914851681` (run 87) before PR #16 was merged.

### Limitations and completion record

- The feature is constructible through research; this change does not add round-start cloning machinery to station maps.
- PR #16 was merged into the authoritative `master` branch as commit `a20db3146dd18082d4b16571d31ba5a31b1989d5`.

## Cheap printable shotgun ammunition

| Field | Value |
| --- | --- |
| Status | `completed` |
| Source repository | `tgstation/tgstation` |
| Source pull request | `tgstation/tgstation#55663` |
| Implementation branch | `agent/restore-shotgun-ammo-pricing` |
| Final stabilization pull request | `Ixde969-hub/SurfShack13#16` |
| Authoritative merge commit | `a20db3146dd18082d4b16571d31ba5a31b1989d5` |

### Historical behavior restored

- Printable shotgun shells are restored to low material costs instead of the much higher modern prices.
- Single beanbag, rubbershot, slug, and buckshot shells are priced so cargo autolathes display a two-sheet cost.
- Seven-shell slug and buckshot boxes are priced so cargo autolathes display a fourteen-sheet cost.

### Current-code implementation

- Applies the material cost directly to the current autolathe/protolathe design definitions.
- Keeps shotgun ammunition printable from security protolathes and cargo autolathes.
- Avoids late type overrides in the circuit imprinter file.
- PR #16 carries the final security-protolathe and cargo-autolathe pricing corrections into the authoritative branch.

### Validation

- Runtime spot-check reported the shotgun pricing is fixed.
- `git diff --check` passed for the follow-up branch.
- The final combined stabilization head `c178b2d3c5d7742025374c7a01e0f4d7c1630ed2` passed CI Suite run `30914851681` (run 87) before PR #16 was merged.

### Limitations and completion record

- Security protolathe displayed cost can differ from cargo autolathe cost because the two machine families apply different material efficiency coefficients.
- PR #16 was merged into the authoritative `master` branch as commit `a20db3146dd18082d4b16571d31ba5a31b1989d5`.
