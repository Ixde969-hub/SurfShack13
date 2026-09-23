EfficiencyStation local test copy

1. Install BYOND 516.1667 (the version required by this repository).
2. Extract the entire ZIP into a new folder; do not run inside the ZIP or overwrite an existing server.
3. Double-click TRY_EFFICIENCY.cmd. The first build requires internet access and may take several minutes. It builds the game and starts the server on port 1337.
4. Once startup finishes, use BYOND > Open Location and enter byond://127.0.0.1:1337
5. Leave the launcher window open during play. Ctrl+C stops the server.

The launcher selects EfficiencyStation on every launch by copying its configuration to data/next_map.json. This is a source download with a build launcher, not a precompiled executable.

This copy contains the EfficiencyStation port and pipe crossing fixes from commit 2f971de89560f9f270c312388e88470ac7ca9868. It does not combine the separate cloning or shield-potion PRs. The generator setup remains for manual editing. CI and in-game validation are still pending for the newest pipe changes.

Playtest priorities: shuttle docking/travel, station and room pressure, department access, wiring/APCs, and visual layout. Keep error logs if anything fails.
