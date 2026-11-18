# Generate a Task List from a PRD

Generate a detailed, step-by-step task list based on a PRD document: $ARGUMENTS

## Goal

Create a detailed, step-by-step task list in Markdown format based on an existing PRD. Each task includes a full **Orchestration** block specifying MCP servers, agents, guards, skills, and verification steps.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `docs/tasks/`
- **Filename:** `tasks-[prd-file-name].md`

## Process

1. **Receive PRD Reference:** The user points to a PRD file via `$ARGUMENTS`.
2. **Analyze PRD:** Read and analyze functional requirements, user stories, and technical considerations.
3. **Research Codebase:** Use Explore agents to understand existing code structure and patterns.
4. **Phase 1 — Parent Tasks:** Generate high-level tasks with full Orchestration blocks. Pause and ask: "Parent tasks generated with orchestration. Reply 'Go' to generate sub-tasks."
5. **Wait for Confirmation.**
6. **Phase 2 — Sub-Tasks:** Break down each parent task into actionable sub-tasks with file paths and line numbers.
7. **Phase 3 — Risk Validation:** Mandatory risk assessment (see section below).
8. **Save Task List.**

## Task Structure Format (REQUIRED)

Every parent task MUST have an **Orchestration** block. Sub-tasks must reference specific files and lines:

```markdown
## Tasks

- [ ] **{NUMBER} {SHORT TITLE}** [BLOCKS: {OTHER_NUMBER}]
  - **Orchestration**:
    - _MCP_:
      - {MCP server name} (`{tool_name}` — {what it's used for})
      - {MCP server name} (`{tool_name}` — {what it's used for})
    - _Agents_:
      - `{agent-role}` ({what it checks or does})
      - `{agent-role}` ({what it checks or does})
    - _Guards_:
      - `{guard-name}` ({PRE / POST / both} — {purpose})
      - `{guard-name}` ({PRE / POST / both} — {purpose})
    - _Skills_:
      - `{namespace:skill-name}`
      - `{namespace:skill-name}`
    - _Verify_:
      - `{build/test command}` — {what it verifies}
      - {testing tool} — {step-by-step what is verified}
      - {testing tool} — {step-by-step what is verified}
  - [ ] {NUMBER}.1 {Exact change description} (`{src/path/to/file.ts}` lines {X-Y}) [BLOCKS: {NUMBER}.2]
  - [ ] {NUMBER}.2 {Related fix} (`{src/other/file.ts}` line {X})
  - [ ] {NUMBER}.3 Add `{ENV_VARIABLE_NAME}` to `.env.example` — {comment}
  - [ ] {NUMBER}.4 Add missing env vars: {list} ({what happens without them})
  - [ ] {NUMBER}.5 Fix {handler}: replace `{current code}` with {what} (`{src/component/file.tsx}`)
  - [ ] {NUMBER}.6 Write tests: {what they verify}
```

### Orchestration Block Rules

1. **MCP** — List ONLY the MCP servers and tools that will actually be used for this task. Use exact tool names with brief explanation.
2. **Agents** — List agents (both built-in and project-specific) to run. Specify exactly what they check.
3. **Guards** — Specify which guardrails to run PRE (before implementation), POST (after), or both:
   - `payment-guard` — payment code changes
   - `db-migration-guard` — database migrations
   - `language-guard` — UI text in correct language
   - `pre-deploy` — before commit
   - `file-size-guard` — splitting large files
   - `risk-assessor` — revenue/critical path changes
4. **Skills** — Which skills to activate (e.g., `superpowers:test-driven-development (optional)`).
5. **Verify** — Specific verification steps: build commands, test commands, browser testing.

### Sub-Task Rules

1. Each sub-task must reference a **specific file** and **lines** (when known).
2. Use `[BLOCKS: X.Y]` for dependencies between sub-tasks.
3. Env vars always in a separate sub-task with comment.
4. Tests always in the last sub-task.
5. Sub-tasks must be granular enough that one sub-task = one clear action.

## Execution Strategy Section (REQUIRED)

Task file must include an Execution Strategy section:

```markdown
## Execution Strategy

PARALLEL GROUP 1 (no dependencies):
+-- Task 1: {description} [MCP: {servers}] [Guard: {guards}]
+-- Task 2: {description} [Agent: {agents}]

SEQUENTIAL GROUP 2 (depends on Group 1):
+-- Task 3: {description} [Skill: {skills}]
+-- Task 4: {description} [MCP: {servers}]

FINAL VERIFICATION:
+-- Task 5: {description} [Guard: pre-deploy, language-guard]
```

## Relevant Files Section

```markdown
## Relevant Files

- `path/to/file.ts` - {why this file is relevant}
- `path/to/file.test.ts` - Tests for `file.ts`

### Notes

- Test files alongside source files
- `{{TEST_CMD}}` to run tests
- Test coverage must be at least {{COVERAGE_THRESHOLD}}%
```

## Task Dependencies

- `[BLOCKS: X.Y]` — this task blocks another
- `[DEPENDS: X.Y]` — this task depends on another
- Use at both parent and sub-task levels

## MCP Tools Usage

### Research Phase (Phase 1)

- **Explore agent** — find existing code patterns, files, dependencies
- **Database MCP** — understand DB schema
- **Context7 / Documentation MCP** — library docs
- **Sequential-thinking MCP** — complex feature decomposition

### Task Generation (Phase 2)

- **backend-architect agent** — API/DB sub-tasks
- **frontend-architect agent** — UI sub-tasks
- **security-engineer agent** — security sub-tasks
- **quality-engineer agent** — testing sub-tasks

### Risk Validation (Phase 3)

- **risk-assessor agent** — critical path analysis
- **Explore agent** — code comparison (replace X with Y)
- **Grep** — importer search (file splitting)

## Mandatory Risk Validation (Phase 3)

**After Phase 2, you MUST perform risk validation.** Critical for production systems.

### Process

1. **Trace critical paths**: For each task modifying payment/auth/webhook/data files, use Explore agents to read source code.

2. **Validate replacement compatibility**: For every "replace X with Y" task:
   - Read BOTH current code and proposed replacement
   - Compare: selected fields, WHERE filters, ORDER BY, return type shapes
   - Document any differences

3. **Verify import chains for file splitting**: For every file-splitting task:
   - Grep for ALL importers
   - Check if importers are in API/serverless directories
   - Ensure backward-compatible imports

4. **Check semantic consistency**: For shared constants/functions tasks:
   - Verify the value/function is truly identical across all contexts
   - Check for table-specific semantics
   - Check for unit differences

5. **Generate Risk Assessment section**:

```markdown
## Risk Assessment

### Risk per Task

| Task | Risk | Impact               | What Could Break     | Mitigation                |
| ---- | ---- | -------------------- | -------------------- | ------------------------- |
| 1    | LOW  | None                 | ...                  | ...                       |
| 3.5  | HIGH | Critical flow broken | Different data shape | Create dedicated function |

### Assumptions Verified

- [ ] Function X returns identical fields to query Y (VERIFIED / NOT VERIFIED)
- [ ] Constant Z is valid for all contexts (VERIFIED / NOT VERIFIED)

### Safe Execution Order

Reorder tasks from lowest to highest risk.
```

### Red Flags That MUST Be Investigated

- **"Replace direct query with existing hook"** → ALWAYS compare field-by-field
- **"Split file into multiple files"** → ALWAYS grep all importers
- **"Extract shared constant"** → ALWAYS verify semantic identity
- **"Consolidate duplicate functions"** → ALWAYS check input types, units, null handling
- **"Remove type casts"** → ALWAYS verify generated types cover the usage
- **"Move function from A to B"** → ALWAYS check if A is used in API/serverless

## Testing Requirements

- Every component and function must have tests
- Test coverage must be at least {{COVERAGE_THRESHOLD}}%
- Use the project's test framework
- Test files should be co-located with source files
- Include test sub-tasks for each implementation task

## Final Instructions

1. Do NOT start implementing — only generate tasks
2. Phase 1 — parent tasks with orchestration → pause for "Go"
3. Phase 2 — sub-tasks with files/lines
4. Phase 3 — risk validation (REQUIRED)
5. Reference `docs/AI-TOOLKIT.md` as orchestration reference
6. ALWAYS read actual source code — never guess based on names
