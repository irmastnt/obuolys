# Saugumo politika

## Palaikomos versijos

Šis starter kit palaikomas kaip aktyviai vystoma bazė naujiems Node/React projektams. Saugumo pataisos taikomos `main` šakai ir naujausiai publikuotai versijai, jei tokia yra.

| Versija / šaka | Palaikoma |
|---|---|
| `main` | Taip |
| Senesnės šakos | Ne, nebent aiškiai susitarta |

## Pažeidžiamumų raportavimas

Neraportuokite saugumo problemų viešuose GitHub issue.

Rekomenduojamas kelias:

1. Atidarykite https://github.com/ponasObuolys/advanced-vibe-coding-starter/security/advisories/new.
2. Pasirinkite **Security**.
3. Naudokite **Report a vulnerability** arba private security advisory funkciją, jei ji įjungta.

Jei GitHub Security Advisory nėra pasiekiamas, rašykite el. paštu: labas@ponasobuolys.lt.

Raporte pateikite:

- trumpą pažeidžiamumo aprašymą;
- paveiktą komponentą arba route’ą;
- reprodukcijos žingsnius;
- galimą poveikį;
- siūlomą pataisymą, jei turite.

## Atsakymo lūkesčiai

- Pirminis patvirtinimas: per 3 darbo dienas.
- Triage ir rizikos įvertinimas: per 7 darbo dienas.
- Kritinių problemų pataisymas: kuo greičiau, priklausomai nuo poveikio ir reprodukuojamumo.

## Scope

Į scope patenka:

- auth ir session valdymas;
- Supabase RLS ir tenant izoliacija;
- Stripe webhook’ai ir mokėjimų logika;
- server-side API route’ai ir Server Actions;
- secret leakage;
- dependency supply-chain rizikos;
- CI/CD ir GitHub Actions konfigūracija.

Į scope nepatenka:

- social engineering;
- fizinė prieiga prie įrenginių;
- testiniai DoS be išankstinio suderinimo;
- problemos trečiųjų šalių paslaugose, kurios nėra kontroliuojamos šiame repo.

## Paslapčių tvarkymas

Niekada necommittinkite:

- `.env.local` ar kitų realių `.env*` failų;
- Supabase service role key;
- Stripe secret key;
- webhook secret;
- Anthropic, Vercel, GitHub ar kitų API tokenų.

Jei secret pateko į Git istoriją, laikykite jį kompromituotu ir nedelsiant rotuokite tiekėjo dashboard’e.
