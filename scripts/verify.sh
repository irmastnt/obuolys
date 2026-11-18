#!/usr/bin/env bash
# Advanced Vibe Coding Starter. Verifikacija
# Paleidžiama po setup.sh. Patikrina, kad visi komponentai vietoje.

set -uo pipefail

cd "$(dirname "$0")/.."

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "\033[1;32m✅\033[0m %s\n" "$name"
    PASS=$((PASS + 1))
  else
    printf "\033[1;31m❌\033[0m %s\n" "$name"
    FAIL=$((FAIL + 1))
  fi
}

echo "━━━ Struktūra ━━━"
check "CLAUDE.md egzistuoja"               "test -f CLAUDE.md"
check "mempalace.yaml egzistuoja"          "test -f mempalace.yaml"
check ".mcp.json.example egzistuoja"       "test -f .mcp.json.example"
check ".claude/settings.json egzistuoja"   "test -f .claude/settings.json"
check ".claude/hooks/pre-commit.sh yra +x" "test -x .claude/hooks/pre-commit.sh"
check ".claude/agents/ turi agentus"       "test \$(ls .claude/agents/*.md 2>/dev/null | wc -l) -ge 7"
check "raw/ egzistuoja"                    "test -d raw"
check "wiki/ egzistuoja"                   "test -d wiki"
check "docs/requirements/ egzistuoja"      "test -d docs/requirements"
check "docs/tasks/ egzistuoja"             "test -d docs/tasks"
check ".github/workflows/self-heal.yml"    "test -f .github/workflows/self-heal.yml"

echo ""
echo "━━━ Priklausomybės ━━━"
check "python3 pasiekiamas"                "command -v python3"
check "MemPalace CLI pasiekiamas"          "command -v mempalace"
check "MemPalace veikia"                   "mempalace --version"
check "Claude Code CLI pasiekiamas"        "command -v claude"
check "git pasiekiamas"                    "command -v git"

echo ""
echo "━━━ MemPalace būklė ━━━"
check "MemPalace inicializuotas (entities.json)" "test -f entities.json"
check "mempalace.yaml egzistuoja"          "test -f mempalace.yaml"
check "MemPalace MCP prijungtas"           "claude mcp list 2>/dev/null | grep -q mempalace"

echo ""
echo "━━━ CWK pipeline (v3.0.1) ━━━"
check "_templates/ turi 5 komandas"        "test \$(ls .claude/commands/_templates/*.md 2>/dev/null | wc -l) -ge 5"
check "Sugeneruotos 5 .claude/commands/"   "test \$(ls .claude/commands/*.md 2>/dev/null | wc -l) -ge 5"
check ".cwk-config.json egzistuoja"        "test -f .claude/.cwk-config.json"
check "version == 3.0.1"                   "test \"\$(jq -r .version .claude/.cwk-config.json 2>/dev/null)\" = 3.0.1"
check "Stop hook'as settings.json'e"       "jq -e '.hooks.Stop' .claude/settings.json"
check "scripts/port-cwk.sh egzistuoja"     "test -x scripts/port-cwk.sh"
check "docs/CWK-AGENT-MAPPING.md"          "test -f docs/CWK-AGENT-MAPPING.md"

echo ""
echo "━━━ Saugumas ━━━"
check ".mcp.json NĖRA git tracking'e"      "! git ls-files --error-unmatch .mcp.json 2>/dev/null"
check ".env NĖRA git tracking'e"           "! git ls-files --error-unmatch .env 2>/dev/null"

echo ""
echo "━━━ Suvestinė ━━━"
printf "Praėjo: \033[1;32m%d\033[0m | Nepraėjo: \033[1;31m%d\033[0m\n" "$PASS" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Jei kuris nors patikrinimas nepraėjo. Paleiskite: bash scripts/setup.sh"
  echo "(setup.sh idempotentinis: aptinka tinkamą python interpretatorių, perinit'ina partial state'us"
  echo " ir užregistruoja MemPalace MCP. Saugu paleisti pakartotinai.)"
  echo ""
  echo "Jei MemPalace iš viso neįdiegtas. Rankiniu būdu: pipx install mempalace"
  exit 1
fi
