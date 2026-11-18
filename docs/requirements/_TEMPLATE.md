# REQ-YYYY-MM-DD-NNN: <feature pavadinimas>

> Fazė 1 šablonas. Nukopijuokite šį failą su konkrečia data ir numeriu, pvz. `REQ-2026-04-25-001-refund-button.md`.

## User need (viena eilutė)

<Kas ir kodėl to prašo. Pvz.: "Customer Success komanda turi galimybę grąžinti pinigus tiesiai iš admin panelės, o ne per Stripe Dashboard.">

## Non-goals

<Ką SĄMONINGAI nedarome šiame PR'e. Pvz.:>
- Partial refund'ai (tik full refund šiame etape)
- Refund'as per vartotojo profilį (tik admin)
- Webhook'ų naujinimas (kitas PR)

## Success criteria (testuojami)

- [ ] Admin spaudžia "Grąžinti" — Stripe gauna `refund.created` event'ą
- [ ] Klientas gauna el. laišką per ≤ 5 min
- [ ] DB `refunds` lentelėje atsiranda įrašas su `stripe_refund_id`
- [ ] Audit log: `admin_id`, `order_id`, `amount`, `reason`, `created_at`
- [ ] Playwright E2E testas: iki Stripe redirect

## Architectural alternatives (PRIVALOMA ≥ 2)

### Alternative A — Tiesioginis Stripe SDK call iš Server Action

- **Pliusai:** paprasta, 1 endpoint'as, nėra asinchroninio sudėtingumo.
- **Minusai:** jei Stripe lėtai atsako — vartotojas laukia 30s; nėra retry.

### Alternative B — Background job su pg-boss

- **Pliusai:** retry, asinchroninis, admin gauna notifikaciją "refund pending".
- **Minusai:** papildoma infrastruktūra (pg-boss), sudėtingesnis flow, ilgesnis feedback loop.

### Recommended: A

**Pagrindimas:** šiame etape renkamės paprastesnį sprendimą. Pereisime prie B, kai apimtis > 100 refund/dieną. Kol kas — A + Stripe SDK retry built-in.

## Risk assessment

| Rizika | Tikimybė | Poveikis | Mitigacija |
|---|---|---|---|
| Duplikuotas refund (2× click) | Vidutinė | Aukštas (finansinis) | Idempotency key = `refund_${order_id}` |
| Stripe webhook missed | Žema | Vidutinis | Cron job sync every 6h |
| Admin be autorizacijos | Žema | Kritinis | Middleware + RLS |

## Guard Gap Analysis

**Klausimas:** Jei kas nors nepavyks šiame feature'e, kuris guard agent'as sustabdys?

| Scenarijus | Guardas, kuris sustabdo |
|---|---|
| Missing idempotency key | `payment-guard` |
| Nėra admin auth check'o | `security-guard` |
| DB migracija be RLS | `db-migration-guard` + `security-guard` |
| Nėra Playwright E2E | `test-coverage-guard` |
| Mažas coverage | `test-coverage-guard` |
| `refunds` lentelė > 300 LOC | `file-size-guard` |

**Guard Gap:** <Kas NĖRA padengta?>
- Pvz.: "Jei Stripe webhook grįžta failed status, nėra agento, kuris sustabdytų merge'ą" → Rizika priimama raštu, arba sukuriamas naujas `webhook-failure-guard`.

## Priklausomybės

- Blokuoja: REQ-2026-04-20-003 (admin panel scaffold)
- Blokuojama: nėra
- Paveikia: `orders`, `refunds`, `audit_log` lentelės

## Rollback planas

Jei po deploy'o atsiranda problema:
1. `git revert <commit>` → redeploy
2. DB migracija (žr. `supabase/migrations/20260425_refund_up.sql`) — turi `DOWN` scriptą
3. Stripe test mode: refund'ų DB įrašai pažymimi `status='reverted_ops'`

## Autorius

<Vardas> · YYYY-MM-DD
