# Shared Surf Feed prototype

Status: `in-progress` custom SurfShack13 prototype tracked in `docs/CUSTOM_FEATURE_BACKLOG.md` and draft PR #18.

## Selected prototype

Each player receives an independently openable browser window. Every window is intended to use the same disposable TikTok or Instagram account, so players may see different current clips while their account-level watches, skips, likes, follows, and other interactions influence one provider-owned recommendation profile.

SurfShack13 does not implement its own recommendation algorithm, copy a media library, or synchronize playback.

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

## Operator setup

1. Create a completely disposable TikTok or Instagram test account.
2. Keep its password, recovery mailbox, passkey, recovery codes, and two-factor secret outside the repository and player browser.
3. Copy `config/shared_surf_feed_url.example.txt` to `data/shared_surf_feed_url.txt`.
4. Replace the placeholder with either:
   - a server-owned bootstrap URL that establishes the disposable provider session and redirects to the provider; or
   - the provider page URL for an initial manual-login test.
5. Restart the game server, then use the OOC open/close verbs.

A bootstrap URL may expose reusable session material to clients. The prototype explicitly accepts that risk. Treat extracted session material as possible full access to the disposable account, not as a watch-only permission.

## Credential boundary

Never place any of these in DM code, TGUI/FrogUI JavaScript, tracked configuration, changelogs, logs, or the bootstrap URL itself:

- account password;
- recovery mailbox credentials;
- two-factor secret or recovery codes;
- passkeys;
- credentials reused by any other account.

The disposable account should contain no personal information, private messages, payment methods, linked services, or valuable uploads. Recovery and 2FA must remain exclusively under the server owner's control.

## Prototype data flow

```text
Player web client
    -> Open Shared Surf Feed
    -> configured HTTPS bootstrap/provider URL
    -> separate player browser session
    -> one disposable provider account
    -> provider-owned recommendation algorithm
```

A centrally streamed remote browser remains a fallback only if the provider prevents simultaneous sessions or if synchronized playback is later desired.

## Required validation

Test TikTok and Instagram independently and record:

- whether the named browser window opens and closes without disrupting gameplay;
- whether the provider permits navigation inside the game web client;
- whether cookies/login survive closing, reopening, and reconnecting;
- maximum simultaneous sessions observed;
- whether one client invalidates another;
- whether verification challenges prevent bootstrap;
- whether multiple clients' interactions visibly change the shared account recommendations;
- autoplay, sound, keyboard focus, scrolling, touch, and mouse behavior;
- account recovery after intentionally extracting and reusing a test session.

## Current limitations

- No real provider account or session is included.
- No bootstrap service is implemented in this repository.
- Browser security or provider policy may prevent session injection or in-window navigation.
- The provider page may redirect to an external tab rather than remain embedded, depending on the web client.
- No compile or runtime validation has been completed for the new verbs yet.
- No reliable restriction prevents an extracted authenticated session from opening account settings.

The PR must remain draft until one provider works with multiple simultaneous clients and the results are recorded in the backlog.
