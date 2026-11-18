# CLAUDE.md — Projekto Smegenys

Šis failas yra PIRMAS dalykas, kurį Claude Code skaito prieš kiekvieną užduotį.

---

## 1. Karpathy principai (visada aktyvūs)

LLM klaidų antidotas. Kiekvienas principas — privalomas.

### 1.1 Think Before Coding
- Prieš rašant kodą — deklaruok prielaidas. Jei nežinai, **klausk**.
- Dvi interpretacijos — pateik abi, nepasirink tyliai.
- Matai paprastesnį sprendimą — pasakyk. Ne bijok nesutikti.
- Nesupranti — sustok. Įvardink, kas neaišku. Klausk.

### 1.2 Simplicity First
- Minimalus kodas, sprendžiantis užduotį. Nieko spekuliacinio.
- Jokių "ateities lankstumo" abstrakcijų vienetiniam kodui.
- Jokio error handling'o neįmanomiems scenarijams.
- 200 eilutės, kai užtenka 50 — **perrašai**.

### 1.3 Surgical Changes
- Lieti tik tai, ko reikia. Esamo stiliaus nelaužyk.
- Nerefaktorink gretimo kodo "prabėgomis".
- Tavo pakeitimai sukūrė orfanų (nebenaudojami imports, vars) — pašalink TIK savuosius.
- Ne tavo mesas — palik ramybėje. Paminėk, bet netrink.

### 1.4 Goal-Driven Execution
Kiekviena užduotis — verifikuojamas tikslas:
- "Pridėk validaciją" → "Parašyk testus neteisingam įvedimui, tada juos praverčiam"
- "Pataisyk bug'ą" → "Parašyk testą, kuris reprodukuoja bug'ą, tada pravertį"
- "Refactor X" → "Testai pravertinti prieš ir po"

---

## 2. Projekto kontekstas

**Projekto tipas:** <!-- pvz., Next.js 15 + Supabase + Stripe -->
**Tech stack:** <!-- TypeScript, Tailwind, shadcn/ui, Playwright -->
**Production URL:** <!-- https://example.com -->
**Staging URL:** <!-- https://staging.example.com -->

### 2.1 Direktorijos
- `src/` — aplikacijos kodas
- `supabase/migrations/` — DB migracijos (niekada netrink be rollback!)
- `docs/requirements/` — REQ-*.md failai (Pipeline fazė 1)
- `docs/tasks/` — TASK-*.md failai (Pipeline fazė 2)
- `wiki/` — Memoriki generuojama žinių bazė (**neredaguok rankomis**)
- `raw/` — šaltiniai Memoriki'ui ingestuoti

### 2.2 Konvencijos
- **Komitai**: `feat|fix|chore|docs|refactor: <subject>` + DoD eilutė
- **Failų dydis**: ≤ 300 LOC/failas, ≤ 50 LOC/funkcija
- **Testai**: Vitest (unit) + Playwright (E2E), coverage ≥ 80% paveiktiems failams
- **Migracijos**: visada su `UP` + `DOWN` (rollback)

---

## 3. Memoriki wiki protokolas

Kai naudotojas prašo "atnaujink wiki" arba sesijos pabaigoje:

### 3.1 Šaltinių įkėlimas (`raw/*.md` → `wiki/`)
1. Skaitai naujus failus iš `raw/`
2. Suskaičiai entities (žmonės, kompanijos) → `wiki/entities/<name>.md`
3. Suskaičiai concepts (idėjos, frameworks) → `wiki/concepts/<concept>.md`
4. Sukuri šaltinio santrauką → `wiki/sources/<source-id>.md`
5. Atnaujini `wiki/index.md` ir `wiki/log.md`

### 3.2 Užklausos metu
1. Skaitai `wiki/index.md`, kad rastum relevant puslapius
2. Sintezuoji atsakymą su citations (`[[wiki/entities/alice.md]]`)
3. Jei rastas konfliktas tarp šaltinių — pažymi `wiki/synthesis/conflicts.md`

### 3.3 Sesijos pabaigoje
1. `mempalace mine .` — reindeksuoti naują turinį
2. `wiki/log.md` → pridedamas įrašas: kas buvo ingestuota, ką sužinojo

**Wiki frontmatter privalomas:**
```yaml
---
type: entity | concept | source | synthesis
created: 2026-04-25
updated: 2026-04-25
sources: [raw/paper-001.md]
---
```

---

## 4. Guard agentai (.claude/agents/)

Prieš commit — pre-commit hook iškviečia visus guardus. Jei bent vienas grąžina `BLOCKED` — commit sustabdomas.

| Agentas | Trigger |
|---|---|
| `db-migration-guard` | Keičiasi `supabase/migrations/**` |
| `payment-guard` | Keičiasi `**/stripe/**` ar `**/checkout/**` |
| `risk-assessor` | Kiekvienas PR (išduoda low/medium/high) |
| `language-guard` | `**/*.tsx`, `**/*.md` (LT/EN konvencijos) |
| `file-size-guard` | Bet koks `src/**/*` |
| `test-coverage-guard` | Kiekvienas PR su logic pakeitimais |
| `security-guard` | `.env*`, `supabase/**`, auth kodas |

---

## 5. MCP serveriai (iš `.mcp.json`)

Kai užduotis liečia DB — naudok **Supabase** MCP. Kai mokėjimus — **Stripe**. Kai dokumentaciją — **Context7** (ne atmintį!). Naršyklės testai — **Playwright** arba **Chrome DevTools**. Deploy — **Vercel**. Atmintis tarp sesijų — **MemPalace**.

---

## 6. Verifikacija prieš commit'ą

Privalomai kiekvienam PR:

```bash
npm run build            # Next.js build
npm run lint             # ESLint + TypeScript
npm run test             # Vitest unit
npm run test:e2e         # Playwright E2E (kritiniam flow)
.claude/hooks/pre-commit.sh  # Guard agentų apklausa
```

Jei bet kuris žingsnis fail — grįžti atgal, taisai, kartoji.

---

## 7. Kada kreiptis į naudotoją

- Žr. 1.1 — jei yra dvi interpretacijos.
- Jei Guard Gap Analysis rodo "nė vienas guardas nesustabdytų klaidos šiame feature'e".
- Jei tektų pažeisti 1.3 (chirurginiai pakeitimai) — pvz., liesti 10+ failų, kurie nėra scope'e.
- Jei reikalavimas prieštarauja production duomenims (pvz., "pridėk kolonėlę, bet migracija bus destruktyvi").

---

**Šis failas = projekto konstitucija. Jei kyla konfliktas tarp šio failo ir ad-hoc prompt'o — šis failas pirmesnis.**

<!-- CWK:START -->
# CWK Workflow

This project uses [Claude Workflow Kit](https://github.com/ponasObuolys/claude-workflow-kit) for structured development.

## Available Commands

| Command | Purpose |
|---|---|
| `/create-prd` | Generate PRD with risk assessment and orchestration hints |
| `/generate-tasks` | Generate task list from PRD with orchestration blocks |
| `/process-tasks` | Implement tasks one sub-task at a time (max control) |
| `/process-tasks-batch` | Batch implement entire main tasks (faster) |
| `/status` | View current task progress |

## Workflow

Always follow: **PRD → Tasks → Implementation → Verification**

Never skip steps. Every feature starts with `/create-prd`, not with code.

## Guards

Guards run automatically per orchestration blocks in task lists:
- `pre-deploy` — lint, build, tests before commit
- `db-guardian` — migration safety (PRE/POST)
- `payment-guardian` — revenue-critical path protection (PRE)
- `language-guard` — UI text language verification (POST)
- `file-splitter` — safe file splitting strategy (PRE)
- `risk-assessor` — critical path risk analysis (PRE)
- `dependency-guardian` — vulnerable/outdated dependency check (PRE)
- `test-quality-guardian` — test meaningfulness and coverage gaps (POST)

## MCP Servers

Configured in `settings.local.json` — use these tools in your workflow:

| Server | Purpose | When to use |
|---|---|---|
| `sequential-thinking` | Complex analysis, debugging, architecture decisions | Multi-step reasoning, root cause analysis |
| `context7` | Library docs, framework patterns, API references | Before using unfamiliar APIs or libraries |
| `playwright` | Browser E2E testing, visual validation, screenshots | UI testing, form flows, visual regression |
| `supabase` | DB tables, migrations, SQL, edge functions | Database operations (if Supabase detected) |
| `stripe` | Products, prices, customers, payment docs | Payment integration (if Stripe detected) |

Vercel MCP (if detected) requires manual setup: `claude mcp add --transport http vercel https://mcp.vercel.com`

## Hooks

Automatic quality checks configured in `settings.local.json`:
- **PreToolUse (Write|Edit)** — warns when a file exceeds the line limit, suggests running file-splitter agent
- **Stop** — reminds to run build/test/lint before ending a session with uncommitted changes

## Reference

See `docs/AI-TOOLKIT.md` for the full tool catalog (MCP servers, agents, guards, skills, orchestration patterns).
<!-- CWK:END -->
