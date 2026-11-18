#!/usr/bin/env bash
# Advanced Vibe Coding Starter. Setup script.
# Paleidžia viską, ko reikia, kad dalyvis per 5 min turėtų veikiančią aplinką.
#
# Naudojimas:
#   bash scripts/setup.sh                     # konfigūruoja patį starter projektą
#   bash scripts/setup.sh /path/to/project    # įdiegia starter į egzistuojantį projektą
#   bash scripts/setup.sh --help
#
# Architektūra:
#   - scripts/lib/detect.sh        — stack aptikimas, komandų default'ai, python detect
#   - scripts/lib/cwk-pipeline.sh  — CWK §5 (template substitucija, jq merge'ai)
#   - scripts/lib/mcp-config.sh    — interaktyvi MCP konfigūracija
#   - scripts/lib/install.sh       — starter diegimas į target projektą
#   - scripts/setup.sh             — orkestracija (šis failas)

set -euo pipefail

# --- 0. Argumentų parsavimas ---
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage: bash scripts/setup.sh [TARGET_DIR]

Be argumentų  : konfigūruoja patį starter projektą.
Su TARGET_DIR : įdiegia starter scaffolding į egzistuojantį projektą,
                tada paleidžia konfigūraciją jame.

Įdiegiama (esami target failai NEPERRAŠOMI; konfliktai → *.starter):
  .claude/                  agentai, hooks, komandos, _templates, settings
  scripts/                  setup.sh, verify.sh, lib/*
  .mcp.json.example         MCP serverių template
  CLAUDE.md                 jei target neturi (kitaip CLAUDE.md.starter)
  .gitignore                jei target neturi (kitaip .gitignore.starter)
  raw/, wiki/               skeleton (jei nėra)
  docs/{requirements,tasks} skeleton (jei nėra)

Nekopijuojama: app kodas, package.json, build configai, node_modules, .git.
EOF
  exit 0
fi

TARGET_DIR_ARG="${1:-}"

cd "$(dirname "$0")/.."
STARTER_ROOT=$(pwd)
ROOT="$STARTER_ROOT"

# Single source of truth versijai. Skaitoma vienoje vietoje, naudojama .cwk-config.json,
# CLAUDE.md ir README.md (per template substituciją, žr. cwk-pipeline.sh).
CWK_VERSION="3.0.1"

info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; exit 1; }

# Lib funkcijos. Source'inama iš STARTER_ROOT, kad veiktų ir po cd į target.
# shellcheck disable=SC1091
source "$STARTER_ROOT/scripts/lib/detect.sh"
# shellcheck disable=SC1091
source "$STARTER_ROOT/scripts/lib/cwk-pipeline.sh"
# shellcheck disable=SC1091
source "$STARTER_ROOT/scripts/lib/mcp-config.sh"
# shellcheck disable=SC1091
source "$STARTER_ROOT/scripts/lib/render-claude.sh"
# shellcheck disable=SC1091
source "$STARTER_ROOT/scripts/lib/install.sh"

# --- 0.1 Target mode: cd į target PRIEŠ detect, kad detect skaitytų target'o stack'ą. ---
if [ -n "$TARGET_DIR_ARG" ]; then
  [ -d "$TARGET_DIR_ARG" ] || err "TARGET_DIR nėra direktorija: $TARGET_DIR_ARG"
  TARGET_DIR=$(cd "$TARGET_DIR_ARG" && pwd)
  [ "$TARGET_DIR" = "$STARTER_ROOT" ] && err "TARGET_DIR sutampa su starter root. Naudokite be argumentų."
  cd "$TARGET_DIR"
  ROOT="$TARGET_DIR"
  info "Aptinkamas target projekto stack'as: $TARGET_DIR"
  detect_project
  configure_project_auto
  detect_target_state "$TARGET_DIR"
  ok "Target stack: lang=${PROJECT_LANG:-?} framework=${PROJECT_FRAMEWORK:-?} pkg=${TARGET_PKG_MGR:-npm} karpathy_present=$TARGET_HAS_KARPATHY cwk_present=$TARGET_HAS_CWK"
  install_starter_to "$TARGET_DIR"
  info "Toliau — konfigūracija kataloge: $TARGET_DIR"
fi

# --- 1. Reikalavimų patikra ---
info "Tikrinama Python 3.9+..."
command -v python3 >/dev/null || err "python3 nerastas. Įdiekite Python 3.9+."
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
ok "Python $PY_VERSION"

info "Tikrinama Claude Code CLI..."
command -v claude >/dev/null || err "claude CLI nerastas. Diegimas: https://docs.claude.com/claude-code"
ok "Claude Code CLI: $(claude --version 2>/dev/null || echo 'versija nenustatyta')"

info "Tikrinama git..."
command -v git >/dev/null || err "git nerastas."
ok "git $(git --version | awk '{print $3}')"

# --- 2. MemPalace diegimas ---
info "Diegiamas MemPalace..."
if command -v mempalace >/dev/null 2>&1; then
  ok "MemPalace jau įdiegtas ($(mempalace --version 2>/dev/null || echo 'versija nenustatyta'))"
else
  # macOS, Linux su Homebrew Python reikalauja pipx (PEP 668). Fallback į venv.
  if command -v pipx >/dev/null 2>&1; then
    info "Naudojamas pipx..."
    pipx install mempalace || err "pipx install mempalace nepavyko"
    pipx ensurepath >/dev/null 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"
    ok "MemPalace įdiegtas per pipx"
  elif command -v brew >/dev/null 2>&1; then
    warn "pipx nerastas. Bandoma brew install pipx"
    brew install pipx >/dev/null 2>&1 && pipx ensurepath >/dev/null 2>&1 || err "Nepavyko įdiegti pipx per brew"
    export PATH="$HOME/.local/bin:$PATH"
    pipx install mempalace || err "pipx install mempalace nepavyko"
    ok "MemPalace įdiegtas per pipx (naujai)"
  else
    warn "pipx ir brew nerasti. Kuriamas vietinis venv (.venv)"
    python3 -m venv .venv || err "venv kūrimas nepavyko"
    # shellcheck disable=SC1091
    source .venv/bin/activate
    python3 -m pip install --upgrade pip >/dev/null
    python3 -m pip install mempalace || err "pip install mempalace nepavyko venv'e"
    ok "MemPalace įdiegtas į .venv/ (aktyvuokite: source .venv/bin/activate)"
  fi
fi

# --- 3. MemPalace inicializacija ---
# `mempalace init . --yes` sukuria DU artefaktus projekto šaknyje:
# `mempalace.yaml` (config) ir `entities.json` (auto-detected entities).
# Re-run init'ą, jei trūksta bent vieno failo. Tai apsauga nuo partial-failure.
if [ ! -f "mempalace.yaml" ] || [ ! -f "entities.json" ]; then
  if [ -f "mempalace.yaml" ] || [ -f "entities.json" ]; then
    warn "Aptiktas partial init state, perinit'inama"
  else
    info "Inicializuojamas MemPalace šiame projekte..."
  fi
  mempalace init . --yes || err "mempalace init nepavyko"
  ok "MemPalace inicializuotas (mempalace.yaml + entities.json)"
else
  ok "MemPalace jau inicializuotas"
fi

# --- 4. Claude Code MCP prijungimas ---
info "Prijungiamas MemPalace MCP serveris prie Claude Code..."
MEMPALACE_PY=""
if MEMPALACE_PY=$(detect_mempalace_python); then
  ok "MemPalace python interpretatorius: $MEMPALACE_PY"
else
  warn "Nepavyko aptikti python su 'mempalace' moduliu. MCP registracija praleidžiama"
  MEMPALACE_PY=""
fi

if [ -n "$MEMPALACE_PY" ]; then
  EXISTING_CMD=$(claude mcp get mempalace 2>/dev/null | awk '/^  Command:/ {print $2}' || true)
  if [ -n "$EXISTING_CMD" ] && [ "$EXISTING_CMD" != "$MEMPALACE_PY" ]; then
    warn "Aptikta sena MemPalace MCP registracija ($EXISTING_CMD), perregistruojama"
    claude mcp remove mempalace -s local >/dev/null 2>&1 || true
  fi

  if claude mcp get mempalace >/dev/null 2>&1; then
    ok "MemPalace MCP jau prijungtas"
  else
    if claude mcp add mempalace -- "$MEMPALACE_PY" -m mempalace.mcp_server >/dev/null 2>&1; then
      ok "MemPalace MCP prijungtas"
    else
      warn "claude mcp add nepavyko. Pridėkite rankiniu būdu:"
      warn "  claude mcp add mempalace -- $MEMPALACE_PY -m mempalace.mcp_server"
    fi
  fi
fi

# --- 5. CWK 4 etapų pipeline konfigūracija ---
info "Aptinkamas projekto stack'as (CWK pipeline)..."
detect_project
configure_project_auto

# Warn'ai unknown stack atvejais (lib funkcijos jų nedeklaruoja, kad būtų gryna logika).
case "$PROJECT_LANG" in
  "")  warn "Stack'as neaptiktas. Komandos paliekamos kaip placeholder'iai. Atnaujinkite .claude/.cwk-config.json arba pridėkite stack žymeklį (package.json / manage.py / Cargo.toml / go.mod)." ;;
  python|rust|go|node|typescript) ;;
  *)   warn "Stack'as '$PROJECT_LANG' nepalaikomas auto-konfigūracijoje. Atnaujinkite .claude/.cwk-config.json rankomis." ;;
esac

ok "Stack: lang=${PROJECT_LANG:-(nera)} framework=${PROJECT_FRAMEWORK:-(nera)} db=${PROJECT_DB:-(nera)} payments=${PROJECT_PAYMENTS:-(nera)} hosting=${PROJECT_HOSTING:-(nera)} test=${PROJECT_TEST:-(nera)}"
ok "Default'ai: build=\"$BUILD_CMD\" lint=\"$LINT_CMD\" test=\"$TEST_CMD\""

cwk_pipeline_setup

# --- 6. Hook'ų vykdomumo nustatymas ---
info "Nustatomas pre-commit hook..."
chmod +x .claude/hooks/pre-commit.sh
ok "pre-commit hook +x"

# --- 7. Git pre-commit nuoroda ---
if [ -d ".git" ]; then
  HOOK_PATH=".git/hooks/pre-commit"
  if [ ! -L "$HOOK_PATH" ] && [ ! -f "$HOOK_PATH" ]; then
    ln -s "../../.claude/hooks/pre-commit.sh" "$HOOK_PATH"
    ok "Git pre-commit hook prijungtas"
  else
    ok "Git pre-commit hook jau egzistuoja"
  fi
fi

# --- 8. MCP serverių konfigūracija (interaktyvi) ---
if ! mcp_config_interactive; then
  if [ ! -f ".mcp.json" ]; then
    warn "Interaktyvi konfigūracija praleista. Rankinis būdas: cp .mcp.json.example .mcp.json && \$EDITOR .mcp.json"
  fi
fi

# --- 9. Pradinis mine (jei raw/ nėra tuščias) ---
if [ -n "$(ls -A raw/ 2>/dev/null | grep -v .gitkeep || true)" ]; then
  info "raw/ turi failų. Paleidžiama mempalace mine..."
  mempalace mine . || warn "mempalace mine nepavyko. Galite paleisti vėliau"
fi

printf "\n\033[1;32m━━━ SETUP BAIGTAS ━━━\033[0m\n"
echo "Kiti žingsniai:"
echo "  1. bash scripts/verify.sh    # sanity check"
echo "  2. claude                    # paleiskite Claude Code"
if [ -f .mcp.json ]; then
  echo ""
  echo "MCP redagavimas vėliau: \$EDITOR .mcp.json (chmod 600, .gitignore'e)"
fi
