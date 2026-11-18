# Process Task List

Implement tasks from a task list one sub-task at a time: $ARGUMENTS

## Task Implementation

- **One sub-task at a time:** Do NOT start the next sub-task until the user says "yes" or "y"
- **Follow Orchestration:** Each parent task has an **Orchestration** block — follow it exactly:
  1. Run PRE guards before starting
  2. Use specified MCP servers and agents
  3. Activate specified skills
  4. Run POST guards and verify steps after completing
- **Completion protocol:**
  1. When you finish a **sub-task**, mark it `[x]`.
  2. If all subtasks under a parent are `[x]`, mark the parent `[x]` too.
- Stop after each sub-task and wait for user approval.

## Orchestration Execution Protocol

Each parent task has this structure:

```markdown
- [ ] **{NR} {TITLE}**
  - **Orchestration**:
    - _MCP_: {MCP servers and tools}
    - _Agents_: {agents to run}
    - _Guards_: {PRE/POST guards}
    - _Skills_: {skills to invoke}
    - _Verify_: {verification steps}
```

### Execution Order:

1. **PRE Guards** — Run all PRE guards before any work:
   - `payment-guard` → if touching payment code
   - `db-migration-guard` → if DB migration planned
   - `file-size-guard` → if splitting a large file
   - `risk-assessor` → if touching critical paths

2. **Skills** — Activate specified skills (e.g., `superpowers:test-driven-development (optional)`)

3. **Research** — Run specified agents and MCP tools:
   - `Explore` agent → find existing patterns
   - Context7/Documentation MCP → library docs
   - Database MCP → schema info
   - Sequential-thinking → complex problems

4. **Implement** — Execute sub-tasks in order

5. **POST Guards** — After implementation:
   - `language-guard` → check UI text language
   - `db-migration-guard` → verify migration
   - `pre-deploy` (background) → lint, tests, build

6. **Verify** — Execute all verification steps:
   - Build commands
   - Test commands
   - Browser verification (if applicable)

## Task List Maintenance

1. **Update the task list as you work:**
   - Mark tasks as completed (`[x]`)
   - Add new tasks as they emerge

2. **Maintain "Relevant Files" section:**
   - List every file created or modified
   - One-line description per file

## MCP Tools Reference

Use any available MCP tools as specified in the Orchestration block. Common tools:

### Database Operations

- Schema inspection, query execution, migrations, type generation, advisors/linting

### Documentation

- Library docs fetching for implementation guidance

### Problem Solving

- Sequential thinking for complex analysis, debugging, trade-offs

### Verification

- Browser navigation, snapshots, screenshots, interaction testing, console/network checks

### Payments

- Documentation search, product/price verification, payment debugging

## Agents Reference

| Agent                    | When to Use                                                |
| ------------------------ | ---------------------------------------------------------- |
| **Explore**              | Find files, patterns, imports, dependencies before changes |
| **security-engineer**    | Auth, API endpoints, webhooks, access control              |
| **backend-architect**    | API design, DB schema, data flow                           |
| **frontend-architect**   | Components, state management, UX                           |
| **quality-engineer**     | Test strategy, coverage, edge cases                        |
| **performance-engineer** | Queries, bundle size, rendering                            |
| **refactoring-expert**   | Code restructuring, DRY                                    |

## Testing Requirements

- **Run tests after each sub-task:** `{{TEST_CMD}}`
- **Minimum coverage: {{COVERAGE_THRESHOLD}}%**
- Test file naming follows project conventions

### What to Test

- Component rendering
- User interactions
- State changes
- API calls (mocked)
- Error states
- Edge cases

## Error Handling Protocol

When a sub-task fails:

1. **Root cause** — Use Sequential-thinking MCP if available
2. **Check logs** — Database logs, browser console, server logs
3. **Document** in the task list:
   ```markdown
   - [ ] 2.1 Task description
     - BLOCKED: [Issue description]
     - FIX ATTEMPTED: [What was tried]
   ```
4. **Create fix task** if needed:
   ```markdown
   - [ ] 2.1.1 Fix: [Fix description]
   ```
5. **Inform user** — Explain issue and proposed solution

## Blocked Task Protocol

1. Skip to next unblocked task
2. Document why skipped
3. Return when unblocked

## Verification Checklist (per sub-task)

Before marking a sub-task complete:

- [ ] Code compiles (`{{BUILD_CMD}}`)
- [ ] Tests pass with {{COVERAGE_THRESHOLD}}%+ coverage
- [ ] UI correct (browser verification if applicable)
- [ ] No console errors
- [ ] UI text in correct language (if applicable)
- [ ] Task list file updated
- [ ] All orchestration verify steps completed
