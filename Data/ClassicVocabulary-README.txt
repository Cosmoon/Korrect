WOW CLASSIC ERA & ANNIVERSARY TBC SPELLCHECK – six languages

Game folders: ClassicEra and AnniversaryTBC.
Locales: enUS deDE frFR esES itIT nlNL.
Categories: Locations, Bosses, Spells, Items, Professions, Jargon, Classes.

Lua files populate ns.SpellcheckWords[category], with case-preserved valid terms as keys.
These dictionaries are CURATED STARTER LISTS, not complete spell, item, boss, or NPC data dumps.
TBC contains Classic terms + hand-curated The Burning Crusade additions.
The TBC dataset covers the full original TBC expansion, including later raid phases; content availability on Anniversary servers depends on phase.
German, French, Spanish and Italian are NOT fully translated; they accept English names and include a LIMITED selection of localized additions. Dutch has no official Blizzard locale; nlNL is a community placeholder.
Potentially common aliases and abbreviations may be ambiguous; accepting a word does not imply a unique location.

INTEGRATION:
Each .lua file should be loaded inside an addon .toc. Copy their filenames into your addon .toc in the needed order.
Addon's namespace normally comes from: local addonName, ns = ...
Check words via ns.SpellcheckWords["Locations"]["Stratholme"] == true
For case-insensitive matching implement UTF-8-aware case folding in your spellchecker; plain string.lower in Lua does not handle all accented characters.
To match spaces/apostrophes, do longest phrase matching before individual word spellchecking.
The Example_Load_Order.toc.txt is illustrative only. Use your real client Interface number.
