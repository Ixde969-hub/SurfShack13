# Shared Surf Feed prototype

Status: experimental prototype for the custom SurfShack13 feature tracked in `docs/CUSTOM_FEATURE_BACKLOG.md`.

## Selected prototype

The first experiment uses **separate player browser sessions logged into one disposable TikTok or Instagram account**.

Each player may receive a different current video because the provider can personalize by device and session, but all account-level watches, skips, likes, follows, and other interactions may contribute to the same provider-owned recommendation profile. This is the behavior SurfShack13 wants to test.

A centrally streamed remote browser is not required for this first experiment. It remains a fallback only if the provider refuses simultaneous sessions or if the game later wants every player to see the exact same video and scroll position.

## Prototype data flow

```text
Player web client
    -> openable/closable Surf feed window
    -> provider web page in that player's browser session
    -> one shared disposable provider account
    -> provider-owned recommendation algorithm
```

## Credential decision

Passwords, recovery codes, email credentials, passkeys, and two-factor secrets must not be committed, obfuscated in client code, or delivered to player browsers.

The prototype may distribute an already authenticated disposable session because the owner has accepted that players may be able to extract and reuse that session. That session must be treated as full account access, not as a reliable watch-only permission.

The disposable account must therefore have:

- a unique password that is not reused anywhere else;
- a recovery email controlled only by the server owner;
- two-factor authentication controlled only by the server owner;
- no personal information, private messages, payment methods, linked services, or valuable uploads;
- no saved recovery email session, password, passkey, recovery code, or two-factor secret in the player-facing browser;
- an account owner who is prepared to revoke all sessions and replace the account if it is altered or lost.

The prototype does not claim that a leaked provider session cannot alter account settings. The security boundary is the disposability of the account and owner-controlled recovery, not password obfuscation.

## Session bootstrap options

Test these in order:

1. **Existing browser session reuse.** Determine whether the Surf web client has a persistent browser profile that can be pre-seeded on the host or retained between reconnects.
2. **Session bootstrap endpoint.** A small server-owned endpoint supplies only the disposable provider session material needed by the embedded browser. It never supplies the password, recovery mailbox, or two-factor secret. This is acceptable only for the prototype because players can potentially extract the session.
3. **Manual login for trusted test clients.** Use this only to validate that simultaneous sessions influence one account before automating session bootstrap.
4. **Remote-browser gateway fallback.** Use only if direct simultaneous sessions fail or the provider repeatedly invalidates them.

## Prototype scope

The first prototype should prove only these points:

1. The game web client can open and close the provider page without disrupting gameplay.
2. Several clients can remain logged into the same disposable account at the same time.
3. Different clients can browse independently while their interactions affect the shared account profile.
4. Login state survives the expected reconnect or browser-window lifecycle.
5. Losing or revoking the disposable account fails cleanly and does not block the game server.
6. The owner can recover the account or replace the prototype session without changing committed code.

It does not need a custom recommender, copied video library, synchronized playback, long-term analytics, or production-grade account security.

## Provider experiments

Run TikTok and Instagram Reels as separate experiments. Do not mix both providers into one account or one result.

For each provider record:

- maximum simultaneous sessions observed;
- whether sessions survive closing and reopening the in-game browser;
- whether sessions survive reconnecting to the game;
- whether unfamiliar clients trigger verification challenges;
- whether one client logs out or invalidates another;
- whether account-level recommendations visibly change after combined activity;
- whether the web page works acceptably inside the Surf web client;
- whether autoplay, sound, keyboard focus, scrolling, and touch/mouse controls behave correctly;
- whether account recovery remains under the server owner's control after intentionally extracting and reusing a test session.

## SurfShack13 integration boundary

The game-side implementation should:

- expose an optional openable and closable browser surface;
- never contain provider passwords or recovery secrets;
- obtain the prototype session from server configuration or a separately hosted bootstrap service;
- keep the feed isolated from critical game UI and keyboard handling;
- provide an admin enable/disable switch and a way to rotate or revoke the prototype session;
- show an unavailable/login-expired message rather than blocking the client or game server.

## Stop conditions

Stop the direct-session experiment and use the remote-browser fallback if:

- the provider consistently prevents simultaneous sessions;
- verification challenges make automatic bootstrap impractical;
- one client repeatedly logs out every other client;
- the provider page cannot function inside the game web client;
- leaked sessions can compromise anything beyond the intentionally disposable account;
- session rotation cannot be performed without exposing password or recovery secrets.

## Validation status

Prototype architecture selected and documented. No provider account, session bootstrap service, game-side browser integration, compile, or runtime test has been completed yet.
