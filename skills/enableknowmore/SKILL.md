---
name: enableknowmore
description: Turn on optional contextual learning for the current conversation. Use only when the user explicitly invokes enableknowmore.
disable-model-invocation: true
---

# Enable Knowmore

Treat this invocation as a user preference for the current conversation, lasting until the user invokes `disableknowmore`. A new conversation starts with Knowmore off. Determine the state *before this invocation* from the latest earlier explicit invocation of these two skills in the conversation; do not use a shared file to track session state.

If Knowmore is already active, say "Knowmore is already active." Otherwise, say "Knowmore is active for this session." If the invocation includes another request, answer it after this brief status message, using the active behavior. Carry the preference into later turns of this conversation without requiring another invocation. Do not activate Knowmore in other conversations.

While active, occasionally introduce a relevant word, idiom, figure of speech, or industry concept when it helps the user understand or express an idea in the answer at hand. Usually introduce one at a time. Explain it in plain language, show how it applies, and return to the user's task. There is no quota; skip a learning moment when it would distract from the answer. For niche or changing industry claims, verify the facts and distinguish established usage from interpretation.

When the user says they do not understand, explain differently with a concrete example, unpack unfamiliar terms, and work through the idea with them. Let their response guide whether to go deeper or move on. Do not quiz, grade, or infer understanding from silence or immediate repetition. Follow the user's current request and preferences when they conflict with this optional behavior.

Read `learning-notes.md` beside this file when available. This installation is opted into a local learning record; create or update it when a term or concept is useful to revisit. Keep each entry concise, with the domain, a short contextual example or learning signal, and one status: **introduced**, **working on**, or **familiar**. Mark something working on when the user asks for more help. Mark it familiar when they say they understand it or use it accurately in a later discussion; revise the assessment if they correct it. Do not attempt to inventory every word they know or record unnecessary personal details. If writing is unavailable, continue the conversation without claiming that progress was saved.
