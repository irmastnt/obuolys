# Tasks for REQ-YYYY-MM-DD-NNN

> Fazė 2 šablonas. Kiekviena užduotis = vienas PR = vienas commit. Jei > 100 LOC — skaldome toliau.

## TASK-YYYY-MM-DD-NNN-01: Create `refunds` DB schema

**DoD (Definition of Done):**
- [ ] Migracija `supabase/migrations/<ts>_refunds_up.sql` sukurta
- [ ] Rollback script `<ts>_refunds_down.sql` arba `-- DOWN:` komentaras yra
- [ ] RLS policies: admin-only read/write
- [ ] Testas: `npx supabase db test` praeina
- [ ] `db-migration-guard` grąžina `OK`

**Paveikti failai:**
- `supabase/migrations/<timestamp>_refunds_up.sql` (NEW)
- `supabase/migrations/<timestamp>_refunds_down.sql` (NEW)

**Reikalingi MCP:**
- Supabase (migration apply + RLS check)

**Guard agentai:**
- `db-migration-guard` (privaloma)
- `security-guard` (privaloma — dėl RLS)

**LOC limitas:** 50 LOC

**Priklausomybės:** nėra

---

## TASK-YYYY-MM-DD-NNN-02: Stripe refund Server Action

**DoD:**
- [ ] `app/actions/refund.ts` su `createRefund(orderId, reason)` funkcija
- [ ] Idempotency key = `refund_${orderId}`
- [ ] Admin auth check (`role === 'admin'`)
- [ ] Error handling: Stripe error → grąžina `{ ok: false, error }`
- [ ] Unit testas: `app/actions/refund.test.ts` (mock Stripe)
- [ ] `payment-guard` grąžina `OK`

**Paveikti failai:**
- `app/actions/refund.ts` (NEW, ≤ 80 LOC)
- `app/actions/refund.test.ts` (NEW)

**Reikalingi MCP:**
- Stripe (SDK docs)
- Context7 (Next.js Server Actions best practices)

**Guard agentai:**
- `payment-guard` (privaloma)
- `security-guard` (auth check)
- `test-coverage-guard` (unit test)

**LOC limitas:** 80 LOC (feature) + 60 LOC (test)

**Priklausomybės:** blokuojama TASK-01

---

## TASK-YYYY-MM-DD-NNN-03: Admin UI "Grąžinti" mygtukas

**DoD:**
- [ ] Komponentas `app/admin/orders/RefundButton.tsx`
- [ ] Loading state kai kviečia Server Action
- [ ] Confirmation dialog prieš refund'ą
- [ ] Toast notification po success/error
- [ ] LT kalba (su diakritika)
- [ ] `language-guard` grąžina `OK`

**Paveikti failai:**
- `app/admin/orders/RefundButton.tsx` (NEW, ≤ 120 LOC)
- `app/admin/orders/page.tsx` (MODIFIED — įtraukti komponentą)

**Reikalingi MCP:**
- Context7 (shadcn/ui Dialog, Sonner)

**Guard agentai:**
- `language-guard`
- `file-size-guard`

**LOC limitas:** 120 LOC

**Priklausomybės:** blokuojama TASK-02

---

## TASK-YYYY-MM-DD-NNN-04: Playwright E2E — refund flow

**DoD:**
- [ ] `e2e/admin/refund.spec.ts` sukurtas
- [ ] Testas: admin login → orders list → "Grąžinti" → confirm → assert DB ir Stripe test mode
- [ ] CI praeina (`npm run test:e2e`)
- [ ] `test-coverage-guard` grąžina `OK`

**Paveikti failai:**
- `e2e/admin/refund.spec.ts` (NEW)
- `e2e/fixtures/admin-user.ts` (NEW or REUSE)

**Reikalingi MCP:**
- Playwright
- Supabase (seed data)
- Stripe (test mode verification)

**Guard agentai:**
- `test-coverage-guard`

**LOC limitas:** 150 LOC

**Priklausomybės:** blokuojama TASK-03

---

## TASK-YYYY-MM-DD-NNN-05: Docs + release notes

**DoD:**
- [ ] `docs/features/refund-flow.md` aprašytas flow
- [ ] Release notes įrašas
- [ ] Admin onboarding screenshot

**Paveikti failai:**
- `docs/features/refund-flow.md` (NEW)
- `CHANGELOG.md` (MODIFIED)

**LOC limitas:** n/a (dokumentacija)

**Priklausomybės:** blokuojama TASK-04
