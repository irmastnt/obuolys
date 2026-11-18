## Santrauka

Trumpai aprašykite, ką keičia šis PR.

## Susiję dokumentai / issue

- Closes #
- PRD / TASK:

## Pakeitimų tipas

- [ ] Bug fix
- [ ] Feature
- [ ] Refactor
- [ ] Dokumentacija
- [ ] Chore / tooling
- [ ] Saugumas

## Patikrinimai

- [ ] `npm run lint`
- [ ] `npx tsc --noEmit`
- [ ] `npm run test:run`
- [ ] `npm run build`
- [ ] `npm run test:e2e` jei keistas E2E/UI flow
- [ ] `npm run test:rls` jei keista DB/RLS
- [ ] `bash scripts/verify.sh` jei keistas starterio/AI tooling sluoksnis

## UI pakeitimai

Jei keistas UI, pridėkite screenshot arba video.

## Saugumo poveikis

- [ ] Nėra auth/RLS/payment/security poveikio
- [ ] Keičiasi auth/session
- [ ] Keičiasi RLS/tenant izoliacija
- [ ] Keičiasi Stripe/payment/webhook logika
- [ ] Keičiasi secrets/env/CI/CD

Pastabos:

## Rollback planas

Kaip saugiai atšaukti pakeitimą, jei production’e atsiranda problema?

## Checklist

- [ ] Pakeitimas minimalus ir susietas su issue/task
- [ ] Dokumentacija atnaujinta, jei reikia
- [ ] Nėra hardcoded secrets
- [ ] Nėra nereikalingų refactor’ų
- [ ] PR paruoštas review
