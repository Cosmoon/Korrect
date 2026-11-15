# Changelog

## 1.0.6 — 2026-11-15

- New Autocorrect tab (the former Replacements tab). Korrect now fixes typos as you type: well-known English typos such as teh and recieve, and your personal replacements, when you finish the word. Autocorrect is on by default; each rule can be switched off on this tab.
- Autocorrect also fixes fast-typing slips: swapped letters (tetsing → testing), a missing or doubled letter (forver → forever, untill → until), and letters hit with a neighbouring key (hwlp → help; two wrong keys in longer words). A word is changed only when exactly one fix fits, or when only one of the possible fixes is a common chat word.
- Press Backspace right after an automatic fix to restore your word; it is then ignored for the session.
- Words fixed automatically briefly light up so you notice the change. The flash never changes your text, so it also works during encounters.
- Autocorrect never changes dictionary words, WoW terms or remembered names, and does nothing while chat is locked.
- Added about 50 common gaming words to the chat vocabulary, such as misclick, keybinds, laggy, relog, despawn, overpull, nerfed, noob, reroll and oneshot.
- Pausing spelling checks is now visible: a chat message when they are paused or resumed (minimap right-click, /korrect off or the settings), a grey minimap icon while paused, and a reminder at login.
- Retail: possible spelling mistakes are much easier to see. Besides the underline, each word now gets a tinted box in your highlight color, like a highlighter pen. It is still drawn over the chat box, so messages are never blocked during encounters.
- Fixed garbled characters in `/korrect help`.
- The settings footer now shows the installed version.

## 1.0.5 — 2026-11-12

- Fixed chat messages being blocked ("Korrect has been blocked from an action only available to the Blizzard UI") during boss encounters, Mythic+ runs and rated PvP in Midnight.
- Retail: misspellings are now underlined in your highlight color instead of coloring the text itself. Korrect never writes to the chat input to show them, so they stay visible everywhere, including during encounters.
- During chat lockdown Korrect does not change your text: applying a correction and word completion wait until the encounter ends. You can still open the suggestions.
- Classic clients keep the colored text as before.
- `/korrect debug` now shows the chat lockdown state.

## 1.0.4 — 2026-11-04

- Language dictionaries are now separate addons (Korrect - Deutsch, Français, Español, Italiano, Nederlands, English (UK)) that load only when enabled. Korrect uses far less memory and loads faster at login.
- Faster typing checks, word completion, and correction suggestions, especially with many remembered names.
- Lighter name tracking in large guilds and friend lists; roster updates are now batched.
- Less background overhead when Whisper Messenger is not installed.

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
