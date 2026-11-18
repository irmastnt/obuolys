# AI Toolkit Reference

> Complete catalog of all available tools, agents, guards, skills, and orchestration patterns.
> Use as reference when writing PRDs, generating tasks, and during development.

---

## 1. MCP Servers (Model Context Protocol)

### Available MCP Servers

Use whichever MCP servers are configured in your project. Common ones:

| MCP Server              | Purpose               | Key Tools                                                                                    |
| ----------------------- | --------------------- | -------------------------------------------------------------------------------------------- |
| **Supabase**            | Database operations   | `list_tables`, `execute_sql`, `apply_migration`, `generate_typescript_types`, `get_advisors` |
| **Context7**            | Library documentation | `resolve-library-id`, `query-docs`                                                           |
| **Sequential-thinking** | Complex analysis      | `sequentialthinking`                                                                         |
| **Playwright**          | E2E / UI testing      | `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`                      |
| **Stripe**              | Payment operations    | `search_stripe_documentation`, `list_products`, `list_prices`                                |
| **Vercel**              | Deployment monitoring | `list_deployments`, `get_runtime_logs`, `get_deployment_build_logs`                          |

### When to Use Each

| Situation                    | MCP Server                     |
| ---------------------------- | ------------------------------ |
| Need library docs/examples   | Context7                       |
| DB schema changes            | Supabase (or project's DB MCP) |
| Complex multi-step reasoning | Sequential-thinking            |
| UI verification              | Playwright                     |
| Payment configuration        | Stripe                         |
| Deploy issues                | Vercel                         |

---

## 2. Project Agents (Guards)

These agents serve as **guardrails** — run them PRE/POST implementation:

| Guard                    | Model  | PRE/POST  | When to Use                                          |
| ------------------------ | ------ | --------- | ---------------------------------------------------- |
| **payment-guardian**     | Sonnet | PRE       | Before changes to payment/checkout/webhook code      |
| **db-guardian**          | Sonnet | PRE/POST  | Before/after DB migrations and schema changes        |
| **language-guard**        | Haiku  | POST      | After modifying components with user-facing text     |
| **pre-deploy**           | Haiku  | POST (bg) | Before commit/deploy — lint, tests, build            |
| **file-splitter**        | Sonnet | PRE       | Before splitting files over {{MAX_FILE_LINES}} lines |
| **risk-assessor**        | —      | PRE       | During PRD/task generation for critical paths        |
| **dependency-guardian**  | Haiku  | PRE       | Before deploy — vulnerability audit, outdated deps   |
| **test-quality-guardian**| Sonnet | POST      | After writing tests — meaningfulness, coverage gaps  |

### Guard Selection Quick Reference

| What's Changing                     | Required Guard                           |
| ----------------------------------- | ---------------------------------------- |
| Payment/checkout code               | `payment-guardian` (PRE)                 |
| DB migrations, schemas, functions   | `db-guardian` (PRE/POST)                 |
| UI components with text             | `language-guard` (POST)                   |
| Files over {{MAX_FILE_LINES}} lines | `file-splitter` (PRE)                    |
| Revenue/auth/critical paths         | `risk-assessor` (PRE)                    |
| Before any commit                   | `pre-deploy` (POST, background)          |
| Adding/updating dependencies        | `dependency-guardian` (PRE)              |
| After writing/modifying tests       | `test-quality-guardian` (POST)           |

---

## 3. Built-in Agents

| Agent                  | Purpose                          | When to Use                                      |
| ---------------------- | -------------------------------- | ------------------------------------------------ |
| `Explore`              | Codebase search, pattern finding | Before any code changes — find existing patterns |
| `security-engineer`    | Auth, API security review        | Webhook handlers, RLS, endpoints                 |
| `backend-architect`    | API design, DB schema, data flow | New endpoints, migrations, services              |
| `frontend-architect`   | Component architecture, UX       | UI decomposition, hook design                    |
| `quality-engineer`     | Test strategy, coverage          | Test plans, edge cases                           |
| `performance-engineer` | Optimization                     | Queries, bundle size, rendering                  |
| `refactoring-expert`   | Code restructuring               | DRY, file splitting, utilities                   |
| `requirements-analyst` | Specifications                   | Ambiguous requirements                           |
| `root-cause-analyst`   | Bug diagnostics                  | Complex, hard-to-reproduce bugs                  |
| `system-architect`     | System design                    | Scalability, architecture decisions              |
| `technical-writer`     | Documentation                    | API docs, guides                                 |

---

## 4. Skills

### Workflow Skills

| Skill                                        | Purpose                           |
| -------------------------------------------- | --------------------------------- |
| `superpowers:brainstorming`                  | **REQUIRED** before creative work |
| `superpowers:writing-plans`                  | Implementation plan creation      |
| `superpowers:executing-plans`                | Plan execution with checkpoints   |
| `superpowers:test-driven-development`        | TDD before writing code           |
| `superpowers:systematic-debugging`           | Before proposing bug fixes        |
| `superpowers:verification-before-completion` | Before claiming work is done      |
| `superpowers:requesting-code-review`         | After feature completion          |
| `superpowers:dispatching-parallel-agents`    | 2+ independent tasks              |

### Development Skills

| Skill                             | Purpose                  |
| --------------------------------- | ------------------------ |
| `feature-dev:feature-dev`         | Full feature development |
| `frontend-design:frontend-design` | Production-grade UI      |
| `simplify`                        | Code quality review      |
| `code-review:code-review`         | PR code review           |

---

## 5. Orchestration Pattern

Every task in a task list follows this structure:

```markdown
- [ ] **{NUMBER} {TITLE}** [BLOCKS: {OTHER}]
  - **Orchestration**:
    - _MCP_:
      - {server} (`{tool}` — {purpose})
    - _Agents_:
      - `{agent}` ({what it does})
    - _Guards_:
      - `{guard}` ({PRE/POST} — {purpose})
    - _Skills_:
      - `{skill-name}`
    - _Verify_:
      - `{command}` — {what it checks}
  - [ ] {NUMBER}.1 {What to change} (`{file}` lines {X-Y})
  - [ ] {NUMBER}.2 {Related change} (`{file}`)
  - [ ] {NUMBER}.3 Write tests: {what they verify}
```

---

## 6. Tool Selection Matrix

| Task Type    | MCP                  | Agent                                | Guard                           | Skill                  |
| ------------ | -------------------- | ------------------------------------ | ------------------------------- | ---------------------- |
| DB schema    | Database             | backend-architect                    | db-guardian                     | —                      |
| API endpoint | Database, Context7   | backend-architect, security-engineer | —                               | `/sc:implement`        |
| UI component | Context7, Playwright | frontend-architect                   | language-guard                   | `frontend-design`      |
| Payment code | Payments             | —                                    | payment-guardian, risk-assessor | —                      |
| Bug fix      | Sequential-thinking  | root-cause-analyst                   | —                               | `systematic-debugging` |
| Refactoring  | —                    | refactoring-expert                   | file-splitter                   | `simplify`             |
| Testing      | Playwright           | quality-engineer                     | pre-deploy                      | TDD                    |
| Performance  | —                    | performance-engineer                 | —                               | `/sc:analyze`          |

---

## 7. Verification Pipeline

Standard verification before commit:

```
1. npm run lint         → 0 errors, 0 warnings
2. npm run test:run         → All tests pass ({{COVERAGE_THRESHOLD}}%+)
3. npm run build        → No compilation errors
4. language-guard agent  → UI text in correct language
5. pre-deploy agent     → Full pre-deploy validation
```

---

## 8. Development Workflow Commands

| Command                | Purpose                                                 |
| ---------------------- | ------------------------------------------------------- |
| `/create-prd`          | Generate PRD with risk assessment + orchestration hints |
| `/generate-tasks`      | Generate task list from PRD with orchestration blocks   |
| `/process-tasks`       | Process one sub-task at a time with guard execution     |
| `/process-tasks-batch` | Batch mode — complete main tasks with PRE/POST guards   |
| `/status`              | View current task progress and next action              |

---

## 9. Hooks (Automatic Guards)

CWK installs hooks that run automatically without manual invocation:

| Hook | Trigger | What It Does |
|------|---------|-------------|
| File size check | `PreToolUse(Write\|Edit)` | Warns if file exceeds {{MAX_FILE_LINES}} lines, suggests file-splitter |
| Pre-deploy reminder | `Stop` | Reminds to run build/test/lint before ending session |

Hooks are configured in `.claude/settings.local.json` under the `hooks` key.

---

## 10. Examples

See the `examples/` directory in the CWK repository for complete samples:

- `examples/prd-example.md` — Full PRD with risk assessment and orchestration hints
- `examples/tasks-example.md` — Complete task list with orchestration blocks and execution strategy
