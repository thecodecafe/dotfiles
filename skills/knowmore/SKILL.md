---
name: knowmore
description: Control optional contextual learning or list saved concepts by learning status. Use only when the user explicitly invokes knowmore.
disable-model-invocation: true
---

# Knowmore

Recognize lowercase `on`, `off`, `introduced`, `working on`, or `familiar` as the command. Match the two-word command `working on` without requiring quotes.

If the command is missing or invalid, show usage: `knowmore on | off | introduced | working on | familiar`. Leave activation and learning notes unchanged; do not infer a command from an accompanying request.

## Status listings

`introduced`, `working on`, and `familiar` list saved concepts with that status, whether Knowmore is on or off. These commands never toggle activation, update learning notes, or reassess understanding. Only explicit `on` and `off` commands affect activation history.

An optional single angle-bracket block accepts comma-separated `key: value` pairs, for example `knowmore familiar <order by: most recent, limit: 10>`:

- `order by`: `most recent` (default) or `oldest first`, based on the last learning update.
- `limit`: a positive whole number; omit it to list all matches. Sort before limiting.

Use `scripts/list_notes.py` beside this skill to read the local notes and produce the listing. Pass the full listing argument as one safely quoted `--query` value, for example:

```sh
python3 <skill-directory>/scripts/list_notes.py --query 'working on <order by: most recent, limit: 10>'
```

Resolve `<skill-directory>` to this skill's actual directory; never interpolate raw user input into shell code. Show the returned table (concept, domain, learning context, updated time), or its empty-result message. Surface malformed filters or unreadable notes as errors rather than inventing results. Unknown keys, duplicate keys, invalid values, extra text, and malformed brackets are rejected without writes. Dated entries sort before entries with unknown dates in either direction; equal timestamps retain their recorded order.

## Activation

For `on` and `off`, any remaining text is an accompanying request.

For a valid mode, determine the state before this invocation from the latest earlier valid `knowmore on` or `knowmore off` invocation in this conversation. A new conversation starts with Knowmore off. Use conversation context for this setting, not a shared file; do not change other conversations or other active skills.

- `on`: enable the behavior below for this conversation until a later `knowmore off`. Say "Knowmore is active for this session." If it was already on, say "Knowmore is already active."
- `off`: stop the optional learning behavior and preserve the local learning record. Say "Knowmore is off for this session." If it was already off, say "Knowmore is already off."

After the brief status message, answer any accompanying request using the resulting setting. When enabling Knowmore, read the existing local learning notes so the next explanation can build on them. Carry the setting into later turns without requiring another invocation. The acknowledgement confirms the conversation preference; it does not mean any concept has already been taught or saved.

## Learning behavior

While active, use the first substantive answer with a relevant learning opportunity to introduce a useful word, idiom, figure of speech, or industry concept. A question accompanying `on` can be that opportunity. Do not wait for the user to ask what a term means. Explain one useful concept in plain language, connect it to the user's actual task, and then continue the answer.

Keep looking for further learning opportunities as the discussion develops: a new topic, a meaningful design choice, or an unfamiliar distinction can justify another brief explanation. Do not treat the first introduction as fulfilling Knowmore for the rest of the conversation. Routine acknowledgements, command status reports, and simple answers with no useful concept do not require a lesson. Avoid forced vocabulary, repeated explanations of familiar material, and a fixed per-turn quota. For niche or changing industry claims, verify the facts and distinguish established usage from interpretation.

When the user says they do not understand, explain differently with a concrete example, unpack unfamiliar terms, and work through the idea with them. Let their response guide whether to go deeper or move on. Do not quiz, grade, or infer understanding from silence or immediate repetition. Follow the user's current request and preferences when they conflict with this optional behavior.

## Recording learning

While Knowmore is on, save each concept you introduce through this learning behavior to `learning-notes.md` beside this file as part of the same response. This installation is opted into that local record: no additional request or confirmation from the user is needed. An introduction is itself enough evidence for an **introduced** entry; a user reaction is not required. Do not leave a taught concept unrecorded merely because the user has not responded.

Use a Markdown table with columns `Term or concept`, `Domain`, `Status`, `Context or learning signal`, and `Updated at`. Include a concise contextual example or learning signal. Read the current notes before writing, update the matching concept instead of adding duplicates, and use existing knowledge to tailor the explanation. Preserve unrelated entries and do not backfill unreviewed earlier sessions or invent assessments to populate an empty record.

- **introduced**: you explained the concept in context, with no stronger evidence of understanding yet. No response, a topic change, or immediate repetition does not promote it.
- **working on**: the user asks for more explanation or otherwise clearly shows they are still working through the concept. Explain differently and record that signal.
- **familiar**: the user explicitly says they understand it or uses it accurately in a later discussion. Record that evidence; revise the assessment if they later show difficulty.

Repeating a known concept does not reset its status to introduced. Change an existing status only when the conversation supports that change. When Knowmore is off, do not introduce or capture optional learning moments; explicit listing commands remain read-only.

Record `Updated at` as an ISO 8601 UTC timestamp (for example `2026-11-06T20:00:00Z`) from the current system time when an entry is first saved or its status, domain, or learning context changes. Reading, listing, repeating activation, or rewriting unchanged content must not advance it. Preserve old entries when adding the column; use `unknown` for missing historical dates instead of inventing them. Escape literal table-cell pipes as `\|` and keep each entry on one line.

Verify that the intended entry was saved before claiming it was recorded. If writing is unavailable because of the current mode, permissions, or a write failure, still provide the useful explanation and briefly state that this learning moment could not be saved, with the concrete reason. An activation acknowledgement or a planned write is not evidence of persistence.

Do not attempt to inventory every word the user knows or record unnecessary personal details. Knowmore remains driven by conversation instructions, not a background process; retain the explicit on/off state in context without claiming it survives loss of that context.
