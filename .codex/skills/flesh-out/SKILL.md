---
name: flesh-out
description: Clarify a partial GitHub feature or bug issue through repository research and a requirements interview, then optionally replace the issue with the agreed canonical requirements. Use when invoked as `$flesh-out` with a GitHub issue URL or when the user asks to "flesh out this issue."
---

# Flesh Out

Turn an incomplete GitHub issue into an airtight, implementation-ready specification. Research and clarification are read-only until the user explicitly authorizes canonization.

## Establish scope

1. Require a GitHub issue URL. If the request does not identify exactly one issue, ask for the URL.
2. Determine the repository containing the current working directory with authenticated `gh` commands.
3. Confirm that the target issue belongs to that repository. If it does not, stop and explain that this skill only operates on issues from the repository in which it is invoked.
4. Treat the issue as partial requirements, not as a complete or necessarily correct specification.

Use the authenticated `gh` CLI as the primary interface for GitHub. Inspect the repository and issue before drawing conclusions. Do not modify the issue, repository, or any other external state during research or interviewing.

## Research the issue

Read the issue title, body, comments, labels, state, milestone, and relevant timeline or cross-reference events. Inspect repository code, tests, documentation, and history when they can resolve context or expose constraints.

Follow relevant links to a maximum depth of two:

- The target issue is depth 0.
- Every resource linked from its body, comments, linked issues, pull requests, or other associated GitHub context is depth 1.
- Every resource linked from a depth-1 resource is depth 2.
- Read relevant depth-2 resources, but do not follow links found within them.

Links may point to GitHub resources, repository files, or external documentation. Use `gh` for GitHub content. Skip clearly irrelevant, duplicate, inaccessible, unsafe, or machine-generated navigation links. Record inaccessible material and ask the user only when it prevents a reliable specification.

## Interview the user

Compare the researched evidence with the requested outcome. Identify every material ambiguity, conflict, missing constraint, and undefined behavior. Consider at least:

- user-visible behavior and workflows;
- functional requirements and acceptance criteria;
- edge cases, errors, permissions, and state transitions;
- compatibility, migration, performance, and accessibility where relevant;
- affected interfaces, data, tests, and explicit non-goals.

Ask focused clarifying questions in manageable rounds. Do not silently choose among plausible interpretations, invent requirements, or implement the issue. When an answer exposes another material ambiguity, research as needed and continue the interview. Treat the user's answers as authoritative unless they conflict with another unresolved answer; surface any conflict for resolution.

Finish the interview only when the title and issue body can be rewritten without relying on unstated product decisions. Do not require the user to review a proposed title or body.

## Offer canonization

Once no material clarifying questions remain, ask: "Do you want to make this session canon and replace the original issue's title and body with the clarified requirements?"

- If the user declines, make no GitHub changes and await further instruction.
- If the answer is unclear, ask for an explicit yes or no.
- If the user agrees, that approval authorizes only replacing the target issue's title and body. It does not authorize implementation or any other GitHub mutation.

## Rewrite the issue

After explicit approval, synthesize a concise title and a self-contained issue body that incorporates the original issue, researched evidence, and every resolved interview decision. Replace the old body completely; do not append a clarification section or preserve obsolete wording merely for provenance.

Organize the body for the issue at hand. Include clear requirements and objectively verifiable acceptance criteria, plus relevant constraints, edge cases, and non-goals. Distinguish confirmed behavior from any implementation guidance supported by the repository. Do not introduce new decisions during the rewrite.

Before editing, re-check the repository and issue identity. Use `gh issue edit` to update the title and body together. Then read the issue back with `gh` and report whether the canonical update succeeded.
