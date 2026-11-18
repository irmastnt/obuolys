---
title: Projekto indeksas
type: index
created: 2026-04-26
updated: 2026-04-26
---

# Advanced Vibe Coding Starter · Projekto indeksas

Šis dokumentas — navigacinis žemėlapis. Jis apibūdina **kas yra kur**, **kodėl** ir **kada kreiptis** į konkrečią dalį.

> **Pastaba:** šis indeksas yra **statinis** ir aprašo repo kūno struktūrą. Wiki turinio katalogą (entities/concepts/sources) žr. [`wiki/index.md`](../wiki/index.md) — jis atnaujinamas automatiškai.

---

## 1. Greitas žemėlapis

| Sluoksnis | Failas / dir | Paskirtis |
|---|---|---|
| Projekto smegenys | [`CLAUDE.md`](../CLAUDE.md) | Karpathy principai + projekto kontekstas + protokolai |
| Įvadas naudotojui | [`README.md`](../README.md) | 5-min setup, struktūros apžvalga, komponentų sąrašas |
| Diegimas | [`scripts/setup.sh`](../scripts/setup.sh) | MemPalace + MCP + hooks bootstrap |
| Patikra | [`scripts/verify.sh`](../scripts/verify.sh) | Sanity-check po setup |
| MCP konfigas | [`.mcp.json.example`](../.mcp.json.example) | 6 MCP serveriai (kopijuoti į `.mcp.json`) |
| Permissions | [`.claude/settings.json`](../.claude/settings.json) | allow / deny / ask sąrašai |
| Pre-commit | [`.claude/hooks/pre-commit.sh`](../.claude/hooks/pre-commit.sh) | Iškviečia 7 guard agentus |
| Self-Healing | [`.github/workflows/self-heal.yml`](../.github/workflows/self-heal.yml) | CI fail → AI fix → PR |
| Memoriki ingest | [`raw/`](../raw/) | Šaltiniai įmesti čia |
| Memoriki output | [`wiki/`](../wiki/) | LLM-generuota wiki (neredaguoti rankomis) |
| 4-fazių pipeline | [`docs/requirements/`](./requirements/), [`docs/tasks/`](./tasks/) | REQ + TASK šablonai |

---

## 2. Trijų sluoksnių apjungimas

Repozitorija jungia tris atskirus open-source projektus į vieną klonavimui paruoštą starterį:

| Sluoksnis | Šaltinis | Įgyvendinimas |
|---|---|---|
| **Taisyklės** (anti-LLM klaidos) | [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | [`CLAUDE.md §1`](../CLAUDE.md) + [`.claude/skills/karpathy-principles/SKILL.md`](../.claude/skills/karpathy-principles/SKILL.md) |
| **Atmintis** (semantinė paieška) | [MemPalace](https://github.com/MemPalace/mempalace) | `mempalace.yaml` + 29 MCP įrankiai |
| **Žinynas** (raw → wiki pipeline) | [Memoriki](https://github.com/AyanbekDos/memoriki) | [`raw/`](../raw/) → [`wiki/`](../wiki/) protokolas |

---

## 3. Guard agentai (`.claude/agents/`)

Septyni autonominiai LLM "saugikliai" iškviečiami iš pre-commit hook'o. Vienas `BLOCKED` verdiktas sustabdo commit'ą.

| # | Agentas | Trigger | Modelis | Verdict galimybės |
|---|---|---|---|---|
| 1 | [`db-migration-guard`](../.claude/agents/db-migration-guard.md) | `supabase/migrations/**` | sonnet | OK / WARN / BLOCKED |
| 2 | [`payment-guard`](../.claude/agents/payment-guard.md) | `**/stripe/**`, `**/checkout/**` | sonnet | OK / WARN / BLOCKED |
| 3 | [`risk-assessor`](../.claude/agents/risk-assessor.md) | **visada** | sonnet | OK + low/medium/high |
| 4 | [`language-guard`](../.claude/agents/language-guard.md) | `*.tsx`, `*.ts`, `*.md` | sonnet | OK / WARN / BLOCKED |
| 5 | [`file-size-guard`](../.claude/agents/file-size-guard.md) | `src/**` | haiku | OK / WARN / BLOCKED |
| 6 | [`test-coverage-guard`](../.claude/agents/test-coverage-guard.md) | `src/**`, `app/**` | sonnet | OK / WARN / BLOCKED |
| 7 | [`security-guard`](../.claude/agents/security-guard.md) | `.env*`, `supabase/**`, `auth/**`, `middleware.ts` | sonnet | OK / WARN / BLOCKED |

**Hook logika:** `risk-assessor` paleidžiamas visada; kiti — tik jei pakeitimuose yra atitinkančių failų pattern'ų. Žr. [`pre-commit.sh`](../.claude/hooks/pre-commit.sh) eilutės 24–35.

---

## 4. MCP serveriai (`.mcp.json.example`)

| # | Serveris | Komanda | Aplinkos kintamieji |
|---|---|---|---|
| 1 | Supabase | `npx @supabase/mcp-server-supabase` | `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` |
| 2 | Context7 | `npx @upstash/context7-mcp` | — |
| 3 | Stripe | `npx @stripe/mcp --tools=all` | `STRIPE_SECRET_KEY` |
| 4 | Playwright | `npx @playwright/mcp` | — |
| 5 | Vercel | `https://mcp.vercel.com` (HTTP) | — |
| 6 | Chrome DevTools | `npx chrome-devtools-mcp` | — |
| 7 | MemPalace | `python -m mempalace.mcp_server` (registruoja `setup.sh`) | — |

**Saugumas:** raktai NIEKADA neįrašomi `.mcp.json`'e tiesiogiai. Naudoti `${VAR}` substituciją + OS keychain. Failas yra `.gitignore`'e.

---

## 5. 4-fazių pipeline

| Fazė | Artefaktas | Šablonas |
|---|---|---|
| 1. Reikalavimai | `docs/requirements/REQ-YYYY-MM-DD-NNN.md` | [`_TEMPLATE.md`](./requirements/_TEMPLATE.md) |
| 2. Užduotys | `docs/tasks/TASK-*.md` (≤ 100 LOC vienai) | [`_TEMPLATE.md`](./tasks/_TEMPLATE.md) |
| 3. Implementacija | Claude Code + guard agentai | iš `.claude/agents/*` |
| 4. Verifikacija | `npm run build/lint/test/test:e2e` + pre-commit hook | [`pre-commit.sh`](../.claude/hooks/pre-commit.sh) |

**Reikalavimo šablono privalomi skyriai:** User need · Non-goals · Success criteria · ≥ 2 architectural alternatives · Risk assessment · **Guard Gap Analysis** · Rollback plan.

---

## 6. Permissions (`.claude/settings.json`)

| Sąrašas | Pavyzdžiai |
|---|---|
| `allow` | `npm run build/lint/test`, `git status/diff/log`, `npx supabase/vercel/playwright`, `mempalace *`, `Edit(src/**)`, `Edit(wiki/**)`, `Read(**)` |
| `deny` | `rm -rf *`, `git push --force`, `git reset --hard`, `npx supabase db reset`, `npx vercel --prod`, `Edit(.env)`, `Edit(.mcp.json)`, `Read(.env)` |
| `ask` | `git push`, `gh pr create`, `npm publish`, `Edit(package.json)`, `Edit(.github/workflows/**)` |

**Modelis:** `opus` (default). **Telemetrija:** išjungta (`CLAUDE_CODE_ENABLE_TELEMETRY=0`).

---

## 7. Self-Healing CI/CD

Workflow [`self-heal.yml`](../.github/workflows/self-heal.yml) reaguoja į CI fail'ą feature šakose ir bando automatiškai pataisyti **tik 4 žinomus klaidų tipus**:

| # | Klaidos tipas | Detekcijos pattern |
|---|---|---|
| 1 | `playwright-selector` | `data-testid.*not found`, `locator.*waiting for` |
| 2 | `snapshot-drift` | `snapshot.*out of date`, `toMatchSnapshot` |
| 3 | `typescript-type` | `TypeError: Cannot read`, `Property .* does not exist` |
| 4 | `lint` | `ESLint.*error`, `Parsing error` |

**Saugumas:** veikia tik feature šakose (ne `main`); fix'as visada eina per naują PR + privalomas review.

---

## 8. Memoriki wiki protokolas

Detalus protokolas — [`CLAUDE.md §3`](../CLAUDE.md). Trumpa schema:

```
raw/<file>.md  ──► [Claude Code arba `mempalace mine .`]
                       │
                       ├──► wiki/entities/<name>.md   (žmonės, kompanijos)
                       ├──► wiki/concepts/<name>.md   (idėjos, frameworks)
                       ├──► wiki/sources/<id>.md      (šaltinio santrauka)
                       │
                       └──► wiki/index.md             (puslapių katalogas)
                            wiki/log.md               (operacijų žurnalas)
```

**Atvaizdai:** įmesti į [`raw/assets/`](../raw/assets/), wiki puslapiuose nuorodos relatyvios (`![](../../raw/assets/diagram.png)`).

**Lint** (kontradikcijos, orphan'ai, stale info) — žr. [`CLAUDE.md §3.4`](../CLAUDE.md).

---

## 9. Naudingiausi entry points pagal užduotį

| Užduotis | Pradėk nuo |
|---|---|
| Pirmas setup | [`README.md`](../README.md) → `bash scripts/setup.sh` |
| Naujas feature | [`docs/requirements/_TEMPLATE.md`](./requirements/_TEMPLATE.md) |
| Naujas guard | [`.claude/agents/`](../.claude/agents/) (kopijuoti `risk-assessor.md` kaip starter) |
| Wiki naujinimas | [`raw/`](../raw/) įmesti šaltinį → "atnaujink wiki" prompt |
| MCP raktų rotacija | [`.mcp.json.example`](../.mcp.json.example) + OS keychain |
| Production deploy | Vercel MCP (`.mcp.json` įrašyti) + `ask` permission'as |

---

## 10. Versijų patikra

```bash
bash scripts/verify.sh
```

Tikrina struktūrą, priklausomybes (Python 3.9+, Claude CLI, git, MemPalace), MemPalace MCP registraciją ir tai, kad `.env` / `.mcp.json` NĖRA git tracking'e.
