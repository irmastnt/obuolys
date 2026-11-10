#!/usr/bin/env bash
# hooks/po-config.sh
# ============================================================================
# SOURCE'INAMAS helper (NE vykdomas tiesiogiai). Nuskaito projekto .po-config.json
# ir eksportuoja PO_* kintamuosius bei po_trigger_pattern() funkciją.
# ----------------------------------------------------------------------------
# Naudojimas (iš kito hook'o): `. "$(dirname "$0")/po-config.sh"`
#
# Bash 3.2 suderinamas (be `declare -A`, be `mapfile`).
# Graceful: jei nėra .po-config.json arba nėra `jq` - eksportuoja default reikšmes,
# kad guard'ai ir hook'ai vis tiek veiktų.
# ============================================================================

# Aplinkos override išsaugomas prieš uždedant default'us ir skaitant config.
_PO_GUARD_PROVIDER_ENV="${PO_GUARD_PROVIDER:-}"

# --- Default reikšmės (galioja, jei .po-config.json ar jq nėra) ---
PO_COVERAGE_THRESHOLD=80
PO_MAX_FILE_LINES=400
PO_MAX_FUNCTION_LINES=50
PO_MAX_COMPONENT_LINES=250
PO_BUILD_CMD=""
PO_LINT_CMD=""
PO_TEST_CMD=""
PO_FORMAT_CMD=""
PO_UI_LANGUAGE="lt"
PO_WIKI_GATE="true"
PO_DOCS_GATE="true"
PO_ENABLED_GUARDS="risk-assessor language-guard file-size-guard security-guard test-coverage-guard db-migration-guard"
# Guard gate režimas: "per-guard" (senas elgesys - atskiras claude kvietimas kiekvienam guard'ui)
# arba "combined" (vienas claude kvietimas su visų trigger'intų guard'ų sekcijomis - pigiau/greičiau).
# Default kai rakto NĖRA = per-guard (backward compat esamiems projektams).
PO_GUARD_MODE="per-guard"
PO_GUARD_MODEL="sonnet"
PO_GUARD_PROVIDER="auto"
PO_GUARD_CLAUDE_MODEL="sonnet"
PO_GUARD_CODEX_MODEL=""
# Guard timeout (sek.) iš config'o. Tuščia = nenurodyta, tada pre-commit.sh renkasi numatytąją
# reikšmę pagal parinktą providerį (po_guard_timeout_default). Config kelias veikia be sesijos
# perkrovimo, skirtingai nei aplinkos kintamasis nustatymų faile.
PO_GUARD_TIMEOUT_CONFIG=""
# Drift slenksčiai: Stop/commit gate'ai blokuoja tik kai drift >= threshold commit'ų.
PO_WIKI_DRIFT_THRESHOLD=3
PO_DOCS_DRIFT_THRESHOLD=3

# --- Surask config failą dabartinio repo šaknyje ---
_po_repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$_po_repo_root" ]; then
  PO_CONFIG="$_po_repo_root/.po-config.json"
else
  PO_CONFIG=".po-config.json"
fi

# --- Validacija: jei config YRA, bet jo negalim perskaityti (nėra jq) ar jis ne validus JSON -
# pažymim, kad gate galėtų fail-closed. (Kitaip tyliai grįžtų prie default guard'ų, prarasdamas
# payment-guard, custom trigger'ius, slenksčius ir kt.)
PO_CONFIG_INVALID=0
if [ -f "$PO_CONFIG" ]; then
  if ! command -v jq >/dev/null 2>&1; then
    PO_CONFIG_INVALID=1   # config yra, bet be jq neperskaitomas
  elif ! jq -e . "$PO_CONFIG" >/dev/null 2>&1; then
    PO_CONFIG_INVALID=1   # config yra, bet ne validus JSON
  fi
fi

# --- Jei yra failas IR jq - perrašom default'us realiomis reikšmėmis ---
if [ -f "$PO_CONFIG" ] && command -v jq >/dev/null 2>&1; then
  _po_get() { jq -r "$1 // empty" "$PO_CONFIG" 2>/dev/null; }

  _v=$(_po_get '.config.coverage_threshold');       [ -n "$_v" ] && PO_COVERAGE_THRESHOLD="$_v"
  _v=$(_po_get '.config.max_file_lines');           [ -n "$_v" ] && PO_MAX_FILE_LINES="$_v"
  _v=$(_po_get '.config.max_function_lines');        [ -n "$_v" ] && PO_MAX_FUNCTION_LINES="$_v"
  _v=$(_po_get '.config.max_component_lines');       [ -n "$_v" ] && PO_MAX_COMPONENT_LINES="$_v"
  _v=$(_po_get '.config.build_cmd');                 [ -n "$_v" ] && PO_BUILD_CMD="$_v"
  _v=$(_po_get '.config.lint_cmd');                  [ -n "$_v" ] && PO_LINT_CMD="$_v"
  _v=$(_po_get '.config.test_cmd');                  [ -n "$_v" ] && PO_TEST_CMD="$_v"
  _v=$(_po_get '.config.format_cmd');                [ -n "$_v" ] && PO_FORMAT_CMD="$_v"
  _v=$(_po_get '.config.ui_language');               [ -n "$_v" ] && PO_UI_LANGUAGE="$_v"

  # wiki_gate yra boolean - NEnaudojam `// empty` (jq laiko `false` falsy ir numestų jį).
  _v=$(jq -r '.wiki_gate.block_commit_on_drift' "$PO_CONFIG" 2>/dev/null)
  case "$_v" in true|false) PO_WIKI_GATE="$_v" ;; esac

  # docs_gate (CLAUDE.md -> AGENTS.md sync) - irgi boolean.
  _v=$(jq -r '.docs_gate.block_commit_on_drift' "$PO_CONFIG" 2>/dev/null)
  case "$_v" in true|false) PO_DOCS_GATE="$_v" ;; esac

  _v=$(jq -r '.enabled_guards | join(" ")' "$PO_CONFIG" 2>/dev/null)
  [ -n "$_v" ] && PO_ENABLED_GUARDS="$_v"

  # guard_gate.mode - priimam TIK žinomas reikšmes (kitaip lieka default per-guard).
  _v=$(_po_get '.guard_gate.mode')
  case "$_v" in combined|per-guard) PO_GUARD_MODE="$_v" ;; esac

  _v=$(_po_get '.guard_gate.provider')
  case "$_v" in auto|claude|codex) PO_GUARD_PROVIDER="$_v" ;; esac

  # guard_gate.combined_model - reikšmė eina į `claude --print --model <v>` komandinę eilutę,
  # todėl validuojam griežtai (apsauga nuo vėliavų/argumentų injekcijos per config).
  _v=$(_po_get '.guard_gate.combined_model')
  case "$_v" in
    '') : ;;
    *[!A-Za-z0-9._-]*) : ;;
    *) PO_GUARD_MODEL="$_v"; PO_GUARD_CLAUDE_MODEL="$_v" ;;
  esac

  # Nauji provider-specifiniai modeliai. Claude reikšmė perrašo legacy combined_model.
  _v=$(_po_get '.guard_gate.claude_model')
  case "$_v" in
    '') : ;;
    *[!A-Za-z0-9._-]*) : ;;
    *) PO_GUARD_CLAUDE_MODEL="$_v"; PO_GUARD_MODEL="$_v" ;;
  esac
  _v=$(_po_get '.guard_gate.codex_model')
  case "$_v" in
    '') : ;;
    *[!A-Za-z0-9._-]*) : ;;
    *) PO_GUARD_CODEX_MODEL="$_v" ;;
  esac

  # guard_gate.timeout_seconds - tik teigiamas sveikasis. 0 ar netinkama reikšmė = "nenurodyta"
  # (lieka numatytoji pagal providerį), NE 0 sekundžių, nes nulinis timeout nukirstų kiekvieną guard'ą.
  _v=$(_po_get '.guard_gate.timeout_seconds')
  case "$_v" in ''|0|*[!0-9]*) : ;; *) PO_GUARD_TIMEOUT_CONFIG="$_v" ;; esac

  # Drift slenksčiai - tik neneigiami sveikieji.
  _v=$(_po_get '.wiki_gate.drift_block_threshold')
  case "$_v" in ''|*[!0-9]*) : ;; *) PO_WIKI_DRIFT_THRESHOLD="$_v" ;; esac
  _v=$(_po_get '.docs_gate.drift_block_threshold')
  case "$_v" in ''|*[!0-9]*) : ;; *) PO_DOCS_DRIFT_THRESHOLD="$_v" ;; esac

  unset _v
fi

# Tikras aplinkos override yra aukščiau už config. Nežinoma reikšmė paliekama tokia,
# kad providerio resolveris fail-closed ją atmestų, o ne tyliai rinktųsi kitą CLI.
# PO_GUARD_PROVIDER_FROM_ENV žymi šaltinį: staged-config anti-downgrade (pre-commit.sh)
# HEAD baseline taiko tik config kilmės reikšmei, ne vietiniam aplinkos override'ui.
[ -n "$_PO_GUARD_PROVIDER_ENV" ] && PO_GUARD_PROVIDER="$_PO_GUARD_PROVIDER_ENV"
PO_GUARD_PROVIDER_FROM_ENV="${_PO_GUARD_PROVIDER_ENV:+1}"
unset _PO_GUARD_PROVIDER_ENV

# --- Grąžina trigger regex pattern'ą duotam guard'ui ---
# Pirma bando iš .po-config.json guard_triggers; fallback - generiniai default'ai.
po_trigger_pattern() {
  _g="$1"
  if [ -f "$PO_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    _p=$(jq -r --arg g "$_g" '.guard_triggers[$g] // empty' "$PO_CONFIG" 2>/dev/null)
    if [ -n "$_p" ]; then
      printf '%s' "$_p"
      return 0
    fi
  fi
  # Default'ai SINCHRONIZUOTI su templates/po-config.template.json guard_triggers
  # (sinchronizaciją tikrina tests/pre-commit.test.sh SYNC assert'ai).
  case "$_g" in
    db-migration-guard)   printf '%s' 'migrations/|\.sql$|db/changelog/' ;;
    language-guard)       printf '%s' '\.(tsx|ts|jsx|js|vue|svelte|md)$' ;;
    file-size-guard)      printf '%s' '\.(sh|ts|tsx|js|jsx|mjs|cjs|py|rs|go|rb|java|kt|kts|swift|php|c|cc|cpp|h|hpp|cs|yml|yaml|tf)$' ;;
    test-coverage-guard)  printf '%s' '^(src|app|lib|server|api|cmd|internal|pkg|Sources)/.*\.(ts|tsx|js|jsx|py|go|rs|java|kt|swift|php|cs|rb)$' ;;
    security-guard)       printf '%s' '\.env|auth|security|middleware|(^|/)api/' ;;
    payment-guard)        printf '%s' 'payment|checkout|billing|refund|webhook' ;;
    email-guard)          printf '%s' 'email|mail|resend|notification' ;;
    dependency-guardian)  printf '%s' 'package\.json|requirements\.txt|pyproject\.toml|go\.mod|Cargo\.toml|composer\.(json|lock)|Gemfile(\.lock)?|pom\.xml|build\.gradle(\.kts)?|\.csproj|Package\.(swift|resolved)' ;;
  esac
}
