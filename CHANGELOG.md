# Changelog

## 1.0.3 — 2026-10-25

- Added automatic WhisperMessenger support for spelling corrections and word completion, with channel settings following the selected conversation.
- Added WhisperMessenger spelling colors, enabled by default and configurable under Typing. Colors may be retained in saved drafts; disable this option to keep its input plain.
- Added Cellular support for character and Battle.net whispers, including its relocated Blizzard input, word completion, and clean Enter/numpad Enter sending.
- Added a registration API for other chat addons to connect their input fields to Korrect.
- Improved discovery of default chat inputs and inputs available after another addon loads.
- WhisperMessenger checks pause when search or paging hides the selected contact row, until its channel can be identified again.

## 1.0.2 — 2026-10-24

- Added spellchecking, corrections, and word completion in WIM message windows.
- Supports WIM whispers (including Battle.net), Guild, Officer, Party, Raid, Battleground, Say, World, custom channels, and Community chat.
- Correction, completion, and settings windows now open above WIM windows, including raised tabs and custom screen layers.
- CurseForge packages use the curated changelog instead of Git history and author email addresses.

## 1.0.1 — 2026-10-23

- Added dedicated Mists of Pandaria Classic vocabulary

## 1.0.0 — 2026-10-23

First public release of Korrect.

- Spellchecking with colored highlights and clickable corrections.
- Word completion with up to three choices after three letters and a short pause.
- Eight language options, with up to two active dictionaries at once.
- Layered WoW vocabulary for Retail, Forever, Classic Era, and TBC Anniversary.
- Temporary recognition of player, NPC, guild, friend, and linked item names.
- Personal dictionary, session ignores, and custom replacement suggestions.
- Configurable chat channels, colors, correction-panel size, and minimap button.
- Native Tab/Enter behavior and item links preserved; no automatic replacement or sending.
- Client compatibility handling for Retail, Forever, Era, TBC Anniversary, Mists of Pandaria Classic.
