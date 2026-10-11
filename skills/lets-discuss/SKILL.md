---
name: lets-discuss
description: Have an iterative discussion about a product, domain, business, or architecture topic. Use when the user invokes lets-discuss with a topic or asks to collaboratively clarify a concept, explore tradeoffs, and reach decisions.
metadata:
  opencode/slash: "true"
---

# Let's discuss

Help the user develop their thinking through a grounded conversation that produces clear definitions, reasoned decisions, and explicit open questions.

## Input

Treat the topic supplied with the invocation as the starting focus. Accept plain-language topics, questions, document paths, and proposed decisions. Use accompanying context and prior conversation. If no topic is available, ask what the user wants to discuss.

## Establish context

- Read applicable repository instructions and locate the authoritative documents relevant to the topic.
- Read enough related material to understand existing definitions, constraints, and decisions. Avoid an exhaustive repository audit.
- When documents are absent or empty, say what is unspecified and continue using the user's examples. Do not invent existing behavior.
- Give a brief synthesis of the current understanding and identify the most consequential uncertainty.
- Use research when the discussion depends on external facts that require verification. Distinguish sourced facts from your judgment.

## Discuss iteratively

- Treat each reply as input to the ongoing discussion. Incorporate clarifications before moving forward.
- Explain what the user's answer changes about the model, scope, or decision. Do not merely repeat it.
- Use concrete examples to clarify actors, relationships, lifecycle steps, outcomes, and boundaries.
- Usually address one main issue and ask one focused follow-up question per turn. Ask only questions that could materially affect the conclusion.
- Answer the user's questions directly. When asked for an opinion, lead with your recommendation, then explain the relevant tradeoffs.
- Give a provisional definition, rule, or example when that makes a question easier to answer.
- Compare alternatives when useful, considering user value, consistency, complexity, governance, and maintenance at the scale the user describes.
- Recommend the least complex option that meets the established need. Explain when a deferred alternative would become worthwhile.
- Identify inconsistencies with existing documents or earlier statements explicitly; explain the consequence and resolve them with the user when necessary.
- Challenge assumptions respectfully. Avoid automatic agreement, adversarial questioning, and forcing the discussion through a fixed questionnaire.
- Keep responses conversational and proportionate. Use a compact table or diagram only when it clarifies the issue.

## Track decisions

Maintain a lightweight distinction between:

- Established context and existing constraints.
- Decisions explicitly accepted by the user.
- Your proposals and recommendations awaiting agreement.
- Assumptions and unresolved questions.

Do not print the full ledger every turn. Surface the relevant distinction when introducing a proposal or summarizing progress.

Treat agreement as acceptance of the specific recommendation under discussion. Do not extend it to unrelated decisions or actions. Preserve accepted decisions unless the user revises them.

Keep tentative terminology tentative. Distinguish intended product behavior from implemented capabilities.

## Capture agreements

Default to discussion in the conversation. Update files when the user requests documentation or existing instructions and authorization establish that agreements should be recorded.

When documentation is authorized:

- Capture accepted decisions promptly without asking for the same permission again.
- Update the authoritative page and related terminology, domain definitions, or rules where needed.
- Preserve the reasoning and alternatives for significant decisions in the repository's established decision-record format.
- Supersede settled decisions rather than silently rewriting their history.
- Mark unresolved details as open questions or TBD; do not convert recommendations into requirements.
- Keep edits scoped, preserve unrelated changes, and check links and formatting.

Do not implement the discussed product or system merely because a design decision was accepted.

## End naturally

If a consequential question remains and the user wants to continue, ask it. Do not force closure or manufacture more questions after the user is satisfied.

When the user closes the discussion or asks for a recap, summarize the accepted decisions and remaining uncertainties. If files were updated, identify the important changes and verification.
