#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║              WISPER ALPHA — Automated Recon Orchestrator                ║
# ║              Flow: Session → Scope → Profile → Run → Report             ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage: bash wisper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Colors & Symbols ────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'

OK="${GREEN}✓${RESET}"
WARN="${YELLOW}⚠${RESET}"
ERR="${RED}✗${RESET}"
ARROW="${CYAN}›${RESET}"
BULLET="${DIM}●${RESET}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║       ██╗    ██╗██╗███████╗██████╗ ███████╗██████╗          ║"
    echo "  ║       ██║    ██║██║██╔════╝██╔══██╗██╔════╝██╔══██╗         ║"
    echo "  ║       ██║ █╗ ██║██║███████╗██████╔╝█████╗  ██████╔╝         ║"
    echo "  ║       ██║███╗██║██║╚════██║██╔═══╝ ██╔══╝  ██╔══██╗         ║"
    echo "  ║       ╚███╔███╔╝██║███████║██║     ███████╗██║  ██║         ║"
    echo "  ║        ╚══╝╚══╝ ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝         ║"
    echo "  ║                   A L P H A  v1.0                            ║"
    echo "  ║           Automated Web Attack Surface Mapper                ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}${BOLD}  │  STEP $1: $2${RESET}"
    echo -e "${CYAN}${BOLD}  └─────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

log()     { echo -e "  ${BULLET} $1"; }
success() { echo -e "  ${OK} ${GREEN}$1${RESET}"; }
warn()    { echo -e "  ${WARN} ${YELLOW}$1${RESET}"; }
error()   { echo -e "  ${ERR} ${RED}$1${RESET}"; }
step()    { echo -e "  ${ARROW} ${WHITE}$1${RESET}"; }

divider() { echo -e "  ${DIM}──────────────────────────────────────────────────────────────${RESET}"; }

prompt() {
    echo -e "  ${CYAN}?${RESET} ${WHITE}$1${RESET}"
    echo -ne "  ${CYAN}›${RESET} "
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

detect_python() {
    if has_cmd python3; then
        echo "python3"
    elif has_cmd python; then
        echo "python"
    else
        echo ""
    fi
}

bootstrap_tool_paths() {
    local -a candidate_dirs=(
        "${GOPATH:-${HOME}/go}/bin"
        "${HOME}/go/bin"
        "/usr/local/go/bin"
    )

    for dir in "${candidate_dirs[@]}"; do
        [[ -d "${dir}" ]] || continue
        case ":${PATH}:" in
            *":${dir}:"*) ;;
            *) export PATH="${dir}:${PATH}" ;;
        esac
    done
}

detect_platform() {
    local os_name
    os_name="$(uname -s 2>/dev/null || echo "unknown")"
    case "${os_name}" in
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        Linux*) echo "linux" ;;
        Darwin*) echo "macos" ;;
        *) echo "unknown" ;;
    esac
}

python_import_check() {
    local module_name="$1"
    local py_cmd=""
    py_cmd="$(detect_python)"
    [[ -z "${py_cmd}" ]] && return 1
    ${py_cmd} -c "import ${module_name}" >/dev/null 2>&1
}

python_module_entry_works() {
    local module_name="$1"
    local py_cmd=""
    py_cmd="$(detect_python)"
    [[ -z "${py_cmd}" ]] && return 1
    ${py_cmd} -m "${module_name}" --help >/dev/null 2>&1
}

MISSING_TOOLS=()
AUDIT_MISSING_COUNT=0
HARD_MISSING_TOOLS=()
HARD_MISSING_COUNT=0

record_missing_tool() {
    local tool_name="$1"
    MISSING_TOOLS+=("${tool_name}")
    AUDIT_MISSING_COUNT=$((AUDIT_MISSING_COUNT + 1))
}

record_hard_missing_tool() {
    local tool_name="$1"
    HARD_MISSING_TOOLS+=("${tool_name}")
    HARD_MISSING_COUNT=$((HARD_MISSING_COUNT + 1))
}

print_dep_status() {
    local tool_name="$1"
    local status="$2"
    local note="$3"
    case "${status}" in
        ok)
            printf "  %-18s %b\n" "${tool_name}" "${GREEN}OK${RESET}${note:+  ${DIM}${note}${RESET}}"
            ;;
        fallback)
            printf "  %-18s %b\n" "${tool_name}" "${YELLOW}FALLBACK${RESET}${note:+  ${DIM}${note}${RESET}}"
            ;;
        missing)
            printf "  %-18s %b\n" "${tool_name}" "${RED}MISSING${RESET}${note:+  ${DIM}${note}${RESET}}"
            record_missing_tool "${tool_name}"
            ;;
    esac
}

dependency_audit() {
    local phase="${1:-pre-check}"
    MISSING_TOOLS=()
    AUDIT_MISSING_COUNT=0
    HARD_MISSING_TOOLS=()
    HARD_MISSING_COUNT=0

    echo ""
    section "0" "DEPENDENCY PRE-CHECK (${phase})"
    echo -e "  ${DIM}Checking required tools and available fallbacks before recon starts...${RESET}"
    echo ""

    if has_cmd subfinder; then print_dep_status "subfinder" "ok" ""; else print_dep_status "subfinder" "missing" "core subdomain discovery"; record_hard_missing_tool "subfinder"; fi
    if has_cmd whois; then
        print_dep_status "whois" "ok" ""
    elif has_cmd curl; then
        print_dep_status "whois" "fallback" "RDAP via curl"
    else
        print_dep_status "whois" "missing" "needs whois or curl"
        record_hard_missing_tool "whois"
    fi

    if has_cmd dig; then
        print_dep_status "dig" "ok" ""
    elif has_cmd nslookup; then
        print_dep_status "dig" "fallback" "using nslookup for DNS records"
    else
        print_dep_status "dig" "missing" "needs dig or nslookup"
        record_hard_missing_tool "dig"
    fi

    if has_cmd nslookup; then print_dep_status "nslookup" "ok" ""; else print_dep_status "nslookup" "missing" "DNS resolution fallback"; record_hard_missing_tool "nslookup"; fi
    if has_cmd dnsrecon; then
        print_dep_status "dnsrecon" "ok" ""
    elif python_module_entry_works "dnsrecon"; then
        print_dep_status "dnsrecon" "fallback" "python -m dnsrecon"
    else
        print_dep_status "dnsrecon" "missing" "passive DNS enrichment"
        record_hard_missing_tool "dnsrecon"
    fi
    if has_cmd waybackurls; then print_dep_status "waybackurls" "ok" ""; else print_dep_status "waybackurls" "missing" "historical URL collection"; record_hard_missing_tool "waybackurls"; fi
    if has_cmd whatweb; then
        print_dep_status "whatweb" "ok" ""
    elif has_cmd curl; then
        print_dep_status "whatweb" "fallback" "HTTP header/title fingerprint fallback"
    else
        print_dep_status "whatweb" "missing" "technology fingerprinting"
        record_hard_missing_tool "whatweb"
    fi
    if has_cmd amass; then print_dep_status "amass" "ok" ""; else print_dep_status "amass" "missing" "advanced profile"; record_hard_missing_tool "amass"; fi
    if has_cmd theHarvester; then
        print_dep_status "theHarvester" "ok" ""
    elif python_module_entry_works "theHarvester"; then
        print_dep_status "theHarvester" "fallback" "python -m theHarvester"
    else
        print_dep_status "theHarvester" "missing" "advanced profile"
        record_hard_missing_tool "theHarvester"
    fi
    if has_cmd spiderfoot; then
        print_dep_status "spiderfoot" "ok" ""
    elif python_module_entry_works "spiderfoot"; then
        print_dep_status "spiderfoot" "fallback" "python -m spiderfoot"
    else
        print_dep_status "spiderfoot" "missing" "advanced profile optional"
        record_missing_tool "spiderfoot"
    fi
    if has_cmd recon-ng; then
        print_dep_status "recon-ng" "ok" ""
    elif python_module_entry_works "reconng"; then
        print_dep_status "recon-ng" "fallback" "python -m reconng"
    else
        print_dep_status "recon-ng" "missing" "advanced profile optional"
        record_hard_missing_tool "recon-ng"
    fi
    if has_cmd curl; then print_dep_status "curl" "ok" ""; else print_dep_status "curl" "missing" "RDAP/crt.sh/shodan helpers"; record_hard_missing_tool "curl"; fi

    echo ""
    if [[ ${AUDIT_MISSING_COUNT} -eq 0 ]]; then
        success "Environment status: CORRECT (all required tools available)"
    else
        warn "Environment status: PROBLEMS DETECTED (${AUDIT_MISSING_COUNT} missing tools)"
        log "Missing tools: ${MISSING_TOOLS[*]}"
    fi
    if [[ ${HARD_MISSING_COUNT} -gt 0 ]]; then
        warn "Hard install gate: BLOCKED (${HARD_MISSING_COUNT} tools still not fully installed)"
        log "Install-required tools: ${HARD_MISSING_TOOLS[*]}"
    fi
    echo ""
}

install_with_system_manager() {
    local pkg="$1"
    if has_cmd apt-get; then
        local prefix=""
        has_cmd sudo && prefix="sudo"
        ${prefix} apt-get install -y -qq "${pkg}" >/dev/null 2>&1 && return 0
    elif has_cmd dnf; then
        local prefix=""
        has_cmd sudo && prefix="sudo"
        ${prefix} dnf install -y "${pkg}" >/dev/null 2>&1 && return 0
    elif has_cmd yum; then
        local prefix=""
        has_cmd sudo && prefix="sudo"
        ${prefix} yum install -y "${pkg}" >/dev/null 2>&1 && return 0
    elif has_cmd pacman; then
        local prefix=""
        has_cmd sudo && prefix="sudo"
        ${prefix} pacman -S --noconfirm "${pkg}" >/dev/null 2>&1 && return 0
    elif has_cmd zypper; then
        local prefix=""
        has_cmd sudo && prefix="sudo"
        ${prefix} zypper --non-interactive install "${pkg}" >/dev/null 2>&1 && return 0
    fi
    return 1
}

install_go_if_missing() {
    has_cmd go && return 0
    step "Go not found. Checking installation options..."
    install_with_system_manager "golang-go" || install_with_system_manager "go" || true
    has_cmd go
}

run_dns_record_query() {
    local record="$1"
    local out_file="$2"
    if has_cmd dig; then
        run_tool "dig — ${record} record" "${out_file}" dig "${TARGET_DOMAIN}" "${record}" +short
    elif has_cmd nslookup; then
        run_tool "nslookup — ${record} record (dig fallback)" "${out_file}" nslookup -type="${record}" "${TARGET_DOMAIN}"
    else
        warn "Neither dig nor nslookup found — skipping ${record} record lookup"
        echo "No DNS CLI available for ${record} lookup (${TARGET_DOMAIN})" > "${out_file}"
    fi
}

run_whois_query() {
    local out_file="$1"
    local py_cmd=""
    py_cmd="$(detect_python)"
    if has_cmd whois; then
        run_tool "WHOIS" "${out_file}" whois "${TARGET_DOMAIN}"
    elif has_cmd curl; then
        if [[ -n "${py_cmd}" ]]; then
            run_tool "RDAP lookup (WHOIS fallback)" "${out_file}" bash -c "curl -s 'https://rdap.org/domain/${TARGET_DOMAIN}' | ${py_cmd} -m json.tool 2>/dev/null || curl -s 'https://rdap.org/domain/${TARGET_DOMAIN}'"
        else
            run_tool "RDAP lookup (WHOIS fallback)" "${out_file}" curl -s "https://rdap.org/domain/${TARGET_DOMAIN}"
        fi
    else
        warn "WHOIS and curl are unavailable — skipping registration lookup"
        echo "WHOIS skipped: no whois/curl command available" > "${out_file}"
    fi
}

run_http_fingerprint_fallback() {
    local out_file="$1"
    local py_cmd=""
    py_cmd="$(detect_python)"
    if has_cmd curl; then
        if [[ -n "${py_cmd}" ]]; then
            run_tool "HTTP fingerprint fallback" "${out_file}" bash -c "curl -sI 'https://${TARGET_DOMAIN}'; echo ''; curl -sL 'https://${TARGET_DOMAIN}' | ${py_cmd} -c \"import re,sys; h=sys.stdin.read(); m=re.search(r'<title[^>]*>(.*?)</title>',h,re.I|re.S); print('TITLE:',(m.group(1).strip() if m else 'N/A'))\""
        else
            run_tool "HTTP fingerprint fallback" "${out_file}" curl -sI "https://${TARGET_DOMAIN}"
        fi
    else
        warn "No curl available for HTTP fingerprint fallback"
        echo "HTTP fingerprint fallback unavailable (curl missing)" > "${out_file}"
    fi
}

file_has_meaningful_data() {
    local file="$1"
    [[ -f "${file}" ]] || return 1
    grep -qvE '^(=+|[[:space:]]*$| TOOL     : | COMMAND  : | STARTED  : |\[ FINISHED: |\[ TIMED OUT AFTER: )' "${file}"
}

count_meaningful_lines() {
    local file="$1"
    [[ -f "${file}" ]] || { echo 0; return; }
    grep -vcE '^(=+|[[:space:]]*$| TOOL     : | COMMAND  : | STARTED  : |\[ FINISHED: |\[ TIMED OUT AFTER: )' "${file}" 2>/dev/null || echo 0
}

load_env_file() {
    local env_file="$1"
    [[ -f "${env_file}" ]] || return 1
    set -a
    # shellcheck disable=SC1090
    source "${env_file}"
    set +a
}

detect_llm_provider_key_and_model() {
    LLM_PROVIDER="$(echo "${LLM_PROVIDER:-}" | tr '[:upper:]' '[:lower:]')"

    if [[ -z "${LLM_PROVIDER}" ]]; then
        if [[ -n "${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}" ]]; then
            LLM_PROVIDER="gemini"
        elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
            LLM_PROVIDER="openai"
        elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
            LLM_PROVIDER="anthropic"
        elif [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
            LLM_PROVIDER="openrouter"
        fi
    fi

    LLM_API_KEY=""
    case "${LLM_PROVIDER}" in
        gemini)
            LLM_API_KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"
            [[ -z "${LLM_MODEL:-}" ]] && LLM_MODEL="gemini-1.5-flash"
            ;;
        openai)
            LLM_API_KEY="${OPENAI_API_KEY:-}"
            [[ -z "${LLM_MODEL:-}" ]] && LLM_MODEL="gpt-4o-mini"
            ;;
        anthropic)
            LLM_API_KEY="${ANTHROPIC_API_KEY:-}"
            [[ -z "${LLM_MODEL:-}" ]] && LLM_MODEL="claude-3-5-haiku-latest"
            ;;
        openrouter)
            LLM_API_KEY="${OPENROUTER_API_KEY:-}"
            [[ -z "${LLM_MODEL:-}" ]] && LLM_MODEL="openai/gpt-4o-mini"
            ;;
        *)
            LLM_PROVIDER=""
            ;;
    esac
}

upsert_env_value() {
    local env_file="$1"
    local key="$2"
    local value="$3"
    local temp_file
    temp_file="$(mktemp)"

    if [[ -f "${env_file}" ]]; then
        awk -v k="${key}" -v v="${value}" '
            BEGIN { found=0 }
            $0 ~ "^" k "=" {
                if (!found) {
                    print k "=" v
                    found=1
                }
                next
            }
            { print }
            END {
                if (!found) {
                    print k "=" v
                }
            }
        ' "${env_file}" > "${temp_file}"
    else
        printf "%s=%s\n" "${key}" "${value}" > "${temp_file}"
    fi

    mv "${temp_file}" "${env_file}"
}

configure_llm_api_key_interactive() {
    echo -e "  ${YELLOW}No LLM API key detected in an env file.${RESET}"
    echo -e "  ${DIM}To use optional AI analysis, you can use any supported provider:${RESET}"
    echo -e "    ${CYAN}Gemini${RESET} (free tier available): https://aistudio.google.com/app/apikey"
    echo -e "    ${CYAN}OpenAI${RESET}: https://platform.openai.com/api-keys"
    echo -e "    ${CYAN}Anthropic${RESET}: https://console.anthropic.com/settings/keys"
    echo -e "    ${CYAN}OpenRouter${RESET} (multi-model gateway): https://openrouter.ai/keys"
    echo ""
    echo -e "  ${DIM}Expected env keys: GEMINI_API_KEY / OPENAI_API_KEY / ANTHROPIC_API_KEY / OPENROUTER_API_KEY${RESET}"
    echo -e "  ${DIM}Optional model override key: LLM_MODEL${RESET}"
    echo ""

    local setup_now=""
    prompt "Configure an API key now for this run? [y/N]"
    read -r setup_now
    [[ "${setup_now,,}" != "y" ]] && return 1

    local provider_choice=""
    echo ""
    echo -e "  ${CYAN}[1]${RESET} Gemini (free tier)"
    echo -e "  ${CYAN}[2]${RESET} OpenAI"
    echo -e "  ${CYAN}[3]${RESET} Anthropic"
    echo -e "  ${CYAN}[4]${RESET} OpenRouter"
    echo ""
    prompt "Choose provider [1-4]:"
    read -r provider_choice
    case "${provider_choice}" in
        1) LLM_PROVIDER="gemini" ;;
        2) LLM_PROVIDER="openai" ;;
        3) LLM_PROVIDER="anthropic" ;;
        4) LLM_PROVIDER="openrouter" ;;
        *) warn "Invalid provider choice — skipping AI analysis."; return 1 ;;
    esac

    echo ""
    prompt "Paste ${LLM_PROVIDER} API key (input hidden):"
    read -rs LLM_API_KEY
    echo ""
    [[ -z "${LLM_API_KEY}" ]] && { warn "No API key provided."; return 1; }

    local model_input=""
    prompt "Model name (press ENTER for default):"
    read -r model_input
    if [[ -n "${model_input}" ]]; then
        LLM_MODEL="${model_input}"
    fi

    case "${LLM_PROVIDER}" in
        gemini) GEMINI_API_KEY="${LLM_API_KEY}" ;;
        openai) OPENAI_API_KEY="${LLM_API_KEY}" ;;
        anthropic) ANTHROPIC_API_KEY="${LLM_API_KEY}" ;;
        openrouter) OPENROUTER_API_KEY="${LLM_API_KEY}" ;;
    esac
    detect_llm_provider_key_and_model

    local save_key=""
    prompt "Save these settings to ${PROJECT_ROOT}/.env for future runs? [y/N]"
    read -r save_key
    if [[ "${save_key,,}" == "y" ]]; then
        local env_file="${PROJECT_ROOT}/.env"
        upsert_env_value "${env_file}" "LLM_PROVIDER" "${LLM_PROVIDER}"
        upsert_env_value "${env_file}" "LLM_MODEL" "${LLM_MODEL}"
        case "${LLM_PROVIDER}" in
            gemini) upsert_env_value "${env_file}" "GEMINI_API_KEY" "${LLM_API_KEY}" ;;
            openai) upsert_env_value "${env_file}" "OPENAI_API_KEY" "${LLM_API_KEY}" ;;
            anthropic) upsert_env_value "${env_file}" "ANTHROPIC_API_KEY" "${LLM_API_KEY}" ;;
            openrouter) upsert_env_value "${env_file}" "OPENROUTER_API_KEY" "${LLM_API_KEY}" ;;
        esac
        success "Saved LLM configuration to ${env_file}"
    fi

    return 0
}

init_llm_configuration() {
    local -a env_candidates=(
        "${PROJECT_ROOT}/.env"
        "${SCRIPT_DIR}/.env"
        "${HOME}/.wisper.env"
    )
    local env_file=""
    for env_file in "${env_candidates[@]}"; do
        [[ -f "${env_file}" ]] || continue
        load_env_file "${env_file}" || continue
    done

    detect_llm_provider_key_and_model
}

append_meaningful_excerpt() {
    local title="$1"
    local file="$2"
    local max_lines="$3"
    [[ -f "${file}" ]] || return 0
    file_has_meaningful_data "${file}" || return 0

    echo "### ${title}"
    grep -vE '^(=+|[[:space:]]*$| TOOL     : | COMMAND  : | STARTED  : |\[ FINISHED: |\[ TIMED OUT AFTER: )' "${file}" | head -n "${max_lines}" || true
    echo ""
}

build_llm_prompt_context() {
    local prompt_file="$1"
    local subdomains=0
    local urls=0
    local tech=0
    local dns=0

    [[ -f "${OUTPUT_ROOT}/core/01_subfinder.txt" ]] && subdomains=$((subdomains + $(count_meaningful_lines "${OUTPUT_ROOT}/core/01_subfinder.txt")))
    [[ -f "${OUTPUT_ROOT}/advanced/01_amass.txt" ]] && subdomains=$((subdomains + $(count_meaningful_lines "${OUTPUT_ROOT}/advanced/01_amass.txt")))
    [[ -f "${OUTPUT_ROOT}/core/06_waybackurls.txt" ]] && urls="$(count_meaningful_lines "${OUTPUT_ROOT}/core/06_waybackurls.txt")"
    [[ -f "${OUTPUT_ROOT}/core/07_whatweb.txt" ]] && tech="$(count_meaningful_lines "${OUTPUT_ROOT}/core/07_whatweb.txt")"
    [[ -f "${OUTPUT_ROOT}/core/03_dig_A.txt" ]] && dns="$(count_meaningful_lines "${OUTPUT_ROOT}/core/03_dig_A.txt")"

    {
        echo "You are a senior penetration testing analyst preparing a final report."
        echo "Only use evidence provided below. Do not invent findings."
        echo "If evidence is missing for a claim, explicitly state uncertainty."
        echo "Do not include any exploit code or weaponization steps."
        echo ""
        echo "Session metadata:"
        echo "- Session ID: ${SESSION_ID}"
        echo "- Target: ${TARGET_DOMAIN}"
        echo "- Profile: ${PROFILE}"
        echo "- Session Start: ${SESSION_START}"
        echo "- Report Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Observed counts:"
        echo "- Subdomains: ${subdomains}"
        echo "- Historical URLs: ${urls}"
        echo "- Technology fingerprints: ${tech}"
        echo "- DNS records lines: ${dns}"
        echo ""
        echo "Required output structure:"
        echo "1) Session activity timeline and what each recon phase discovered."
        echo "2) Threat and vulnerability analysis table with columns: Finding, Evidence, Possible Impact, Likelihood, Severity."
        echo "3) Abuse scenarios in defensive language (how attackers could misuse weaknesses at a high level, no procedural exploit steps)."
        echo "4) Prioritized remediation plan: Immediate, Short-Term, Long-Term."
        echo "5) Validation notes and confidence level per major finding."
        echo ""
        echo "Recon evidence excerpts:"
        echo ""
        append_meaningful_excerpt "Subfinder output" "${OUTPUT_ROOT}/core/01_subfinder.txt" 80
        append_meaningful_excerpt "Amass output" "${OUTPUT_ROOT}/advanced/01_amass.txt" 80
        append_meaningful_excerpt "WHOIS key output" "${OUTPUT_ROOT}/core/02_whois.txt" 80
        append_meaningful_excerpt "DNS A records" "${OUTPUT_ROOT}/core/03_dig_A.txt" 60
        append_meaningful_excerpt "DNS MX records" "${OUTPUT_ROOT}/core/03_dig_MX.txt" 40
        append_meaningful_excerpt "DNS NS records" "${OUTPUT_ROOT}/core/03_dig_NS.txt" 40
        append_meaningful_excerpt "DNS TXT records" "${OUTPUT_ROOT}/core/03_dig_TXT.txt" 40
        append_meaningful_excerpt "Wayback historical URLs" "${OUTPUT_ROOT}/core/06_waybackurls.txt" 120
        append_meaningful_excerpt "Technology fingerprints" "${OUTPUT_ROOT}/core/07_whatweb.txt" 80
        append_meaningful_excerpt "crt.sh results" "${OUTPUT_ROOT}/advanced/03_crtsh.txt" 80
        append_meaningful_excerpt "theHarvester results" "${OUTPUT_ROOT}/advanced/02_theharvester.txt" 80
    } > "${prompt_file}"
}

extract_llm_response_text() {
    local provider="$1"
    local py_cmd=""
    py_cmd="$(detect_python)"
    [[ -n "${py_cmd}" ]] || return 1
    local parser_script
    parser_script="$(mktemp)"
    cat > "${parser_script}" <<'PY'
import json
import sys

provider = sys.argv[1]
raw = sys.stdin.read()
data = json.loads(raw)

text = ""
if provider == "gemini":
    cands = data.get("candidates", [])
    if cands:
        parts = cands[0].get("content", {}).get("parts", [])
        text = "\n".join(p.get("text", "") for p in parts if p.get("text"))
elif provider in ("openai", "openrouter"):
    choices = data.get("choices", [])
    if choices:
        content = choices[0].get("message", {}).get("content", "")
        if isinstance(content, list):
            text = "\n".join(item.get("text", "") for item in content if isinstance(item, dict))
        else:
            text = content or ""
elif provider == "anthropic":
    content = data.get("content", [])
    text = "\n".join(item.get("text", "") for item in content if isinstance(item, dict) and item.get("type") == "text")

if not text.strip():
    raise SystemExit(1)

print(text.strip())
PY

    if ! ${py_cmd} "${parser_script}" "${provider}"; then
        rm -f "${parser_script}"
        return 1
    fi

    rm -f "${parser_script}"
}

run_llm_analysis_request() {
    local prompt_file="$1"
    local output_file="$2"
    local py_cmd=""
    py_cmd="$(detect_python)"
    [[ -n "${py_cmd}" ]] || { warn "Python is required for JSON payload handling."; return 1; }

    local payload=""
    local response=""

    case "${LLM_PROVIDER}" in
        gemini)
            payload="$(${py_cmd} - "${prompt_file}" <<'PY'
import json
import pathlib
import sys

prompt = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
print(json.dumps({
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {"temperature": 0.2}
}))
PY
)"
            response="$(curl -sS -X POST \
                -H "Content-Type: application/json" \
                "https://generativelanguage.googleapis.com/v1beta/models/${LLM_MODEL}:generateContent?key=${LLM_API_KEY}" \
                -d "${payload}")" || return 1
            ;;
        openai)
            payload="$(${py_cmd} - "${prompt_file}" "${LLM_MODEL}" <<'PY'
import json
import pathlib
import sys

prompt = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
model = sys.argv[2]
print(json.dumps({
    "model": model,
    "temperature": 0.2,
    "messages": [
        {"role": "system", "content": "You are a senior penetration testing analyst."},
        {"role": "user", "content": prompt}
    ]
}))
PY
)"
            response="$(curl -sS -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${LLM_API_KEY}" \
                "https://api.openai.com/v1/chat/completions" \
                -d "${payload}")" || return 1
            ;;
        anthropic)
            payload="$(${py_cmd} - "${prompt_file}" "${LLM_MODEL}" <<'PY'
import json
import pathlib
import sys

prompt = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
model = sys.argv[2]
print(json.dumps({
    "model": model,
    "max_tokens": 1800,
    "temperature": 0.2,
    "messages": [{"role": "user", "content": prompt}]
}))
PY
)"
            response="$(curl -sS -X POST \
                -H "Content-Type: application/json" \
                -H "x-api-key: ${LLM_API_KEY}" \
                -H "anthropic-version: 2023-06-01" \
                "https://api.anthropic.com/v1/messages" \
                -d "${payload}")" || return 1
            ;;
        openrouter)
            payload="$(${py_cmd} - "${prompt_file}" "${LLM_MODEL}" <<'PY'
import json
import pathlib
import sys

prompt = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
model = sys.argv[2]
print(json.dumps({
    "model": model,
    "temperature": 0.2,
    "messages": [
        {"role": "system", "content": "You are a senior penetration testing analyst."},
        {"role": "user", "content": prompt}
    ]
}))
PY
)"
            response="$(curl -sS -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${LLM_API_KEY}" \
                "https://openrouter.ai/api/v1/chat/completions" \
                -d "${payload}")" || return 1
            ;;
        *)
            return 1
            ;;
    esac

    if ! printf "%s" "${response}" | extract_llm_response_text "${LLM_PROVIDER}" > "${output_file}"; then
        return 1
    fi

    return 0
}

generate_optional_llm_analysis() {
    local enable_analysis=""
    prompt "Generate optional AI threat analysis report? [y/N]"
    read -r enable_analysis
    [[ "${enable_analysis,,}" == "y" ]] || return 0

    init_llm_configuration
    if [[ -z "${LLM_PROVIDER:-}" || -z "${LLM_API_KEY:-}" ]]; then
        configure_llm_api_key_interactive || {
            warn "AI analysis skipped (no provider/key configured)."
            return 0
        }
        detect_llm_provider_key_and_model
    fi

    if [[ -z "${LLM_PROVIDER:-}" || -z "${LLM_API_KEY:-}" || -z "${LLM_MODEL:-}" ]]; then
        warn "AI analysis skipped (incomplete LLM configuration)."
        return 0
    fi

    local prompt_file
    prompt_file="$(mktemp)"
    local analysis_body_file
    analysis_body_file="$(mktemp)"
    LLM_ANALYSIS_FILE="${OUTPUT_ROOT}/reports/WISPER_AI_ANALYSIS_${SESSION_ID}_${SAFE_NAME}.md"

    step "Generating AI analysis via ${LLM_PROVIDER}:${LLM_MODEL} ..."
    build_llm_prompt_context "${prompt_file}"

    if ! run_llm_analysis_request "${prompt_file}" "${analysis_body_file}"; then
        warn "AI analysis request failed. Check API key/model/provider and network access."
        rm -f "${prompt_file}" "${analysis_body_file}"
        return 0
    fi

    {
        echo "# Wisper AI Threat Analysis"
        echo ""
        echo "- Session ID: ${SESSION_ID}"
        echo "- Target: ${TARGET_DOMAIN}"
        echo "- Profile: ${PROFILE}"
        echo "- Provider: ${LLM_PROVIDER}"
        echo "- Model: ${LLM_MODEL}"
        echo "- Generated at: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        cat "${analysis_body_file}"
        echo ""
        echo "---"
        echo "_Generated from collected recon evidence. Validate manually before remediation decisions._"
    } > "${LLM_ANALYSIS_FILE}"

    success "AI analysis generated → ${LLM_ANALYSIS_FILE}"
    rm -f "${prompt_file}" "${analysis_body_file}"
}

start_loading_effect() {
    local label="$1"
    local detail="${2:-collecting data}"

    if [[ ! -t 1 ]]; then
        return 0
    fi

    (
        local frames='|/-\'
        local i=0
        while true; do
            printf '\r  %s %s %s %s' "${ARROW}" "${WHITE}${label}${RESET}" "${DIM}${detail}${RESET}" "${frames:i++%4:1}" >&2
            sleep 0.15
        done
    ) &

    echo $!
}

stop_loading_effect() {
    local spinner_pid="$1"
    [[ -n "${spinner_pid}" ]] || return 0
    kill "${spinner_pid}" >/dev/null 2>&1 || true
    wait "${spinner_pid}" >/dev/null 2>&1 || true
    if [[ -t 1 ]]; then
        printf '\r\033[K' >&2
    fi
}

resolve_ip_for_target() {
    if has_cmd dig; then
        dig +short "${TARGET_DOMAIN}" | head -1
        return
    fi
    if has_cmd nslookup; then
        nslookup "${TARGET_DOMAIN}" 2>/dev/null | awk '/^Address: / {print $2}' | head -1
        return
    fi
    echo ""
}

# run a command, tee output to both terminal and file
run_tool() {
    local tool_name="$1"
    local out_file="$2"
    shift 2
    local timeout_seconds=""
    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        timeout_seconds="$1"
        shift
    fi
    local cmd=("$@")

    echo ""
    echo -e "  ${MAGENTA}⌖ Running:${RESET} ${DIM}${cmd[*]}${RESET}"
    echo -e "  ${DIM}  Output  → ${out_file}${RESET}"
    divider

    local spinner_pid=""
    spinner_pid="$(start_loading_effect "${tool_name}" "collecting data")"

    # Write header to file
    {
        echo "================================================================"
        echo " TOOL     : ${tool_name}"
        echo " COMMAND  : ${cmd[*]}"
        echo " STARTED  : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================"
        echo ""
    } > "${out_file}"

    # Run — tee to terminal AND append to file
    if [[ -n "${timeout_seconds}" && -n "$(command -v timeout 2>/dev/null || true)" ]]; then
        if timeout --preserve-status --signal=INT "${timeout_seconds}" "${cmd[@]}" 2>&1 | tee -a "${out_file}"; then
            echo "" >> "${out_file}"
            echo "[ FINISHED: $(date '+%Y-%m-%d %H:%M:%S') ]" >> "${out_file}"
            success "${tool_name} complete → ${out_file}"
        else
            local exit_code=$?
            if [[ ${exit_code} -eq 124 || ${exit_code} -eq 137 ]]; then
                echo "" >> "${out_file}"
                echo "[ TIMED OUT AFTER: ${timeout_seconds}s ]" >> "${out_file}"
                warn "${tool_name} timed out after ${timeout_seconds}s"
            else
                warn "${tool_name} returned non-zero (may be normal for some tools)"
            fi
        fi
    elif "${cmd[@]}" 2>&1 | tee -a "${out_file}"; then
        echo "" >> "${out_file}"
        echo "[ FINISHED: $(date '+%Y-%m-%d %H:%M:%S') ]" >> "${out_file}"
        success "${tool_name} complete → ${out_file}"
    else
        warn "${tool_name} returned non-zero (may be normal for some tools)"
    fi

    stop_loading_effect "${spinner_pid}"
    divider
}

# ─── STEP 0: Tool Installation ───────────────────────────────────────────────
install_tools() {
    section "0" "TOOL INSTALLATION"
    echo -e "  ${DIM}Installing all required tools for core and advanced profiles...${RESET}"
    echo ""

    local os_name
    os_name="$(uname -s 2>/dev/null || echo "unknown")"
    local has_apt=0
    local has_sudo=0
    local pip_cmd=""
    local py_cmd=""
    local sys_prefix=""

    command -v apt-get >/dev/null 2>&1 && has_apt=1
    command -v sudo >/dev/null 2>&1 && has_sudo=1
    if command -v pip3 >/dev/null 2>&1; then
        pip_cmd="pip3"
    elif command -v python3 >/dev/null 2>&1; then
        pip_cmd="python3 -m pip"
    elif command -v python >/dev/null 2>&1; then
        pip_cmd="python -m pip"
    fi
    py_cmd="$(detect_python)"
    [[ ${has_sudo} -eq 1 ]] && sys_prefix="sudo"

    step "Runtime detected: ${os_name}"
    if [[ ${has_apt} -eq 0 ]]; then
        warn "apt-get is unavailable in this environment. System-level package install will be skipped."
    fi
    if [[ -z "${pip_cmd}" ]]; then
        warn "Python pip was not found. Python tool installs will be skipped."
    elif [[ -n "${py_cmd}" ]]; then
        USER_BASE="$(${py_cmd} -m site --user-base 2>/dev/null || true)"
        if [[ -n "${USER_BASE}" ]]; then
            export PATH="${PATH}:${USER_BASE}/Scripts:${USER_BASE}/bin"
        fi
    fi

    # ── System packages ──
    if [[ ${has_apt} -eq 1 ]]; then
        step "Updating apt & installing system dependencies..."
        ${sys_prefix} apt-get update -qq 2>&1 | tail -1 || true
        ${sys_prefix} apt-get install -y -qq \
            curl wget git python3 python3-pip \
            dnsutils whois nmap \
            golang-go \
            ruby ruby-dev \
            2>&1 | grep -E "(install|upgrade|already)" | head -20 || true
        success "System packages ready"
    else
        warn "Skipped apt-based system package installation"
    fi

    # ── Python libraries ──
    if [[ -n "${pip_cmd}" ]]; then
        step "Installing missing Python recon libraries..."
        local -a missing_py_libs=()
        python_module_entry_works "theHarvester" || missing_py_libs+=("theHarvester")
        python_import_check "dns" || missing_py_libs+=("dnspython")
        python_import_check "requests" || missing_py_libs+=("requests")
        python_import_check "bs4" || missing_py_libs+=("beautifulsoup4")
        python_import_check "aiohttp" || missing_py_libs+=("aiohttp")

        if [[ ${#missing_py_libs[@]} -eq 0 ]]; then
            success "Python recon libraries already installed"
        else
            ${pip_cmd} install -q "${missing_py_libs[@]}" \
                2>/dev/null || ${pip_cmd} install --break-system-packages -q \
                "${missing_py_libs[@]}" 2>/dev/null || true
            success "Python libraries ready"
        fi
    else
        warn "Skipped Python library installation"
    fi

    # ── Go tools ──
    export GOPATH="${HOME}/go"
    export PATH="${PATH}:${GOPATH}/bin"
    bootstrap_tool_paths
    install_go_if_missing || true

    if command -v go >/dev/null 2>&1; then
        step "Installing Subfinder (passive subdomain discovery)..."
        if ! command -v subfinder &>/dev/null; then
            go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest \
                2>/dev/null || warn "Subfinder install failed — install manually: go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        else
            success "Subfinder already installed"
        fi

        step "Installing Amass (asset discovery & mapping)..."
        if ! command -v amass &>/dev/null; then
            go install -v github.com/owasp-amass/amass/v4/...@master \
                2>/dev/null || warn "Amass install failed — try: sudo apt install amass"
        else
            success "Amass already installed"
        fi

        step "Installing waybackurls (historical URL discovery)..."
        if ! command -v waybackurls &>/dev/null; then
            go install -v github.com/tomnomnom/waybackurls@latest \
                2>/dev/null || warn "waybackurls install failed"
        else
            success "waybackurls already installed"
        fi
    else
        warn "Go is not installed — skipping go-based tool installs (subfinder/amass/waybackurls)"
    fi

    step "Installing WhatWeb (technology fingerprinting)..."
    if ! command -v whatweb &>/dev/null; then
        install_with_system_manager "whatweb" || true
        command -v whatweb &>/dev/null || \
        ${sys_prefix} gem install whatweb 2>/dev/null || \
        warn "WhatWeb install failed — fallback mode will be used"
    else
        success "WhatWeb already installed"
    fi

    step "Installing DNSRecon (DNS enumeration)..."
    if ! command -v dnsrecon &>/dev/null && ! python_module_entry_works "dnsrecon"; then
        [[ ${has_apt} -eq 1 ]] && ${sys_prefix} apt-get install -y -qq dnsrecon 2>/dev/null || true
        command -v dnsrecon &>/dev/null || python_module_entry_works "dnsrecon" || \
        [[ -n "${pip_cmd}" ]] && ${pip_cmd} install --break-system-packages dnsrecon 2>/dev/null || \
        warn "DNSRecon install failed — try: sudo apt install dnsrecon"
    else
        success "DNSRecon already installed"
    fi

    step "Installing SpiderFoot (OSINT aggregation)..."
    if ! command -v spiderfoot &>/dev/null && ! python_module_entry_works "spiderfoot"; then
        install_with_system_manager "spiderfoot" || true
        command -v spiderfoot &>/dev/null || python_module_entry_works "spiderfoot" || \
        warn "SpiderFoot is not available via direct pip install in many environments; use distro package, Docker, or source install."
    else
        success "SpiderFoot already installed"
    fi

    # ── Recon-ng check ──
    step "Checking Recon-ng..."
    if ! command -v recon-ng &>/dev/null && ! python_module_entry_works "reconng"; then
        [[ -n "${pip_cmd}" ]] && ${pip_cmd} install --break-system-packages recon-ng 2>/dev/null || \
        warn "Recon-ng not found — try: pip3 install recon-ng"
    else
        success "Recon-ng already installed"
    fi

    echo ""
    success "Installation phase complete"
    echo ""
}

# ─── STEP 1: Create Session ───────────────────────────────────────────────────
create_session() {
    section "1" "CREATE SESSION"

    RAND_SUFFIX="$(printf '%06X' "$(( ((RANDOM << 16) | RANDOM) & 0xFFFFFF ))")"
    SESSION_ID="WA-$(date '+%Y%m%d')-${RAND_SUFFIX}"
    SESSION_START=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "  ${GREEN}${BOLD}New Session Created${RESET}"
    echo ""
    log "Session ID   : ${CYAN}${SESSION_ID}${RESET}"
    log "Started At   : ${SESSION_START}"
    echo ""
    success "Session initialized: ${SESSION_ID}"
}

# ─── STEP 2: Add Website Scope ────────────────────────────────────────────────
add_scope() {
    section "2" "ADD WEBSITE SCOPE"

    echo -e "  ${DIM}Enter the target domain or URL for this recon session.${RESET}"
    echo -e "  ${DIM}Examples: example.com | https://example.com | sub.example.com${RESET}"
    echo ""

    while true; do
        prompt "Target domain / URL:"
        read -r TARGET_INPUT

        # Normalize
        TARGET_DOMAIN=$(echo "${TARGET_INPUT}" | sed 's|https\?://||' | sed 's|/.*||' | tr '[:upper:]' '[:lower:]' | xargs)

        if [[ -z "${TARGET_DOMAIN}" ]]; then
            error "Target cannot be empty. Try again."
            continue
        fi

        # Basic validation
        if [[ "${TARGET_DOMAIN}" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.\-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            warn "That doesn't look like a valid domain. Continue anyway? [y/N]"
            echo -ne "  ${CYAN}›${RESET} "
            read -r confirm
            [[ "${confirm,,}" == "y" ]] && break
        fi
    done

    TARGET_URL="https://${TARGET_DOMAIN}"

    # ── Create output folder structure ──
    SAFE_NAME=$(echo "${TARGET_DOMAIN}" | tr '.' '_' | tr '-' '_')
    OUTPUT_ROOT="./sessions/${SESSION_ID}_${SAFE_NAME}"
    mkdir -p "${OUTPUT_ROOT}"/{core,advanced,evidence,reports}

    echo ""
    log "Target Domain : ${CYAN}${TARGET_DOMAIN}${RESET}"
    log "Target URL    : ${CYAN}${TARGET_URL}${RESET}"
    log "Output Folder : ${CYAN}${OUTPUT_ROOT}${RESET}"
    echo ""

    # Write session manifest
    cat > "${OUTPUT_ROOT}/session.txt" << EOF
================================================================
 WISPER ALPHA — SESSION MANIFEST
================================================================
 Session ID   : ${SESSION_ID}
 Target       : ${TARGET_DOMAIN}
 URL          : ${TARGET_URL}
 Started      : ${SESSION_START}
 Output Root  : ${OUTPUT_ROOT}
================================================================
EOF

    success "Scope locked: ${TARGET_DOMAIN}"
    success "Output folder: ${OUTPUT_ROOT}"
}

# ─── STEP 3: Choose Profile ───────────────────────────────────────────────────
choose_profile() {
    section "3" "CHOOSE RECON PROFILE"

    echo -e "  ${WHITE}${BOLD}Available Profiles:${RESET}"
    echo ""
    echo -e "  ${CYAN}[1]${RESET} ${WHITE}${BOLD}core-passive${RESET}"
    echo -e "      ${DIM}Fast baseline mapping with passive-only tools${RESET}"
    echo -e "      ${DIM}Tools: subfinder, whois, dig, nslookup, dnsrecon, waybackurls, whatweb${RESET}"
    echo -e "      ${DIM}Runtime: ~2-5 minutes | Low noise | Good coverage${RESET}"
    echo ""
    echo -e "  ${YELLOW}[2]${RESET} ${WHITE}${BOLD}advanced-deep-passive${RESET}"
    echo -e "      ${DIM}Deeper intelligence with full enrichment toolset${RESET}"
    echo -e "      ${DIM}Tools: ALL core tools + amass, theHarvester, spiderfoot, recon-ng, shodan hints${RESET}"
    echo -e "      ${DIM}Runtime: ~10-20 minutes | Medium noise | High depth${RESET}"
    echo ""

    while true; do
        prompt "Select profile [1/2]:"
        read -r PROFILE_CHOICE
        case "${PROFILE_CHOICE}" in
            1) PROFILE="core-passive";           break ;;
            2) PROFILE="advanced-deep-passive";  break ;;
            *) error "Enter 1 or 2" ;;
        esac
    done

    echo ""
    success "Profile selected: ${CYAN}${BOLD}${PROFILE}${RESET}"
    [[ "${PROFILE_CHOICE}" == "1" ]] && PROFILE_DIR="core" || PROFILE_DIR="advanced"
    log "All outputs → ${OUTPUT_ROOT}/${PROFILE_DIR}/"
}

# ─── STEP 4A: Run Core Profile ────────────────────────────────────────────────
run_core() {
    section "4" "RUN RECON — core-passive"
    OUT="${OUTPUT_ROOT}/core"
    echo -e "  ${DIM}Running passive-first tools. Output in terminal + saved to:${RESET}"
    echo -e "  ${CYAN}  ${OUT}/${RESET}"
    echo ""

    # ── 1. Subfinder ──
    if command -v subfinder &>/dev/null; then
        run_tool "Subfinder" \
            "${OUT}/01_subfinder.txt" 120 \
            subfinder -d "${TARGET_DOMAIN}" -silent
    else
        warn "Subfinder not found — skipping"
    fi

    # ── 2. WHOIS / RDAP fallback ──
    run_whois_query "${OUT}/02_whois.txt"

    # ── 3. DNS records with dig/nslookup fallback ──
    run_dns_record_query "A"   "${OUT}/03_dig_A.txt"
    run_dns_record_query "MX"  "${OUT}/03_dig_MX.txt"
    run_dns_record_query "NS"  "${OUT}/03_dig_NS.txt"
    run_dns_record_query "TXT" "${OUT}/03_dig_TXT.txt"

    # ── 4. nslookup ──
    if has_cmd nslookup; then
        run_tool "nslookup" \
            "${OUT}/04_nslookup.txt" \
            nslookup "${TARGET_DOMAIN}"
    else
        warn "nslookup not found — skipping"
        echo "nslookup unavailable in current environment" > "${OUT}/04_nslookup.txt"
    fi

    # ── 5. DNSRecon ──
    if command -v dnsrecon &>/dev/null; then
        run_tool "DNSRecon (passive std)" \
            "${OUT}/05_dnsrecon.txt" 120 \
            dnsrecon -d "${TARGET_DOMAIN}" -t std
    elif python_module_entry_works "dnsrecon"; then
        run_tool "DNSRecon (python module fallback)" \
            "${OUT}/05_dnsrecon.txt" 120 \
            bash -c "$(detect_python) -m dnsrecon -d '${TARGET_DOMAIN}' -t std"
    else
        warn "DNSRecon not found — skipping"
    fi

    # ── 6. waybackurls ──
    if command -v waybackurls &>/dev/null; then
        run_tool "waybackurls" \
            "${OUT}/06_waybackurls.txt" 120 \
            bash -c "echo '${TARGET_DOMAIN}' | waybackurls"
    else
        warn "waybackurls not found — skipping"
    fi

    # ── 7. WhatWeb ──
    if command -v whatweb &>/dev/null; then
        run_tool "WhatWeb" \
            "${OUT}/07_whatweb.txt" 120 \
            whatweb "https://${TARGET_DOMAIN}" --color=never
    elif has_cmd curl; then
        run_http_fingerprint_fallback "${OUT}/07_whatweb.txt"
    else
        warn "WhatWeb not found — skipping"
    fi

    # ── Merge all core output into one combined file ──
    COMBINED="${OUT}/COMBINED_core_${SAFE_NAME}.txt"
    {
        echo "================================================================"
        echo " WISPER ALPHA — CORE PROFILE COMBINED OUTPUT"
        echo " Session  : ${SESSION_ID}"
        echo " Target   : ${TARGET_DOMAIN}"
        echo " Profile  : core-passive"
        echo " Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================"
        echo ""
        for f in "${OUT}"/0*.txt; do
            [ -f "${f}" ] || continue
            file_has_meaningful_data "${f}" || continue
            echo ""
            echo "────────────────────────────────────────────────────────"
            echo " FILE: $(basename "${f}")"
            echo "────────────────────────────────────────────────────────"
            cat "${f}"
        done
    } > "${COMBINED}"

    echo ""
    success "Core profile complete"
    success "Combined report → ${COMBINED}"
}

# ─── STEP 4B: Run Advanced Profile ───────────────────────────────────────────
run_advanced() {
    section "4" "RUN RECON — advanced-deep-passive"
    OUT="${OUTPUT_ROOT}/advanced"
    echo -e "  ${DIM}Running full enrichment toolset. Output in terminal + saved to:${RESET}"
    echo -e "  ${CYAN}  ${OUT}/${RESET}"
    echo ""

    # ── Run all core tools first ──
    step "Phase A: Running all core-passive tools first..."
    echo ""

    CORE_OUT="${OUTPUT_ROOT}/core"

    if command -v subfinder &>/dev/null; then
        run_tool "Subfinder" "${CORE_OUT}/01_subfinder.txt" 120 \
            subfinder -d "${TARGET_DOMAIN}" -silent
    fi

    run_whois_query "${CORE_OUT}/02_whois.txt"
    run_dns_record_query "A"   "${CORE_OUT}/03_dig_A.txt"
    run_dns_record_query "MX"  "${CORE_OUT}/03_dig_MX.txt"
    run_dns_record_query "NS"  "${CORE_OUT}/03_dig_NS.txt"
    run_dns_record_query "TXT" "${CORE_OUT}/03_dig_TXT.txt"
    if has_cmd nslookup; then
        run_tool "nslookup" "${CORE_OUT}/04_nslookup.txt" nslookup "${TARGET_DOMAIN}"
    else
        warn "nslookup not found — skipping"
        echo "nslookup unavailable in current environment" > "${CORE_OUT}/04_nslookup.txt"
    fi

    if command -v dnsrecon &>/dev/null; then
        run_tool "DNSRecon" "${CORE_OUT}/05_dnsrecon.txt" 120 dnsrecon -d "${TARGET_DOMAIN}" -t std
    elif python_module_entry_works "dnsrecon"; then
        run_tool "DNSRecon (python module fallback)" "${CORE_OUT}/05_dnsrecon.txt" 120 bash -c "$(detect_python) -m dnsrecon -d '${TARGET_DOMAIN}' -t std"
    fi

    if command -v waybackurls &>/dev/null; then
        run_tool "waybackurls" "${CORE_OUT}/06_waybackurls.txt" 120 \
            bash -c "echo '${TARGET_DOMAIN}' | waybackurls"
    fi

    if command -v whatweb &>/dev/null; then
        run_tool "WhatWeb" "${CORE_OUT}/07_whatweb.txt" 120 \
            whatweb "https://${TARGET_DOMAIN}" --color=never
    elif has_cmd curl; then
        run_http_fingerprint_fallback "${CORE_OUT}/07_whatweb.txt"
    fi

    # ── Phase B: Advanced-only tools ──
    echo ""
    step "Phase B: Running advanced enrichment tools..."
    echo ""

    # Amass
    if command -v amass &>/dev/null; then
        run_tool "Amass (passive enum)" \
            "${OUT}/01_amass.txt" 180 \
            amass enum -passive -d "${TARGET_DOMAIN}"
    else
        warn "Amass not found — skipping (install: go install github.com/owasp-amass/amass/v4/...@master)"
    fi

    # theHarvester
    if command -v theHarvester &>/dev/null; then
        run_tool "theHarvester (all sources)" \
            "${OUT}/02_theharvester.txt" 180 \
            theHarvester -d "${TARGET_DOMAIN}" -b bing,google,yahoo,duckduckgo,crtsh
    elif python_module_entry_works "theHarvester"; then
        run_tool "theHarvester (python module fallback)" \
            "${OUT}/02_theharvester.txt" 180 \
            bash -c "$(detect_python) -m theHarvester -d '${TARGET_DOMAIN}' -b bing,google,yahoo,duckduckgo,crtsh"
    else
        warn "theHarvester not found — skipping"
    fi

    # crt.sh certificate transparency (passive, no tool needed — curl)
    run_tool "crt.sh (certificate transparency)" \
        "${OUT}/03_crtsh.txt" 120 \
        bash -c "curl -s 'https://crt.sh/?q=%25.${TARGET_DOMAIN}&output=json' | python3 -m json.tool 2>/dev/null | grep '\"name_value\"' | sort -u | head -50 || echo 'crt.sh query returned no results'"

    # Shodan CLI hint (passive)
    if command -v shodan &>/dev/null; then
        TARGET_IP="$(resolve_ip_for_target)"
        if [[ -z "${TARGET_IP}" ]]; then
            TARGET_IP="${TARGET_DOMAIN}"
        fi
        run_tool "Shodan (host info)" \
            "${OUT}/04_shodan.txt" 120 \
            bash -c "shodan host ${TARGET_IP} 2>/dev/null || echo 'Shodan: configure API key with: shodan init YOUR_KEY'"
    else
        {
            echo "Shodan CLI not installed."
            echo "To install: pip3 install shodan"
            echo "To configure: shodan init YOUR_API_KEY"
            echo ""
            echo "Manual search: https://www.shodan.io/search?query=${TARGET_DOMAIN}"
        } > "${OUT}/04_shodan_manual.txt"
        cat "${OUT}/04_shodan_manual.txt"
        warn "Shodan CLI not installed — manual URL saved"
    fi

    # Censys hint
    {
        echo "Censys passive search (API key required)."
        echo "Manual search: https://search.censys.io/search?resource=hosts&q=${TARGET_DOMAIN}"
        echo ""
        echo "To use Censys CLI:"
        echo "  pip3 install censys"
        echo "  censys config  # enter API ID + Secret from censys.io"
        echo "  censys search '${TARGET_DOMAIN}'"
    } > "${OUT}/05_censys_manual.txt"
    cat "${OUT}/05_censys_manual.txt"

    # SpiderFoot CLI (if available)
    if command -v spiderfoot &>/dev/null; then
        warn "SpiderFoot detected — run interactively: spiderfoot -l 127.0.0.1:5001"
        echo "SpiderFoot available. Run interactively with: spiderfoot -l 127.0.0.1:5001" \
            > "${OUT}/06_spiderfoot_note.txt"
    fi

    # Recon-ng note
    if command -v recon-ng &>/dev/null; then
        {
            echo "Recon-ng is available."
            echo "Start with: recon-ng"
            echo ""
            echo "Suggested modules for ${TARGET_DOMAIN}:"
            echo "  use recon/domains-hosts/brute_hosts"
            echo "  use recon/domains-contacts/whois_pocs"
            echo "  use recon/hosts-hosts/resolve"
            echo "  set SOURCE ${TARGET_DOMAIN}"
            echo "  run"
        } > "${OUT}/07_recon_ng_guide.txt"
        cat "${OUT}/07_recon_ng_guide.txt"
    fi

    # ── Merge all outputs ──
    COMBINED="${OUT}/COMBINED_advanced_${SAFE_NAME}.txt"
    {
        echo "================================================================"
        echo " WISPER ALPHA — ADVANCED PROFILE COMBINED OUTPUT"
        echo " Session  : ${SESSION_ID}"
        echo " Target   : ${TARGET_DOMAIN}"
        echo " Profile  : advanced-deep-passive"
        echo " Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================"
        echo ""
        echo "─── CORE PHASE ─────────────────────────────────────────────────"
        for f in "${CORE_OUT}"/0*.txt; do
            [ -f "${f}" ] || continue
            file_has_meaningful_data "${f}" || continue
            echo ""
            echo "  FILE: $(basename "${f}")"
            echo "  ──────────────────────────────────────────────────────────"
            cat "${f}"
        done
        echo ""
        echo "─── ADVANCED PHASE ─────────────────────────────────────────────"
        for f in "${OUT}"/0*.txt; do
            [ -f "${f}" ] || continue
            file_has_meaningful_data "${f}" || continue
            echo ""
            echo "  FILE: $(basename "${f}")"
            echo "  ──────────────────────────────────────────────────────────"
            cat "${f}"
        done
    } > "${COMBINED}"

    echo ""
    success "Advanced profile complete"
    success "Combined report → ${COMBINED}"
}

# ─── STEP 5: Review Dashboard ─────────────────────────────────────────────────
review_dashboard() {
    section "5" "REVIEW DASHBOARD"

    echo -e "  ${WHITE}${BOLD}Session Summary${RESET}"
    echo ""

    # Count findings from files
    SUBDOMAIN_COUNT=0
    URL_COUNT=0
    TECH_COUNT=0
    DNS_COUNT=0

    if file_has_meaningful_data "${OUTPUT_ROOT}/core/01_subfinder.txt"; then
        SUBDOMAIN_COUNT=$(count_meaningful_lines "${OUTPUT_ROOT}/core/01_subfinder.txt")
    fi
    if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/01_amass.txt"; then
        AMASS_COUNT=$(count_meaningful_lines "${OUTPUT_ROOT}/advanced/01_amass.txt")
        SUBDOMAIN_COUNT=$((SUBDOMAIN_COUNT + AMASS_COUNT))
    fi
    if file_has_meaningful_data "${OUTPUT_ROOT}/core/06_waybackurls.txt"; then
        URL_COUNT=$(count_meaningful_lines "${OUTPUT_ROOT}/core/06_waybackurls.txt")
    fi
    if file_has_meaningful_data "${OUTPUT_ROOT}/core/07_whatweb.txt"; then
        TECH_COUNT=$(count_meaningful_lines "${OUTPUT_ROOT}/core/07_whatweb.txt")
    fi
    if file_has_meaningful_data "${OUTPUT_ROOT}/core/03_dig_A.txt"; then
        DNS_COUNT=$(count_meaningful_lines "${OUTPUT_ROOT}/core/03_dig_A.txt")
    fi

    echo -e "  ${DIM}┌────────────────────────────────────────────────┐${RESET}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "Subdomains found"   "${SUBDOMAIN_COUNT}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "Historical URLs"    "${URL_COUNT}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "Tech fingerprints"  "${TECH_COUNT}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "DNS records"        "${DNS_COUNT}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "Profile"            "${PROFILE}"
    printf "  ${DIM}│${RESET}  %-28s ${CYAN}${BOLD}%8s${RESET}  ${DIM}│${RESET}\n" "Session ID"         "${SESSION_ID}"
    echo -e "  ${DIM}└────────────────────────────────────────────────┘${RESET}"
    echo ""

    echo -e "  ${WHITE}Output Files:${RESET}"
    find "${OUTPUT_ROOT}" -name "*.txt" | sort | while read -r f; do
        file_has_meaningful_data "${f}" || continue
        SIZE=$(wc -l < "${f}" 2>/dev/null || echo 0)
        printf "  ${DIM}│${RESET}  ${CYAN}%-50s${RESET}  ${DIM}%4d lines${RESET}\n" "${f}" "${SIZE}"
    done
    echo ""
    success "Dashboard ready"
}

# ─── STEP 6: Inspect Findings ─────────────────────────────────────────────────
inspect_findings() {
    section "6" "INSPECT FINDINGS"

    echo -e "  ${DIM}Choose a finding category to inspect in the terminal:${RESET}"
    echo ""
    echo -e "  ${CYAN}[1]${RESET} Subdomains"
    echo -e "  ${CYAN}[2]${RESET} DNS Records (A / MX / NS / TXT)"
    echo -e "  ${CYAN}[3]${RESET} WHOIS Registration Info"
    echo -e "  ${CYAN}[4]${RESET} Historical URLs (top 30)"
    echo -e "  ${CYAN}[5]${RESET} Technology Fingerprints"
    echo -e "  ${CYAN}[6]${RESET} Certificate Transparency (crt.sh)"
    echo -e "  ${CYAN}[s]${RESET} Skip inspection"
    echo ""

    while true; do
        prompt "Select finding to inspect [1-6 / s]:"
        read -r INSPECT_CHOICE

        case "${INSPECT_CHOICE}" in
            1)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Subdomains ──────────────────────────────────────────────${RESET}"
                if file_has_meaningful_data "${OUTPUT_ROOT}/core/01_subfinder.txt"; then
                    cat "${OUTPUT_ROOT}/core/01_subfinder.txt"
                else
                    warn "No subfinder output"
                fi
                if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/01_amass.txt"; then
                    cat "${OUTPUT_ROOT}/advanced/01_amass.txt"
                fi
                ;;
            2)
                echo ""
                echo -e "  ${CYAN}${BOLD}── DNS Records ─────────────────────────────────────────────${RESET}"
                for rec in A MX NS TXT; do
                    f="${OUTPUT_ROOT}/core/03_dig_${rec}.txt"
                    if file_has_meaningful_data "${f}"; then
                        echo -e "  ${YELLOW}${rec}:${RESET}"
                        cat "${f}"
                    fi
                done
                ;;
            3)
                echo ""
                echo -e "  ${CYAN}${BOLD}── WHOIS ───────────────────────────────────────────────────${RESET}"
                if file_has_meaningful_data "${OUTPUT_ROOT}/core/02_whois.txt"; then
                    grep -E "(Domain|Registrar|Name Server|Creation|Expiry|Email|handle|ldhName|status)" "${OUTPUT_ROOT}/core/02_whois.txt" | head -30 || head -30 "${OUTPUT_ROOT}/core/02_whois.txt"
                else
                    warn "No WHOIS output"
                fi
                ;;
            4)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Historical URLs (top 30) ────────────────────────────────${RESET}"
                if file_has_meaningful_data "${OUTPUT_ROOT}/core/06_waybackurls.txt"; then
                    head -30 "${OUTPUT_ROOT}/core/06_waybackurls.txt"
                else
                    warn "No waybackurls output"
                fi
                ;;
            5)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Technology Fingerprints ─────────────────────────────────${RESET}"
                if file_has_meaningful_data "${OUTPUT_ROOT}/core/07_whatweb.txt"; then
                    cat "${OUTPUT_ROOT}/core/07_whatweb.txt"
                else
                    warn "No WhatWeb output"
                fi
                ;;
            6)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Certificate Transparency ────────────────────────────────${RESET}"
                if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/03_crtsh.txt"; then
                    cat "${OUTPUT_ROOT}/advanced/03_crtsh.txt"
                else
                    warn "No crt.sh output (advanced profile only)"
                fi
                ;;
            s|S) break ;;
            *)  error "Enter 1-6 or s" ;;
        esac

        echo ""
        prompt "Press [ENTER] to inspect another or type 's' to continue:"
        read -r again
        [[ "${again,,}" == "s" ]] && break
    done

    success "Inspection complete"
}

# ─── STEP 7: Open Evidence ────────────────────────────────────────────────────
open_evidence() {
    section "7" "OPEN EVIDENCE"

    echo -e "  ${DIM}Copy raw tool output files to the evidence folder for archiving.${RESET}"
    echo ""

    EVIDENCE_DIR="${OUTPUT_ROOT}/evidence"
    for f in "${OUTPUT_ROOT}/core"/*.txt "${OUTPUT_ROOT}/advanced"/*.txt; do
        [ -f "${f}" ] || continue
        file_has_meaningful_data "${f}" || continue
        cp "${f}" "${EVIDENCE_DIR}/" 2>/dev/null || true
    done

    echo -e "  ${WHITE}Evidence files:${RESET}"
    ls -lh "${EVIDENCE_DIR}/" | awk 'NR > 1 {print "    "$0}'
    echo ""
    success "Evidence archived → ${EVIDENCE_DIR}/"
}

# ─── STEP 8: Generate Report ──────────────────────────────────────────────────
generate_report() {
    section "8" "GENERATE REPORT"

    REPORT_FILE="${OUTPUT_ROOT}/reports/WISPER_REPORT_${SESSION_ID}_${SAFE_NAME}.txt"
    REPORT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
    LLM_ANALYSIS_FILE=""

    echo -e "  ${DIM}Building final report...${RESET}"
    echo ""

    {
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║           WISPER ALPHA — RECONNAISSANCE REPORT                  ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "  Session ID   : ${SESSION_ID}"
        echo "  Target       : ${TARGET_DOMAIN}"
        echo "  Profile      : ${PROFILE}"
        echo "  Scan Start   : ${SESSION_START}"
        echo "  Report Date  : ${REPORT_DATE}"
        echo ""
        echo "──────────────────────────────────────────────────────────────────"
        echo " EXECUTIVE SUMMARY"
        echo "──────────────────────────────────────────────────────────────────"
        echo ""

        # Subdomains
        echo "  [SUBDOMAINS]"
        if file_has_meaningful_data "${OUTPUT_ROOT}/core/01_subfinder.txt"; then
            echo "  Subfinder:"
            sed 's/^/    /' "${OUTPUT_ROOT}/core/01_subfinder.txt"
        fi
        if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/01_amass.txt"; then
            echo "  Amass:"
            sed 's/^/    /' "${OUTPUT_ROOT}/advanced/01_amass.txt" | head -30
        fi

        echo ""
        echo "  [DNS RECORDS]"
        for rec in A MX NS TXT; do
            f="${OUTPUT_ROOT}/core/03_dig_${rec}.txt"
            if file_has_meaningful_data "${f}"; then
                echo "  ${rec}:"
                sed 's/^/    /' "${f}"
            fi
        done

        echo ""
        echo "  [TECHNOLOGY STACK]"
        if file_has_meaningful_data "${OUTPUT_ROOT}/core/07_whatweb.txt"; then
            sed 's/^/    /' "${OUTPUT_ROOT}/core/07_whatweb.txt"
        fi

        echo ""
        echo "  [HISTORICAL URLS — TOP 20]"
        if file_has_meaningful_data "${OUTPUT_ROOT}/core/06_waybackurls.txt"; then
            head -20 "${OUTPUT_ROOT}/core/06_waybackurls.txt" | sed 's/^/    /'
        fi

        echo ""
        echo "  [WHOIS — KEY FIELDS]"
        if file_has_meaningful_data "${OUTPUT_ROOT}/core/02_whois.txt"; then
            grep -E "(Domain|Registrar|Name Server|Creation|Expiry|Email)" \
                "${OUTPUT_ROOT}/core/02_whois.txt" 2>/dev/null | head -15 | sed 's/^/    /'
        fi

        if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/03_crtsh.txt"; then
            echo ""
            echo "  [CERTIFICATE TRANSPARENCY — crt.sh]"
            grep '"name_value"' "${OUTPUT_ROOT}/advanced/03_crtsh.txt" 2>/dev/null | \
                sed 's/.*"name_value": "//;s/".*//' | sort -u | head -20 | sed 's/^/    /' || \
                sed 's/^/    /' "${OUTPUT_ROOT}/advanced/03_crtsh.txt" | head -20
        fi

        if file_has_meaningful_data "${OUTPUT_ROOT}/advanced/02_theharvester.txt"; then
            echo ""
            echo "  [theHarvester — EMAILS & HOSTS]"
            grep -E "(\[.*\]|@)" "${OUTPUT_ROOT}/advanced/02_theharvester.txt" 2>/dev/null | \
                head -20 | sed 's/^/    /' || \
                head -20 "${OUTPUT_ROOT}/advanced/02_theharvester.txt" | sed 's/^/    /'
        fi

        echo ""
        echo "──────────────────────────────────────────────────────────────────"
        echo " OUTPUT FILES"
        echo "──────────────────────────────────────────────────────────────────"
        echo ""
        find "${OUTPUT_ROOT}" -name "*.txt" | sort | while read -r f; do
            file_has_meaningful_data "${f}" || continue
            SIZE=$(wc -l < "${f}")
            printf "  %-60s  %d lines\n" "${f}" "${SIZE}"
        done

        echo ""
        echo "──────────────────────────────────────────────────────────────────"
        echo " END OF REPORT"
        echo " Generated by Wisper Alpha v1.0"
        echo "──────────────────────────────────────────────────────────────────"

    } | tee "${REPORT_FILE}"

    echo ""
    generate_optional_llm_analysis
    if [[ -n "${LLM_ANALYSIS_FILE}" && -f "${LLM_ANALYSIS_FILE}" ]]; then
        {
            echo ""
            echo "──────────────────────────────────────────────────────────────────"
            echo " OPTIONAL AI THREAT ANALYSIS"
            echo "──────────────────────────────────────────────────────────────────"
            echo "  File: ${LLM_ANALYSIS_FILE}"
            echo "  Provider: ${LLM_PROVIDER}"
            echo "  Model: ${LLM_MODEL}"
        } >> "${REPORT_FILE}"
    fi

    echo ""
    success "Report generated → ${REPORT_FILE}"

    echo ""
    echo -e "  ${WHITE}${BOLD}All session data:${RESET}"
    echo ""
    find "${OUTPUT_ROOT}" -name "*.txt" | sort | while read -r f; do
        echo -e "  ${CYAN}→${RESET} ${f}"
    done
    echo ""
}

# ─── Main Flow ────────────────────────────────────────────────────────────────
main() {
    clear
    banner
    bootstrap_tool_paths

    echo -e "  ${DIM}This script follows the Wisper Alpha recon flow:${RESET}"
    echo -e "  ${DIM}Session → Scope → Profile → Run → Dashboard → Inspect → Evidence → Report${RESET}"
    echo ""

    dependency_audit "initial"
    if [[ ${HARD_MISSING_COUNT} -gt 0 ]]; then
        local install_answer=""
        while true; do
            echo -e "  ${CYAN}?${RESET} ${WHITE}Install required dependencies now? [Y/n]${RESET}"
            echo -ne "  ${CYAN}›${RESET} "
            read -r install_answer
            case "${install_answer,,}" in
                ""|y|yes) install_tools; break ;;
                n|no) warn "Session canceled. All tools must be installed before running."; exit 0 ;;
                *) warn "Please enter Y or N." ;;
            esac
        done
        dependency_audit "post-install-gate"
        if [[ ${HARD_MISSING_COUNT} -gt 0 ]]; then
            error "Cannot continue. Install all required tools first, then re-run."
            exit 1
        fi
    else
        echo -e "  ${CYAN}?${RESET} ${WHITE}All dependencies are present. Continue to session setup? [Y/n]${RESET}"
        echo -ne "  ${CYAN}›${RESET} "
        read -r CONTINUE_RUN
        [[ "${CONTINUE_RUN,,}" == "n" ]] && { warn "Session canceled by user."; exit 0; }
    fi

    create_session     # Step 1
    add_scope          # Step 2
    choose_profile     # Step 3

    # Step 4 — run chosen profile
    case "${PROFILE}" in
        "core-passive")          run_core     ;;
        "advanced-deep-passive") run_advanced ;;
    esac

    review_dashboard   # Step 5
    inspect_findings   # Step 6
    open_evidence      # Step 7
    generate_report    # Step 8

    echo ""
    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║              WISPER ALPHA SESSION COMPLETE                   ║${RESET}"
    echo -e "${CYAN}${BOLD}  ║  Session: ${SESSION_ID}                          ║${RESET}"
    echo -e "${CYAN}${BOLD}  ║  Output:  ${OUTPUT_ROOT}${RESET}"
    echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

main "$@"
