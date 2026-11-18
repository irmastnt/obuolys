---
id: REQ-2026-04-26-001
title: Advanced Vibe Coding Starter — universal Node/React starter kit
status: approved
phase: 1 (requirements)
date: 2026-04-26
related_spec: docs/superpowers/specs/2026-04-26-advanced-vibe-coding-starter-design.md
icp: Kūrėjai ir komandos, pradedančios modernius Node/React produktus
target_stage: verified Next.js starter baseline
---

# PRD: Advanced Vibe Coding Starter

## 1. Įvadas / Apžvalga

Advanced Vibe Coding Starter yra universalus starter kit moderniems Node/React projektams. Jis turi padėti greitai pradėti naują produktą arba pridėti disciplinuotą AI-assisted workflow sluoksnį į esamą projektą.

Patikrintas starterio kelias yra Next.js 16.2+ ir React 19 su Tailwind v4, shadcn/ui, testais, GitHub Actions ir AI powerpack. Vite, Supabase ir Vercel dokumentuojami kaip adaptacijos kryptys, kurias reikia sukonfigūruoti pagal konkretų projektą.

## 2. Tikslai

- **G1:** Naujas projektas paleidžiamas lokaliai per aiškų `clone → npm ci → npm run dev` flow.
- **G2:** CI tikrina lint, typecheck, unit testus ir build.
- **G3:** Dokumentacija aiškiai paaiškina, kaip naudoti starterį ir ką keisti naujam produktui.
- **G4:** Repo neturi produkto-specifinio pozicionavimo pagrindiniuose dokumentuose.
- **G5:** Supabase, Vercel, testų ir AI workflow struktūra yra paruošta konfigūravimui.
- **G6:** Saugumo, support, issue ir PR procesai atitinka GitHub community standards.

## 3. User stories

- **US-1:** Kaip kūrėjas, noriu greitai startuoti naują Next.js arba Vite + React projektą su moderniu tooling.
- **US-2:** Kaip komanda, noriu turėti paruoštą GitHub dokumentaciją ir contribution procesą.
- **US-3:** Kaip full-stack kūrėjas, noriu aiškios Supabase/Vercel integracijos krypties be hardcoded secrets.
- **US-4:** Kaip AI-assisted workflow naudotojas, noriu PRD → tasks → implementacijos → verifikacijos pipeline.
- **US-5:** Kaip maintaineris, noriu aiškių release, security ir support taisyklių.

## 4. Funkciniai reikalavimai

### 4.1 Starterio branduolys

- **FR-1:** Repo pavadinimas, README, package metadata ir landing copy pristato universalų starter kit.
- **FR-2:** Next.js App Router scaffold veikia su React 19+, Tailwind v4 ir shadcn/ui.
- **FR-3:** Struktūra neturi būti pririšta prie vieno produkto domeno.
- **FR-4:** Vite + React kryptis dokumentuojama kaip palaikoma alternatyva arba powerpack adaptacijos scenarijus.

### 4.2 Backend ir deploy kryptis

- **FR-5:** Supabase dokumentuojamas kaip rekomenduojama backend kryptis: Auth, Postgres, RLS, Storage, Edge Functions.
- **FR-6:** Vercel dokumentuojamas kaip rekomenduojama deploy kryptis Next.js aplikacijai.
- **FR-7:** Stripe ir Resend dokumentuojami kaip pasirenkamos integracijos, ne privalomas produkto domenas.
- **FR-8:** `.env.example` turi likti tik pavyzdžiams; realūs `.env*` failai necommittinami.

### 4.3 Kokybė ir verifikacija

- **FR-9:** `npm run lint`, `npx tsc --noEmit`, `npm run test:run` ir `npm run build` praeina švariame setup.
- **FR-10:** Vitest smoke testas patvirtina bazinį UI renderinimą.
- **FR-11:** GitHub Actions CI paleidžia lint, typecheck ir testus.
- **FR-12:** E2E workflow lieka paruoštas įjungimui, kai projekte atsiranda stabilūs kritiniai vartotojo srautai.

### 4.4 GitHub ir bendruomenės standartai

- **FR-13:** Repo turi README, CONTRIBUTING, SECURITY, SUPPORT, CODE_OF_CONDUCT ir LICENSE.
- **FR-14:** Issue template’ai yra neutralūs: UI, Auth, App core, Supabase, Stripe, CI/CD, Docs, AI tooling.
- **FR-15:** PR template reikalauja aiškaus scope, verifikacijos ir rizikos įvertinimo.
- **FR-16:** Dependabot stebi npm ir GitHub Actions priklausomybes.

### 4.5 AI powerpack

- **FR-17:** Dokumentuojamas 4 fazių workflow: requirements, tasks, implementation, verification.
- **FR-18:** Guard agentai, MCP serveriai ir skills aprašomi kaip pasirenkamas, bet rekomenduojamas powerpack.
- **FR-19:** PRD ir task šablonai išlieka produkto-agnostiški.
- **FR-20:** Projekto atmintis ir dokumentacija neturi prieštarauti universaliam starterio pozicionavimui.

## 5. Non-goals

- Starter kit neturi būti vieno produkto domeno implementacija.
- Starter kit neturi automatiškai kurti realių `.env*` failų.
- Starter kit neturi hardcodinti API raktų, project IDs ar paslaugų secrets.
- Starter kit neturi priverstinai rinktis tik Next.js arba tik Vite visiems naudotojams.
- Starter kit neturi automatiškai taisyti dependency audit problemų su breaking `--force`.

## 6. Brandos kriterijai

Starter kit laikomas pilnaverte stadija, kai:

- README ir setup veikia nuo švaraus klono.
- CI praeina be rankinių pataisymų.
- Public dokumentai neturi produkto-specifinio pozicionavimo.
- Yra aiškūs security, support ir contribution procesai.
- Yra bent vienas stabilus release tag ir changelog įrašas.
- Pagrindinė folder struktūra laikoma stabili iki kito major release.

## 7. Techniniai apribojimai

- **Runtime:** Node.js 20+.
- **Framework:** Next.js 16.2+ App Router arba Vite + React 19+ adaptacija.
- **UI:** Tailwind v4, shadcn/ui, Base UI, Lucide.
- **Backend:** Supabase.
- **Deploy:** Vercel.
- **Tests:** Vitest, Testing Library, Playwright.
- **Language:** TypeScript.
- **Package manager:** npm.

## 8. Orchestration hints

| Komponentas | Kas reikalinga |
|---|---|
| **MCP serveriai** | Context7, Supabase, Playwright, Vercel, Sequential Thinking |
| **Agentai** | `dependency-guardian`, `security-engineer`, `frontend-architect`, `quality-engineer` |
| **PRE Guards** | dependency, security, file-size, risk |
| **POST Guards** | lint, typecheck, tests, build, docs/link validation |
| **Skills** | Tailwind v4 + shadcn, Supabase backend, Vercel React/Next.js practices |

## 9. Rizikos vertinimas

| Rizika | Tikimybė | Poveikis | Mitigacija |
|---|---|---|---|
| Starteris lieka pririštas prie seno produkto domeno | Vidutinė | Aukštas | Reguliari paieška pagal domeno terminus ir neutralūs šablonai |
| Next.js/Vite skirtumai sukuria painiavą | Vidutinė | Vidutinis | Aiškiai dokumentuoti Next.js default ir Vite adaptacijos ribas |
| Supabase secrets nuteka į repo | Žema | Kritinis | `.env*` failai necommittinami, SECURITY dokumentas, pre-commit guard’ai |
| Dependency breakage dėl naujų versijų | Vidutinė | Vidutinis | Dependabot, CI ir užrakintos versijos `package-lock.json` |
| AI workflow tampa per sunkus mažam projektui | Vidutinė | Vidutinis | Powerpack aprašyti kaip modulinius sluoksnius |

## 10. Sėkmės metrikos

- Švarus klonas praeina `npm ci`, lint, typecheck, testus ir build.
- README turi aiškų starto kelią per mažiau nei 10 minučių.
- GitHub community standards failai yra užpildyti realiais kontaktais.
- Nėra public-facing produkto-specifinio pozicionavimo pagrindiniuose failuose.
- Starter kit galima panaudoti naujam produktui nepakeitus branduolinės struktūros.

## 11. Atviri klausimai

- **Q1:** Ar Vite adaptacijai reikia atskiro branch/template, ar pakanka dokumentuoto migravimo kelio?
- **Q2:** Ar release modelis bus `v0.x` iki pirmo viešo naudojimo, ar iš karto `v1.0.0`?
- **Q3:** Ar Supabase local dev turi būti privalomas CI dalis, ar atskiras workflow?
- **Q4:** Ar AI powerpack turi būti default įjungtas, ar dokumentuotas kaip pasirenkamas sluoksnis?

---

**Susiję dokumentai:**
- Spec: `docs/superpowers/specs/2026-04-26-advanced-vibe-coding-starter-design.md`
- Tasks: `docs/tasks/TASK-2026-04-26-001-advanced-vibe-coding-starter.md`
- Projekto taisyklės: `CLAUDE.md`
