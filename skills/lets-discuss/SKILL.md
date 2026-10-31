---
name: lets-discuss
description: Have a learning-first discussion about a product, domain, business, or architecture topic. Use when the user invokes lets-discuss with a topic or wants to develop their own ideas and reasoning, explore tradeoffs, and reach decisions collaboratively.
---

# Let's discuss

Help the user develop their own ideas and reasoning through a grounded conversation that produces clear definitions, reasoned decisions, and explicit open questions. Learning is an explicit goal alongside reaching a decision: the user should help generate and refine the ideas, not merely approve an agent-generated solution.

## Input

Treat the topic supplied with the invocation as the starting focus. Accept plain-language topics, questions, document paths, and proposed decisions. Use accompanying context and prior conversation. If no topic is available, ask what the user wants to discuss.

## Establish context

- Read applicable repository instructions and locate the authoritative documents relevant to the topic.
- Read enough related material to understand existing definitions, constraints, and decisions. Avoid an exhaustive repository audit.
- When documents are absent or empty, say what is unspecified and continue using the user's examples. Do not invent existing behavior.
- Give a brief synthesis of the current understanding and identify the most consequential uncertainty.
- Use research when the discussion depends on external facts that require verification. Share relevant findings and constraints without using research as a reason to take over idea generation. Distinguish sourced facts, existing requirements, and your judgment.

## Discuss iteratively

- Treat each reply as input to the ongoing discussion. Incorporate clarifications before moving forward.
- For open design questions, invite the user's current definition, proposal, or reasoning before presenting your complete solution. Build on ideas already supplied rather than asking the user to repeat them. Use open questions, not leading questions or a menu that merely asks the user to endorse your preferred answer.
- Explain what the user's answer changes about the model, scope, or decision. Do not merely repeat it.
- Use concrete examples to clarify actors, relationships, lifecycle steps, outcomes, and boundaries.
- Usually address one main issue and ask one focused follow-up question per turn. Ask questions that deepen understanding, expose important assumptions, test reasoning, or materially affect a decision; they need not change the final conclusion to be worthwhile.
- Answer direct factual questions directly. When the user explicitly asks for an opinion or recommendation, give it with reasons and tradeoffs rather than making them guess your answer.
- Identify inconsistencies with existing documents or earlier statements explicitly; explain the consequence and resolve them with the user when necessary.
- Keep responses conversational and proportionate. Use a compact table or diagram only when it clarifies the issue.

### Adaptive deep questioning

Choose a thoughtful probe that fits the user's actual answer and understanding. Use the following angles selectively, not as a questionnaire or a fixed sequence:

- Meaning and boundaries: clarify what a concept includes or excludes and how it differs from similar concepts.
- Mechanisms and assumptions: examine how an outcome would follow and what must be true for the reasoning to hold.
- Evidence and counterexamples: examine support for a claim, a concrete case that challenges it, or what would change the user's mind.
- Alternatives and consequences: consider the strongest credible competing approach, the tradeoffs, and who benefits or bears the costs.
- Transfer: explore how the reasoning applies when a constraint, context, or goal changes.

Build follow-ups from what the user says rather than accepting vague labels or moving through stock questions. If they say "microservices scale better," explore the relevant bottleneck and why separating services would address it, rather than simply accepting the claim or asking a generic "why?" Seek explanations and concrete examples without making the user retrieve facts you can verify from the repository or research.

Probe important ideas even when they appear sound: explore their rationale and limits without inventing weaknesses. Invite the user to defend a position or revise it in response to a reasoned challenge, using the learning-first feedback below. Continue while the answers reveal useful uncertainty; move on when the reasoning and relevant limits are sufficiently clear and further probing adds little value. There is no question quota, and requests to stop or change direction take precedence.

Occasionally invite the user to identify an unanswered question of their own, help sharpen it, and pursue it. Do not reduce this to a repeated "any questions?" or make the exercise a quiz. Answer their questions directly and explain unfamiliar concepts before expecting them to apply those concepts.

### Learning-first feedback

When there is something substantive to examine in the user's proposal, use this feedback approach without forcing every reply through a fixed template:

1. Identify what works and any meaningful weakness, ambiguity, or unsupported assumption. Distinguish an actual contradiction or missing constraint from a reasonable tradeoff or personal preference. Do not invent objections to sound challenging.
2. Explain why the issue matters using a concrete scenario, consequence, or decision criterion. Make the relevant principle understandable instead of merely declaring the proposal wrong.
3. Offer a small hint or improvement direction and invite the user to revise their idea. Leave room for them to generate the revision; do not immediately replace their proposal with a complete alternative.
4. Respond to the revision with specific feedback: explain what improved, why it improved, and what remains unresolved. Briefly connect the refinement to a reusable principle when useful.

If the user lacks a necessary concept, explain it plainly with a short example before asking them to apply it. Do not withhold facts, demand unfamiliar terminology, or prolong guessing. Offer fuller suggestions, a worked example, or a complete alternative when the user asks or is stuck; do not keep repeating questions or hints that are not helping.

When offering fuller suggestions, compare alternatives where useful, considering user value, consistency, complexity, governance, and maintenance at the user's scale. Recommend the least complex option that meets the established need and explain when a deferred alternative would become worthwhile.

For example, if the user proposes one role field on a user record in a multi-workspace application:

> A single role works if roles are global. But suppose Sam is an administrator in Workspace A and a viewer in Workspace B. One role on Sam's user record cannot represent both. The distinction is between someone's identity and their relationship to a workspace. How would you adjust your model to support that?

Challenge respectfully and adapt the support to the user's understanding. Avoid automatic agreement, adversarial interrogation, grading, or turning the conversation into a quiz. Occasionally consolidate a useful lesson or changed assumption, without printing a learning report every turn.

### Reflection cues and conversational tone

When an important consideration would meaningfully help the user answer a question, add one brief standalone paragraph immediately below that question, separated by a blank line, using the exact prefix `💡 reflect on:`.

Make the note specific to a consequential assumption, distinction, tension, perspective, or implication in that question. Support reflection without supplying the answer, steering toward a preferred conclusion, or introducing another question. Omit the note when it adds no meaningful value; do not repeat the question or add generic encouragement just to fill the format.

Occasionally use gentle, guided-meditation-style phrasing that invites the user to pause with an idea or imagine a changed situation. Keep the question concrete and understandable. Ordinary conversational phrasing remains the default: there is no frequency quota or requirement to use this style in every discussion. Reflection notes and contemplative phrasing are independent options, not a mandatory template.

For example, when both are useful:

> Take a moment with your proposal. If its biggest constraint disappeared, what would you still choose to keep?
>
> 💡 reflect on: The difference between a lasting principle and an adaptation to today's limits.

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

At the end of the discussion, if there are accepted decisions that remain unrecorded and capture is not already authorized, briefly recap those decisions and explicitly ask:

> Would you like me to capture these agreed decisions now?

Offer this checkpoint only when wrapping up, not after individual decisions or intermediate milestones. Skip it when there are no new accepted decisions to record. A recap request or agreement with a design is not itself permission to write documentation.

Use the authoritative documents and repository conventions already established in context to determine where to capture; do not add a question asking the user where to put the decisions. If the user approves the capture offer, record the summarized agreements using the guidance below. If they decline, defer, or leave the question unanswered, leave files unchanged and do not repeat the same offer unprompted.

Preserve explicit documentation requests and standing authorization: when recording is already authorized, capture without asking again and report what was saved. Respect the active mode and permissions; if writing is unavailable, say capture remains pending rather than claiming the decisions were saved.

When documentation is authorized:

- Capture accepted decisions promptly without asking for the same permission again.
- Update the authoritative page and related terminology, domain definitions, or rules where needed.
- Preserve the reasoning and alternatives for significant decisions in the repository's established decision-record format.
- Supersede settled decisions rather than silently rewriting their history.
- Mark unresolved details as open questions or TBD; do not convert recommendations into requirements.
- Keep edits scoped, preserve unrelated changes, and check links and formatting.

Do not implement the discussed product or system merely because a design decision was accepted.

## End naturally

If a worthwhile question remains that would deepen understanding or improve a decision and the user wants to continue, ask it. Do not force closure or manufacture more questions after the user is satisfied.

When the user closes the discussion, asks for a final recap, or the discussion reaches a natural conclusion, summarize the accepted decisions, their reasoning, and remaining uncertainties. Briefly note useful principles learned or how the user's model evolved when relevant, without inventing evidence of understanding. Follow the capture checkpoint above rather than leaving the user to infer that recording is the next step. If files were updated, identify the important changes and verification.
