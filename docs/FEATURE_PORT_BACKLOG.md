# External Feature Port Backlog

## The Great Saiyan Race

- Status: `in-progress`
- Branch: `agent/port-saiyan-race`
- Implementation PR: `Ixde969-hub/SurfShack13#17` (draft)
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

- The implementation has been hardened against empty-bodypart power-level calculation, missing internal Saiyan body during Great Ape death, missing tail organs during forced Great Ape tail severing, and missing/deleted owner during tail transform checks.
- GitHub integration previously failed `organ_sanity` because a standalone Saiyan tail overlay had no sprite datum before species/DNA imprinting.
- Commit `e8eaef533da0dacadd53fd9cbc9ca17752014b4b` initialized the overlay with the Saiyan tail accessory, but CI Suite run 96 showed that generic organ insertion subsequently attempted to imprint a null DNA feature and cleared it.
- Commit `7f9369c99e7d552aa2448b464563b2f66f404daa` keeps the fixed Saiyan tail accessory and disables the later one-time DNA imprint for this single-accessory overlay.
- CI Suite validation is pending for the current PR head.

### Testing Requirements

- Compile with the current SurfShack13 DME.
- Run the normal GitHub integration checks.
- Manually validate Saiyan spawn/species assignment, tail rendering, Ki Blast, flight, at least one random Saiyan skill, power-level examine text, Great Ape transform/revert, and tail sever behavior.

## 7TV image emotes

- **Status:** in-progress
- **Source repository:** `tgstation/tgstation`
- **Source reference:** closed-unmerged PR #90372, stable head commit `d72fcf2177c44000b350ab4a519b3b937513ff8c`
- **Original author:** `mcbalaam`
- **Implementation branch:** `agent/port-7tv-emotes`
- **Source license:** GNU Affero General Public License v3.0, matching the codebase lineage.
- **Assets and provenance:** `icons/mob/human/aprilfools_emotes.dmi` and seven OGG files under `sound/effects/aprilfools/`, copied from the source commit above.
- **Historical behavior:** twelve human emotes (`hmm`, `clueless`, `reallymad`, `lmao`, `zorp`, `uncanny`, `xdd`, `noway`, `taa`, `tuh`, `jokerge`, and `fuckingdies`) display an overhead image and selected emotes play audio.
- **SurfShack13 differences:**
  - normal `deathgasp` behavior is preserved; `fuckingdies` is manual only;
  - the current global overlay helper is used for the three-second overhead image;
  - the current emote-help implementation automatically lists usable emotes and bolds those with playable audio.
- **Dependencies:** current human emote registration, global overlay helpers, and the emote audio cooldown system.
- **Validation:** pending CI compile, DMI/sound checks, invocation checks, help-list visibility, bold audio-emote display, three-second overlay lifetime, and cooldown behavior.
- **Pull request:** pending.
- **Limitations:** manual in-game audio and visual verification remains required after CI.
