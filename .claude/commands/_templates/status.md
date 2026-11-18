# Task Progress Status

Show the current progress of a task list: $ARGUMENTS

## Process

1. **Find the task file**: If `$ARGUMENTS` is provided, use it as the file path. Otherwise, look for the most recently modified `TASK-*.md` file in the `docs/tasks/` directory.

2. **Parse the task file**: Read the file and extract:
   - All parent tasks (`- [ ]` or `- [x]` with bold number+title)
   - All sub-tasks under each parent
   - Blocked tasks (containing `BLOCKED:`)
   - Any orchestration results already recorded

3. **Generate status report**:

```
## Task Progress: {filename}

### Overview
- Total main tasks: {N}
- Completed: {N} ({percentage}%)
- In progress: {N}
- Blocked: {N}
- Remaining: {N}

### Progress
{N}/{TOTAL} ████████░░░░░░░░ {percentage}%

### Task Breakdown
| # | Task | Sub-tasks | Status |
|---|------|-----------|--------|
| 1 | {title} | 4/4 | DONE |
| 2 | {title} | 2/6 | IN PROGRESS |
| 3 | {title} | 0/5 | BLOCKED |
| 4 | {title} | 0/3 | PENDING |

### Current Focus
Next action: Task {N}.{M} "{sub-task title}"
Orchestration: {MCP servers, guards, skills needed}

### Blockers
- Task {N}: {blocker description}
```

4. **Do NOT modify the task file** — this is a read-only status check.

## Rules

- If no task file is found, inform the user and suggest running `/generate-tasks` first
- Show the NEXT actionable sub-task (first uncompleted, unblocked sub-task)
- Include the orchestration context for the next task so the user knows what tools will be needed
- Keep output concise — this is a quick status check, not a full report
