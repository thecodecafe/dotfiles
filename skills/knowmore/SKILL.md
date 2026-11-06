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

After the brief status message, answer any accompanying request using the resulting setting. Carry the setting into later turns without requiring another invocation.

While active, occasionally introduce a relevant word, idiom, figure of speech, or industry concept when it helps the user understand or express an idea in the answer at hand. Usually introduce one at a time. Explain it in plain language, show how it applies, and return to the user's task. There is no quota; skip a learning moment when it would distract from the answer. For niche or changing industry claims, verify the facts and distinguish established usage from interpretation.

When the user says they do not understand, explain differently with a concrete example, unpack unfamiliar terms, and work through the idea with them. Let their response guide whether to go deeper or move on. Do not quiz, grade, or infer understanding from silence or immediate repetition. Follow the user's current request and preferences when they conflict with this optional behavior.

Read `learning-notes.md` beside this file when available. This installation is opted into a local learning record; create or update it when a term or concept is useful to revisit. Keep each entry concise, with the domain, a short contextual example or learning signal, and one status: **introduced**, **working on**, or **familiar**. Mark something working on when the user asks for more help. Mark it familiar when they say they understand it or use it accurately in a later discussion; revise the assessment if they correct it. Do not attempt to inventory every word they know or record unnecessary personal details. If writing is unavailable, continue the conversation without claiming that progress was saved.
