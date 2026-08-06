# SurfShack13 Custom Feature Backlog

## Hyper Adrenaline Mode

- **Status:** completed
- **Branch:** `agent/feature-hyper-adrenaline-mode`
- **Source:** peppyrmynt/SurfShack13 PR #370
- **Category:** Custom SurfShack13 feature
- **Final stabilization PR:** `Ixde969-hub/SurfShack13#16`
- **Authoritative merge:** `a20db3146dd18082d4b16571d31ba5a31b1989d5`

### Intended gameplay behavior

Hyper Adrenaline is an optional high-intensity round mode. Admins can enable or disable it before the round starts with **Server -> Toggle Hyper Adrenaline**. The selected next-round state is copied into the active round state at round start and cannot be changed during an active round.

### Configurable values

- Global damage and healing are doubled at round start by multiplying the configured `DAMAGE_MULTIPLIER`, unless the configured multiplier is already at the Hyper Adrenaline threshold of `2`.
- Shared `do_after` action durations use `HYPER_ADRENALINE_ACTION_TIME_MULTIPLIER` of `0.5`.
- Reagent processing uses `HYPER_ADRENALINE_CHEM_EFFECT_MULTIPLIER` of `2`.
- Explosion devastation, heavy, light, flame, and flash ranges use `HYPER_ADRENALINE_EXPLOSION_MULTIPLIER` of `2`.
- Base embedding chance uses `HYPER_ADRENALINE_EMBED_CHANCE_MULTIPLIER` of `2`, capped at 100 before speed and armor modifiers.
- Shared wound-generation damage uses `HYPER_ADRENALINE_WOUND_MULTIPLIER` of `2`.

### Affected systems

- Admin Server tab.
- Round-start state setup.
- Shared damage/healing multiplier.
- Item throwforce.
- Shared action timers.
- Embedding rolls.
- Reagent metabolism and stasis-ignoring reagent processing.
- Wound generation.
- Explosion range argument handling.
- Localized catastrophic trauma activation.

### Expected interactions and balance assumptions

Hyper Adrenaline does not change maximum health, default movement speed, individual melee weapon damage values, or individual projectile damage values. Some effects are intentionally nonlinear: thrown-item hits may receive both doubled throwforce and doubled global damage; chemicals may process faster while also inheriting the global damage/healing multiplier; explosion ranges remain subject to normal caps; faster metabolism may shorten reagent duration. A preconfigured `DAMAGE_MULTIPLIER` of `2` is treated as Hyper Adrenaline active for compatibility with earlier local testing and patch ordering.

### Administrator controls

Admins with Server permissions can select the mode before the round starts. Attempts to toggle it after pregame are rejected. The selected state is announced, logged, and recorded in blackbox admin-toggle feedback.

### Testing requirements

- Confirm **Toggle Hyper Adrenaline** appears in the Server tab.
- Confirm it can be enabled and disabled before round start.
- Confirm it cannot be changed after pregame.
- Confirm round start activates the selected state once.
- Confirm normal rounds retain default damage, action timing, throwforce, embedding, chemistry, wounds, explosions, and catastrophic-trauma gating.
- Confirm Hyper Adrenaline rounds apply the intended multipliers without changing max health or movement speed.
- Confirm existing localized catastrophic trauma only runs while Hyper Adrenaline is active.

### Completion record

The combined stabilization head passed CI Suite run `30914851681` (run 87). PR #16 was then merged into the authoritative `master` branch as commit `a20db3146dd18082d4b16571d31ba5a31b1989d5`.

## Localized Catastrophic Trauma

- **Status:** completed
- **Branch:** `agent/feature-localized-catastrophic-trauma`
- **Pull request:** #12
- **Mode:** Hyper Adrenaline only

### Intended gameplay behavior

Hyper Adrenaline attacks may cause localized catastrophic injuries without adding any new full-body gib paths. Existing established gib mechanics remain unchanged.

### Outcomes

- **Brain ejection/head destruction:** 55 final post-armor damage plus a critical non-burn head wound. Installed head-zone organs are removed intact and remain recoverable. Qualifying blunt, curbstomp, and gun/projectile outcomes can either sever the head as a bodypart or pop/delete the head while spraying blood and dropping the organs. Base chance 15%, scaling by one percentage point per damage above threshold, capped at 45%.
- **Disembowelment:** 55 final post-armor slash or pierce damage plus a critical chest wound. Spills only currently installed chest-zone organs from the living target. No intestines organ or replacement anatomy is added. Base chance 15%, scaling to 45%.
- **Sharp limb severing:** 40 final post-armor slash damage plus a critical wound. Base chance 15%, scaling to 45%.
- **Ballistic/piercing limb destruction:** 50 final post-armor pierce damage plus a critical wound. Base chance 15%, scaling to 45%.
- **Curbstomp:** An unarmed shoe-wearing humanoid attacker has a 25% chance to execute a critical or dead target that still has an attached head and installed brain. The event uses bold combat messages, heavy blood, and the same head severing or head-popping presentation as other catastrophic head trauma.

### Eligible targets and damage sources

Eligibility is based on carbon bodyparts and installed organs, not sentience, `mind`, `client`, or species-name checks. NPC monkeys and other non-sentient full-anatomy carbons are eligible; basic/simple mobs are excluded.

The evaluator is attached to finalized bodypart wound damage, so qualifying melee, projectile, explosion, thrown-debris, and high-speed collision damage share the same rules where those sources produce wounds. Existing full-gib explosions and special mechanics are not intercepted.

### Invariants

- Existing full-gib mechanics remain unchanged.
- This feature introduces no new whole-body gib path.
- Only existing installed organs and bodyparts are moved or removed.
- The brain remains intact and recoverable.
- No generic single-organ ejection.
- Lungs remain one installed lungs object.
- A one-decisecond per-target guard deduplicates pellet clouds and immediate same-impact event chains; it is not player-facing immunity.
- Blood/tissue production is bounded, with heavier bursts for catastrophic head trauma.

### Current implementation state

Direct source implementation was merged through PR #12.

- `code/modules/mob/living/carbon/carbon_defines.dm`
- `code/modules/surgery/bodyparts/wounds.dm`
- `code/_onclick/other_mobs.dm`

The stale `localized-catastrophic-trauma.patch` artifact was removed after reimplementation against the current branch source. The implementation reuses the existing `hyper_trauma_cd` cooldown declared in carbon mob state.

The wound evaluator is called after a new or replacement wound is actually applied and logged, and repeated qualifying damage against an existing critical wound can also trigger the catastrophic roll. It is gated to active Hyper Adrenaline mode, requires a critical wound, uses final incoming wound damage for thresholds, and preserves existing full-body gib behavior.

Curbstomp is integrated through the current unarmed attack chain after normal unarmed attack checks and right-click handling.

PR #13 follow-up fixes align Hyper Adrenaline checks across wound, curbstomp, thrown embedding, reagent, action-timer, and explosion paths. They also treat an already configured damage multiplier of `2` as active Hyper Adrenaline, without multiplying it to `4`, and replace the live disembowelment path with direct installed chest-organ spilling.

PR #13 follow-up fixes also add direct attacker feedback for catastrophic head and chest events, resolve projectile shooters from projectile damage sources, and split catastrophic head removal into severed-head and popped/deleted-head presentations.

The final combined stabilization changes, including martial-art damage integration, projectile and explosion cleanup, and runtime guards, were merged through PR #16 at commit `a20db3146dd18082d4b16571d31ba5a31b1989d5`.

### Validation results

- Static whitespace check: passed with `git diff --check`.
- Full build script: blocked because the local build bootstrap attempted to download Node and network access is unavailable in this Codex session.
- Direct DreamMaker compile: attempted with local BYOND, but did not finish within the available command timeout and produced no compiler artifact or error output.
- Runtime testing: not yet performed.
- PR #13 follow-up local whitespace check: passed with `git diff --check`.
- PR #13 follow-up direct DreamMaker compile: attempted after stopping the local server and removing a stale BYOND lock file, but `dm.exe tgstation.dme` still did not return before the command timeout.
- Combined stabilization head `c178b2d3c5d7742025374c7a01e0f4d7c1630ed2` passed CI Suite run `30914851681` (run 87) before PR #16 was merged.

### Validation requirements

- Compile DreamMaker and run relevant tests/CI.
- Verify normal rounds bypass the evaluator.
- Verify thresholds, critical-wound gates, and the 45% cap.
- Verify no duplicate organs or repeated outcomes from pellet/explosion chains.
- Verify humans, monkeys, lizards, and a non-blood humanoid species.
- Verify brain reimplantation/revival.
- Verify existing full-body gib behavior is unchanged.
- Verify curbstomp on both critical and dead targets.

## Synchronized Station Television

- **Status:** in-progress
- **Branch:** `agent/feature-synced-video-tv`
- **Pull request:** #19
- **Category:** Custom SurfShack13 feature
- **Implementation stage:** Stage 1 technical spike

### Intended gameplay behavior

An administrator can spawn a synchronized television prototype and load one YouTube video into it. Crew within the configured local range may interact with the machine to open a fixed in-client watch surface. Every viewer derives the expected playback position from the same server-owned playback epoch, so late viewers seek to the current shared position rather than starting from the beginning. Leaving the local range closes the interface and stops that client's embedded player.

Stage 1 intentionally proves the browser, synchronization, and proximity model before adding crew submissions, queues, vote skipping, linked channels, map placement, or a browser surface visually anchored over the world map.

### Configurable values

- Viewing range: seven tiles in the prototype.
- Local volume: 100% within two tiles, falling to 15% at the edge of the viewing range.
- Drift-correction interval: fifteen seconds.
- Provider allowlist: YouTube video IDs and common YouTube URL forms only.
- Playback authority: one active video and one server playback epoch per television.

### Affected systems

- Spawnable machinery and machinery interaction.
- TGUI browser rendering and external iframe playback.
- Administrator media controls, logging, and announcements.
- Per-viewer range checks and distance-scaled volume.
- Unit-test discovery for YouTube URL validation.

### Expected interactions and balance assumptions

- Playback is local to users who deliberately interact with the television; it is not sent globally.
- The embedded video is a fixed TGUI watch surface, not a native BYOND sprite texture.
- Browser autoplay may require the viewer to press **Start / Resync** once.
- The prototype does not yet check line of sight or walls and does not create ambient audio for players who have not opened the watch surface.
- The machine uses no power during this technical spike so browser compatibility can be tested independently of mapping and power setup.
- Only one active embedded television is expected per client during Stage 1.

### Administrator controls

Any connected administrator may load a validated YouTube URL or eleven-character video ID and may stop the current video. Load and stop actions are written to the admin log and announced to administrators. The object is available through existing Spawn Atom tooling; no round-start map placement is included.

### Testing requirements

- Compile DreamMaker and the TGUI bundle.
- Run the synchronized-television YouTube-ID unit test.
- Confirm invalid and non-YouTube URLs are rejected server-side.
- Confirm non-administrators cannot load or stop a video.
- Confirm two nearby clients begin at approximately the same shared position.
- Confirm a late viewer seeks to the elapsed server position.
- Confirm periodic correction and manual **Start / Resync** work.
- Confirm moving beyond seven tiles closes playback.
- Confirm distance changes adjust the embedded player's volume.
- Confirm stopping or deleting the television removes active playback.
- Confirm YouTube embedding and unmuted playback function in the supported DreamSeeker browser runtime.

### Current implementation and validation

PR #19 contains the backend machinery, server-side URL parser, unit assertions, fixed TGUI YouTube player, distance-volume updates, and periodic server-timeline seeking. CI Suite run `31077449090` (run 130) passed grep checks, ticked-file enforcement, DreamChecker, OpenDream, map and DMI checks, Windows compilation, all-map compilation, and both configured BYOND artifact builds; its only code failure was Prettier formatting of the new TGUI file. The repository's locked Prettier version then formatted the interface on commit `eaccac7d493ddcae9521e805c65b4ff1dede7c2c`, and a clean full CI run is pending on the documented head. Runtime YouTube embedding, autoplay, two-client synchronization, volume falloff, and range closure still require a DreamSeeker test server. Queueing, crew submissions, vote skipping, line-of-sight occlusion, linked channels, and map-anchored presentation remain explicitly out of scope for this PR.
