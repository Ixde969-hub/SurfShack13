# Shared Surf Feed prototype

Status: experimental prototype for the custom SurfShack13 feature tracked in `docs/CUSTOM_FEATURE_BACKLOG.md`.

## Goal

Test the simplest version of the idea: SurfShack13 does not implement its own recommendation algorithm. Instead, one persistent TikTok or Instagram browser profile is used as the recommendation profile for the server, so activity from the crew changes the platform-provided feed seen later by other players.

## Important technical finding

Opening TikTok or Instagram independently in each BYOND client will **not** create a shared feed. Browser cookies and login state live on each player's machine. A real shared algorithm prototype therefore requires one centrally hosted browser session.

The proposed data flow is:

```text
BYOND clients
    -> Surf shared-feed UI
    -> small Surf session gateway
    -> one persistent remote browser profile
    -> TikTok or Instagram recommendation feed
```

All connected players would control or view that same remote session. The provider's existing recommendation system receives the combined watch, skip, follow, and like behavior.

## Prototype scope

The first prototype should prove only these points:

1. A persistent remote browser profile can remain logged in between sessions.
2. Up to roughly 20 connected clients can view the current feed state.
3. One client's navigation changes what later clients see.
4. Concurrent controls can be serialized so two players do not corrupt the session.
5. Loss of the remote browser or provider page does not block the game server.

It does not need a custom recommender, copied video library, long-term analytics, or polished moderation tools.

## Minimal gateway contract

A separately hosted gateway should expose a very small authenticated interface to the game server:

- `GET /health` — browser and provider status.
- `GET /frame` — current low-resolution browser frame or stream endpoint.
- `POST /input` — serialized click, swipe, key, mute, pause, and navigation commands.
- `POST /reset` — admin-only browser restart while retaining or clearing the persistent profile.

The provider credentials and browser profile must remain on the gateway host. They must never be committed to the repository or sent to BYOND clients.

## Provider experiments

Run TikTok and Instagram Reels as separate experiments. Do not mix both providers into one profile or one test result.

For each provider record:

- whether login survives a gateway restart;
- whether the feed works in the automated/remote browser;
- whether video and audio can be streamed acceptably;
- whether swipe/click controls are reliable;
- whether simultaneous viewers trigger verification or session invalidation;
- whether the recommendation feed visibly changes after shared activity.

## SurfShack13 integration after gateway proof

Only after the gateway works should a game-side UI be added. The game-side implementation should:

- open an optional non-critical browser/TGUI surface;
- display the gateway stream;
- send rate-limited controls through the game server;
- show who currently holds control or use a short command queue;
- provide admins with enable, disable, reset, and emergency-disconnect controls;
- fail closed with an unavailable message when the gateway is offline.

## Validation status

Documentation-only prototype scaffold. No provider login, remote-browser gateway, media stream, BYOND integration, compile, or runtime test has been completed yet.
