# Prisidėjimo gidas

Ačiū, kad prisidedate prie `advanced-vibe-coding-starter`. Šis dokumentas aprašo minimalų workflow, kurio reikia tvarkingiems GitHub issue ir pull request’ams.

## Prieš pradedant

1. Peržiūrėkite [`README.md`](README.md).
2. Susiraskite susijusį PRD arba task dokumentą `docs/requirements/` ir `docs/tasks/`.
3. Jei tokio nėra, sukurkite issue arba PRD prieš pradedant didesnį pakeitimą.

## Lokalus setup

```bash
npm ci
npm run lint
npm run test:run
npm run build
```

AI starterio patikra:

```bash
bash scripts/verify.sh
```

## Darbo principai

- **Minimalus diff:** keiskite tik tai, kas tiesiogiai susiję su issue/task.
- **Root-cause first:** taisykite priežastį, ne simptomus.
- **Esamos konvencijos:** failų, komponentų, UI kalbos ir testų stilius turi sekti repo praktiką.
- **Jokių paslapčių:** necommittinkite `.env.local`, API raktų, service role key ar webhook secret.
- **Testai:** naujas elgesys turi turėti testą arba aiškią priežastį PR aprašyme, kodėl testas nepridėtas.

## Branch ir commit gairės

Rekomenduojami branch pavadinimai:

```text
feature/<trumpas-aprasymas>
fix/<trumpas-aprasymas>
docs/<trumpas-aprasymas>
chore/<trumpas-aprasymas>
```

Commit žinutėms rekomenduojamas Conventional Commits formatas:

```text
feat: pridėti kontaktų sąrašą
fix: pataisyti pipeline stage validaciją
docs: sutvarkyti README
chore: atnaujinti CI konfigūraciją
```

## Pull request reikalavimai

PR turi turėti:

- aiškų problemos ir sprendimo aprašymą;
- nuorodą į issue, PRD arba task;
- atliktų patikrinimų sąrašą;
- screenshot arba video, jei keičiamas UI;
- migracijos ir rollback planą, jei keičiasi DB schema;
- saugumo pastabas, jei keičiasi auth, RLS, mokėjimai ar webhook’ai.

## Patikrinimai prieš PR

```bash
npm run lint
npx tsc --noEmit
npm run test:run
npm run build
```

Jei pakeitimai liečia Playwright scenarijus:

```bash
npm run test:e2e
```

Jei pakeitimai liečia RLS ar DB:

```bash
npm run test:rls
```

## Dokumentacija

Atnaujinkite dokumentaciją, jei pakeitimas keičia:

- setup eigą;
- environment kintamuosius;
- public API arba route’us;
- CI/CD procesą;
- PRD/task statusą;
- saugumo ar mokėjimų elgesį.

## Issue triage

Naudokite GitHub issue templates:

- **Bug report:** kai funkcija neveikia pagal lūkestį.
- **Feature request:** kai siūlomas naujas elgesys arba UI.

Saugumo problemoms naudokite [`SECURITY.md`](SECURITY.md), ne public issue.
