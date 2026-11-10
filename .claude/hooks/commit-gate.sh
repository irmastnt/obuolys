#!/usr/bin/env bash
# hooks/commit-gate.sh
# ============================================================================
# PreToolUse hook (matcher: Bash). Atpažįsta TIK `git commit` iš tool_input.command;
# visiems kitiems Bash kvietimams - greitas exit 0 (be sąnaudų). Tik git commit
# paleidžia brangų guard orkestratorių (pre-commit.sh run_all_guards) ir, jei
# BLOCKED, grąžina Claude Code hook JSON su ABIEM block formomis ({"decision":"block",...} IR
# {"hookSpecificOutput":{...,"permissionDecision":"deny",...}}) maksimaliam fail-closed suderinamumui.
# ----------------------------------------------------------------------------
# DĖMESIO: brangu (paleidžia `claude --print` per guard'ą). Registruok tik per
# /po-init ar /po-adapt, kai sąmoningai nori AI guard peržiūros prieš commit'ą.
# PreToolUse blokavimas = JSON (decision:block IR permissionDecision:deny; visada exit 0), NE exit 1.
#
# FAIL-CLOSED: jei komanda PANAŠI į git commit, bet gate negali jos įvertinti
# (jq nėra / įvestis neparse'inama / pre-commit.sh nerastas), grąžinamas statinis
# block JSON, o ne tylus exit 0. Ne-commit Bash kvietimai visada praleidžiami.
# ============================================================================

set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

_po_hook_input=""
for d in "${PLUGIN_ROOT:-}/hooks" "${CLAUDE_PLUGIN_ROOT:-}/hooks" ".codex/hooks" ".claude/hooks" "$(dirname "${BASH_SOURCE[0]:-$0}")"; do
  if [ -n "$d" ] && [ "$d" != "/hooks" ] && [ -f "$d/hook-input.sh" ]; then
    _po_hook_input="$d/hook-input.sh"
    break
  fi
done
if [ -n "$_po_hook_input" ]; then
  # shellcheck disable=SC1090
  . "$_po_hook_input"
fi

# Statinis fail-closed block: kai gate negali tinkamai įvertinti git commit'o, jis privalo
# blokuoti (saugos gate'as nepraleidžia commit'o, kurio realiai nepatikrino). PreToolUse
# blokavimas = JSON (abi block formos) su exit 0.
_po_block_static() {
  # PreToolUse blokavimas = JSON (visada exit 0). Emit'inam ABI suderinamas formas su VIENODU
  # block/deny ketinimu (radinys: fail-OPEN rizika emit'inant tik vieną): top-level
  # {"decision":"block","reason":...} (senesni Claude Code parseriai) IR {"hookSpecificOutput":
  # {...,"permissionDecision":"deny","permissionDecisionReason":...}} (dabartinė dokumentuota
  # PreToolUse forma). Abu laukai yra toje pačioje kanoninėje Claude Code hook output struktūroje ir
  # gali koegzistuoti; kadangi ketinimas VIENODAS (abi = BLOCK), precedencija nesvarbi - bet kuris
  # parseris, atpažįstantis bent vieną formą, BLOKUOJA. Tai maksimaliai fail-CLOSED: gate netaptų
  # fail-OPEN nei senuose, nei naujuose klientuose. (NEtinka prieštaringam ketinimui allow+deny -
  # čia jo nėra.)
  # SVARBU (radinys SA): NEnaudojam heredoc'o - read-only/pilname /tmp heredoc temp failas
  # nesukuriamas ir python net nepaleidžiamas -> JOKIO deny JSON -> fail-OPEN. Naudojam `python3 -c`
  # su argv (be temp failo) tinkamam JSON escape'ui; jei python nėra ar nieko negrąžino - pure-shell
  # printf fallback, kuris VISADA emit'ina galiojantį deny JSON (reason be `"`/`\`/newline).
  _po_bs_json=""
  if command -v python3 >/dev/null 2>&1; then
    _po_bs_json=$(python3 -c 'import json,sys; r=sys.argv[1]; print(json.dumps({"decision":"block","reason":r,"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":r}}))' "$1" 2>/dev/null)
  fi
  if [ -z "$_po_bs_json" ]; then
    _po_bs_reason=$(printf '%s' "$1" | tr -d '"\\' | tr '\n\r\t' '   ')
    _po_bs_json=$(printf '{"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$_po_bs_reason" "$_po_bs_reason")
  fi
  printf '%s\n' "$_po_bs_json"
  exit 0
}

# Coarse "ar panašu į git commit" patikra (pigi, BE false-negative): git commit komandoje
# VISADA yra ir "git", ir "commit" (nesvarbu kabutės, tarpai, nested bash -c). Jei bent vieno
# nėra - tikrai ne git commit. Naudojama ir raw INPUT fallback'ui (jq nėra / parse nepavyko ->
# fail-closed block), ir kaip pre-filtras prieš brangų shlex klasifikatorių. Tikslus sprendimas
# visada - klasifikatorius (jis korektiškai tvarko kabutes/tarpus/nested formas), tad coarse
# over-match nepavojingas (tiesiog grąžina NOT_COMMIT -> exit 0).
_po_looks_like_commit() {
  # Įprastas atvejis: yra "git" + commit/alias/config-injekcijos žymeklis.
  if printf '%s' "$1" | grep -q git; then
    printf '%s' "$1" | grep -q commit && return 0
    printf '%s' "$1" | grep -q 'alias\.' && return 0
    # Config injekcija (gali įnešti commit alias): -c include.path/includeIf, GIT_CONFIG*.
    printf '%s' "$1" | grep -qiE 'include\.path|includeif|GIT_CONFIG' && return 0
    # Repo-selection env (GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_COMMON_DIR): commit'as gali eiti į
    # KITĄ repo per alias'ą, gyvenantį TIKSLINIAME repo (kurio aliasų nematome), tad žodžio "commit"
    # komandoje gali ir nebūti. Maršrutuojam į klasifikatorių (jis fail-close'ina nežinomą subkomandą
    # su repo-selection env). Be šito `GIT_DIR=/x git ci` (alias.ci tiksliniame repo) praslystų (radinys GD2).
    printf '%s' "$1" | grep -qE '(^|[^A-Za-z0-9_])(GIT_DIR|GIT_WORK_TREE|GIT_INDEX_FILE|GIT_COMMON_DIR)=' && return 0
  fi
  # Obfuskuotas atvejis: "commit" + shell expansion/assignment - "git" vardas gali būti paslėptas
  # per $-konkatenaciją (pvz. `g=gi;h=t;"$g$h" commit`). Siunčiam klasifikatoriui (jis fail-closes
  # dinaminiam komandos vardui); jei tai ne commit - klasifikatorius vis tiek grąžins NOT_COMMIT.
  if printf '%s' "$1" | grep -q commit && printf '%s' "$1" | grep -qE '\$|`'; then
    return 0
  fi
  # Maksimaliai obfuskuotas: bypass flag (--no-verify/--all ARBA trumpas -n/-a klasteris) + shell
  # expansion - IR "git", IR "commit" gali būti sukonstruoti dinamiškai (`"$g$h" "$c$d" -n` ar
  # `... --no-verify`). Trumpą `-n` traktuojam kaip `--no-verify` (radinys TA - kitaip short forma
  # praslystų pro fully-obfuscated kelią). Klasifikatorius fail-closes dinaminiam komandos vardui.
  if printf '%s' "$1" | grep -qE -- '--no-verify|--all|(^| )-[A-Za-z]*[an][A-Za-z]*( |=|$)' \
     && printf '%s' "$1" | grep -qE '\$|`'; then
    return 0
  fi
  # git komanda su shell expansion IR bypass flag (-n/-a trumpas ar --no-verify/--all) - git/-C
  # taikinys/alias subkomanda gali būti dinaminiai (`git -C "$T" ci -n`). Klasifikatorius fail-closes.
  if printf '%s' "$1" | grep -q git && printf '%s' "$1" | grep -qE '\$|`' \
     && printf '%s' "$1" | grep -qE -- '--no-verify|--all|(^| )-[A-Za-z]*[an][A-Za-z]*( |=|$)'; then
    return 0
  fi
  return 1
}

# Surenka configured git aliasus, kurie reiškia `commit`. $1 (nebūtina) - repo katalogas (git -C).
# Grąžina po eilutę `vardas<TAB>reikšmė` (reikšmė reikalinga, kad būtų galima įvertinti įdėtus
# flag'us, pvz. `ci = !git commit --no-verify`).
_po_commit_aliases() {
  command -v git >/dev/null 2>&1 || return 0
  if [ -n "${1:-}" ]; then
    _aliasout=$(git -C "$1" config --get-regexp '^alias\.' 2>/dev/null)
  else
    _aliasout=$(git config --get-regexp '^alias\.' 2>/dev/null)
  fi
  # Emit'inam VISUS alias'us (ne tik tiesiogiai-commit). Chained alias'ai (radinys XA: alias.ci=cm,
  # alias.cm=commit --no-verify) reiškia, kad `ci` yra TRANZITYVUS commit alias - jį resolvina
  # klasifikatoriaus rekursija (ci->cm->commit). Be visų alias'ų prefiltras nematytų `ci` ir praleistų.
  printf '%s\n' "$_aliasout" | while IFS= read -r _l; do
    [ -n "$_l" ] || continue
    _name=${_l%% *}; _name=${_name#alias.}
    [ -n "$_name" ] || continue
    _val=${_l#* }
    printf '%s\t%s\n' "$_name" "$_val"
  done
}

# Geriausių pastangų `git -C <taikinys>` ištraukimas (kabutes nuima, backslash-escape'us išskleidžia),
# kad alias'us tikrintume ir tame repo (radinys: `git -C other-repo ci` su other-repo alias'u).
# `(\\.|...)` token'e leidžia `\ ` escape'intus tarpus (radinys NA: `-C /tmp/repo\ with\ spaces`),
# o galutinis sed nuima `\` prieš escape'intą simbolį.
_po_extract_dash_c() {
  printf '%s' "$1" | grep -oE "[[:space:]]-C[[:space:]]+('[^']*'|\"[^\"]*\"|(\\\\.|[^\"'[:space:]])+)" | head -1 \
    | sed -E "s/.*-C[[:space:]]+//; s/^['\"]//; s/['\"]\$//; s/\\\\(.)/\\1/g"
}

# Geriausių pastangų `cd <taikinys>` / `pushd <taikinys>` ištraukimas (kabutes nuima). Reikalingas
# simetriškai su -C: `cd other-repo && git ci -n` commit'ina KITĄ repo, kurio alias'ai (pvz.
# alias.ci=commit) gyvena tame repo. Be šito coarse prefiltras nemato "commit" nei žinomo alias'o,
# atmestų komandą (exit 0) ir --no-verify commit'as apeitų ir PreToolUse, ir git-hook backstop'ą.
# Grąžina po vieną taikinį eilutėje (gali būti keli `cd`).
_po_extract_cd_targets() {
  printf '%s' "$1" \
    | grep -oE "(^|[;&|(){[:space:]])(cd|pushd)[[:space:]]+('[^']*'|\"[^\"]*\"|(\\\\.|[^\"'[:space:]&|;()])+)" \
    | sed -E "s/^[^A-Za-z]*(cd|pushd)[[:space:]]+//; s/^['\"]//; s/['\"]\$//; s/\\\\(.)/\\1/g"
}

# Ar komanda naudoja kurį nors iš duotų alias vardų (kaip žodį)?
_po_cmd_uses_alias() {
  for _a in $2; do
    printf '%s' "$1" | grep -qw -- "$_a" && return 0
  done
  return 1
}

# Geriausių pastangų vykdomų SCRIPT failų ištraukimas (kabutes nuima). Formos:
#   (a) <shell|interpretatorius> [be -opcijų] <failas>  (pvz. `bash ./commit.sh`, `python3 ship.py`);
#   (b) tiesioginis ./failas | ../failas | /abs/failas komandos pozicijoje (pvz. `./commit.sh`);
#   (c) POSIX dot-source `. ./failas` (`source` jau (a));
#   (d) stdin-redirect `sh < ./failas`;
#   (e) reader pipe `cat ./failas | sh` (tik kai pipe į bare shell).
# Reikalinga radinys EA: `git commit --no-verify` script faile apeitų ir PreToolUse (komandoje
# nėra "git commit"), ir git-hook backstop'ą (--no-verify). (c)/(d)/(e) - radinys SR: dot-source,
# stdin-redirect ir pipe-į-shell formos irgi vykdo failo turinį, tad jas surenkam (kitaip prefiltras
# išeitų anksti su tuščiu PO_SCRIPT_FILES; (d)/(e) papildomai fail-close'ina klasifikatoriaus
# is_bare_shell). -c/-e inline kodo NEgrąžinam (jį tvarko klasifikatorius atskirai). Po vieną kelią eilutėje.
_po_script_exec_files() {
  # (a) interpretatorius [-opcijos|--]* failas (radinys KB: `bash -e ./x.sh`; radinys VB: `bash --
  # ./x.sh` end-of-options). Praleidžiam vedančius -opcijų token'us IR `--`; po jų eina failas.
  printf '%s' "$1" \
    | grep -oE "(^|[;&|(){[:space:]])(bash|sh|zsh|dash|ash|ksh|source|python|python2|python3|node|nodejs|ruby|perl|php|deno|bun)([[:space:]]+(--|-[A-Za-z][^[:space:];&|()]*))*[[:space:]]+('[^']*'|\"[^\"]*\"|[^-][^[:space:];&|()]*)" \
    | sed -E "s/^[^A-Za-z]*(bash|sh|zsh|dash|ash|ksh|source|python|python2|python3|node|nodejs|ruby|perl|php|deno|bun)([[:space:]]+(--|-[A-Za-z][^[:space:];&|()]*))*[[:space:]]+//; s/^['\"]//; s/['\"]\$//"
  # (b) tiesioginis path-vykdymas komandos pozicijoje (po ^/;/&/|)
  printf '%s' "$1" \
    | grep -oE "(^|[;&|])[[:space:]]*('[^']*'|\"[^\"]*\"|(\\.{1,2})?/[^[:space:];&|()]+)" \
    | sed -E "s/^[^/.'\"]*//; s/^['\"]//; s/['\"]\$//" \
    | grep -E '/'
  # (c) POSIX dot-source: `. ./failas` / `. /abs/failas` (`.` komandos pozicijoje, failas po jo).
  printf '%s' "$1" \
    | grep -oE "(^|[;&|(){]|[[:space:]])\.[[:space:]]+('[^']*'|\"[^\"]*\"|[^-][^[:space:];&|()]*)" \
    | sed -E "s/^.*\.[[:space:]]+//; s/^['\"]//; s/['\"]\$//"
  # (d) stdin-redirect: `sh < ./failas` (failas po `<`).
  printf '%s' "$1" \
    | grep -oE "<[[:space:]]*('[^']*'|\"[^\"]*\"|[^-<>&|;(){}[:space:]][^[:space:];&|()<>]*)" \
    | sed -E "s/^<[[:space:]]*//; s/^['\"]//; s/['\"]\$//"
  # (e) reader (`cat`/`head`/...) failas, KAI komandoje yra `| shell` (bare shell skaito stdin),
  # pvz. `cat ./failas | sh`. Pipe-į-shell tikrinimas saugo nuo `cat ./failas | grep x` (ne vykdymas).
  if printf '%s' "$1" | grep -qE '\|[[:space:]]*(sh|bash|zsh|dash|ash|ksh)([[:space:]]|;|&|\||$)'; then
    printf '%s' "$1" \
      | grep -oE "(^|[;&|(){]|[[:space:]])(cat|head|tail|tac|nl)[[:space:]]+('[^']*'|\"[^\"]*\"|[^-][^[:space:];&|()]*)" \
      | sed -E "s/^.*(cat|head|tail|tac|nl)[[:space:]]+//; s/^['\"]//; s/['\"]\$//"
  fi
}

# Ištraukia quoted payload'us po -c/--command/eval/-S/--split-string (kabutes nuima). Reikalinga
# radinys FA: nested `bash -c './commit.sh'` / `eval './commit.sh'` / `env -S './commit.sh'` slepia
# script vykdymą payload'e - jam reikia pritaikyti tą patį command-position detektorių.
_po_extract_payloads() {
  printf '%s' "$1" \
    | grep -oE "(^|[^A-Za-z0-9_-])(-c|--command|eval|-S|--split-string=?)[[:space:]]*('[^']*'|\"[^\"]*\")" \
    | sed -E "s/.*(-c|--command|eval|-S|--split-string=?)[[:space:]]*//; s/^['\"]//; s/['\"]\$//"
}

# Emit'ina kelią, jei tai egzistuojantis nedidelis (<256KB) failas, miniantis "commit".
_po_emit_if_secret_script() {
  [ -n "$1" ] && [ -f "$1" ] || return 0
  _po_sz=$(wc -c < "$1" 2>/dev/null || echo 0)
  [ "$_po_sz" -lt 262144 ] 2>/dev/null || return 0
  grep -q commit "$1" 2>/dev/null && printf '%s\n' "$1"
}

# Surenka repo-lokalius vykdomus script failus (top-level IR nested payload'uose, 2 lygiai), kurie
# EGZISTUOJA, nedideli (<256KB) ir mini "commit" - tik tokius verta shlex-skenuoti dėl --no-verify
# bypass'o (pigus pre-filtras; command-position detektorius -> `cat ./README.md` NEpakliūna).
# Reliatyvūs keliai tikrinami ir hook cwd, ir po kiekvienu static cd/pushd taikiniu - kitaip
# `cd other-repo && bash ./commit.sh` (script gyvena other-repo) apeitų gate'ą (radinys IA).
_po_collect_script_files() {
  # cd/pushd taikiniai iš komandos IR payload'ų (script kelias gali būti reliatyvus jiems).
  _po_cd_dirs=$({
    _po_extract_cd_targets "$1"
    _po_extract_payloads "$1" | while IFS= read -r _pl; do
      [ -n "$_pl" ] || continue
      _po_extract_cd_targets "$_pl"
      _po_extract_payloads "$_pl" | while IFS= read -r _pl2; do
        [ -n "$_pl2" ] && _po_extract_cd_targets "$_pl2"
      done
    done
  })
  {
    _po_script_exec_files "$1"
    _po_extract_payloads "$1" | while IFS= read -r _pl; do
      [ -n "$_pl" ] || continue
      _po_script_exec_files "$_pl"
      _po_extract_payloads "$_pl" | while IFS= read -r _pl2; do
        [ -n "$_pl2" ] && _po_script_exec_files "$_pl2"
      done
    done
  } | while IFS= read -r _sf; do
    [ -n "$_sf" ] || continue
    _po_emit_if_secret_script "$_sf"   # hook cwd / absoliutus
    # Reliatyvius kelius tikrinam ir po kiekvienu static cd taikiniu.
    case "$_sf" in
      /*) : ;;
      *) printf '%s\n' "$_po_cd_dirs" | while IFS= read -r _cdd; do
           case "$_cdd" in *'$'*|*'`'*|'') continue ;; esac   # dinaminį/tuščią cd praleidžiam
           [ -d "$_cdd" ] && _po_emit_if_secret_script "$_cdd/$_sf"
         done ;;
    esac
  done | sort -u
}

# Shell-level fallback: kai komandos negalima tiksliai klasifikuoti (python3 nėra ar parse
# nepavyko), konservatyviai blokuojam commit-panašias komandas su bypass žymekliais
# (--no-verify/-a/--all/compound git add/substitution/dinaminė). Degraduotas kelias - gali būti
# netikslu (pvz. žymeklis commit ŽINUTĖJE), bet python3 yra reikalavimas, tad tai retas atvejis.
_po_shell_fallback_check() {
  if printf '%s' "$1" | grep -Eq -- '--no-verify|--all|[Cc]ore\.[Hh]ooks[Pp]ath|\$\(|`|\$\{|\$[A-Za-z]|(^|[^A-Za-z0-9_-])git +(add|rm|reset|restore|stage)( |$)|(^| )-[A-Za-z]*[an][A-Za-z]*( |=|$)'; then
    _po_block_static "Pre-commit gate: komandos negalima tiksliai įvertinti (python3 nėra ar parse nepavyko), o ji turi bypass žymeklių (--no-verify/-a/core.hooksPath/compound/substitution/dinaminė). Įdiek python3 arba commit'ink švariu 'git commit -m'."
  fi
}

# jq trūksta -> negalim patikimai parse'inti komandos. FAIL-CLOSED tik jei raw atrodo kaip commit
# (kitiems Bash kvietimams - exit 0, kad neblokuotume viso darbo dėl trūkstamo jq).
if ! command -v jq >/dev/null 2>&1; then
  if _po_looks_like_commit "$INPUT"; then
    _po_block_static "Pre-commit gate negali veikti: jq nerastas PATH'e, o komanda panaši į 'git commit'. Įdiek jq (žr. docs/01-install.md) arba laikinai išjunk gate'ą."
  fi
  exit 0
fi

if command -v po_hook_command >/dev/null 2>&1; then
  CMD=$(po_hook_command "$INPUT" 2>/dev/null)
else
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
fi

# CMD tuščias (malformed įvestis) -> jei raw atrodo kaip commit, FAIL-CLOSED.
if [ -z "$CMD" ]; then
  if _po_looks_like_commit "$INPUT"; then
    _po_block_static "Pre-commit gate negali parse'inti komandos iš hook įvesties, bet ji panaši į 'git commit'. Patikrink hook konfigūraciją."
  fi
  exit 0
fi

# Vykdomi repo-lokalūs script failai su "commit" turiniu (radinys EA) - juos shlex-skenuos python
# (ar shell fallback) dėl įdėto `git commit --no-verify`. Renkam VISADA (pigu): jei komanda nevykdo
# tokio failo - tuščia. Naudojama ir prefiltre (nepraleisti į python), ir žemiau (perduoti python'ui).
PO_SCRIPT_FILES=$(_po_collect_script_files "$CMD")

# Coarse pre-filtras (pigus, BE false-negative): atmeta akivaizdžius ne-commit'us nepaleisdamas
# python'o. Plačiai pagauna ir kabutėse esančius kelius (`git -C "/path with spaces" commit`) bei
# nested formas - tikslus sprendimas paliekamas shlex klasifikatoriui žemiau.
PO_ALIAS_PAIRS=""
if ! _po_looks_like_commit "$CMD"; then
  if printf '%s' "$CMD" | grep -q git; then
    # Gali būti configured git alias (pvz. `git ci` su `git config alias.ci commit`) - tokia komanda
    # neturi žodžio "commit".
    PO_ALIAS_PAIRS=$(_po_commit_aliases)
    # Plius `git -C <taikinys>` repo alias'ai (jei komanda commit'ina kitą repo per -C).
    _po_ctarget=$(_po_extract_dash_c "$CMD")
    if [ -n "$_po_ctarget" ] && [ -d "$_po_ctarget" ]; then
      PO_ALIAS_PAIRS="$PO_ALIAS_PAIRS
$(_po_commit_aliases "$_po_ctarget")"
    fi
    # Plius `cd <taikinys> && ...` / `pushd` repo alias'ai (commit'as kitame repo po cd). Be šito
    # `cd other && git ci -n` (su other repo alias.ci=commit) apeitų gate'ą - žr. _po_extract_cd_targets.
    _po_cd_aliases=$(_po_extract_cd_targets "$CMD" | while IFS= read -r _cdt; do
      [ -n "$_cdt" ] && [ -d "$_cdt" ] && _po_commit_aliases "$_cdt"
    done)
    if [ -n "$_po_cd_aliases" ]; then
      PO_ALIAS_PAIRS="$PO_ALIAS_PAIRS
$_po_cd_aliases"
    fi
    # Alias vardai (pirmas TAB laukas) komandos panaudojimo patikrai.
    _po_alias_names=$(printf '%s\n' "$PO_ALIAS_PAIRS" | cut -f1 | tr '\n' ' ')
    if ! { [ -n "$_po_alias_names" ] && _po_cmd_uses_alias "$CMD" "$_po_alias_names"; }; then
      # Ne tiesioginis ir ne alias commit. Tęsiam TIK jei vykdomas script failas su "commit" viduje.
      [ -n "$PO_SCRIPT_FILES" ] || exit 0
    fi
  else
    # Komandoje nėra "git". Vienintelė priežastis tęsti - script failas su "commit" viduje (EA).
    [ -n "$PO_SCRIPT_FILES" ] || exit 0
  fi
fi

# Patvirtinta: tai git commit. PreToolUse paleidžiamas PRIEŠ komandos vykdymą, todėl gate gali
# peržiūrėti tik ESAMĄ indeksą. Kai kurios formos verstų tikrinti NE tą indeksą arba apeiti
# git-hook backstop'ą -> FAIL-CLOSED block. SVARBU: vertinam TIK realius opcijų token'us per
# shlex tokenizaciją - commit ŽINUTĖS turinys (-m/-F/--message reikšmės) NEtraktuojamas kaip
# flag'as (kitaip `git commit -m "minim --no-verify"` būtų klaidingai blokuotas).
# Jei python3 nėra ar komanda neparse'inama -> praleidžiam analizę ir einam į guard
# orkestratorių (core peržiūra vis tiek įvyksta).
PO_COMMIT_CD=""
if command -v python3 >/dev/null 2>&1; then
  PO_PY_OUT=$(python3 - "$CMD" "$PO_ALIAS_PAIRS" "$PO_SCRIPT_FILES" <<'PYEOF' 2>/dev/null
import shlex, sys, os, re

# Configured commit-aliasai: `vardas<TAB>reikšmė` eilutės. Reikšmė reikalinga įdėtiems flag'ams
# (pvz. `ci = !git commit --no-verify`) - alias'as resolvinamas kaip komanda, ne tik vardas.
CONFIGURED_ALIASES = {}
if len(sys.argv) > 2:
    for _line in sys.argv[2].splitlines():
        if '\t' in _line:
            _n, _v = _line.split('\t', 1)
            if _n:
                CONFIGURED_ALIASES[_n] = _v
SHELLS = {'sh','bash','zsh','dash','ash','ksh'}
# Ne-shell interpretatoriai: jų inline kodo (-c/-e) parse'inti negalim - jei jame git+commit,
# fail-closed (pvz. `python3 -c 'subprocess.run(["git","commit","--no-verify"])'`).
INTERPRETERS = {'python','python2','python3','node','nodejs','ruby','perl','php','deno','bun',
                'pwsh','powershell','osascript'}
WRAPPERS = {'env','command','nice','nohup','time','setsid','stdbuf','exec','builtin'}
# Shell control keyword'ai, galintys eiti PRIEŠ komandą segmente (po ;/&&/| split'o):
# `if true; then git commit ...` -> 'then' segmentas; `! git commit ...` -> '!' prefiksas.
CONTROL_KW = {'!', 'if', 'then', 'elif', 'else', 'while', 'until', 'do', 'for', '{', '}'}
VALUE_OPTS = {
    '-m','--message','-F','--file','-c','--reedit-message','-C','--reuse-message',
    '--squash','--fixup','--author','--date','--cleanup','--trailer',
    '-t','--template','--pathspec-from-file','--git-dir','--work-tree','--namespace',
    '--super-prefix','--exec-path','--config-env',
}
SHORT_VALUE = set('mFcCt')
# Optional-attached-value short opcijos: `-S[<keyid>]` (gpg-sign). Skirtumas nuo SHORT_VALUE: bare
# `-S` NEsuvalgo kito token'o (keyid privalo būti ATTACHED, pvz. -Skeyid), o `-Skeyid` likusį token'o
# turinį traktuoja kaip reikšmę (NE flag'ų klasterį) - kitaip `git commit -S -m msg` klaidingai
# laikytų `msg` pathspec'u, o `-Sdeadbeef` raidę 'a' laikytų `-a` (radinys HB).
SHORT_OPTVALUE = set('S')
STAGE = {'add','rm','mv','reset','restore','stage'}
# Saugios (NE-commit) git subkomandos. Reikalingos GIT_DIR/GIT_WORK_TREE env atvejui: kai repo-selection
# env nustatytas, gate nemato tikslinio repo aliasų, tad NEŽINOMA subkomanda (galimas commit alias tame
# repo) -> fail-closed; ŽINOMA ne-commit subkomanda -> leidžiam (jokio false-positive `GIT_DIR=/x git log`).
# `commit` čia SĄMONINGAI nėra (jis tvarkomas atskirai per commit_segs/has_wtf).
NON_COMMIT_SAFE = {
    'status','log','diff','show','fetch','pull','push','clone','remote','branch','checkout','switch',
    'restore','reset','stash','tag','rev-parse','ls-files','ls-tree','ls-remote','cat-file','blame',
    'describe','shortlog','reflog','show-ref','symbolic-ref','for-each-ref','rev-list','merge-base',
    'grep','clean','gc','fsck','bisect','cherry-pick','revert','rebase','merge','apply','am',
    'format-patch','worktree','submodule','notes','archive','bundle','help','version','name-rev',
    'whatchanged','count-objects','update-index','update-ref','verify-commit','verify-tag','diff-tree',
    'diff-index','diff-files','config','add','rm','mv','init','range-diff','cherry','sparse-checkout',
    'maintenance','prune','repack','pack-refs','annotate','difftool','mergetool','pull','clean'
}
BYPASS_PRI = ['BYPASS:noverify','BYPASS:hookspath','BYPASS:dynamic','BYPASS:worktreeform','BYPASS:all','BYPASS:pathspec','BYPASS:compound','BYPASS:multicommit','BYPASS:alias']

# Necituotus newline'us paverčia komandų separatoriumi `;` (radinys RA): shlex newline laiko
# whitespace'u, tad `git add .<newline>git commit --no-verify` be šito susilietų į vieną segmentą ir
# commit'as liktų neatpažintas (NOT_COMMIT -> bypass). Kabučių/escape-aware: newline kabutėse (multi-
# line commit žinutė) ar po `\` (line continuation) NEskaidomas.
def split_newlines(cmd):
    out = []; q = None; esc = False
    for ch in cmd:
        if esc:
            out.append(ch); esc = False; continue
        if ch == '\\' and q != "'":
            out.append(ch); esc = True; continue
        if q:
            out.append(ch)
            if ch == q: q = None
            continue
        if ch == '"' or ch == "'":
            q = ch; out.append(ch); continue
        if ch == '\n':
            out.append(';'); continue
        out.append(ch)
    return ''.join(out)

# Kabučių/skliaustų simboliai per chr() - tas pats bash 3.2 $(...)-su-heredoc apribojimas kaip
# scan_script_file pattern'e (nelyginis kabučių skaičius čia sulaužytų bash'o parserį).
Q1 = chr(39); Q2 = chr(34); BT = chr(96); LP = chr(40); RP = chr(41)
HEREDOC_STOP = ' \t\n;&|<>' + LP + RP

def heredoc_delim(s, j):
    # Heredoc terminatoriaus žodis nuo pozicijos j (kabutės nuimamos). quoted=True, kai bent dalis
    # cituota ar escape'inta: tada kūnas yra grynas tekstas (be $(...)/backtick išskleidimo).
    d = []; quoted = False; n = len(s)
    while j < n and s[j] not in HEREDOC_STOP:
        c = s[j]
        if c == Q1 or c == Q2:
            quoted = True; k = s.find(c, j + 1)
            if k < 0:
                return (None, quoted, n)
            d.append(s[j+1:k]); j = k + 1; continue
        if c == '\\':
            quoted = True
            if j + 1 < n: d.append(s[j+1])
            j += 2; continue
        d.append(c); j += 1
    return (''.join(d) or None, quoted, j)

def scan_shell(cmd, heredoc_body=False):
    # Kabučių-aware skaitytuvas (radinys FP: nekenksmingos komandos su git/commit žodžiais buvo
    # blokuojamos). Grąžina (tekstas, subs, heredocs, balanced):
    #   tekstas  - komanda BE heredoc kūnų (kūnas yra duomenys, ne komandos; apostrofas jame anksčiau
    #              darydavo UNPARSEABLE -> block);
    #   subs     - $(...) ir backtick kūnai (taip pat kabutėse ir neapsaugotų heredoc'ų kūnuose) -
    #              jie VYKDOMI, tad klasifikuojami rekursiškai vietoj aklo substitution block'o;
    #   heredocs - (kūnas, quoted, operatoriaus eilutė);
    #   balanced - False, kai kabutės/skliaustai neužsidaro (kviečiantysis fail-close'ina).
    # heredoc_body=True: neapsaugoto heredoc kūno režimas (kabutės literalios, $(...)/backtick aktyvūs).
    out = []; subs = []; heredocs = []; pending = []; starts = []
    stack = ['h' if heredoc_body else 'c']
    i = 0; n = len(cmd)
    while i < n:
        ch = cmd[i]; top = stack[-1]
        if top == Q1:
            out.append(ch); i += 1
            if ch == Q1: stack.pop()
            continue
        if ch == '\\':
            out.append(cmd[i:i+2]); i += 2; continue
        if ch == '\n' and pending and top in ('c', LP, BT, 'p'):
            # Heredoc kūnai prasideda po operatoriaus eilutės ir baigiasi terminatoriaus eilute.
            out.append(ch); i += 1; resume = i
            for (delim, quoted, strip_tabs, opline) in pending:
                body = []; found = False
                while i < n:
                    e = cmd.find('\n', i)
                    if e < 0: e = n
                    ln = cmd[i:e]; i = min(e + 1, n)
                    if (ln.lstrip('\t') if strip_tabs else ln) == delim:
                        found = True; break
                    body.append(ln)
                if not found:
                    # Neužbaigtas heredoc: nieko neslepiam (tekstas lieka komandų analizei).
                    i = resume; heredocs = [h for h in heredocs if h[3] != resume]; break
                heredocs.append(('\n'.join(body), quoted, opline, resume))
            pending = []
            continue
        if top in (Q2, 'h'):
            if ch == Q2 and top == Q2:
                stack.pop(); out.append(ch); i += 1; continue
            if cmd.startswith('$' + LP, i):
                out.append('$' + LP); i += 2; stack.append(LP); starts.append(len(out)); continue
            if ch == BT:
                out.append(ch); i += 1; stack.append(BT); starts.append(len(out)); continue
            out.append(ch); i += 1; continue
        # Kodo kontekstas: 'c' (viršus), LP ($(...) kūnas), BT (backtick kūnas), 'p' (skliaustai jame).
        if ch == Q1 or ch == Q2:
            stack.append(ch); out.append(ch); i += 1; continue
        if cmd.startswith('$' + LP, i):
            out.append('$' + LP); i += 2; stack.append(LP); starts.append(len(out)); continue
        if ch == LP and top in (LP, 'p'):
            stack.append('p'); out.append(ch); i += 1; continue
        if ch == RP and top == 'p':
            stack.pop(); out.append(ch); i += 1; continue
        if ch == RP and top == LP:
            stack.pop(); subs.append(''.join(out[starts.pop():])); out.append(ch); i += 1; continue
        if ch == BT:
            if top == BT:
                stack.pop(); subs.append(''.join(out[starts.pop():]))
            else:
                stack.append(BT); starts.append(len(out) + 1)
            out.append(ch); i += 1; continue
        if ch == '#' and (i == 0 or cmd[i-1] in ' \t\n;&|' + LP):
            e = cmd.find('\n', i)
            i = n if e < 0 else e
            continue
        if not heredoc_body and cmd.startswith('<<', i) and not cmd.startswith('<<<', i) \
           and (i == 0 or cmd[i-1] != '<'):
            j = i + 2; strip_tabs = False
            if j < n and cmd[j] == '-':
                strip_tabs = True; j += 1
            while j < n and cmd[j] in ' \t':
                j += 1
            delim, quoted, end = heredoc_delim(cmd, j)
            if delim:
                ls = cmd.rfind('\n', 0, i) + 1; le = cmd.find('\n', i)
                pending.append((delim, quoted, strip_tabs, cmd[ls:le if le >= 0 else n]))
                out.append(cmd[i:end]); i = end; continue
        out.append(ch); i += 1
    balanced = stack == ['h' if heredoc_body else 'c']
    return (''.join(out), subs, [(b, q, o) for (b, q, o, _) in heredocs], balanced)

def tokenize(cmd):
    lex = shlex.shlex(split_newlines(cmd), posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    return list(lex)

def split_segments(tokens):
    segs, cur = [], []
    for t in tokens:
        if (t and all(c in "();<>|&" for c in t)) or t == ";":
            if cur: segs.append(cur); cur = []
        else:
            cur.append(t)
    if cur: segs.append(cur)
    return segs

def strip_wrappers(seg):
    i = 0; changed = True
    while changed and i < len(seg):
        changed = False
        # leading shell control keyword'ai (! if then do { ...)
        while i < len(seg) and seg[i] in CONTROL_KW:
            i += 1; changed = True
        # env VAR=val prefiksai
        while i < len(seg) and ('=' in seg[i]) and not seg[i].startswith('-'):
            i += 1; changed = True
        # wrapper komandos (env/command/exec/nice/...)
        if i < len(seg) and seg[i].rsplit('/', 1)[-1] in WRAPPERS:
            w = seg[i].rsplit('/', 1)[-1]
            i += 1; changed = True
            if w == 'env':
                # env opcijos: -i/-0/-v/--ignore-environment (be arg); -u/-C/-S/--unset/--chdir/
                # --split-string (su atskiru arg); VAR=val. Likusios -opcijos -> be arg / =-forma.
                while i < len(seg):
                    t = seg[i]; base = t.split('=', 1)[0]
                    if '=' in t and not t.startswith('-'):
                        i += 1; changed = True
                    elif base in ('-u', '-C', '-S', '--unset', '--chdir', '--split-string') and '=' not in t:
                        i += 2; changed = True
                    elif t.startswith('-'):
                        i += 1; changed = True
                    else:
                        break
            else:
                # kiti wrapper'iai (command/exec/nice/...): praleidžiam tik VAR=val; opcijas su
                # argumentais (pvz. nice -n 10) palieka classify leftover-option fail-closed apsaugai.
                while i < len(seg) and ('=' in seg[i] and not seg[i].startswith('-')):
                    i += 1; changed = True
    return seg[i:]

SHELL_VALUE_OPTS = {'-o','+o','-O','+O','--rcfile','--init-file'}

def shell_payloads(seg):
    # Tikras shell opcijų modelis (sh/bash/zsh): praleidžia opcijas su atskiru argumentu
    # (`-o pipefail`, `--rcfile f`), kad `bash -o pipefail -c 'payload'` payload'as būtų išgautas.
    seg = strip_wrappers(seg)
    if not seg or seg[0].rsplit('/', 1)[-1] not in SHELLS:
        return []
    j = 1
    while j < len(seg):
        tok = seg[j]
        if tok == '--':
            return []  # po -- eina script/args, ne -c
        if tok == '-c' or tok == '--command' or (tok.startswith('-') and not tok.startswith('--') and 'c' in tok):
            return [seg[j+1]] if j+1 < len(seg) else []
        if tok in SHELL_VALUE_OPTS:
            j += 2; continue  # opcija su atskiru argumentu (pvz. -o pipefail)
        if tok.startswith('-') or tok.startswith('+'):
            if not tok.startswith('--') and tok[-1] in ('o', 'O'):
                j += 2; continue  # trumpas bundle baigiasi -o/-O value-opt -> argumentas toliau
            j += 1; continue
        return []  # pirmas ne-opcijos token'as be -c = script -> ne -c forma
    return []

def is_bare_shell(seg):
    # Bare shell (sh/bash/...) BE -c ir BE script failo skaito komandas iš STDIN (pvz.
    # `printf '...' | sh`, `cat s | bash`, here-string). Payload'o (stdin) nematom -> fail-closed.
    s = strip_wrappers(seg)
    if not s or s[0].rsplit('/', 1)[-1] not in SHELLS:
        return False
    j = 1
    while j < len(s):
        t = s[j]
        if t == '-c' or t == '--command' or (t.startswith('-') and not t.startswith('--') and 'c' in t):
            return False  # -c -> kodas argumente, ne stdin
        if t == '-s' or t == '--stdin':
            j += 1; continue  # -s aiškiai stdin
        if t in SHELL_VALUE_OPTS:
            j += 2; continue
        if t.startswith('-') or t.startswith('+'):
            j += 1; continue
        return False  # pozicijinis = script failas, ne stdin
    return True

def eval_payload(seg):
    seg = strip_wrappers(seg)
    if seg and seg[0].rsplit('/', 1)[-1] == 'eval' and len(seg) > 1:
        return [' '.join(seg[1:])]
    return []

def env_split_payload(seg):
    # `env -S "cmd"` / `--split-string=cmd` VYKDO string'ą kaip komandą -> grąžinam jį payload'u.
    i = 0
    while i < len(seg) and (seg[i] in CONTROL_KW or ('=' in seg[i] and not seg[i].startswith('-'))):
        i += 1
    s = seg[i:]
    if not s or s[0].rsplit('/', 1)[-1] != 'env':
        return []
    j = 1
    while j < len(s):
        t = s[j]
        if '=' in t and not t.startswith('-'):
            j += 1; continue
        if t in ('-S', '--split-string'):
            return [s[j+1]] if j+1 < len(s) else []
        if t.startswith('--split-string='):
            return [t.split('=', 1)[1]]
        if t.startswith('-S') and not t.startswith('--'):
            return [t[2:]] if len(t) > 2 else ([s[j+1]] if j+1 < len(s) else [])
        if t in ('-u', '-C', '--unset', '--chdir'):
            j += 2; continue
        if t.startswith('-'):
            j += 1; continue
        break
    return []

def parse_git(seg):
    # Grąžina (subkomanda, args_nuo_subkomandos, -C taikinys, ar --git-dir/--work-tree, inline_aliasai,
    # ar nustatomas core.hooksPath per -c/--config-env).
    seg = strip_wrappers(seg)
    if not seg or seg[0].rsplit('/', 1)[-1] != 'git':
        return (None, None, None, False, {}, False)
    i = 1; cd_target = None; wtf = False; aliases = {}; hookspath = False
    while i < len(seg):
        tok = seg[i]; base = tok.split('=', 1)[0]; has_eq = '=' in tok
        if tok.startswith('-'):
            if base == '-C':
                cd_target = tok.split('=', 1)[1] if has_eq else (seg[i+1] if i+1 < len(seg) else None)
            if base in ('--git-dir','--work-tree'):
                wtf = True
            if base in ('-c', '--config-env'):
                val = tok.split('=', 1)[1] if has_eq else (seg[i+1] if i+1 < len(seg) else '')
                if val.startswith('alias.') and '=' in val:
                    ak, av = val[6:].split('=', 1)
                    # -c -> reikšmę turim; --config-env -> reikšmė env'e (neresolvinama) -> None
                    aliases[ak] = av if base == '-c' else None
                # core.hooksPath override (case-insensitive git config raktas) NUKREIPIA git hookus
                # kitur ir IŠJUNGIA pre-commit backstop'ą - tas pats bypass kaip --no-verify (radinys HP).
                if val.split('=', 1)[0].strip().lower() == 'core.hookspath':
                    hookspath = True
            i += 2 if (base in VALUE_OPTS and not has_eq) else 1
        else:
            return (tok, seg[i:], cd_target, wtf, aliases, hookspath)
    return (None, None, cd_target, wtf, aliases, hookspath)

def commit_risky_flags(args):
    found = set(); i = 1
    while i < len(args):
        tok = args[i]
        if tok == '--':
            # po -- viskas yra pathspec (wrong-index forma)
            if i + 1 < len(args): found.add('pathspec')
            break
        if tok.startswith('--'):
            base = tok.split('=', 1)[0]
            if base == '--no-verify': found.add('--no-verify')
            elif base == '--all': found.add('--all')
            elif base == '--only': found.add('--only')
            elif base == '--include': found.add('--include')
            # Wrong-index formos: --pathspec-from-file[=...]/--pathspec-file-nul (keliai iš failo),
            # --patch/--interactive (hunk'ai iš worktree) - commit'ina NE peržiūrėtą indeksą (radinys MA).
            elif base in ('--pathspec-from-file','--pathspec-file-nul','--patch','--interactive'):
                found.add('pathspec')
            # --gpg-sign[=keyid] / --no-gpg-sign - NE value-opcijos (i+=1; reikšmė attached per '=').
            i += 2 if (base in VALUE_OPTS and '=' not in tok) else 1
            continue
        if tok.startswith('-') and len(tok) > 1:
            letters = tok[1:]; consumed = False
            for idx, ch in enumerate(letters):
                if ch in SHORT_OPTVALUE:
                    break  # -S[<keyid>]: likęs token'as = opcionalus attached keyid, NE flag'ai
                if ch == 'n': found.add('-n')
                elif ch == 'a': found.add('-a')
                elif ch == 'o': found.add('--only')
                elif ch == 'i': found.add('--include')
                elif ch == 'p': found.add('pathspec')   # -p = --patch (hunk select -> wrong index)
                elif ch in SHORT_VALUE:
                    if idx == len(letters) - 1: consumed = True
                    break
            i += 2 if consumed else 1
            continue
        # pozicijinis argumentas po `commit` = pathspec (commit'ina ne peržiūrėtą indeksą)
        found.add('pathspec')
        i += 1
    return found

def classify(cmd, depth=0):
    if depth > 5:
        return ("AMBIGUOUS", None)
    try:
        stripped, subs, hdocs, balanced = scan_shell(cmd)
        if not balanced:
            return ("UNPARSEABLE", None)
        segs = split_segments(tokenize(stripped))
    except ValueError:
        return ("UNPARSEABLE", None)
    commit_segs = []  # (risky_flags, cd, wtf) - VISI commit segmentai (ne tik paskutinis)
    mutates = False; nested = []; alias_opaque = False; dynamic_git = False; running_cd = None
    hookspath_seen = False; worktree_env_seen = False; env_unsafe_sub = False
    for seg in segs:
        # Dinaminis komandos VARDAS pozicijoje (pvz. `G=git; $G commit`) - po wrapper/control strip
        # pirmasis token'as yra $-išskleidimas; gali būti `git`. Taip pat leftover -opcija reiškia
        # nepilnai išparse'intą wrapper'į (pvz. `nice -n 10 git commit`). Fail-closed (commit-panaši).
        _sw = strip_wrappers(seg)
        if _sw and ('$' in _sw[0] or BT in _sw[0] or _sw[0].startswith('-')):
            dynamic_git = True
        # `cd <dir>` / `pushd <dir>` PRIEŠ commit - efektyvi commit repo keičiasi (pvz.
        # `cd ../other && git commit`). Sekam, kad guard'us paleistume teisingame repo.
        if _sw and _sw[0] in ('cd', 'pushd'):
            for _a in _sw[1:]:
                if not _a.startswith('-'):
                    running_cd = _a; break
        # Bare shell skaitantis stdin (`printf '...' | sh`) - payload'o nematom -> fail-closed.
        if is_bare_shell(seg):
            dynamic_git = True
        # Ne-shell interpretatorius su inline kodu (-c/-e), turinčiu git+commit -> negalim parse'inti
        # payload'o (ne shell) -> fail-closed. (Script failo - ne inline - turinio komandoje nematom.)
        if _sw and _sw[0].rsplit('/', 1)[-1] in INTERPRETERS:
            for _k in range(1, len(_sw)):
                _tk = _sw[_k]
                if _tk in ('-c', '-e', '--eval', '--exec', '--command') or \
                   (_tk.startswith('-') and not _tk.startswith('--') and ('c' in _tk or 'e' in _tk)):
                    _pl = _sw[_k+1] if _k+1 < len(_sw) else ''
                    # Žodžio ribos: `github`/`digit`/`commits` tekste nėra git commit (radinys FP).
                    if re.search(r'\bgit\b', _pl) and re.search(r'\bcommit\b', _pl):
                        dynamic_git = True
                    break
                if not _tk.startswith('-'):
                    break  # pirmas ne-opcijos token'as = script failas, ne inline kodas
        # GIT_CONFIG* env injekcija (gali įnešti alias/config per env) ARBA `-c include.path/includeif`
        # (gali įnešti config su alias'ais) -> negalim įvertinti -> fail-closed. GIT_DIR/GIT_WORK_TREE/
        # GIT_INDEX_FILE/GIT_COMMON_DIR env nurodo KITĄ repo/indeksą/work-tree (env atitikmuo --git-dir/
        # --work-tree formai, radinys GD) -> gate peržiūrėtų ne tą, kurį commit'ina -> worktreeform.
        # strip_wrappers šiuos VAR=value prefiksus nuima prieš parse_git, tad gaudom čia (ant raw seg).
        for _idx, _t in enumerate(seg):
            if '=' in _t and not _t.startswith('-'):
                _envk = _t.split('=', 1)[0]
                if _envk.startswith('GIT_CONFIG'):
                    dynamic_git = True
                elif _envk in ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR'):
                    worktree_env_seen = True
            _b = _t.split('=', 1)[0]
            if _b in ('-c', '--config-env'):
                _cv = _t.split('=', 1)[1] if '=' in _t else (seg[_idx+1] if _idx+1 < len(seg) else '')
                if _cv.split('=', 1)[0].lower().startswith('include'):
                    dynamic_git = True
        sub, args, cd, w, aliases, hookspath = parse_git(seg)
        if hookspath:
            hookspath_seen = True
        # Repo-selection env (GIT_DIR/...) + NEŽINOMA git subkomanda: kadangi tikslinio repo aliasų
        # nematome, ši subkomanda gali būti commit alias tame repo -> fail-closed (radinys GD2). Žinomos
        # ne-commit subkomandos (NON_COMMIT_SAFE) ir žinomi aliasai/commit/stage NEpakliūna; dinaminę ($)
        # subkomandą tvarko dynamic_git.
        if worktree_env_seen and sub is not None and '$' not in sub and sub != 'commit' \
           and sub not in STAGE and sub not in NON_COMMIT_SAFE \
           and sub not in aliases and sub not in CONFIGURED_ALIASES:
            env_unsafe_sub = True
        # Inline `-c alias.X=Y` alias'us padarom matomus REKURSIJAI (chained inline alias'ai, radinys
        # XA: `-c alias.ci=cm -c alias.cm='commit --no-verify' ci`). Be šito rekursinis classify('git cm')
        # nematytų cm (inline aliasai lieka tik šio segmento `aliases` dict'e). Configured turi pirmenybę.
        for _ak, _av in aliases.items():
            CONFIGURED_ALIASES.setdefault(_ak, _av)
        # git -C <dinaminis $> <ne-commit subkomanda> su bypass flag'u (-n/--no-verify/-a): target
        # repo alias'o negalim resolvint, o bypass flag apeitų hook'ą -> fail-closed.
        if cd and '$' in cd and sub is not None and sub != 'commit':
            _df = commit_risky_flags(args)
            if _df & {'--no-verify', '-n', '-a', '--all'}:
                dynamic_git = True
        if sub == 'commit':
            commit_segs.append((commit_risky_flags(args), cd or running_cd, w, hookspath))
        elif sub in STAGE:
            mutates = True
        elif sub is not None and ('$' in sub or BT in sub):
            # git <param> - subkomanda nežinoma (pvz. bash -c 'git "$1"' _ commit); gali būti commit.
            dynamic_git = True
        elif sub is not None and (sub in aliases or sub in CONFIGURED_ALIASES):
            # subkomanda yra alias (inline -c arba configured) -> realiai vykdoma alias reikšmė
            # PLIUS call-site argumentai. `!`-prefiksuoti aliasai yra shell komandos (be 'git ').
            av = aliases.get(sub) if sub in aliases else CONFIGURED_ALIASES.get(sub)
            if av is None:
                alias_opaque = True  # --config-env alias - reikšmės neturim
            else:
                tail = ' '.join(args[1:]) if args and len(args) > 1 else ''
                if av.startswith('!'):
                    resolved = (av[1:].strip() + ' ' + tail).strip()   # shell alias body
                else:
                    resolved = ('git ' + av + ' ' + tail).strip()
                _nv, _ncd = classify(resolved, depth + 1)
                # alias'as resolvinamas DABARTINIAME running_cd repo (pvz. `cd ../other && git ci`):
                # jei nested commit be savo -C/cd, paveldi running_cd, kad gate eitų į teisingą repo.
                nested.append((_nv, _ncd or running_cd))
        for p in shell_payloads(seg) + eval_payload(seg) + env_split_payload(seg):
            nested.append(classify(p, depth + 1))
    # $(...)/backtick kūnai VYKDOMI (ir kabutėse, pvz. `echo "$(git commit -n)"`) - klasifikuojam
    # rekursiškai. Anksčiau bet koks substitution commit-panašioje komandoje blokuodavo aklai (radinys FP).
    for body in subs:
        nested.append(classify(body, depth + 1))
    for body, quoted, opline in hdocs:
        # Neapsaugotas heredoc (<<EOF) išskleidžia $(...)/backtick kūne - juos irgi klasifikuojam.
        if not quoted:
            for b in scan_shell(body, heredoc_body=True)[1]:
                nested.append(classify(b, depth + 1))
        # Kūnas, paduodamas shell'ui ar interpretatoriui (`python3 - <<EOF`, `cat <<EOF | bash`), yra
        # vykdomas kodas - skenuojam kaip script failą (tik --no-verify/core.hooksPath bypass'ui).
        if any(w in SHELLS or w in INTERPRETERS for w in re.findall(r'[A-Za-z0-9_]+', opline)):
            hv = scan_script_text(body, depth + 1)
            if hv:
                nested.append((hv, None))
    local = None; local_cd = None
    if commit_segs:
        has_nv = any(('--no-verify' in f or '-n' in f) for f, _, _, _ in commit_segs)
        has_wtf = any(w for _, _, w, _ in commit_segs) or worktree_env_seen
        has_hookspath = any(hp for _, _, _, hp in commit_segs)
        has_all = any(('-a' in f or '--all' in f) for f, _, _, _ in commit_segs)
        has_pathspec = any(({'pathspec', '--only', '--include'} & f) for f, _, _, _ in commit_segs)
        if has_nv: local = "BYPASS:noverify"
        elif has_hookspath: local = "BYPASS:hookspath"
        elif has_wtf: local = "BYPASS:worktreeform"
        elif has_all: local = "BYPASS:all"
        elif has_pathspec: local = "BYPASS:pathspec"
        elif mutates: local = "BYPASS:compound"
        elif len(commit_segs) > 1: local = "BYPASS:multicommit"
        else: local = "OK"; local_cd = commit_segs[0][1]
    if local is None and dynamic_git:
        local = "BYPASS:dynamic"
    # core.hooksPath išoriniame `-c` + alias, kuris resolvinasi į realų commit (nested OK), pvz.
    # `git -c core.hooksPath=/x ci` su alias.ci=commit. core.hooksPath nepatenka į alias reikšmę, tad
    # rekursija jo nemato - čia pagaunam. Sąlyga `nested OK` saugo nuo false-positive ne-commit aliasams
    # (pvz. `git -c core.hooksPath=/x st` su alias.st=status -> nested NOT_COMMIT -> NEblokuojam).
    if local is None and hookspath_seen and any(v == "OK" for (v, _) in nested):
        local = "BYPASS:hookspath"
    # GIT_DIR/GIT_WORK_TREE/... env + alias, kuris resolvinasi į realų commit (nested OK), pvz.
    # `GIT_DIR=/x git ci` su alias.ci=commit -> tas pats wrong-repo bypass kaip tiesioginis commit.
    if local is None and worktree_env_seen and any(v == "OK" for (v, _) in nested):
        local = "BYPASS:worktreeform"
    # Repo-selection env + nežinoma subkomanda (galimas commit alias nematomame tiksliniame repo) ->
    # fail-closed, net jei nested neturi OK (alias'o resolvint negalim) (radinys GD2).
    if local is None and env_unsafe_sub:
        local = "BYPASS:worktreeform"
    if local is None and alias_opaque:
        local = "BYPASS:alias"
    verdicts = [local] + [v for (v, _) in nested]
    # Propaguojam nested OK cd/-C taikinį (pvz. bash -c 'cd /other && git commit') - kitaip
    # gate peržiūrėtų ne tą repo. Dinaminį/nepavykusį cd sutvarko BB fail-closed (cd-handling).
    nested_cd = next((c for (v, c) in nested if v == "OK" and c), None)
    for b in BYPASS_PRI:
        if b in verdicts: return (b, None)
    if "AMBIGUOUS" in verdicts: return ("AMBIGUOUS", None)
    if "UNPARSEABLE" in verdicts: return ("UNPARSEABLE", None)
    if "OK" in verdicts: return ("OK", local_cd or nested_cd)
    return ("NOT_COMMIT", None)

def scan_script_file(path):
    # Skaito vykdomą script failą ir tikrina, ar jame yra `git commit --no-verify` (BYPASS:noverify) -
    # tokia forma apeitų git-hook backstop'ą (--no-verify) IR PreToolUse (komandoje "git commit" nėra).
    # Tik --no-verify: PAPRASTĄ commit'ą script'e pagauna git pre-commit hook'as (jis veikia ant realaus
    # indekso), tad jo čia neblokuojam (kitaip lūžtų įprastas `bash release.sh`). Eilutė po eilutės, nes
    # shlex naujų eilučių nelaiko separatoriais; greitas praleidimas, jei eilutėje nėra "commit".
    try:
        if not os.path.isfile(path) or os.path.getsize(path) > 262144:
            return None
        with open(path, 'r', errors='replace') as fh:
            body = fh.read(262144)
    except Exception:
        return None
    return scan_script_text(body)

def scan_script_text(body, depth=1):
    # scan_script_file turinio dalis (naudojama ir heredoc kūnams, paduodamiems shell'ui/interpretatoriui).
    if depth > 5:
        return None
    joined = body.replace('\\\n', ' ')
    # (1) Shell-script: per-eilutės shlex klasifikacija (tiksli - gaudo ir `git commit -n`, ignoruoja
    #     -n ŽINUTĖJE, pvz. `git commit -m "use -n"`).
    for line in joined.split('\n'):
        if 'commit' not in line:
            continue
        lv, _ = classify(line, depth)
        if lv in ('BYPASS:noverify', 'BYPASS:hookspath'):
            return lv
    # (2) Ne-shell script (python/node `subprocess.run(["git","commit","-n"])`, `execSync("git
    #     commit --no-verify")` ir pan.): git args yra STRING LITERALAI. Ištraukiam cituotus token'us,
    #     sujungiam ir klasifikuojam tuo pačiu shlex keliu - taip pagaunamas IR `-n`, IR `--no-verify`
    #     (per commit_risky_flags), bet proza su leading žodžiais (`print("the git commit -n flag")`)
    #     lieka NOT_COMMIT, o `head -n 5` necituotas shell kontekstas čia nepakliūna (radinys KA).
    # Pattern statomas per chr() (be literalų " ar ' eilutėje), kad bash'o $(...) heredoc quote-
    # tracker'is nesulūžtų dėl nelyginio kabučių skaičiaus (sena bash 3.2 $()-su-heredoc klaida).
    _dq = chr(34); _sq = chr(39)
    _qp = '[' + _dq + _sq + ']([^' + _dq + _sq + ']*)[' + _dq + _sq + ']'
    for line in joined.split('\n'):
        if 'commit' not in line:
            continue
        quoted = re.findall(_qp, line)
        if not quoted:
            continue
        # JOIN (list-forma `["git","commit","-n"]`) PLIUS kiekvienas token'as atskirai (string-forma
        # `execSync("git commit -n")`, kur kiti token'ai - pvz. "child_process" - eilutėje nesvarbūs).
        for cand in [' '.join(quoted)] + quoted:
            if 'commit' not in cand:
                continue
            qv, _ = classify(cand, depth)
            if qv in ('BYPASS:noverify', 'BYPASS:hookspath'):
                return qv
    # (3) DAUGIAEILIS non-shell arg-masyvas (radinys ML): `subprocess.run([\n "git",\n "commit",\n
    #     "-n"\n ])` - elementai atskirose eilutėse, tad (2) per-eilutės nepagauna. Surenkam VISUS
    #     cituotus literalus FAILE iš eilės, sujungiam ir klasifikuojam. Flag'inam TIK noverify/hookspath
    #     (NE pathspec), tad data masyvai be bypass flag'o (pvz. ["git","commit","msg"] -> pathspec) ar
    #     proza su leading žodžiu ("the git commit -n") lieka NEflag'inami - mažas false-positive paviršius.
    all_quoted = re.findall(_qp, joined)
    if all_quoted and 'git' in joined and 'commit' in joined:
        gv, _ = classify(' '.join(all_quoted), depth)
        if gv in ('BYPASS:noverify', 'BYPASS:hookspath'):
            return gv
    return None

v, cd = classify(sys.argv[1] if len(sys.argv) > 1 else "")
# Script-failų skenavimas (argv[3] = newline-joined keliai, surinkti shell pusėje): jei vykdomas
# script turi `git commit --no-verify` ARBA `git -c core.hooksPath=... commit`, tai bypass net jei
# pati komanda atrodo nekalta.
if v not in ('BYPASS:noverify', 'BYPASS:hookspath') and len(sys.argv) > 3 and sys.argv[3].strip():
    for _p in sys.argv[3].splitlines():
        _p = _p.strip()
        if not _p:
            continue
        _sv = scan_script_file(_p)
        if _sv in ('BYPASS:noverify', 'BYPASS:hookspath'):
            v = _sv; cd = None; break
print(v)
if cd and v == "OK":
    print("CD:" + cd)
PYEOF
)
  PO_COMMIT_VERDICT=$(printf '%s\n' "$PO_PY_OUT" | head -1)
  PO_COMMIT_CD=$(printf '%s\n' "$PO_PY_OUT" | sed -n 's/^CD://p' | head -1)
  case "$PO_COMMIT_VERDICT" in
    BYPASS:noverify)
      _po_block_static "Pre-commit gate: --no-verify (-n) apeina commit guard'us ir git-hook backstop'ą (net įdėtas per bash -c/eval). Commit'ink BE --no-verify, kad guard'ai suveiktų." ;;
    BYPASS:hookspath)
      _po_block_static "Pre-commit gate: 'git -c core.hooksPath=...' (ar --config-env=core.hooksPath) nukreipia git hookus kitur ir taip IŠJUNGIA pre-commit backstop'ą (gate ir secret skeneris nepatikrintų galutinio indekso). Commit'ink BE core.hooksPath override." ;;
    BYPASS:all)
      _po_block_static "Pre-commit gate: 'git commit -a/--all' stage'ina commit metu, tad gate negali peržiūrėti galutinio indekso. Pirma 'git add' (atskiru veiksmu), tada 'git commit' be -a." ;;
    BYPASS:pathspec)
      _po_block_static "Pre-commit gate: 'git commit <pathspec>' / --only / --include commit'ina ne peržiūrėtą indeksą (worktree turinį pagal kelią), tad gate (ir secret skeneris) matytų ne tą. Pirma 'git add <failai>' (atskiru veiksmu), tada 'git commit' be pathspec." ;;
    BYPASS:compound)
      _po_block_static "Pre-commit gate: indekso keitimas (git add/rm/mv/...) ir commit toje pačioje komandoje - gate matytų ne galutinį indeksą. Atskirk 'git add' ir 'git commit' į atskirus veiksmus (tool calls)." ;;
    BYPASS:worktreeform)
      _po_block_static "Pre-commit gate: 'git --git-dir/--work-tree ... commit' ARBA GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE env formos PreToolUse negali patikimai peržiūrėti (indeksas/work-tree/repo kitur). Commit'ink iš to repo vidaus (be šių override'ų), kad gate matytų teisingą indeksą." ;;
    BYPASS:dynamic)
      _po_block_static "Pre-commit gate: dinaminė komanda ar git subkomanda (pvz. 'git \$1', \$(...) ar backtick komandos vietoje), kurios įvertinti negalima. Commit'ink tiesioginiu 'git commit'." ;;
    BYPASS:multicommit)
      _po_block_static "Pre-commit gate: kelios git commit komandos vienoje invokacijoje - PreToolUse gali peržiūrėti tik vieną indeksą. Commit'ink po vieną (atskiri tool calls)." ;;
    BYPASS:alias)
      _po_block_static "Pre-commit gate: inline git alias (-c alias.*=... / --config-env), kurio reikšmės įvertinti negalima. Commit'ink tiesiogiai, be inline alias." ;;
    OK)
      : ;; # tęsiam į guard orkestratorių (su galimu CD)
    *)
      # NOT_COMMIT: klasifikatorius įrodė, kad tai ne commit. $(...)/backtick kūnus jis klasifikuoja
      # rekursiškai, o substitution komandos ar git subkomandos pozicijoje duoda BYPASS:dynamic, tad
      # atskiro aklo substitution block'o nebereikia (jis stabdė ir `ls -la "${HOME}"`, radinys FP).
      [ "$PO_COMMIT_VERDICT" = "NOT_COMMIT" ] && exit 0
      # EMPTY (klasifikatorius nepasileido/krito - pvz. heredoc temp failas read-only /tmp), AMBIGUOUS
      # (gylio limitas/cikliniai alias'ai) ar UNPARSEABLE (nesubalansuotos kabutės): komanda PRAĖJO
      # commit-like prefiltrą, BET python3 YRA, tad klasifikatorius turėjo veikti - jei negrąžino
      # įvertinamo verdikto, negalim įrodyti, kad tai NE bypass (pvz. `--only`/`core.hooksPath` su
      # neveikiančiu klasifikatoriumi). BESĄLYGIŠKAI fail-closed (radinys YA), NE siauras shell fallback.
      _po_block_static "Pre-commit gate: komanda panaši į git commit, bet klasifikatorius negrąžino įvertinamo verdikto (galimas heredoc/temp trikdis read-only ar pilname /tmp, dviprasmiška ar neparse'inama forma). Fail-closed. Įsitikink, kad TMPDIR/tmp rašomas, ir commit'ink švariu 'git commit -m'."
      ;;
  esac
else
  # python3 nėra (degraduota - python3 yra reikalavimas). Negalim tiksliai klasifikuoti ->
  # shell-level konservatyvus fail-closed bypass žymekliams (kitaip compound --no-verify praeitų).
  _po_shell_fallback_check "$CMD"
  # Script-failų bypass be python3 (grubus grep): shell forma `git commit ... -n/--no-verify` ARBA
  # kalbai agnostiška forma (eilutė su git + commit + -n/--no-verify, pvz. subprocess) ARBA
  # `core.hooksPath` + commit (išjungia git-hook backstop'ą lygiai kaip --no-verify, radinys HP-deg).
  # Degraduotas kelias - konservatyvus (gali over-block'inti), bet python3 yra reikalavimas, tad retas.
  if [ -n "$PO_SCRIPT_FILES" ]; then
    if printf '%s\n' "$PO_SCRIPT_FILES" | while IFS= read -r _sf; do
        [ -n "$_sf" ] || continue
        grep -Eq 'git[[:space:]]+commit[^|;&]*([[:space:]]--no-verify|[[:space:]]-[A-Za-z]*n)' "$_sf" 2>/dev/null && echo HIT
        grep -E -- '--no-verify|(^|[^A-Za-z0-9_-])-[A-Za-z]*n([^A-Za-z0-9_-]|$)' "$_sf" 2>/dev/null | grep commit | grep -qw git && echo HIT
        # core.hooksPath script faile + commit kažkur faile -> backstop bypass (konservatyvu degraduotai).
        { grep -Eiq 'core\.hookspath' "$_sf" 2>/dev/null && grep -q commit "$_sf" 2>/dev/null; } && echo HIT
      done | grep -q HIT; then
      _po_block_static "Pre-commit gate: vykdomas script failas apeina git-hook backstop'ą ('git commit --no-verify' arba 'git -c core.hooksPath=...'). Pašalink --no-verify/core.hooksPath iš script'o arba commit'ink tiesiogiai."
    fi
  fi
fi

# Jei commit naudoja `git -C <path>` / `cd <path> &&`, peržiūrim TĄ repo (ne hook proceso cwd).
# FAIL-CLOSED: dinaminis taikinys ($/backtick - hook proceso neišskleidžiamas) ARBA nepavykęs cd
# reikštų, kad gate peržiūrėtų NE tą repo (ir secret skeneris praleistų) -> blokuojam.
if [ -n "$PO_COMMIT_CD" ]; then
  case "$PO_COMMIT_CD" in
    *'$'*|*'`'*)
      _po_block_static "Pre-commit gate: dinaminis git -C / cd taikinys ($PO_COMMIT_CD), kurio gate negali resolvint - peržiūrėtų ne tą repo. Commit'ink iš to repo vidaus (be dinaminio -C/cd)." ;;
  esac
  cd "$PO_COMMIT_CD" 2>/dev/null \
    || _po_block_static "Pre-commit gate: nepavyko pereiti į commit taikinį ($PO_COMMIT_CD) - gate negali peržiūrėti teisingo repo. Commit'ink iš to repo vidaus."
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$REPO_ROOT" || exit 0

# Surask hook katalogą (kur yra pre-commit.sh). TRUST: pirmenybė patikimam plugin'ui
# (${CLAUDE_PLUGIN_ROOT}), tada repo .claude/hooks (radinys OA) - kai plugin'as įdiegtas, source'inam
# TRUSTED pre-commit.sh, ne repo kopiją.
HOOK_DIR=""
for d in "${CLAUDE_PLUGIN_ROOT:-}/hooks" ".claude/hooks" "$(dirname "${BASH_SOURCE[0]:-$0}")"; do
  if [ -n "$d" ] && [ "$d" != "/hooks" ] && [ -f "$d/pre-commit.sh" ]; then
    HOOK_DIR="$d"
    break
  fi
done

# pre-commit.sh nerastas, BET tai PATVIRTINTAS git commit -> FAIL-CLOSED (gate negali patikrinti).
[ -n "$HOOK_DIR" ] || _po_block_static "Pre-commit gate įdiegtas, bet pre-commit.sh nerastas (.claude/hooks/, plugin, ar šalia commit-gate.sh). Gate negali patikrinti commit'o - paleisk /po-init arba /po-adapt."

# Source'inam pre-commit.sh kaip biblioteką (PO_GATE_LIB=1 -> main blokas praleistas)
PO_GATE_LIB=1
export PO_GATE_LIB
# shellcheck disable=SC1090
. "$HOOK_DIR/pre-commit.sh"

run_all_guards

if [ "${BLOCKED:-0}" -gt 0 ]; then
  # FAIL-CLOSED: naudojam _po_block_static (turi printf JSON fallback), kad ir be python3
  # BLOCKED virstų block JSON, o ne tyliu exit 0 = allow.
  _po_block_static "Pre-commit guard gate BLOCKED - commit'as sustabdytas.

${GUARD_REPORT:-}

Pataisyk problemas ir bandyk vėl. (Šis gate'as valdo Claude Code lygį.)"
fi

exit 0
