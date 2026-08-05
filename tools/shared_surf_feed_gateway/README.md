# Shared Surf Feed multiplayer gateway scaffold

Status: `in-progress` prototype for draft PR #18.

This directory contains the first multiplayer-facing part of the Shared Surf Feed architecture: a small allocation broker that gives each player one independent remote-browser viewer while all remote browsers are logged into the same disposable provider account.

Players do not need synchronized playback. Different players may see different clips and scroll independently; the provider account is the shared recommendation state.

## What the broker does

- accepts one public HTTPS entry URL for every SurfShack13 client;
- assigns each browser client one fixed remote-browser slot;
- retains the assignment with a signed, HTTP-only cookie;
- releases an allocation when the feed window closes or its heartbeat expires;
- displays a clean unavailable page when every slot is occupied;
- optionally crops the remote viewer for presentation.

The broker does **not** start Chromium, log into TikTok, copy cookies, store provider credentials, or claim that the remote UI is watch-only.

## Required architecture

```text
SurfShack13 player A -> HTTPS broker -> remote browser slot A --\
SurfShack13 player B -> HTTPS broker -> remote browser slot B ----> same disposable TikTok account
SurfShack13 player C -> HTTPS broker -> remote browser slot C --/
```

Each slot must be a separately controllable browser process or container. Log every slot into the same disposable account manually during the prototype. Keep the password, recovery mailbox, passkeys, recovery codes, and two-factor secrets outside the repository and outside player-visible browser sessions.

## Setup

1. Provision at least two isolated remote-browser sessions. A noVNC-capable Chromium container is suitable for testing, but the exact browser host is intentionally not coupled to the broker.
2. Give every slot a distinct HTTPS viewer URL.
3. Use a narrow mobile viewport, approximately `390x844`, and a mobile user agent when the browser host supports it.
4. Log each slot into the same completely disposable TikTok account.
5. Copy `.env.example` to `.env` and replace the placeholder slot URLs and cookie secret.
6. Run the broker behind a public HTTPS reverse proxy:

   ```text
   docker compose -f docker-compose.example.yml up -d --build
   ```

7. Put only the broker's public URL in the game server's runtime file:

   ```text
   data/shared_surf_feed_url.txt
   ```

   Example:

   ```text
   https://feed.example.org/
   ```

The existing game-side OOC verb already opens this URL, so no provider password or cookie belongs in the DM code or runtime URL file.

## Removing the TikTok sidebar

The direct TikTok page is cross-origin, so SurfShack13 cannot reliably delete or restyle TikTok's navigation elements from its wrapper page. The official TikTok player can hide controls for one known video, but it is not the personalized scrolling feed.

The remote-browser path provides two practical presentation controls:

1. **Preferred:** launch the remote browser with a mobile viewport and mobile user agent. This is the least brittle way to obtain a video-first layout.
2. **Fallback:** set `SURF_FEED_CROP_LEFT_PX`, `SURF_FEED_CROP_RIGHT_PX`, `SURF_FEED_CROP_TOP_PX`, or `SURF_FEED_CROP_BOTTOM_PX` to clip the remote viewer.

Cropping is only visual. It does not prevent a determined player from reaching account controls, extracting an authenticated session, or otherwise obtaining broad access to the disposable account. The account must remain empty, replaceable, and recoverable only by the operator.

## Prototype limitations

- Allocations are stored in memory and reset when the broker restarts.
- Run one broker process; multiple replicas do not share allocation state.
- Viewer URLs are present in the delivered page and should themselves use short-lived or otherwise restricted access.
- The broker does not currently authenticate SurfShack13 players or prove that a request originated from the game server.
- Browser-slot creation, profile seeding, health checks, and cleanup are operator-managed.
- Provider verification challenges, concurrent-session limits, and account enforcement may block the experiment.
- A full-width remote desktop may require significant bandwidth per player.

## Validation checklist

- Open the gateway from two real game clients.
- Confirm each receives a different remote browser slot.
- Confirm both slots are logged into the same disposable account.
- Confirm the players can scroll and like independently.
- Confirm one player's close action releases only that player's slot.
- Confirm expired slots become available again.
- Confirm exhaustion produces the unavailable page without affecting the game server.
- Confirm mobile layout or cropping hides the unwanted sidebar without hiding scroll and like controls.
- Confirm no password, recovery credential, two-factor secret, or reusable provider cookie appears in the repository, game logs, runtime URL, or broker logs.

Do not mark the feature completed or merge PR #18 until these multi-client checks are recorded in `docs/CUSTOM_FEATURE_BACKLOG.md`.
