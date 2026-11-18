---
id: TASK-2026-04-26-001
title: Advanced Vibe Coding Starter — implementation task list
status: ready
phase: 2 (tasks)
date: 2026-04-26
related_prd: docs/requirements/REQ-2026-04-26-001-advanced-vibe-coding-starter.md
related_spec: docs/superpowers/specs/2026-04-26-advanced-vibe-coding-starter-design.md
target_stage: verified Next.js starter baseline
---

# Tasks for REQ-2026-04-26-001 — Advanced Vibe Coding Starter

> Phase 2 task list. Kiekvienas parent task = atskira PR arba aiškus pakeitimų batch.

## Relevant files

| Failas | Paskirtis |
|---|---|
| `README.md` | Starterio pozicionavimas, quickstart, stack ir kontaktai |
| `package.json`, `package-lock.json` | Projekto metadata, scripts, dependencies |
| `app/layout.tsx`, `app/page.tsx` | Neutralus starterio landing ir metadata |
| `components/ui/` | shadcn/ui baziniai komponentai |
| `.github/workflows/` | CI ir pasirenkami deploy/self-heal workflow’ai |
| `.github/ISSUE_TEMPLATE/` | Neutralūs issue template’ai |
| `docs/requirements/` | PRD šablonai ir starterio requirements |
| `docs/tasks/` | Implementacijos task sąrašai |
| `docs/superpowers/specs/` | Design/spec dokumentai |
| `tests/` | Vitest setup ir smoke testai |

## Notes

- Public-facing copy turi būti produkto-agnostiškas.
- Realūs `.env*` failai nekeičiami ir necommittinami.
- Verifikacija: lint, typecheck, testai, build.
- Visi nauji dokumentai turi naudoti realius repo kontaktus.

---

## TASK-01: Universalus repo pozicionavimas

**Risk:** LOW

- [x] `README.md` pavadinimą pakeisti į `Advanced Vibe Coding Starter`.
- [x] Pakeisti produkto-specifinį aprašymą į universalų Node/React starter kit aprašymą.
- [x] `package.json` ir `package-lock.json` `name` pakeisti į `advanced-vibe-coding-starter`.
- [x] `package.json.description` pakeisti į universalų Next.js/Vite React starter kit aprašymą.
- [x] `app/layout.tsx` metadata pakeisti į starterio metadata.
- [x] `app/page.tsx` landing copy pakeisti į neutralų starterio copy.

**Verify:**
- [x] Public/root/app failuose nebelieka produkto-specifinio landing copy.
- [x] `npm run lint`
- [x] `npx tsc --noEmit`
- [x] `npm run test:run`
- [x] `npm run build`

---

## TASK-02: GitHub community readiness

**Risk:** LOW

- [x] Sukurti arba atnaujinti `CONTRIBUTING.md`.
- [x] Sukurti arba atnaujinti `SECURITY.md`.
- [x] Sukurti arba atnaujinti `SUPPORT.md`.
- [x] Sukurti arba atnaujinti `CODE_OF_CONDUCT.md`.
- [x] Sukurti `.github/pull_request_template.md`.
- [x] Sukurti `.github/ISSUE_TEMPLATE/bug_report.yml`.
- [x] Sukurti `.github/ISSUE_TEMPLATE/feature_request.yml`.
- [x] Sukurti `.github/ISSUE_TEMPLATE/config.yml`.
- [x] Sukurti `.github/dependabot.yml`.
- [x] Sukurti `.gitattributes`.

**Verify:**
- [x] GitHub URL, web ir kontaktinis email yra realūs.
- [x] Blank issues išjungti.
- [x] Issue template sričių sąrašas neutralus.

---

## TASK-03: Starter kit brandos dokumentacija

**Risk:** LOW

- [x] `SECURITY.md` pakeisti iš produkto stadijos į starter kit palaikymo modelį.
- [x] PRD šablone pašalinti produkto brandos fazei pririštą formuluotę.
- [x] Produkto-specifinį PRD konvertuoti į starter kit PRD.
- [x] Produkto-specifinį task list konvertuoti į starter kit task list.
- [x] Produkto-specifinį design spec konvertuoti į starter kit design spec.

**Verify:**
- [ ] Public docs neturi klaidinančio produkto-specifinio pozicionavimo.
- [ ] Public docs neturi klaidinančios produkto brandos fazės formuluotės.
- [ ] Markdown nuorodos veikia.

---

## TASK-04: CI ir testų bazė

**Risk:** LOW

- [x] CI workflow paleidžia lint.
- [x] CI workflow paleidžia typecheck.
- [x] CI workflow paleidžia Vitest.
- [x] E2E job paliktas išjungtas, kol projekte atsiras stabilūs kritiniai vartotojo srautai.
- [x] Smoke testas renderina bazinį UI komponentą.

**Verify:**
- [x] `npm run lint`
- [x] `npx tsc --noEmit`
- [x] `npm run test:run`
- [x] `npm run build`

---

## TASK-05: Supabase/Vercel powerpack kryptis

**Risk:** MED

- [ ] Dokumentuoti Supabase local dev setup kelią.
- [ ] Dokumentuoti Vercel deploy setup kelią.
- [ ] Dokumentuoti, kurie env vars yra privalomi tik pasirinktoms integracijoms.
- [ ] Atskirdami Next.js default nuo Vite adaptacijos, nepridėti perteklinių abstrakcijų.

**Verify:**
- [ ] Setup instrukcijos veikia nuo švaraus klono.
- [ ] Dokumentacijoje aišku, kas yra default, o kas pasirenkama adaptacija.

---

## TASK-06: Vite + React adaptacijos kelias

**Risk:** MED

- [ ] Nuspręsti, ar Vite palaikomas kaip dokumentuotas migravimo kelias, ar atskiras template branch.
- [ ] Aprašyti Tailwind v4 ir shadcn/ui skirtumus Vite aplinkoje.
- [ ] Aprašyti Supabase client setup Vite aplinkoje.
- [ ] Aprašyti Vercel deploy apribojimus Vite SPA atveju.

**Verify:**
- [ ] Vite adaptacijos dokumentas neteigia nepatikrintų komandų.
- [ ] Next.js default setup išlieka veikiantis.

---

## TASK-07: Release readiness

**Risk:** LOW

- [ ] Sukurti `CHANGELOG.md`.
- [ ] Apibrėžti `v1.0.0` kriterijus.
- [ ] Patikrinti README nuo švaraus klono.
- [ ] Sukurti pirmą GitHub Release, kai maintaineris patvirtins.

**Verify:**
- [ ] Release kriterijai dokumentuoti.
- [ ] Pagrindiniai patikrinimai praeina prieš release tag.

---

## Risk summary

| Task | Risk | Kodėl |
|---|---|---|
| TASK-01 | LOW | Copy ir metadata pakeitimai |
| TASK-02 | LOW | GitHub docs/config |
| TASK-03 | LOW | Dokumentacijos konversija |
| TASK-04 | LOW | Esamas CI/testų flow |
| TASK-05 | MED | Supabase/Vercel setup gali priklausyti nuo realaus projekto |
| TASK-06 | MED | Vite kelias turi skirtis nuo Next.js default |
| TASK-07 | LOW | Release procesas be runtime pakeitimų |

---

## Open items

- **OI-1:** Vite palaikymą daryti per atskirą branch/template ar dokumentuotą adaptaciją?
- **OI-2:** Ar `CHANGELOG.md` turi būti kuriamas dabar, ar prieš pirmą release?
- **OI-3:** Ar Supabase local dev turi būti privalomas starterio brandos kriterijus?
- **OI-4:** Ar AI powerpack turi būti default workflow, ar pasirenkamas sluoksnis?

---

**Susiję dokumentai:**
- PRD: `docs/requirements/REQ-2026-04-26-001-advanced-vibe-coding-starter.md`
- Spec: `docs/superpowers/specs/2026-04-26-advanced-vibe-coding-starter-design.md`
