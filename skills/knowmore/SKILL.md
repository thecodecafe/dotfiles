---
name: knowmore
description: Turn optional contextual learning on or off for the current conversation. Use only when the user explicitly invokes knowmore with on or off.
disable-model-invocation: true
---

# Knowmore

Read the first argument supplied with this invocation as the mode: lowercase `on` or `off`. Any remaining text is an accompanying request.

If the mode is missing or invalid, say "Pass either on or off: knowmore on or knowmore off" and leave the current setting unchanged. Do not infer a mode from the accompanying request. Answer any clear accompanying request using the existing setting.

For a valid mode, determine the state before this invocation from the latest earlier valid `knowmore on` or `knowmore off` invocation in this conversation. A new conversation starts with Knowmore off. Use conversation context for this setting, not a shared file; do not change other conversations or other active skills.

- `on`: enable the behavior below for this conversation until a later `knowmore off`. Say "Knowmore is active for this session." If it was already on, say "Knowmore is already active."
- `off`: stop the optional learning behavior and preserve the local learning record. Say "Knowmore is off for this session." If it was already off, say "Knowmore is already off."

After the brief status message, answer any accompanying request using the resulting setting. Carry the setting into later turns without requiring another invocation.

While active, occasionally introduce a relevant word, idiom, figure of speech, or industry concept when it helps the user understand or express an idea in the answer at hand. Usually introduce one at a time. Explain it in plain language, show how it applies, and return to the user's task. There is no quota; skip a learning moment when it would distract from the answer. For niche or changing industry claims, verify the facts and distinguish established usage from interpretation.

When the user says they do not understand, explain differently with a concrete example, unpack unfamiliar terms, and work through the idea with them. Let their response guide whether to go deeper or move on. Do not quiz, grade, or infer understanding from silence or immediate repetition. Follow the user's current request and preferences when they conflict with this optional behavior.

Read `learning-notes.md` beside this file when available. This installation is opted into a local learning record; create or update it when a term or concept is useful to revisit. Keep each entry concise, with the domain, a short contextual example or learning signal, and one status: **introduced**, **working on**, or **familiar**. Mark something working on when the user asks for more help. Mark it familiar when they say they understand it or use it accurately in a later discussion; revise the assessment if they correct it. Do not attempt to inventory every word they know or record unnecessary personal details. If writing is unavailable, continue the conversation without claiming that progress was saved.
