# External Feature Port Backlog

## The Great Saiyan Race

- Status: `completed`
- Branch: `agent/port-saiyan-race`
- Implementation PR: `Ixde969-hub/SurfShack13#17` (merged)
- Authoritative merge commit: `b500ed30a0e55597030a61c106ad782002ab13b6`
- Upstream fix branch: `agent/port-saiyan-race-upstream-fixes`
- Upstream fix commit: `664b3b2c8cda0e3eea487a6fce701c867ed548fb`
- Source repository: `tgstation/tgstation`
- Source material: `tgstation/tgstation#82347` (`The Great Saiyan Race`, April Fools 2024)
- Source status: closed/unmerged on `/tg/station`; this is not a `/tg/station` restoration.
- Related upstream port PR: `peppyrmynt/SurfShack13#362`
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
- CI Suite run `30931192424` passed the integration tests but failed humanoid screenshot comparison because the monkey-tail DMI replaced the normal `m_tail_monkey_default_*` states, making ordinary monkey tails invisible.
- Commit `12327139dea50dbde50ce8f8df8cb7866e6bb780` restores the normal monkey state names while retaining the separate `m_tail_saiyan_monkey_*` states; it intentionally did not alter the ported frame pixels.
- CI Suite run `30935517205` passed compile, lint, map, organ, and integration checks but still failed the ordinary-monkey screenshot because 24 pixels had also been removed from the original normal-monkey frames by the ported DMI.
- Commit `184fe6dc1c74d4ed8c9d482eba5b6df774553660` restores the eight original normal-monkey frames exactly while preserving the eight separate Saiyan frames and all four DMI state definitions.
- CI Suite run `30937101392` (run 101) passed completely on validation head `26cb53bcbc424ad3a33565a8715b636d4937f954`.
- Commit `664b3b2c8cda0e3eea487a6fce701c867ed548fb` reapplies only the validated five-file correction on top of `ZealousZeke:The-Great-Saiyan` head `ad9e66e42286a90d00ef41f0a59372387262a8bf`; the clean branch is one commit ahead and changes only the four Saiyan runtime files plus `monkey_tail.dmi`.
- PR #17 was merged into the authoritative `master` branch as commit `b500ed30a0e55597030a61c106ad782002ab13b6`.

### Testing Requirements

- Compile with the current SurfShack13 DME.
- Run the normal GitHub integration checks.
- Manually validate Saiyan spawn/species assignment, tail rendering, Ki Blast, flight, at least one random Saiyan skill, power-level examine text, Great Ape transform/revert, and tail sever behavior.

## 7TV image emotes

- **Status:** completed
- **Source repository:** `tgstation/tgstation`
- **Source reference:** closed-unmerged PR #90372, stable head commit `d72fcf2177c44000b350ab4a519b3b937513ff8c`
- **Original author:** `mcbalaam`
- **Implementation branch:** `agent/port-7tv-emotes-sentient`
- **Source license:** GNU Affero General Public License v3.0, matching the codebase lineage.
- **Assets and provenance:** `icons/mob/human/aprilfools_emotes.dmi` and seven OGG files under `sound/effects/aprilfools/`, copied from the source commit above.
- **Historical behavior:** twelve image emotes (`hmm`, `clueless`, `reallymad`, `lmao`, `zorp`, `uncanny`, `xdd`, `noway`, `taa`, `tuh`, `jokerge`, and `fuckingdies`) display an overhead image and selected emotes play audio.
- **SurfShack13 differences:**
  - normal `deathgasp` behavior is preserved; `fuckingdies` is manual only;
  - the emotes are available to sentient living mobs rather than humans only;
  - the current global overlay helper is used for the three-second overhead image;
  - the current emote-help implementation automatically lists usable emotes and bolds those with playable audio.
- **Dependencies:** current living emote registration, global overlay helpers, and the emote audio cooldown system.
- **Validation:** CI compile passed on PR #11. Runtime report on PR #13 branch said the emotes did not appear in `*help`; follow-up PR #14 moved the emotes to the living emote tree and expanded unit coverage. The combined follow-up head passed CI Suite run `30914851681` (run 87) before PR #16 was merged.
- **Pull requests:** #11 and follow-up #14; final combined stabilization merged through #16.
- **Authoritative merge:** PR #16, merge commit `a20db3146dd18082d4b16571d31ba5a31b1989d5`.
- **Limitations:** manual in-game audio, visual overlay, and `*help` verification remains recommended.
