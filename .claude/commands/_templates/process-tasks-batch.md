# Batch Task List Processing

Process task list in batch mode — complete entire main tasks without per-subtask permission: $ARGUMENTS

## How It Works

- **Permission requested only for main tasks** (e.g., 1, 2, 3)
- **Subtasks completed automatically** (e.g., 1.1, 1.2, 1.3) without stopping
- **Orchestration followed exactly** — PRE guards, MCP, agents, POST guards, verify
- After completing all subtasks, pause and ask permission for next main task

## Workflow Steps

1. **Identify next incomplete main task**

2. **Read its Orchestration block** — understand required tools, agents, guards, skills

3. **Ask user for permission:**

   ```
   Can I start task {NR} "{Main Task Name}" and complete all sub-tasks ({NR}.1, {NR}.2, ...)?

   Orchestration:
   - MCP: {servers}
   - Guards: {guards}
   - Skills: {skills}
   ```

4. **Execute Orchestration Protocol:**

   **PRE Phase:**
   - Run all PRE guards from Orchestration
   - Activate specified skills
   - Launch research agents

   **IMPLEMENT Phase:**
   - Complete ALL subtasks sequentially
   - Mark each subtask `[x]` as completed
   - Use specified MCP tools throughout

   **POST Phase:**
   - Run all POST guards
   - Execute all Verify steps
   - Run `pre-deploy` in background (if available)

5. **Mark main task `[x]`**

6. **Report completion:**

   ```
   Task {NR} "{Main Task Name}" complete!

   Completed sub-tasks:
   - [x] {NR}.1 ...
   - [x] {NR}.2 ...

   Orchestration results:
   - Guards: {status per guard}
   - Verify: {build/test/lint status}

   Continue with task {NEXT_NR} "{Next Task Name}"?
   ```

## Orchestration Execution in Batch Mode

### PRE Guards (before first sub-task)

```
BATCH START (Main Task X):
  1. Read Orchestration block
  2. Run PRE guards:
     - payment-guard → if touching payments
     - db-migration-guard → if DB migration
     - file-size-guard → if splitting large file
     - risk-assessor → if critical path
  3. Activate skills
  4. Launch Explore agent — find all relevant files
  5. Sequential-thinking — plan execution order
```

### IMPLEMENT (sub-tasks X.1, X.2, ...)

```
BATCH EXECUTE:
  For each sub-task:
    1. Read specified file and lines
    2. Use MCP tools as specified
    3. Launch agents as needed
    4. Implement the change
    5. Quick verification (compile check)
    6. Mark sub-task [x]
```

### POST Guards + Verify (after last sub-task)

```
BATCH VERIFY:
  1. Run POST guards:
     - language-guard → UI text check
     - db-migration-guard → post-migration check
  2. Execute Verify steps:
     - {{BUILD_CMD}} → compilation
     - {{LINT_CMD}} → 0 errors, 0 warnings
     - {{TEST_CMD}} → all tests pass
     - Browser snapshot → UI verification (if applicable)
  3. Run pre-deploy agent (background, if available)
  4. security-engineer agent → review (if applicable)
```

## Important Rules

- **All standard task processing rules apply:**
  - Mark tasks as completed (`[x]`)
  - Update "Relevant Files" section
  - Use MCP tools, Agents, Guards, and Skills as specified

- **Error handling within batch:**
  - If a subtask fails, document the issue
  - Use Sequential-thinking to diagnose
  - Continue to next subtask if possible
  - Report all issues at end of main task
  - If critical blocker (data loss/payment risk), STOP and inform user

- **Guard failures:**
  - If PRE guard identifies HIGH risk → STOP and inform user
  - If POST guard identifies issues → fix before marking complete
  - Never skip guards to save time

## MCP Tools in Batch Mode

| MCP Server              | Batch Usage                                                                                                          |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Database**            | Schema check at start. Migrations for DDL. Queries for verification. Type generation after changes. Advisors at end. |
| **Documentation**       | Fetch docs once per library at start, reuse across sub-tasks.                                                        |
| **Sequential-thinking** | Batch planning and complex debugging within sub-tasks.                                                               |
| **Browser**             | Snapshot at end for UI verification. Console messages for errors. Interactive testing.                               |
| **Payments**            | Documentation for payment tasks. Product/price verification.                                                         |

## Agents in Batch Mode

Launch agents **in parallel** when sub-tasks are independent:

| Agent                    | Phase   | Usage                                                |
| ------------------------ | ------- | ---------------------------------------------------- |
| **Explore**              | START   | Find all files and dependencies for entire main task |
| **backend-architect**    | EXECUTE | API and DB sub-tasks                                 |
| **frontend-architect**   | EXECUTE | UI component sub-tasks                               |
| **security-engineer**    | VERIFY  | Review security-sensitive changes                    |
| **quality-engineer**     | VERIFY  | Coverage and edge case analysis                      |
| **performance-engineer** | VERIFY  | Performance implications review                      |

## Testing

- Run `{{TEST_CMD}}` after batch completion
- Coverage threshold: {{COVERAGE_THRESHOLD}}%
- Report any test failures in completion message

## Usage Example

```
User: /process-tasks-batch docs/tasks/TASK-auth.md

AI: Can I start task 1 "Database Schema" and complete all sub-tasks?
    Orchestration: Database MCP, db-migration-guard (PRE/POST)

User: Yes

AI: [Runs db-migration-guard PRE]
    [Implements 1.1, 1.2, 1.3, 1.4]
    [Runs db-migration-guard POST]
    [Runs build, test, lint]

AI: Task 1 "Database Schema" complete!

    Completed sub-tasks:
    - [x] 1.1 Create migration ...
    - [x] 1.2 Add access policies ...
    - [x] 1.3 Regenerate types ...
    - [x] 1.4 Write tests ...

    Orchestration results:
    - Guards: db-migration-guard PRE OK, POST verified
    - Verify: build OK, tests 96% coverage, lint clean

    Continue with task 2 "API Endpoints"?
```
