# External Feature Port Backlog

## The Great Saiyan Race

- Status: `in-progress`
- Branch: `agent/port-saiyan-race`
- Source repository: `tgstation/tgstation`
- Source material: `tgstation/tgstation#82347` (`The Great Saiyan Race`, April Fools 2024)
- Source status: closed/unmerged on `/tg/station`; this is not a `/tg/station` restoration.
- Current SurfShack13 PR under review: `peppyrmynt/SurfShack13#362`
- Current porter: ZealousZeke
- Original authors: /tg/station PR authors and contributors, review before final merge
- Source license: AGPL-3.0-compatible `/tg/station` codebase; retain repository license notices
- Assets: Saiyan effects DMI, monkey tail DMI update, gorilla DMI update, and Saiyan humanoid screenshot asset from the source port; verify provenance before final merge

### Historical Behavior

- Adds Saiyans as a non-roundstart species with Saiyan organs, bodyparts, tail visuals, power-level examine text, Ki Blast, flight, Kamehameha, Solar Flare, Kaio-ken, Super Saiyan, Ultra Instinct, and Great Ape transformation from moon/space exposure.
- Saiyans gain combat strength from near-death recovery and lose strength when their tail is removed.
- Great Ape form can be ended by severing the tail.

### SurfShack13 Compatibility Notes

- Port compiles and lint passes on GitHub, but integration tests currently fail from runtime errors.
- The implementation has been hardened against empty-bodypart power-level calculation, missing internal Saiyan body during Great Ape death, and missing tail organs during forced Great Ape tail severing.
- Further validation is required after pushing fixes and rerunning GitHub integration checks.

### Testing Requirements

- Compile with the current SurfShack13 DME.
- Run the normal GitHub integration checks.
- Manually validate Saiyan spawn/species assignment, tail rendering, Ki Blast, flight, at least one random Saiyan skill, power-level examine text, Great Ape transform/revert, and tail sever behavior.
