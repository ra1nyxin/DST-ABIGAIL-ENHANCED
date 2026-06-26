# DST-ABIGAIL-ENHANCED

Enhances Wendy's Abigail in Don't Starve Together.

Current feature set:

- Abigail immediately calls down lightning on her current combat target.
- If that same target stays alive and remains Abigail's active target, it is struck again every 2 seconds.
- Whenever Abigail hits a target, she refreshes a 60 second movement slow that reduces that target's speed by 50%.
- Abigail permanently gains 50% movement speed.
- Abigail's light radius is permanently increased by about 50%.
- Abigail is permanently immune to lightning and fire damage.

Implementation notes:

- Hooks into Abigail's `newcombattarget` and `droppedtarget` events instead of replacing her brain or stategraph.
- Applies the target slow by refreshing a single locomotor speed modifier instead of stacking long-duration slowdown timers.
- Reuses the base game's lightning helpers so wetness, electrocution flow, and electric immunity stay consistent with vanilla behavior.
- Keeps the mod structure small and modular so future Abigail upgrades can be added without rewriting `modmain.lua`.
