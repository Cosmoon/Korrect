# Changelog

## 1.0.8 — 2026-11-17

- Whisper Messenger: spelling checks, autocorrect and word completion work in its message box again. Since Whisper Messenger 2.1.6 Korrect no longer recognized the box and stayed inactive there without an error.
- Works with Whisper Messenger 2.1.8, including its new multi-line message box in Retail.

## 1.0.7 — 2026-11-16

- Retail: misspelled words are colored again, as before 1.0.5. In 12.1 the drawn underline could fail to appear, leaving no marks, no suggestions on click and a fast-blinking caret.
- Retail: spelling checks pause during chat lockdown (boss encounters, Mythic+ runs, rated PvP) and resume when it ends. Korrect never writes to the chat input while chat is locked, so your messages are not blocked.
- If lockdown starts while marked words are in your message, Korrect tells you in chat to retype it if it doesn't send.
- Word completion now appears while typing in Retail too.
- Word completion stays open while you keep typing and narrows as the word grows, instead of closing on every letter. It closes when no words match, when you finish the word, or with Escape.
- Word completion tolerates one typo in what you typed so far: `tets` offers test, testing and tests; `helo` offers help and hello. Exact matches still come first.
- Undoing an autocorrect with Backspace no longer hides the word's mark for the rest of the session. The word just isn't autocorrected again, so it stays colored and you can still pick a correction.
- Missing apostrophes: `dont`, `youre`, `isnt`, `im` are fixed to don't, you're, isn't and I'm (under "Fix a missing or doubled letter or apostrophe"), suggested first when you click the word, and offered by word completion. This also stops wrong fixes such as wasnt → want. Words that are correct without an apostrophe, such as its, cant and wont, are left alone.
- Fixed an error when sending or closing chat that skipped part of the cleanup.
- `/korrect debug`: the spelling self-test line is clearer, it shows why the last word completion did or did not appear, and it lists each word of your last message with why it was or wasn't marked.

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
