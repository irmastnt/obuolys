# Create a Product Requirements Document (PRD)

Create a detailed PRD based on the user's input: $ARGUMENTS

## Goal

Create a detailed Product Requirements Document (PRD) in Markdown format. The PRD should be clear, actionable, and suitable for a senior developer to implement. Every PRD must include orchestration hints for task generation and mandatory risk assessment.

## Process

1. **Receive Initial Prompt:** The user provides a brief description via `$ARGUMENTS`.
2. **Ask Clarifying Questions:** Before writing the PRD, ask clarifying questions to understand the "what" and "why".
3. **Research:** Use available MCP tools and agents to understand existing code, DB schema, and architecture.
4. **Generate PRD:** Based on the prompt, answers, and research — generate the PRD.
5. **Risk Assessment:** Perform mandatory risk assessment (REQUIRED).
6. **Save PRD:** Save as `REQ-YYYY-MM-DD-NNN-[feature-name].md` (where YYYY-MM-DD is today, NNN is next 3-digit number in docs/requirements/) inside the `docs/requirements/` directory.

## Clarifying Questions (Examples)

Adapt questions based on the prompt:

- **Problem/Goal:** "What problem does this feature solve for the user?"
- **Target User:** "Who is the primary user of this feature?"
- **Core Functionality:** "What are the key actions a user should be able to perform?"
- **User Stories:** "Can you provide a few user stories?"
- **Acceptance Criteria:** "How will we know when this feature is successfully implemented?"
- **Scope/Boundaries:** "What should this feature NOT do (non-goals)?"
- **Data Requirements:** "What data does this feature need to display or manipulate?"
- **Design/UI:** "Are there existing mockups or UI guidelines?"
- **Edge Cases:** "What potential edge cases or error conditions should we handle?"

## PRD Structure

1. **Introduction/Overview:** Feature description and the problem it solves.
2. **Goals:** Specific, measurable objectives.
3. **User Stories:** User narratives describing usage and benefits.
4. **Functional Requirements:** Specific functionalities (numbered FR-1, FR-2, ...).
5. **Non-Goals (Out of Scope):** What we're NOT building.
6. **Design Considerations:** UI/UX requirements, mockups, components.
7. **Technical Considerations:** Technical constraints, dependencies, architecture.
8. **Orchestration Hints:** Guidance for the task generation phase (see below).
9. **Risk Assessment (REQUIRED):** See "Mandatory Risk Assessment" section.
10. **Success Metrics:** How success will be measured.
11. **Open Questions:** Remaining questions.

## Orchestration Hints Section

PRD must include an Orchestration Hints section to guide `/generate-tasks`:

```markdown
## Orchestration Hints

### MCP Servers Needed

- {MCP server}: {what operations — migrations, docs, testing}

### Guards Required

- `payment-guard`: {YES/NO — does it touch payment flow}
- `db-migration-guard`: {YES/NO — are there DB migrations}
- `language-guard`: {YES/NO — is there UI text}
- `file-size-guard`: {YES/NO — are large files affected}
- `risk-assessor`: {YES/NO — does it touch revenue-critical paths}

### Suggested Agents

- {agent}: {purpose — design, review, testing}

### Suggested Skills

- {skill}: {purpose}

### Critical Paths Affected

- [ ] Payment/checkout flow
- [ ] Webhook handlers
- [ ] User authentication/authorization
- [ ] Data migrations
- [ ] Email notifications
- [ ] Scheduled jobs/cron
```

## Target Audience

Assume the primary reader is a **senior developer**. Requirements must be explicit and unambiguous.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `docs/requirements/`
- **Filename:** `REQ-YYYY-MM-DD-NNN-[feature-name].md` (where YYYY-MM-DD is today, NNN is next 3-digit number in docs/requirements/)

## MCP Tools Usage

Use any available MCP tools for research:

- **Context7 MCP / Documentation:** Fetch library docs to validate feasibility of proposed approaches.
- **Sequential-thinking MCP:** Use for complex problem analysis and requirement decomposition.
- **Database MCP (Supabase/Prisma/etc.):** Understand existing schema when features involve DB changes.
- **Payment MCP (Stripe/etc.):** Verify payment configuration when features involve transactions.
- **Browser MCP (Playwright):** Inspect current UI state to understand what the feature will extend.

## Agents

Delegate research to specialized agents:

| Agent                    | When to Use                                          | PRD Phase                       |
| ------------------------ | ---------------------------------------------------- | ------------------------------- |
| **Explore**              | Find existing code patterns, components, hooks, APIs | Clarifying Questions, Technical |
| **security-engineer**    | Assess security implications (auth, data access)     | Functional Requirements         |
| **backend-architect**    | Evaluate DB schema, API architecture, data flow      | Technical Considerations        |
| **frontend-architect**   | Evaluate UI architecture, state management, UX       | Design Considerations           |
| **requirements-analyst** | Transform ambiguous requests into specifications     | All phases                      |

## Mandatory Risk Assessment

**After generating the PRD, perform a self-critique phase before presenting to the user.** This is especially critical for production systems.

### Process

1. **Identify critical paths**: For each functional requirement, determine if it touches payment flows, user data, auth, webhooks, or access control.
2. **Read the actual code**: Do NOT assume existing hooks/functions are drop-in replacements. Use Explore agents to compare actual query fields, filters, return types.
3. **Verify data compatibility**: When a task says "replace X with Y", verify Y returns the same fields, applies the same filters, uses the same sort order.
4. **Check import chains**: When splitting files, trace all importers. If a file is imported by API handlers or background jobs, document the full dependency chain.
5. **Flag semantic traps**: Look for values with the same name but different semantics (e.g., cents vs dollars, different status enums across tables).

### Required PRD Section: Risk Assessment

```markdown
## Risk Assessment

### Critical Paths Affected

- [ ] Payment/checkout flow
- [ ] Webhook/callback handlers
- [ ] Authentication/authorization
- [ ] Data migrations (irreversible)
- [ ] Email/notification systems
- [ ] Background jobs/cron
- [ ] Third-party API integrations

### Risk Analysis Per Requirement

| FR # | Risk Level   | What Could Break          | Mitigation          |
| ---- | ------------ | ------------------------- | ------------------- |
| FR-1 | HIGH/MED/LOW | Specific failure scenario | Prevention strategy |

### Assumptions to Verify Before Implementation

- "Hook X returns the same data as query Y" → VERIFY by reading both
- "Function A is only used for display" → VERIFY no formatted value reaches critical path
- "Status values are universal across tables" → VERIFY each table's valid statuses

### Safe Execution Order

Order requirements from lowest to highest risk. Group independent low-risk items first.
```

### Red Flags to Always Check

- **"Replace direct query with existing hook/function"** → Compare: selected fields, WHERE filters, ORDER BY, return type shape
- **"Split file into multiple files"** → Trace: who imports the file? Are importers in API/serverless functions?
- **"Extract shared constant"** → Verify: is the value truly identical across all usages?
- **"Consolidate duplicate functions"** → Check: same input types? Same units? Same edge case handling?
- **"Remove type casts"** → Verify: will generated types actually cover this usage?

## Final Instructions

1. Do NOT start implementing the PRD
2. Ask clarifying questions FIRST
3. Use available MCP tools for research
4. Include Orchestration Hints section
5. ALWAYS perform the Mandatory Risk Assessment
6. ALWAYS read actual source code — never assume based on names alone
7. Reference `docs/AI-TOOLKIT.md` for available tools catalog (if installed)
