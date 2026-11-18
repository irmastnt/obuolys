---
title: Advanced Vibe Coding Starter — universal starter kit design
date: 2026-04-26
status: approved
audience: Node/React projektų kūrėjai ir komandos
tech_stack: Next.js 16.2+, Vite, React 19+, Tailwind v4, Supabase, Vercel
---

# Advanced Vibe Coding Starter — design spec

## 1. Kontekstas ir tikslas

Starter kit turi būti universali bazė moderniems Node/React projektams. Jis neturi pririšti repo prie vieno produkto domeno. Default kelias yra Next.js App Router, o Vite + React palaikomas kaip adaptacijos kryptis.

Tikslas — suteikti paruoštą repo sluoksnį su:

- moderniu UI stack;
- Supabase/Vercel kryptimi;
- GitHub community dokumentais;
- CI ir testų baze;
- AI-assisted PRD → tasks → implementation → verification workflow.

## 2. Architektūriniai sprendimai

### 2.1 Next.js kaip default, Vite kaip adaptacija

Next.js App Router naudojamas kaip veikiantis default scaffold, nes jis palaiko Server Components, route handlers, Vercel deploy ir modernų React flow.

Vite + React palaikymas dokumentuojamas kaip adaptacijos kelias, kad starter kit galėtų būti naudojamas ir SPA projektuose be Next.js runtime.

### 2.2 Supabase kaip backend platforma

Supabase dokumentuojamas kaip rekomenduojama backend kryptis:

- Auth;
- Postgres;
- RLS;
- Storage;
- Edge Functions;
- local dev ir type generation.

Starteris neturi hardcodinti realių Supabase project IDs ar secrets.

### 2.3 Vercel kaip deploy platforma

Vercel dokumentuojamas kaip rekomenduojama deploy kryptis Next.js aplikacijai. Vite SPA atveju Vercel lieka galimas static hosting kelias, bet server-side funkcionalumas turi būti dokumentuotas atskirai.

### 2.4 AI powerpack kaip modularus sluoksnis

AI powerpack nėra produkto domenas. Tai darbo disciplina:

1. Requirements dokumentas.
2. Task list.
3. Implementacija su guard agentais.
4. Verifikacija per lint, typecheck, testus, build ir review.

## 3. Sistemos topologija

```text
Developer
  │
  ├─ README / GitHub templates
  ├─ PRD → tasks docs
  ├─ Next.js App Router default scaffold
  ├─ Optional Vite + React adaptation path
  ├─ Supabase backend platform
  ├─ Vercel deploy target
  └─ CI + tests + AI powerpack
```

## 4. Repo sluoksniai

| Sluoksnis | Paskirtis |
|---|---|
| `app/` | Veikiantis Next.js default scaffold |
| `components/ui/` | shadcn/ui komponentų bazė |
| `.github/` | GitHub workflow’ai, issue ir PR template’ai |
| `docs/requirements/` | PRD ir reikalavimų artefaktai |
| `docs/tasks/` | Implementacijos task sąrašai |
| `docs/superpowers/specs/` | Design/spec dokumentai |
| `scripts/` | Setup, verify ir tooling skriptai |
| `tests/` | Smoke/unit/E2E testų bazė |

## 5. Tech stack

| Sluoksnis | Pasirinkimas | Pagrindas |
|---|---|---|
| Runtime | Node.js 20+ | Suderinamumas su moderniu Next.js/tooling |
| Default framework | Next.js 16.2+ App Router | RSC, route handlers, Vercel deploy |
| Alternative frontend | Vite + React 19+ | Greitas SPA kelias |
| UI | Tailwind v4, shadcn/ui, Base UI, Lucide | Moderni komponentų bazė |
| Backend | Supabase | Auth, Postgres, RLS, Storage, Edge Functions |
| Deploy | Vercel | Preview/prod deploy flow |
| Tests | Vitest, Testing Library, Playwright | Unit, integration ir E2E bazė |
| CI | GitHub Actions | Lint, typecheck, testai, build |

## 6. Brandos modelis

Starter kit laikomas paruoštu naudoti, kai:

- `README.md` paaiškina paskirtį ir setup.
- `package.json` metadata atitinka repo pavadinimą.
- Landing page ir metadata neturi produkto domeno.
- GitHub community failai užpildyti realiais kontaktais.
- CI ir lokali verifikacija praeina.
- PRD/task/spec artefaktai yra neutralūs arba aiškiai pažymėti kaip pavyzdžiai.

`v1.0.0` release turėtų reikšti stabilų folder structure, patikrintą švarų kloną, changelog ir aiškų palaikymo modelį.

## 7. Saugumo modelis

Privalomi principai:

- realūs `.env*` failai necommittinami;
- secrets niekada nehardcodinami;
- Supabase service role key naudojamas tik server-side;
- GitHub Actions secrets dokumentuojami, bet neįrašomi į repo;
- Security advisory ir kontaktinis email aiškiai nurodyti.

## 8. Testavimo strategija

| Layer | Tool | Tikslas |
|---|---|---|
| Static | ESLint, TypeScript | Kodo kokybė ir tipai |
| Unit/smoke | Vitest, Testing Library | Bazinis UI ir util funkcionalumas |
| E2E | Playwright | Kritiniai vartotojo srautai, kai projektas juos turi |
| Build | Next build | Production build validacija |
| Docs | Markdown link check | Vidinių dokumentacijos nuorodų vientisumas |

## 9. Rizikos

| Rizika | Poveikis | Mitigacija |
|---|---|---|
| Repo vėl tampa produkto-specifinis | Starteris klaidina naudotojus | Periodinė terminų paieška ir neutralūs šablonai |
| Next.js ir Vite keliai susimaišo | Setup tampa neaiškus | Aiškus default/adaptation atskyrimas |
| Supabase/Vercel instrukcijos pasensta | Setup failina | Context7/docs verifikacija prieš keitimus |
| AI powerpack atrodo privalomas | Maži projektai jaučia per didelį svorį | Dokumentuoti kaip modularų sluoksnį |

## 10. Įgyvendinimo fazės

1. **Repo pozicionavimas** — README, metadata, landing copy.
2. **GitHub readiness** — community files, issue/PR templates, dependabot.
3. **Starterio dokumentacija** — PRD, tasks, spec, support/security.
4. **Verifikacija** — lint, typecheck, testai, build, docs link check.
5. **Release readiness** — changelog, release kriterijai, `v1.0.0` tag.
6. **Adaptacijos** — Vite path, Supabase setup, Vercel deployment guide.

## 11. Atviri klausimai

- Ar Vite adaptacija turi būti atskiras branch/template?
- Ar Supabase local dev turi būti privalomas starterio brandos kriterijus?
- Ar AI powerpack turi būti default workflow ar optional layer?
- Ar release modelis prasideda nuo `v0.x`, ar pirmas stabilus leidimas yra `v1.0.0`?

---

**Susiję dokumentai:**
- PRD: `docs/requirements/REQ-2026-04-26-001-advanced-vibe-coding-starter.md`
- Tasks: `docs/tasks/TASK-2026-04-26-001-advanced-vibe-coding-starter.md`
