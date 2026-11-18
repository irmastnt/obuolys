# Advanced Vibe Coding Starter v3.0.1

Seminaro **Advanced Vibe Coding · 2026-04-25/26** starter projektas.

Apjungia tris atminties + discipline sluoksnius į vieną klonavimui paruoštą repo:

| Sluoksnis | Projektas | Kam skirta |
|---|---|---|
| **Taisyklės** | [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | 4 Karpathy principai. Įtraukti į `CLAUDE.md` |
| **Atmintis** | [MemPalace](https://github.com/MemPalace/mempalace) | Semantinė paieška + 29 MCP įrankiai |
| **Žinynas** | [Memoriki](https://github.com/AyanbekDos/memoriki) | `raw/ → wiki/` wiki pipeline ant MemPalace |

Papildomai pridėti: 7 guard agentai, 4-fazių pipeline šablonai, Self-Healing GitHub Action, Next.js/Supabase/Stripe MCP konfigūracija.

---

## Reikalavimai

- **Python 3.9+** (MemPalace)
- **Node 18+** (jei naudosite Next.js projekte)
- **Claude Code CLI ≥ 1.0**. [diegimas](https://docs.claude.com/claude-code)
- **git**

## Greitas diegimas (5 min)

```bash
# 1. Klonuokite starterį
git clone <šio repo URL> my-project
cd my-project

# 2. Paleiskite automatinį setup (interaktyviai paklaus dėl MCP raktų)
bash scripts/setup.sh

# 3. Patikrinkite, kad viskas veikia
bash scripts/verify.sh

# 4. Paleiskite Claude Code
claude
```

## Ką `scripts/setup.sh` padaro

1. **Įdiegia MemPalace** per `pipx install mempalace`. Atsarginiai variantai. `brew install pipx`, jei pipx dar nėra, arba vietinis `.venv/`, jei nei pipx, nei brew.
2. **Inicializuoja palace projekte.** `mempalace init . --yes` sukuria `mempalace.yaml` ir `entities.json` projekto šaknyje. Pati saugykla gyvena `~/.mempalace/`. Tai globali vieta, dalinama tarp visų jūsų projektų. Kiekvienas projektas joje turi savo *wing*.
3. **Prijungia MemPalace MCP serverį.** Aptinka python interpretatorių, kuris turi `mempalace` modulį. Tai svarbu macOS pipx atveju, kur sistemos `python` modulio neturi. Užregistruoja: `claude mcp add mempalace -- <python> -m mempalace.mcp_server`.
4. **Aptinka stack'ą + sukonfigūruoja CWK pipeline.** Iš `package.json`/`manage.py`/`Cargo.toml`/`go.mod` aptinka kalbą bei framework'ą, sugeneruoja `.claude/commands/*.md` slash komandas su tinkamais `build_cmd`/`lint_cmd`/`test_cmd` default'ais.
5. **Nustato pre-commit hook'ą.** `.claude/hooks/pre-commit.sh` +x, susieja su `.git/hooks/pre-commit`.
6. **Interaktyviai konfigūruoja MCP serverius.** Klausia per kiekvieną iš 6 MCP (Supabase, Context7, Stripe, Playwright, Vercel, Chrome DevTools) ar įtraukti. Default'ai parenkami pagal aptiktą stack'ą (Supabase Y jei `@supabase/supabase-js` rastas, Stripe Y jei `stripe` rastas, ir t.t.). Surenka API tokenus (slaptas įvedimas su `read -s`), įrašo tiesiogiai į `.mcp.json` su `chmod 600`. Failas yra `.gitignore`'e. Paleidus pakartotinai — klausia, ar perrašyti (default N), egzistuojantis `.mcp.json` backup'inamas. Praleisti tokeną Enter'iu = liks `${VAR}` placeholder'is.
7. **Pradinis mine.** Jei `raw/` turi failų, paleidžia `mempalace mine .`. Komanda idempotentinė.

## Struktūra

```
.
├── CLAUDE.md                  # Projekto smegenys (Karpathy + schema + kontekstas)
├── mempalace.yaml             # MemPalace konfigūracija
├── .mcp.json.example          # 6 MCP serveriai (kopijuoti į .mcp.json)
├── .claude/
│   ├── settings.json          # Permissions (allow/deny/ask)
│   ├── hooks/pre-commit.sh    # Guard agentų apklausa prieš commit
│   ├── agents/                # 7 guard agentai (db, payment, risk, ...)
│   └── skills/                # Karpathy principai kaip skill
├── .github/workflows/
│   └── self-heal.yml          # CI fail → AI fix → PR
├── raw/                       # Memoriki: čia metate šaltinius
├── wiki/                      # Memoriki: LLM generuota wiki
│   ├── index.md               # Puslapių katalogas
│   ├── log.md                 # Operacijų žurnalas
│   ├── entities/              # Žmonės, kompanijos
│   ├── concepts/              # Idėjos, framework'ai
│   ├── sources/               # Šaltinių santraukos
│   └── synthesis/             # Kryžminė analizė
├── docs/
│   ├── requirements/          # REQ-*.md (Fazė 1)
│   └── tasks/                 # TASK-*.md (Fazė 2)
└── scripts/
    ├── setup.sh
    └── verify.sh
```

## 4-fazių pipeline (trumpai)

1. **Reikalavimai** → `docs/requirements/REQ-YYYY-MM-DD-NNN.md`
2. **Užduotys** → `docs/tasks/TASK-*.md` (≤ 100 LOC viena užduotis)
3. **Implementacija** → Claude Code + `.claude/agents/*` guardai
4. **Verifikacija** → `build → lint → test → E2E → guards` (pre-commit hook)

Pilna metodika: žr. `ADVANCED-VIBE-CODING-Meistrystes-Vadovas.md`.

## 6 MCP serveriai (iš `.mcp.json.example`)

| # | Serveris | Paskirtis |
|---|---|---|
| 1 | **Supabase** | DB + migracijos + RLS |
| 2 | **Context7** | Reali dokumentacija (ne halucinacijos) |
| 3 | **Stripe** | Mokėjimai, refund'ai, webhook'ai |
| 4 | **Playwright** | E2E naršyklės testai |
| 5 | **Vercel** | Deploy + preview URL'ai |
| 6 | **Chrome DevTools** | DOM inspekcija Self-Healing metu |

Plius **MemPalace** (7-as, iš `mempalace init`).

## 5 slash komandos (CWK 4 etapų pipeline, v3.0.1)

`scripts/setup.sh` aptinka jūsų stack'ą (Node.js, TypeScript, Next.js, Vite-React, Python, Django, Rust, Go) ir sugeneruoja failus `.claude/commands/*.md` su tinkamomis komandomis (`build_cmd`, `lint_cmd`, `test_cmd`).

| # | Komanda | Paskirtis |
|---|---|---|
| 1 | `/create-prd "<aprašymas>"` | PRD su Orchestration Hints. Output: `docs/requirements/REQ-*.md` |
| 2 | `/generate-tasks <REQ>` | PRD virsta struktūruotomis užduotimis. Output: `docs/tasks/TASK-*.md` |
| 3a | `/process-tasks <TASK>` | Vykdo vieną sub-užduotį, sustoja patvirtinimui |
| 3b | `/process-tasks-batch <TASK>` | Vykdo visą pagrindinę užduotį be sustojimo |
| 4 | `/status` | Užduočių progresas |

**Pavyzdinis srautas po `setup.sh` paleidimo:**

```bash
claude
> /create-prd "Pridėk vartotojo profilio puslapį"
> /generate-tasks docs/requirements/REQ-2026-04-26-001-*.md
> /process-tasks docs/tasks/TASK-vartotojo-profilis.md
```

CWK guard'ų pavadinimai port'inti į starter'io LT konvenciją. Pavyzdžiui, `payment-guardian` tampa `payment-guard`. Pilną lentelę rasite `docs/CWK-AGENT-MAPPING.md`.

## 7 guard agentai

Visi gyvena `.claude/agents/`:

1. `db-migration-guard`. blokuoja destruktyvias migracijas be rollback
2. `payment-guard`. tikrina idempotency, kainų logiką, Stripe webhooks
3. `risk-assessor`. priskiria low/medium/high kiekvienam PR
4. `language-guard`. LT/EN tekstai atitinka konvencijas
5. `file-size-guard`. failo ≤ 300 LOC, funkcijos ≤ 50 LOC
6. `test-coverage-guard`. testų coverage ≥ 80% paveiktiems failams
7. `security-guard`. secret leaks, RLS trūkumai, CSP

## Licencija

MIT licencija. Detalės: `LICENSE`.

## Kredits

- [MemPalace](https://github.com/MemPalace/mempalace). @MemPalace
- [Memoriki](https://github.com/AyanbekDos/memoriki). @AyanbekDos
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills). @forrestchang
