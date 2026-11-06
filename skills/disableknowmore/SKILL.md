---
name: disableknowmore
description: Turn off optional Knowmore learning in the current conversation. Use only when the user explicitly invokes disableknowmore.
disable-model-invocation: true
---

# Disable Knowmore

Determine whether Knowmore was active *before this invocation* from the latest earlier explicit invocation of `enableknowmore` or `disableknowmore` in this conversation. A new conversation starts with it off. Do not use a shared file to track session state.

If Knowmore is active, say "Knowmore is off for this session." Otherwise, say "Knowmore is already off." Treat this invocation as the later user instruction: stop the optional learning behavior in subsequent turns of this conversation. Preserve other active skills and the local learning record. If the invocation includes another request, answer it after the brief status message using the conversation's usual behavior.
