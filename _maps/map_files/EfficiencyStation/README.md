# Efficiency Station port

Source: [tgstation/map_depot, EfficiencyStation](https://github.com/tgstation/map_depot/tree/main/StationMaps/EfficiencyStation).
Original map blob: `18fa19bea26394f74417a9ad5965e5e580507c7c`.
The depot identifies original code revision `2b41743ac83c66e3ff97873e13b950db8a371df5`.
Port baseline: SurfShack13 `742ea89e829ff4c7db122faebd99b680fa46aeb5`.

The original 255-by-255 station footprint is retained. Obsolete items, areas,
turfs, machinery, floor artwork, access lists, job landmarks and atmos-control
links have been migrated to current SurfShack definitions. No legacy object
implementations are reintroduced.

## Significant replacements

- Old numeric access IDs become the corresponding current access strings,
  including ordnance, command, engineering and pharmacy renames.
- The 24 original electrical components use two current cable layers to keep
  adjacent, electrically separate networks from merging. Old cable segments on
  the same tile and network become a single current cable.
- APC numeric battery settings become real battery typepaths. The obsolete
  singularity/particle-accelerator equipment becomes a fueled PACMAN/SUPERMAN
  generator bank and spare uranium. Existing solar arrays remain. This changes
  the main-engine gameplay and needs an engineering playtest.
- The incinerator turbine uses a current inlet compressor, central rotor and
  outlet; its console is linked by mapping ID. The outlet extends one tile along
  the existing exhaust route.
- Atmospheric tanks retain their original gas quantities and temperature.
  Gas monitors, sensors and injectors use the current chamber identifiers.
  Gas filters use gas-type lists rather than obsolete string selections.
- Cloning pods become stasis beds; cloning control/scanning equipment becomes
  current genetics equipment. Retired medicines become their current treatment
  equivalents. Additional landmarks cover coroner, paramedic, psychologist and
  prisoner jobs.
- Missing floor sprites become native floor subtypes and decals, including
  department colors, hazard stripes, loading bays and shuttle titanium panels.
  Old launch-lane numbers use directional stripes.
- Cargo, emergency, ferry, arrivals, mining and escape pods are separate shuttle
  templates. Station ports load them through the current shuttle subsystem.
  Cargo/emergency/ferry spawn at CentCom instead of being embedded in the station.
  The historical premapped syndicate ship and whiteship are removed; current
  game systems supply these ships, and their station docking locations remain.
- The bar uses the native bar-atrium area so service departmental orders have a
  recognized delivery destination. Cook CQC includes that area.

## Testing locally

Build using the repository's usual `BUILD.cmd`. Copy
`_maps/efficiencystation.json` to `data/next_map.json`, then launch the server.
The map is registered for compilation and automatic per-map CI, but is not added
to the server's voting/rotation configuration.

Before enabling it for public rounds, playtest engine startup and SMES charging,
station pressure and scrubbers, department door access, cargo ordering, mining,
arrivals, emergency evacuation and escape-pod destinations. Also inspect legacy
wall-mounted objects and department layouts in-game. A successful compile and
map lint do not establish that an entire round works correctly.
