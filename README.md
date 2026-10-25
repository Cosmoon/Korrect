# Korrect: Chat Spellchecker & Word Completion

Type with confidence in World of Warcraft. Korrect checks your spelling as you type, offers corrections, and helps you finish words, all without leaving the game.

## Spellchecking that fits your chat

Possible spelling mistakes appear in a different color. Click a marked word to see corrections, add it to your personal dictionary, or ignore it for the current session.

Korrect preserves item links and removes its highlight formatting before your message is sent.

## Complete words while typing

After three letters and a short pause, Korrect offers up to three word completions. Click a suggestion to finish the current word.

Suggestions use your selected languages, WoW vocabulary, personal dictionary, and recognized names.

## Your languages, your game version

Choose up to two spelling languages at the same time:

- English (US and UK)
- German
- French
- Spanish (Spain)
- Italian
- Dutch (Netherlands and Belgium)

Layered WoW dictionaries recognize locations, bosses, spells, items, classes, professions, and community shorthand. Korrect automatically selects the vocabulary for Retail, Forever, Classic Era, TBC Anniversary, or Mists of Pandaria Classic.

The game dictionaries are curated lists, not complete game databases. Localized names and translations may be incomplete.

## Recognize familiar names

Optional session recognition helps avoid unnecessary spelling warnings for:

- Your character, party members, and raid members
- NPCs you target or mouse over
- Guild members and friends
- Available WoW character names from Battle.net friends
- Item names encountered in chat links

Up to 2,000 names are remembered temporarily. They are cleared when you log out, reload, or choose to forget them. Chat messages are not saved.

## Personal replacements

Create your own shortcuts, such as:

```text
invv = invite
brbb = be right back
```

Your replacement appears as a suggestion when you type the shortcut.

## Make it yours

- Select which chat channels to check
- Customize highlight colors and correction-panel size
- Enable or disable word completion
- Manage your personal dictionary and replacements
- Show, hide, or move the minimap button

## Getting started

Open `/korrect`, click the minimap button, or find Korrect in the game’s AddOns settings.

| Command | Action |
| --- | --- |
| `/korrect` | Open settings |
| `/korrect on` | Enable spelling checks |
| `/korrect off` | Pause spelling checks |
| `/korrect minimap` | Toggle the minimap button |
| `/korrect add word` | Add a personal word |
| `/korrect debug` | Show client and vocabulary information |

Supports standard Blizzard chat boxes and WoW Instant Messenger (WIM) message windows: whispers (including Battle.net), Guild, Officer, Party, Raid, Battleground, Say, World, custom channels, and Community chat. Each uses the matching Korrect channel setting; World, custom channels, and Community chat share the General/Trade/other channels setting. Spelling checks and word suggestions run locally using bundled dictionaries, no external service or separate dictionary addon is required.

Korrect checks spelling, not grammar. Support for other chat-input replacements depends on the addon.
But can confirm it's working with WoW Instant Messenger and Chattynator.

## Other chat addons

WIM, WhisperMessenger, and Cellular are supported automatically. Cellular reuses
the Blizzard chat input, including when it is moved into a Cellular window.
Character and Battle.net whispers follow Korrect's **Whispers** setting and the
normal color option in **General**. Corrections and word completion work in both
window and tab layouts; Cellular's history-copy field is left untouched.

WhisperMessenger supports word completion and right-click corrections without changing its
addon files. Colored misspelling highlights are enabled by default. To keep its
input plain, turn off **Color spelling mistakes in WhisperMessenger** under
`/korrect` > **Typing**. WhisperMessenger may retain highlight colors in saved
drafts when this option is enabled. The global color option in **General** must
also be enabled for colors to appear. The current channel is
read from the selected contact row. If search or paging removes that row,
checks pause until the selected row is available again.

Other addons can opt in through the `Korrect` global API once Korrect has loaded
(check `ADDON_LOADED` if needed):

```lua
if Korrect and Korrect.RegisterChatBox then
    Korrect.RegisterChatBox(input, {
        chatType = function() return selectedContact.channel end,
    })
end
```

Use a channel string such as `"WHISPER"`, or a function returning the current
WoW channel when the input is shared between conversations. A missing channel
disables checks. Registration is idempotent and preserves existing scripts.
It also works before Korrect finishes initializing its chat hooks.

Registered inputs keep plain text by default, so draft saving, character limits
and send buttons receive no Korrect color tags. Right-click a word for
corrections; word completion remains available. Search and note inputs are
never automatically registered.

An integration may opt into `highlights = true` only if it controls every text
consumer: read drafts/messages with `Korrect.GetRawText(input)` (text and byte
cursor), and call `Korrect.PrepareChatBox(input)` before send handlers, draft
snapshots or conversation changes. Script hooks alone cannot guarantee cleanup
before another addon's handlers run.
