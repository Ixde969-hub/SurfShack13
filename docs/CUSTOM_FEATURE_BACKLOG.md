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

## Shared Surf Feed

- **Status:** in-progress
- **Branch:** `agent/feature-shared-surf-feed`
- **Pull request:** draft #18
- **Category:** Custom SurfShack13 feature
- **Current game-side head:** `41093d04d018cc7e269575035ee7a904fe87cd7c`

### Intended gameplay behavior

Surf clients expose an optional short-video browser. Players may watch different clips and scroll independently, but every multiplayer browser slot is intended to use one completely disposable provider account so account-level watches, skips, likes, and similar interactions influence one shared provider-owned recommendation profile. Video playback and scroll position are not synchronized.

The selected multiplayer architecture uses one isolated remote-browser slot per player behind a SurfShack13-operated HTTPS allocation gateway. Provider passwords, recovery credentials, passkeys, and two-factor secrets must remain exclusively with the operator and must not be committed or placed in player-visible URLs.

### Configurable values

- Feature enabled or disabled by presence of the runtime URL configuration.
- Public HTTPS gateway URL.
- Number of remote-browser slots.
- Slot allocation timeout and heartbeat interval.
- Remote-browser viewport and mobile user-agent settings.
- Optional viewer crop on each edge.
- Disposable provider account and session-rotation procedure.

### Affected systems

- OOC client verbs and named BYOND browser window.
- Gitignored runtime URL configuration.
- External HTTPS allocation broker.
- External isolated remote-browser pool.
- Provider account/session operations.
- Bandwidth, moderation, logging, and failure handling.

### Expected interactions and balance assumptions

- Each player receives at most one named feed window and one gateway slot at a time.
- Players can browse independently; only the provider account's recommendation state is shared.
- Feed use remains optional and isolated from critical gameplay UI.
- Closing a feed should release only that player's allocation.
- Exhausted, expired, revoked, or offline gateway sessions must fail without blocking the game client or server.
- Mobile layout is preferred for a video-first presentation; visual cropping is not an access-control boundary.
- The disposable account is assumed to be potentially compromised and must contain no personal information, private messages, payment methods, linked services, or valuable uploads.

### Administrator and operator controls

- Enable or disable the feature by adding or removing `data/shared_surf_feed_url.txt`.
- Rotate the gateway URL without changing committed code.
- Start, stop, or reset the allocation broker and browser pool.
- Set the maximum number of simultaneous browser slots.
- Revoke every provider session and replace the disposable account.
- Adjust mobile viewport and crop values.
- Inspect gateway health without logging provider credentials or player cookies.

### Implementation record

The game-side scaffold is implemented in `surfshack13/code/modules/mob/living/tweak.dm` and reads one HTTPS URL from `data/shared_surf_feed_url.txt`. It exposes **Open Shared Surf Feed** and **Close Shared Surf Feed** OOC verbs and uses one named 480x800 browser window per client.

The multiplayer gateway scaffold is implemented under `tools/shared_surf_feed_gateway/`. Its broker allocates a configured remote-browser viewer URL to each browser client with a signed, HTTP-only cookie, maintains the allocation with heartbeats, releases it on close or timeout, and reports clean slot exhaustion. It does not start browsers, log into TikTok, or store provider credentials.

### Validation results

- CI Suite run `30982521110` completed successfully for game-side head `41093d04d018cc7e269575035ee7a904fe87cd7c`.
- Local runtime smoke test: passed. The configured TikTok URL opened in the named BYOND browser, the scrolling feed rendered, and the same client could not create duplicate named feed windows.
- Gateway broker syntax check: passed with Python `py_compile`.
- Gateway broker local allocation smoke test: passed with two dummy HTTPS slots; allocation, signed cookie, heartbeat, and health counts behaved as expected.
- Multi-client game runtime: not yet performed.
- Shared provider-account recommendation behavior: not yet verified.

### Testing requirements

- Deploy at least two isolated remote-browser slots behind valid HTTPS viewer URLs.
- Log every slot into the same empty, disposable provider account.
- Open the gateway from at least two real game clients and confirm each receives a different slot.
- Confirm both players can scroll and like independently without controlling each other's browser.
- Confirm closing and timeout release only the correct allocation.
- Confirm slot exhaustion produces an unavailable page and does not affect the game server.
- Confirm mobile layout or cropping hides unwanted navigation without hiding scroll and like controls.
- Confirm login persistence, verification challenges, concurrent-session limits, and session invalidation behavior.
- Confirm combined interactions visibly alter the shared account's recommendations.
- Confirm no password, recovery credential, two-factor secret, passkey, or reusable provider cookie appears in the repository, runtime URL, player-visible page, or logs.
- Intentionally revoke every account session and verify clean recovery or account replacement.

### Known limitations and blockers

- No public gateway or browser pool is deployed by this repository.
- The broker uses in-memory allocation state and is intended to run as one process during the prototype.
- Browser-slot creation, login, health checks, and cleanup are operator-managed.
- Viewer URLs are delivered to clients and require their own access controls.
- Visual cropping cannot prevent determined access to account settings or session material.
- Provider verification, simultaneous-session limits, policy enforcement, or account suspension may block the design.
- Bandwidth per remote desktop may be too high for production use.
- PR #18 remains draft and must not be merged until a real multi-client gateway test is documented.
