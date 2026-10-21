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
