#!/usr/bin/env bash
# Interaktyvi MCP serverių konfigūracija.
# Source'inkite iš setup.sh: source "$(dirname "$0")/lib/mcp-config.sh"
#
# Reikalauja: jq, TTY (interaktyvus stdin).
# Reikalauja iš detect.sh: PROJECT_DB, PROJECT_PAYMENTS, PROJECT_HOSTING, PROJECT_TEST.
# Naudoja info/ok/warn/err funkcijas iš setup.sh.
#
# Pagrindinė funkcija: mcp_config_interactive — vaikšto per 6 MCP serverius,
# klausia įtraukti/praleisti, surenka tokenus ir įrašo .mcp.json (chmod 600).
#
# Default'ai per stack detection: Supabase Y jei PROJECT_DB=supabase,
# Stripe Y jei PROJECT_PAYMENTS=stripe, Vercel Y jei PROJECT_HOSTING=vercel,
# Playwright Y jei PROJECT_TEST=playwright. Context7 ir Chrome DevTools — visada Y.

# JSON akumuliuojamas šiame kintamajame, kiekvienas _mcp_add prideda key/value porą.
MCP_JSON=""

_mcp_yes_no() {
  local question="$1" default="${2:-Y}"
  local hint answer
  case "$default" in
    Y|y) hint="[Y/n]" ;;
    *)   hint="[y/N]" ;;
  esac
  printf "  %s %s " "$question" "$hint" >&2
  read -r answer </dev/tty || return 1
  [ -z "$answer" ] && answer="$default"
  case "$answer" in
    y|Y|yes|YES|taip|TAIP) return 0 ;;
    *) return 1 ;;
  esac
}

# Slaptas įvedimas (be echo). Naudojamas API raktams.
_mcp_prompt_secret() {
  local var_name="$1" hint="$2" value
  printf "    %s\n" "$hint" >&2
  printf "    %s (Enter = praleisti, liks \${%s} placeholder'is): " "$var_name" "$var_name" >&2
  read -rs value </dev/tty || true
  printf "\n" >&2
  printf "%s" "$value"
}

# Atviras įvedimas. Naudojamas viešiems ID (project ref ir pan.).
_mcp_prompt_visible() {
  local var_name="$1" hint="$2" value
  printf "    %s\n" "$hint" >&2
  printf "    %s (Enter = praleisti, liks \${%s} placeholder'is): " "$var_name" "$var_name" >&2
  read -r value </dev/tty || true
  printf "%s" "$value"
}

# Default'as Y, jei aplinkos kintamasis lygus tikėtinai reikšmei.
_mcp_default_for() {
  local actual="$1" expected="$2"
  if [ "$actual" = "$expected" ]; then echo "Y"; else echo "N"; fi
}

_mcp_init() {
  MCP_JSON='{"mcpServers":{}}'
}

_mcp_add() {
  local key="$1" obj="$2"
  MCP_JSON=$(printf '%s' "$MCP_JSON" | jq --arg k "$key" --argjson v "$obj" '.mcpServers[$k] = $v')
}

# Jei vartotojas paliko tuščią — grąžina ${VAR} placeholder'į ir įspėja.
_mcp_token_or_placeholder() {
  local value="$1" var_name="$2"
  if [ -z "$value" ]; then
    warn "$var_name nepateiktas. Liks placeholder'is — eksportuokite env var'ą prieš \"claude\""
    printf '${%s}' "$var_name"
  else
    printf '%s' "$value"
  fi
}

_mcp_supabase() {
  local default
  default=$(_mcp_default_for "${PROJECT_DB:-}" "supabase")
  printf "\n\033[1;36m▶ Supabase MCP\033[0m (DB + migracijos + RLS)\n" >&2
  _mcp_yes_no "Įtraukti Supabase MCP?" "$default" || return 0

  local token ref token_val ref_val obj
  token=$(_mcp_prompt_secret "SUPABASE_ACCESS_TOKEN" "Asmeninis token'as iš https://supabase.com/dashboard/account/tokens")
  ref=$(_mcp_prompt_visible "SUPABASE_PROJECT_REF" "Project ref iš jūsų Supabase URL (pvz. abcdefghijklmnop)")
  token_val=$(_mcp_token_or_placeholder "$token" "SUPABASE_ACCESS_TOKEN")
  ref_val=$(_mcp_token_or_placeholder "$ref" "SUPABASE_PROJECT_REF")

  obj=$(jq -n --arg t "$token_val" --arg r "$ref_val" '{
    command: "npx",
    args: ["-y", "@supabase/mcp-server-supabase@latest"],
    env: {SUPABASE_ACCESS_TOKEN: $t, SUPABASE_PROJECT_REF: $r}
  }')
  _mcp_add "supabase" "$obj"
}

_mcp_context7() {
  printf "\n\033[1;36m▶ Context7 MCP\033[0m (library docs, raktų nereikia)\n" >&2
  _mcp_yes_no "Įtraukti Context7 MCP?" "Y" || return 0
  local obj
  obj=$(jq -n '{command: "npx", args: ["-y", "@upstash/context7-mcp@latest"]}')
  _mcp_add "context7" "$obj"
}

_mcp_stripe() {
  local default
  default=$(_mcp_default_for "${PROJECT_PAYMENTS:-}" "stripe")
  printf "\n\033[1;36m▶ Stripe MCP\033[0m (mokėjimai, refund'ai, webhooks)\n" >&2
  _mcp_yes_no "Įtraukti Stripe MCP?" "$default" || return 0

  local key key_val obj
  key=$(_mcp_prompt_secret "STRIPE_SECRET_KEY" "Test key sk_test_... iš https://dashboard.stripe.com/test/apikeys")
  key_val=$(_mcp_token_or_placeholder "$key" "STRIPE_SECRET_KEY")

  obj=$(jq -n --arg k "$key_val" '{
    command: "npx",
    args: ["-y", "@stripe/mcp@latest", "--tools=all"],
    env: {STRIPE_SECRET_KEY: $k}
  }')
  _mcp_add "stripe" "$obj"
}

_mcp_playwright() {
  local default
  default=$(_mcp_default_for "${PROJECT_TEST:-}" "playwright")
  printf "\n\033[1;36m▶ Playwright MCP\033[0m (E2E naršyklės testai, raktų nereikia)\n" >&2
  _mcp_yes_no "Įtraukti Playwright MCP?" "$default" || return 0
  local obj
  obj=$(jq -n '{command: "npx", args: ["-y", "@playwright/mcp@latest"]}')
  _mcp_add "playwright" "$obj"
}

_mcp_vercel() {
  local default
  default=$(_mcp_default_for "${PROJECT_HOSTING:-}" "vercel")
  printf "\n\033[1;36m▶ Vercel MCP\033[0m (deploy, HTTP MCP, OAuth flow per browser)\n" >&2
  _mcp_yes_no "Įtraukti Vercel MCP?" "$default" || return 0
  local obj
  obj=$(jq -n '{type: "http", url: "https://mcp.vercel.com"}')
  _mcp_add "vercel" "$obj"
}

_mcp_chrome_devtools() {
  printf "\n\033[1;36m▶ Chrome DevTools MCP\033[0m (DOM inspekcija, raktų nereikia)\n" >&2
  _mcp_yes_no "Įtraukti Chrome DevTools MCP?" "Y" || return 0
  local obj
  obj=$(jq -n '{command: "npx", args: ["-y", "chrome-devtools-mcp@latest"]}')
  _mcp_add "chrome-devtools" "$obj"
}

# Pagrindinė orkestracija.
mcp_config_interactive() {
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq nerastas. Interaktyvi MCP konfigūracija praleidžiama. Įdiekite: brew install jq"
    return 1
  fi
  if [ ! -t 0 ] || [ ! -r /dev/tty ]; then
    warn "Ne TTY. Interaktyvi MCP konfigūracija praleidžiama"
    return 1
  fi

  if [ -f .mcp.json ]; then
    printf "\n\033[1;33m.mcp.json jau egzistuoja.\033[0m\n" >&2
    if ! _mcp_yes_no "Pakonfigūruoti iš naujo (.mcp.json bus perrašytas, backup'as išsaugomas)?" "N"; then
      info "MCP konfigūracija praleista, .mcp.json paliktas nepakeistas"
      return 0
    fi
    local backup=".mcp.json.backup-$(date +%Y%m%d-%H%M%S)"
    cp .mcp.json "$backup"
    info "Backup'as: $backup"
  fi

  printf "\n\033[1;35m━━━ MCP serverių konfigūracija ━━━\033[0m\n" >&2
  printf "Atsakykite per kiekvieną MCP. Tokenai įrašomi tiesiogiai į .mcp.json.\n" >&2
  printf "Failas .gitignore'e ir bus chmod 600. Default'ai parenkami pagal aptiktą stack'ą.\n" >&2

  _mcp_init
  _mcp_supabase
  _mcp_context7
  _mcp_stripe
  _mcp_playwright
  _mcp_vercel
  _mcp_chrome_devtools

  local final_json count
  final_json=$(printf '%s' "$MCP_JSON" | jq '. + {_comment: "Sugeneruotas scripts/setup.sh interaktyviai. Tokenai įrašyti tiesiogiai. Failas chmod 600 ir .gitignore'\''e."}')
  printf '%s\n' "$final_json" > .mcp.json
  chmod 600 .mcp.json
  count=$(printf '%s' "$final_json" | jq '.mcpServers | length')

  if [ "$count" -eq 0 ]; then
    warn ".mcp.json sukurtas, bet 0 MCP serverių. Galite pridėti vėliau iš .mcp.json.example"
  else
    ok ".mcp.json sukurtas su $count MCP serveriais (chmod 600)"
  fi
}
