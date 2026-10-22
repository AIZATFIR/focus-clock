# Prompt for extracting Antigravity context: Focus Clock

Paste the prompt below into the existing Antigravity conversation with the most Focus Clock history. This is a retrospective and Markdown handoff task only.

```text
Reconstruct the owner's actual intent for Focus Clock and what has already been done. Use the full conversation history available to you, plus relevant plans, walkthroughs, artifacts, and the current repository. Do not interview me, ask follow-up questions, request confirmation, or end by asking me to correct anything. I specifically need you to do the extraction yourself.

Do not implement features or edit application source, tests, configuration, or deployment settings. Your only write should be this Markdown handoff:
docs/handoffs/2026-10-21-focus-clock-owner-intent.md

Evidence rules:
- My direct statements and explicit decisions are the strongest evidence of intent. Preserve short, meaningful quotes when available.
- Separate confirmed owner intent from agent interpretation, suggestions, and generated plans. Silence does not mean approval.
- Track how intent changed. Label old competition/education framing as historical if later owner statements supersede it.
- For implementation, inspect the current source and relevant diffs/history where available. Classify every meaningful item as Verified, Implemented but unverified, Reported by agent only, Partial or unclear, or Not found. Give file paths, symbols/lines, commits, checks, or artifact references as evidence.
- Do not claim you read a conversation or artifact you could not access. If older messages are unavailable, state that limitation and distinguish evidence-based findings from gaps. Do not ask me to supply anything.
- Do not include secrets, credentials, unrelated personal data, or raw logs.

Focus Clock's owner has stated the following in the current project discussion. Treat these as confirmed owner context, while using the older Antigravity history to recover more detail and execution evidence:
- The core function is “visualize.”
- The app should make a person's real goal visible and memorable. A simple goal text on the phone launcher or lock screen may serve this better than a complicated interface.
- The clock face should visualize how the day is being spent, what the person is doing now, and what they should do next in relation to that goal.
- The UI has become complicated and currently obscures the purpose; the experience is not yet finished.
- People forget, drift, and are strongly shaped by the sensory inputs around them. The product should help stabilize life between meaningful long-term effort and immediate pleasure, without treating either extreme as the answer.
- The owner's spiritual grounding is Tauhid and the understanding of God as Ar-Rahman and Ar-Rahim: guidance that protects people from harm and decline. Preserve this meaning accurately and respectfully; do not turn it into generic productivity copy or guilt.
- The concept paper contains the original core. Education and competition requirements were adaptations for a past competition that was rejected; the current direction is everyday usefulness and benefit.

Create a concise handoff with these sections:
1. Confirmed owner intent and meaningful quotes
2. Product evolution: original purpose, changes over time, current direction
3. Intended experience: goal visibility, clock face, today/now/next, and UI hierarchy
4. Product principles and tone, including the owner's stated spiritual grounding
5. Confirmed decisions vs. agent proposals or assumptions
6. Work already executed: status classification and evidence
7. Partial, unfinished, superseded, rejected, or not-found work
8. Material unknowns (write “Unknown / needs owner confirmation”; do not ask questions)
9. Acceptance criteria for the next design and development pass
10. One smallest useful next step grounded in confirmed intent

Make the handoff usable by a new agent with no access to this conversation. Keep claims traceable and concise. If a source is inaccessible, name it and say what you could inspect instead. Finish after saving the Markdown file; do not ask me anything.
```

## Use

1. Open the existing Antigravity conversation with the main Focus Clock history.
2. Paste the entire prompt above.
3. Let Antigravity inspect the available history and repository, then save the handoff Markdown file.
4. Bring the file here for an evidence check against the current project.
