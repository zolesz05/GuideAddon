# Data and generator sources

Quest, NPC, item and object data: QuestieDB Forever 1.0.5, from the user-installed artifact.
Original project: https://github.com/Questie/QuestieDB
Original Questie data: https://github.com/Questie/Questie
Data authors (as credited by the source): Muehe, TheCrux (BreakBB), Drejjmit, Dyaxler, Cheeq, TechnoHunter, Yttrium and contributors. QuestieDB code: Logonz.
The existing Moteve Guide identifies its Questie-derived data as GPL-3.0; the new derived route data and generator are provided under GPL-3.0 as well: https://www.gnu.org/licenses/gpl-3.0.html

This archive includes the exact CBOR metadata and zone-map input used, schema descriptions, generator scripts and generated Lua. No Questie gameplay Lua is imported into the addon.
To regenerate: extract, run `python generate_zone_guides.py` from this folder (Python 3.10+; standard library only). Output is MoteveGuide/ZoneGuides.lua. The included QuestieDB folder is offline input, not a playable addon installation.
The three original Horde routes are kept separately in MoteveGuide/Guides.lua; the new generator never changes them.

The generated quest sequence is a general outdoor quest guide. Manual gameplay validation and optimization remain necessary. Actual quest availability can differ by character and client revision.

## RestedXP Forever routes (RXPRoutes.lua)

The `*_rxp` routes (Alliance 1-20, Horde 1-22 and the Mage routes) are adapted from the free WoW Forever guides of RestedXP:
https://github.com/RestedXP/RXPGuides, folder `Guides/forever`, commit 0eed3ea65746da13535b8e71b2070a2690ae0ec6.
Files: Horde-1-12_Mulgore.lua, Horde-01-12_Durotar.lua, Horde-01-14_Undead.lua, Horde-12-22_Barrens.lua, Alliance-1-13_Human.lua, Alliance-1-14_DwarfGnome.lua, Alliance-1-10_NightElf.lua, Alliance-11-20.lua, Horde-Mage-12-21.lua, Alliance-Mage-1-12.lua, Alliance-Mage-12-21.lua, Alliance-ADV-AoE-Mage-1-22.lua.
License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0); the full text is in RXP-LICENSE. Non-commercial use only.
Changes: converted to Moteve Guide steps by `tools/import_rxp.py` (softcore branch only, no dungeon or Season of Discovery steps, WoW text codes removed from the RXP texts, world coordinates converted to zone coordinates with the RXPGuides UiMapAssignment 1.15.9 table) and continued above 20/22 with the existing Moteve routes.
The source files and their LICENSE are kept in `tools/rxp_src/<commit>/`; `python3 tools/import_rxp.py` regenerates `MoteveGuide/RXPRoutes.lua` from them offline. Nothing from the paid RestedXP guides above 20/22 is included.
