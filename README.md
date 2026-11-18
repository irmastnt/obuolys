# Advanced Vibe Coding Starter

[![CI](https://github.com/ponasObuolys/advanced-vibe-coding-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/ponasObuolys/advanced-vibe-coding-starter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.2-green.svg)](https://github.com/ponasObuolys/advanced-vibe-coding-starter/releases/tag/v3.0.2)

Universalus starter kit moderniems Node/React projektams. Patikrintas default kelias: Next.js 16.2+ ir React 19+ su Tailwind v4, shadcn/ui, testais, CI ir AI powerpack. Vite, Supabase ir Vercel keliai dokumentuojami kaip adaptuojamos kryptys.

Repozitorija skirta greitai pradėti naują produktą su aiškia architektūra, verifikacija ir AI-assisted workflow: Claude Code taisyklėmis, guard agentais, MemPalace/Memoriki žinynu, PRD → tasks pipeline ir GitHub Actions.

## Naujovės v3.0.1

- **MemPalace MCP integracija** — `scripts/setup.sh` automatiškai aptinka python interpretatorių su `mempalace` moduliu ir registruoja MCP serverį (`claude mcp add mempalace`).
- **`/wiki-update` slash komanda** — paleidžia `raw/ → wiki/` Memoriki pipeline'ą: ingestina šaltinius iš `raw/`, sintezuoja entities/concepts į `wiki/`, atnaujina indeksą ir log'ą.
- **Install mode** — `bash scripts/setup.sh /path/to/project` įdiegia starterio sluoksnį (`.claude/`, `scripts/`, `docs/` skeleton) į egzistuojantį projektą, ne tik konfigūruoja patį starter'į.
- **Interaktyvi MCP konfigūracija** — setup'as klausia per kiekvieną iš 6 MCP serverių (Supabase, Context7, Stripe, Playwright, Vercel, Chrome DevTools), default'ai parenkami pagal aptiktą stack'ą.
- **`rsync` vietoj `cp -n`** — install mode pataisytas BSD/macOS exit code suderinamumui.
- **Stop hook'as nesukuria loop'o** — pakeistas iš `type: prompt` į `type: command` (non-blocking echo, kai yra uncommitted pakeitimų).

Pilnas v3.0.1 aprašas: [`docs/STARTER-README.md`](docs/STARTER-README.md).

## Atminties + žinių sluoksniai

Starter apjungia tris atvirojo kodo projektus:

| Sluoksnis | Projektas | Paskirtis |
|---|---|---|
| **Taisyklės** | [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | 4 Karpathy principai (`CLAUDE.md` §1) |
| **Atmintis** | [MemPalace](https://github.com/MemPalace/mempalace) | Semantinė paieška + 29 MCP įrankiai. Saugykla `~/.mempalace/`, kiekvienas projektas — savo *wing*. |
| **Žinynas** | [Memoriki](https://github.com/AyanbekDos/memoriki) | `raw/` šaltinių pipeline į `wiki/` (entities, concepts, sources, synthesis) |

### `/wiki-update` workflow

Kai naudotojas prašo „atnaujink wiki" arba sesijos pabaigoje:

1. **Ingestinama:** skaitoma `raw/*.md`, sintezuojama į `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`.
2. **Reindeksuojama:** `mempalace mine .` perkelia naują turinį į MemPalace saugyklą.
3. **Loginama:** `wiki/log.md` papildomas įrašu apie tai, kas buvo ingestuota ir ką pavyko sužinoti.
4. **Konfliktai:** prieštaraujantys šaltiniai pažymimi `wiki/synthesis/conflicts.md`.

Wiki failų frontmatter privalomas (`type: entity | concept | source | synthesis`, `created`, `updated`, `sources`).

Detalesnis protokolas: [`CLAUDE.md`](CLAUDE.md) §3.

## Būsena

Starter kit yra paruoštas naudoti kaip Next.js bazė naujam produktui arba esamo projekto powerpack sluoksniui.

| Sritis | Būsena |
|---|---|
| Next.js 16.2+ aplikacijos scaffold | Paruošta |
| Tailwind v4 + shadcn/ui bazė | Paruošta |
| Vitest smoke testas | Paruošta |
| CI lint/typecheck/test/build | Paruošta |
| Supabase, Vercel, Stripe ir MCP integracijos | Adaptuojama pagal projektą |
| Vite + React kelias | Suplanuota dokumentuoti |

Repo turi pavyzdinius PRD/task artefaktus `docs/requirements/` ir `docs/tasks/`, kuriuos galima pakeisti savo produkto specifikacija.

## Nuorodos

- **GitHub:** https://github.com/ponasObuolys/advanced-vibe-coding-starter
- **Web:** https://ponasobuolys.lt
- **Kontaktas:** labas@ponasobuolys.lt

## Tech stack

- **Default framework:** Next.js App Router 16.2+
- **Adaptacijos kryptis:** Vite + React 19+
- **Language:** TypeScript
- **UI:** React, Tailwind CSS v4, shadcn/ui, Base UI, Lucide
- **Tests:** Vitest, Testing Library, Playwright
- **Backend kryptis:** Supabase, RLS, Edge Functions
- **Deploy kryptis:** Vercel
- **Pasirenkami mokėjimai:** Stripe
- **AI/dev workflow:** Claude Code, guard agentai, MemPalace, Memoriki

## Greitas startas

### Reikalavimai

- Node.js 20+
- npm
- Python 3.9+ tik AI starterio/MemPalace sluoksniui
- Claude Code CLI tik AI starterio/MCP workflow’ams

### Įdiegimas

```bash
npm ci
```

### Lokalus paleidimas

Prieš paleidžiant dev serverį patikrinkite, ar portas laisvas:

```bash
lsof -i :3000
npm run dev
```

Aplikacija veikia adresu `http://localhost:3000`.

### Patikrinimai

```bash
npm run lint
npx tsc --noEmit
npm run test:run
npm run build
```

AI starterio struktūros patikra:

```bash
bash scripts/verify.sh
```

## Aplinkos kintamieji

Lokaliam darbui naudokite `.env.local`. Jo necommittinkite.

Pavyzdinės reikšmės laikomos `.env.example`. Dažniausiai naudojami starter kit kintamieji:

| Kintamasis | Paskirtis |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase projekto URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase public anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side administracinėms operacijoms |
| `DATABASE_URL` | Lokaliems SQL/RLS testams |
| `STRIPE_SECRET_KEY` | Stripe server-side API |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signature verify |
| `STRIPE_PRICE_ID_MONTHLY` | Mėnesinio plano kaina |
| `STRIPE_PRICE_ID_YEARLY` | Metinio plano kaina |
| `RESEND_API_KEY` | Email/magic link siuntimui |
| `NEXT_PUBLIC_SITE_URL` | Public app URL |

## Repozitorijos struktūra

```text
app/                         Next.js App Router aplikacija
components/ui/               UI komponentai
docs/                        PRD, task sąrašai ir projekto žinynas
docs/requirements/           Reikalavimų dokumentai
docs/tasks/                  Implementacijos task sąrašai
raw/                         Šaltiniai Memoriki wiki pipeline’ui
wiki/                        Generuojama projekto wiki
scripts/                     Setup, verify ir tooling skriptai
tests/                       Vitest smoke/setup testai
.github/workflows/           CI ir self-heal workflow’ai
.claude/                     Claude Code agentai, komandos ir guard'ai
```

Detalesnis žemėlapis: [`docs/INDEX.md`](docs/INDEX.md).

## AI workflow

Repozitorija naudoja 4 fazių workflow:

1. **Reikalavimai:** `docs/requirements/REQ-*.md`
2. **Užduotys:** `docs/tasks/TASK-*.md`
3. **Implementacija:** Claude Code + guard agentai
4. **Verifikacija:** lint, typecheck, testai, build, pre-commit guard’ai

Papildoma dokumentacija:

- [`CLAUDE.md`](CLAUDE.md) — projekto taisyklės ir darbo protokolai
- [`AGENTS.md`](AGENTS.md) — agentų kontekstas
- [`docs/AI-TOOLKIT.md`](docs/AI-TOOLKIT.md) — MCP, agentai, guard’ai ir verifikacija
- [`docs/STARTER-README.md`](docs/STARTER-README.md) — Advanced Vibe Coding starterio sluoksnio aprašymas

## GitHub workflow’ai

- **CI:** `.github/workflows/ci.yml` paleidžia lint, typecheck, Vitest testus ir production build.
- **Self-heal:** `.github/workflows/self-heal.yml` gali sukurti PR su AI siūlomu pataisymu po žinomų CI klaidų tipų.

Self-heal workflow’ui reikia `ANTHROPIC_API_KEY` GitHub Actions secrets.

## Prisidėjimas

Žr. [`CONTRIBUTING.md`](CONTRIBUTING.md). Pull request’ai turi turėti aiškų scope, susietą issue/task ir praeinančius patikrinimus.

## Saugumas

Neraportuokite pažeidžiamumų viešuose issue. Žr. [`SECURITY.md`](SECURITY.md).

## Elgesio kodeksas

Dalyvavimui taikomas [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## Pagalba

Klausimams, bug’ams ir feature request’ams žr. [`SUPPORT.md`](SUPPORT.md).

## Licencija

MIT — žr. [`LICENSE`](LICENSE).
