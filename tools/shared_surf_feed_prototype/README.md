# Shared Surf Feed prototype

Status: `in-progress` custom SurfShack13 prototype tracked in `docs/CUSTOM_FEATURE_BACKLOG.md` and draft PR #18.

## Selected behavior

Each player receives an independently openable feed window and may browse at their own pace. The multiplayer target is for every player-facing session to use the same completely disposable TikTok account, so independent watches, skips, and likes contribute to one provider-owned recommendation profile. Playback and scroll position are not synchronized.

SurfShack13 does not implement its own recommendation algorithm or copy a media library.

## Implemented game-side scaffold

The prototype adds two OOC verbs:

- **Open Shared Surf Feed** opens a named 480x800 browser window and navigates it to the configured HTTPS URL.
- **Close Shared Surf Feed** closes that named browser window.

The implementation is currently in `surfshack13/code/modules/mob/living/tweak.dm` because that existing SurfShack13 module is already included by `tgstation.dme`. A later cleanup should move it to a dedicated client module and add the corresponding DME include after the prototype is proven.

The runtime URL is read from:

```text
data/shared_surf_feed_url.txt
```

The entire `data/` directory is gitignored. A documented placeholder is provided at `config/shared_surf_feed_url.example.txt`.

Only an HTTPS URL is accepted. Missing, empty, or non-HTTPS configuration produces an unavailable message and does not block the client or game server.

## Validation completed

- CI Suite run `30982521110` completed successfully for game-side head `41093d04d018cc7e269575035ee7a904fe87cd7c`.
- A local BYOND runtime smoke test opened the TikTok homepage and scrolling feed inside the named browser window.
- The same client could not create duplicate named Shared Surf Feed windows.
- Direct single-client playback, scrolling, and TikTok navigation were visibly functional.

This proves the configured URL, BYOND browser surface, and basic TikTok rendering path. It does not prove shared login, simultaneous clients, cookie persistence, or recommendation sharing.

## Multiplayer phase

The selected multiplayer architecture is now a remote-browser gateway:

```text
Player web client
    -> one public HTTPS allocation broker
    -> one independently controlled remote-browser slot
    -> same disposable TikTok account in every slot
    -> provider-owned recommendation algorithm
```

The first gateway scaffold is in `tools/shared_surf_feed_gateway/`. It allocates a fixed remote-browser viewer to each player and releases it when the feed closes or expires. Browser creation and provider login remain operator-managed.

Once deployed, `data/shared_surf_feed_url.txt` should contain only the public gateway URL, not the direct TikTok URL and never an account secret.

## Credential boundary

Never place any of these in DM code, TGUI/FrogUI JavaScript, tracked configuration, changelogs, logs, the runtime URL, or the broker configuration delivered to players:

- account password;
- recovery mailbox credentials;
- two-factor secret or recovery codes;
- passkeys;
- credentials reused by any other account.

Every remote-browser slot must use an empty, replaceable account with no personal information, private messages, payment methods, linked services, or valuable uploads. Recovery and two-factor authentication must remain exclusively under the server owner's control.

A remote browser reduces direct cookie distribution, but it is not a guaranteed watch-only boundary. A player may still reach account controls or obtain broad account access. The security boundary is account disposability and owner-controlled recovery.

## Video-first presentation

The direct TikTok page includes TikTok's own sidebar. SurfShack13 cannot reliably remove or restyle that cross-origin page from the game wrapper.

For gateway sessions:

1. Prefer a narrow mobile viewport and mobile user agent to request a video-first layout.
2. Use the gateway's optional viewer crop only when necessary to hide remaining remote-browser chrome or navigation.

Cropping is presentation only and must never be treated as security.

## Required multiplayer validation

- Open the gateway from at least two actual game clients.
- Confirm each client receives a different browser slot and can browse independently.
- Confirm every slot is logged into the same disposable account.
- Confirm closing one feed releases only that slot.
- Confirm slot exhaustion and gateway failure degrade to an unavailable page.
- Confirm session cookies and login survive the intended browser and reconnect lifecycle.
- Confirm one slot does not invalidate or forcibly control another.
- Confirm combined account activity visibly changes recommendations.
- Record autoplay, sound, keyboard focus, scrolling, mouse behavior, bandwidth, verification challenges, and provider enforcement.
- Intentionally revoke the account sessions and confirm clean recovery or replacement.

## Current limitations

- The allocation broker is a scaffold; no public gateway or browser pool is deployed by this repository.
- No multi-client runtime test has been completed.
- Provider verification, simultaneous-session limits, or policy enforcement may block the architecture.
- Browser-slot URLs and remote sessions require separate HTTPS hosting and operational security.
- No reliable restriction prevents a player from reaching account settings through the remote browser.
- The provider account must be treated as disposable and potentially compromised.

PR #18 must remain draft until the gateway works with multiple simultaneous clients and the results are recorded in the backlog.
