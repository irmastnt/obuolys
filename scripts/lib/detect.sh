#!/usr/bin/env bash
# Stack auto-detection (port'as iš CWK install.sh:40-220).
# Source'inkite iš setup.sh: source "$(dirname "$0")/lib/detect.sh"
#
# Eksportuoja kintamuosius: PROJECT_LANG, PROJECT_FRAMEWORK, PROJECT_DB,
# PROJECT_PAYMENTS, PROJECT_HOSTING, PROJECT_TEST.
#
# Konfigūruoja: BUILD_CMD, LINT_CMD, TEST_CMD, COVERAGE_THRESHOLD,
# MAX_FILE_LINES, UI_LANG.
#
# `package.json` nuskaitomas vieną kartą į `_PKG_JSON` kintamąjį, o vėliau visi
# patikrinimai daromi `printf '%s' "$_PKG_JSON" | grep`. 16 atskirų grep'ų
# sumažinta iki 1 read'o.

_PKG_JSON=""

_load_pkg_json() {
  if [ -f "package.json" ] && [ -z "$_PKG_JSON" ]; then
    _PKG_JSON=$(cat package.json 2>/dev/null || echo "")
  fi
}

_pkg_has() {
  printf '%s' "$_PKG_JSON" | grep -q "$1"
}

detect_language() {
  PROJECT_LANG=""
  if [ -n "$_PKG_JSON" ]; then
    PROJECT_LANG="node"
    if _pkg_has '"typescript"'; then PROJECT_LANG="typescript"; fi
  elif [ -f "manage.py" ] && { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; }; then
    PROJECT_LANG="python"
    PROJECT_FRAMEWORK="django"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    PROJECT_LANG="python"
  elif [ -f "go.mod" ]; then
    PROJECT_LANG="go"
  elif [ -f "Cargo.toml" ]; then
    PROJECT_LANG="rust"
  fi
}

detect_framework() {
  [ -n "${PROJECT_FRAMEWORK:-}" ] && return 0
  PROJECT_FRAMEWORK=""
  [ -z "$_PKG_JSON" ] && return 0

  if _pkg_has '"next"'; then PROJECT_FRAMEWORK="nextjs"
  elif _pkg_has '"react"'; then
    if _pkg_has '"vite"'; then PROJECT_FRAMEWORK="vite-react"
    else PROJECT_FRAMEWORK="react"
    fi
  elif _pkg_has '"vue"'; then PROJECT_FRAMEWORK="vue"
  elif _pkg_has '"svelte"'; then PROJECT_FRAMEWORK="svelte"
  elif _pkg_has '"express"'; then PROJECT_FRAMEWORK="express"
  fi
}

detect_database() {
  PROJECT_DB=""
  if [ -n "$_PKG_JSON" ]; then
    if _pkg_has '"@supabase/supabase-js"'; then PROJECT_DB="supabase"
    elif _pkg_has '"prisma"'; then PROJECT_DB="prisma"
    elif _pkg_has '"drizzle-orm"'; then PROJECT_DB="drizzle"
    elif _pkg_has '"mongoose"'; then PROJECT_DB="mongodb"
    elif _pkg_has '"pg"'; then PROJECT_DB="postgres"
    fi
  fi
  if [ -z "$PROJECT_DB" ] && [ -d "supabase" ]; then PROJECT_DB="supabase"; fi
}

detect_payments() {
  PROJECT_PAYMENTS=""
  if [ -n "$_PKG_JSON" ] && _pkg_has '"stripe"'; then PROJECT_PAYMENTS="stripe"; fi
}

detect_hosting() {
  PROJECT_HOSTING=""
  if [ -f "vercel.json" ]; then PROJECT_HOSTING="vercel"
  elif [ -f "netlify.toml" ]; then PROJECT_HOSTING="netlify"
  elif [ -f "fly.toml" ]; then PROJECT_HOSTING="fly"
  elif [ -f "Dockerfile" ]; then PROJECT_HOSTING="docker"
  fi
}

detect_test_framework() {
  PROJECT_TEST=""
  if [ -n "$_PKG_JSON" ]; then
    if _pkg_has '"vitest"'; then PROJECT_TEST="vitest"
    elif _pkg_has '"jest"'; then PROJECT_TEST="jest"
    elif _pkg_has '"@playwright/test"'; then PROJECT_TEST="playwright"
    fi
  fi
  if [ -z "$PROJECT_TEST" ]; then
    case "$PROJECT_LANG" in
      python) PROJECT_TEST="pytest" ;;
      go)     PROJECT_TEST="go-test" ;;
      rust)   PROJECT_TEST="cargo-test" ;;
    esac
  fi
}

# Orkestracija. Iškviečia visas sub-funkcijas teisinga tvarka.
detect_project() {
  _load_pkg_json
  detect_language
  detect_framework
  detect_database
  detect_payments
  detect_hosting
  detect_test_framework
}

# Komandų default'ai pagal aptiktą stack'ą. AUTO mode (be klausimų dalyviui).
configure_project_auto() {
  COVERAGE_THRESHOLD="80"
  MAX_FILE_LINES="300"

  # UI_LANG paveldim iš ankstesnio paleidimo. Default'as `lt`.
  if [ -f .claude/.cwk-config.json ] && command -v jq >/dev/null 2>&1; then
    UI_LANG=$(jq -r '.config.ui_language // "lt"' .claude/.cwk-config.json 2>/dev/null || echo "lt")
  else
    UI_LANG="lt"
  fi

  case "$PROJECT_LANG" in
    python)
      if [ "$PROJECT_FRAMEWORK" = "django" ]; then
        BUILD_CMD="python manage.py check"
      else
        BUILD_CMD="python -m build"
      fi
      LINT_CMD="ruff check ."
      TEST_CMD="pytest"
      ;;
    rust)
      BUILD_CMD="cargo build"; LINT_CMD="cargo clippy"; TEST_CMD="cargo test"
      ;;
    go)
      BUILD_CMD="go build ./..."; LINT_CMD="golangci-lint run"; TEST_CMD="go test ./..."
      ;;
    node|typescript)
      BUILD_CMD="npm run build"; LINT_CMD="npm run lint"
      case "$PROJECT_TEST" in
        vitest)     TEST_CMD="npx vitest run" ;;
        jest)       TEST_CMD="npx jest" ;;
        playwright) TEST_CMD="npx playwright test" ;;
        *)          TEST_CMD="npm run test" ;;
      esac
      ;;
    "")
      BUILD_CMD="(nesukonfigūruota)"; LINT_CMD="(nesukonfigūruota)"
      if [ -x "scripts/verify.sh" ]; then
        TEST_CMD="bash scripts/verify.sh"
      else
        TEST_CMD="(nesukonfigūruota)"
      fi
      ;;
    *)
      BUILD_CMD="(nesukonfigūruota: $PROJECT_LANG)"
      LINT_CMD="(nesukonfigūruota: $PROJECT_LANG)"
      TEST_CMD="(nesukonfigūruota: $PROJECT_LANG)"
      ;;
  esac
}

# Aptinka python interpretatorių, kuris turi `mempalace` modulį.
# Tvarka: plain → pipx environment → hardcoded pipx paths → .venv → shebang fallback.
_try_plain_python() {
  for cmd in python python3; do
    if command -v "$cmd" >/dev/null 2>&1 && "$cmd" -c "import mempalace" >/dev/null 2>&1; then
      command -v "$cmd"
      return 0
    fi
  done
  return 1
}

_try_pipx_query() {
  command -v pipx >/dev/null 2>&1 || return 1
  local venvs candidate
  venvs=$(pipx environment --value PIPX_LOCAL_VENVS 2>/dev/null || true)
  [ -n "$venvs" ] && [ -d "$venvs/mempalace" ] || return 1
  for sub in "bin/python" "bin/python3" "Scripts/python.exe"; do
    candidate="$venvs/mempalace/$sub"
    if [ -x "$candidate" ] && "$candidate" -c "import mempalace" >/dev/null 2>&1; then
      printf "%s" "$candidate"
      return 0
    fi
  done
  return 1
}

_try_hardcoded_pipx() {
  local path
  for path in \
    "$HOME/.local/pipx/venvs/mempalace/bin/python" \
    "$HOME/.local/pipx/venvs/mempalace/Scripts/python.exe" \
    "$HOME/pipx/venvs/mempalace/bin/python" \
    "$HOME/pipx/venvs/mempalace/Scripts/python.exe"; do
    if [ -x "$path" ] && "$path" -c "import mempalace" >/dev/null 2>&1; then
      printf "%s" "$path"
      return 0
    fi
  done
  return 1
}

_try_project_venv() {
  [ -x ".venv/bin/python" ] && .venv/bin/python -c "import mempalace" >/dev/null 2>&1 || return 1
  printf "%s/.venv/bin/python" "$(pwd)"
}

_try_shebang_parse() {
  local mp_bin shebang first second python_path
  mp_bin=$(command -v mempalace 2>/dev/null) || return 1
  [ -f "$mp_bin" ] || return 1
  shebang=$(head -1 "$mp_bin" 2>/dev/null | sed -n 's|^#!\(.*\)|\1|p')
  [ -n "$shebang" ] || return 1

  read -r first second _ <<< "$shebang"
  case "$first" in
    */env|env)
      [ -n "$second" ] || return 1
      python_path=$(command -v "$second" 2>/dev/null) || return 1
      ;;
    *)
      python_path="$first"
      ;;
  esac

  if [ -x "$python_path" ] && "$python_path" -c "import mempalace" >/dev/null 2>&1; then
    printf "%s" "$python_path"
    return 0
  fi
  return 1
}

detect_mempalace_python() {
  _try_plain_python && return 0
  _try_pipx_query && return 0
  _try_hardcoded_pipx && return 0
  _try_project_venv && return 0
  _try_shebang_parse && return 0
  return 1
}
