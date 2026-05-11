#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║              WISPER ALPHA — Automated Recon Orchestrator                ║
# ║              Flow: Session → Scope → Profile → Run → Report             ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Usage: bash wisper.sh

set -euo pipefail

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
        record_hard_missing_tool "whois"
    else
        print_dep_status "whois" "missing" "needs whois or curl"
        record_hard_missing_tool "whois"
    fi

    if has_cmd dig; then
        print_dep_status "dig" "ok" ""
    elif has_cmd nslookup; then
        print_dep_status "dig" "fallback" "using nslookup for DNS records"
        record_hard_missing_tool "dig"
    else
        print_dep_status "dig" "missing" "needs dig or nslookup"
        record_hard_missing_tool "dig"
    fi

    if has_cmd nslookup; then print_dep_status "nslookup" "ok" ""; else print_dep_status "nslookup" "missing" "DNS resolution fallback"; record_hard_missing_tool "nslookup"; fi
    if has_cmd dnsrecon; then
        print_dep_status "dnsrecon" "ok" ""
    elif python_module_entry_works "dnsrecon"; then
        print_dep_status "dnsrecon" "fallback" "python -m dnsrecon"
        record_hard_missing_tool "dnsrecon"
    else
        print_dep_status "dnsrecon" "missing" "passive DNS enrichment"
        record_hard_missing_tool "dnsrecon"
    fi
    if has_cmd waybackurls; then print_dep_status "waybackurls" "ok" ""; else print_dep_status "waybackurls" "missing" "historical URL collection"; record_hard_missing_tool "waybackurls"; fi
    if has_cmd whatweb; then
        print_dep_status "whatweb" "ok" ""
    elif has_cmd curl; then
        print_dep_status "whatweb" "fallback" "HTTP header/title fingerprint fallback"
        record_hard_missing_tool "whatweb"
    else
        print_dep_status "whatweb" "missing" "technology fingerprinting"
        record_hard_missing_tool "whatweb"
    fi
    if has_cmd amass; then print_dep_status "amass" "ok" ""; else print_dep_status "amass" "missing" "advanced profile"; record_hard_missing_tool "amass"; fi
    if has_cmd theHarvester; then
        print_dep_status "theHarvester" "ok" ""
    elif python_module_entry_works "theHarvester"; then
        print_dep_status "theHarvester" "fallback" "python -m theHarvester"
        record_hard_missing_tool "theHarvester"
    else
        print_dep_status "theHarvester" "missing" "advanced profile"
        record_hard_missing_tool "theHarvester"
    fi
    if has_cmd spiderfoot; then
        print_dep_status "spiderfoot" "ok" ""
    elif python_module_entry_works "spiderfoot"; then
        print_dep_status "spiderfoot" "fallback" "python -m spiderfoot"
        record_hard_missing_tool "spiderfoot"
    else
        print_dep_status "spiderfoot" "missing" "advanced profile optional"
        record_hard_missing_tool "spiderfoot"
    fi
    if has_cmd recon-ng; then
        print_dep_status "recon-ng" "ok" ""
    elif python_module_entry_works "reconng"; then
        print_dep_status "recon-ng" "fallback" "python -m reconng"
        record_hard_missing_tool "recon-ng"
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
    local platform
    platform="$(detect_platform)"
    step "Go not found. Checking installation options..."
    if [[ "${platform}" == "windows" ]]; then
        warn "Skipping automatic Go install on Windows to avoid interactive package-manager hangs."
        log "Install Go manually, then re-run:"
        log "  winget install --id GoLang.Go -e"
        log "  or choco install golang -y"
        log "  or scoop install go"
        local go_win="/c/Program Files/Go/bin"
        [[ -d "${go_win}" ]] && export PATH="${PATH}:${go_win}"
    else
        install_with_system_manager "golang-go" || install_with_system_manager "go" || true
    fi
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
    local cmd=("$@")

    echo ""
    echo -e "  ${MAGENTA}⌖ Running:${RESET} ${DIM}${cmd[*]}${RESET}"
    echo -e "  ${DIM}  Output  → ${out_file}${RESET}"
    divider

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
    if "${cmd[@]}" 2>&1 | tee -a "${out_file}"; then
        echo "" >> "${out_file}"
        echo "[ FINISHED: $(date '+%Y-%m-%d %H:%M:%S') ]" >> "${out_file}"
        success "${tool_name} complete → ${out_file}"
    else
        warn "${tool_name} returned non-zero (may be normal for some tools)"
    fi
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
        log "If you are on Windows, run this script from WSL/Ubuntu for full automatic setup."
    fi
    if [[ -z "${pip_cmd}" ]]; then
        warn "Python pip was not found. Python tool installs will be skipped."
    elif [[ -n "${py_cmd}" ]]; then
        USER_BASE="$(${py_cmd} -m site --user-base 2>/dev/null || true)"
        if [[ -n "${USER_BASE}" ]]; then
            if has_cmd cygpath; then
                USER_BASE="$(cygpath -u "${USER_BASE}" 2>/dev/null || echo "${USER_BASE}")"
            fi
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
        [[ -n "${pip_cmd}" ]] && ${pip_cmd} install --break-system-packages spiderfoot 2>/dev/null || \
        warn "SpiderFoot install failed — try: pip3 install spiderfoot"
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
            "${OUT}/01_subfinder.txt" \
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
            "${OUT}/05_dnsrecon.txt" \
            dnsrecon -d "${TARGET_DOMAIN}" -t std
    elif python_module_entry_works "dnsrecon"; then
        run_tool "DNSRecon (python module fallback)" \
            "${OUT}/05_dnsrecon.txt" \
            bash -c "$(detect_python) -m dnsrecon -d '${TARGET_DOMAIN}' -t std"
    else
        warn "DNSRecon not found — skipping"
    fi

    # ── 6. waybackurls ──
    if command -v waybackurls &>/dev/null; then
        run_tool "waybackurls" \
            "${OUT}/06_waybackurls.txt" \
            bash -c "echo '${TARGET_DOMAIN}' | waybackurls"
    else
        warn "waybackurls not found — skipping"
    fi

    # ── 7. WhatWeb ──
    if command -v whatweb &>/dev/null; then
        run_tool "WhatWeb" \
            "${OUT}/07_whatweb.txt" \
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
        run_tool "Subfinder" "${CORE_OUT}/01_subfinder.txt" \
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
        run_tool "DNSRecon" "${CORE_OUT}/05_dnsrecon.txt" dnsrecon -d "${TARGET_DOMAIN}" -t std
    elif python_module_entry_works "dnsrecon"; then
        run_tool "DNSRecon (python module fallback)" "${CORE_OUT}/05_dnsrecon.txt" bash -c "$(detect_python) -m dnsrecon -d '${TARGET_DOMAIN}' -t std"
    fi

    if command -v waybackurls &>/dev/null; then
        run_tool "waybackurls" "${CORE_OUT}/06_waybackurls.txt" \
            bash -c "echo '${TARGET_DOMAIN}' | waybackurls"
    fi

    if command -v whatweb &>/dev/null; then
        run_tool "WhatWeb" "${CORE_OUT}/07_whatweb.txt" \
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
            "${OUT}/01_amass.txt" \
            amass enum -passive -d "${TARGET_DOMAIN}"
    else
        warn "Amass not found — skipping (install: go install github.com/owasp-amass/amass/v4/...@master)"
    fi

    # theHarvester
    if command -v theHarvester &>/dev/null; then
        run_tool "theHarvester (all sources)" \
            "${OUT}/02_theharvester.txt" \
            theHarvester -d "${TARGET_DOMAIN}" -b bing,google,yahoo,duckduckgo,crtsh
    elif python_module_entry_works "theHarvester"; then
        run_tool "theHarvester (python module fallback)" \
            "${OUT}/02_theharvester.txt" \
            bash -c "$(detect_python) -m theHarvester -d '${TARGET_DOMAIN}' -b bing,google,yahoo,duckduckgo,crtsh"
    else
        warn "theHarvester not found — skipping"
    fi

    # crt.sh certificate transparency (passive, no tool needed — curl)
    run_tool "crt.sh (certificate transparency)" \
        "${OUT}/03_crtsh.txt" \
        bash -c "curl -s 'https://crt.sh/?q=%25.${TARGET_DOMAIN}&output=json' | python3 -m json.tool 2>/dev/null | grep '\"name_value\"' | sort -u | head -50 || echo 'crt.sh query returned no results'"

    # Shodan CLI hint (passive)
    if command -v shodan &>/dev/null; then
        TARGET_IP="$(resolve_ip_for_target)"
        if [[ -z "${TARGET_IP}" ]]; then
            TARGET_IP="${TARGET_DOMAIN}"
        fi
        run_tool "Shodan (host info)" \
            "${OUT}/04_shodan.txt" \
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
            echo ""
            echo "  FILE: $(basename "${f}")"
            echo "  ──────────────────────────────────────────────────────────"
            cat "${f}"
        done
        echo ""
        echo "─── ADVANCED PHASE ─────────────────────────────────────────────"
        for f in "${OUT}"/0*.txt; do
            [ -f "${f}" ] || continue
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

    if [ -f "${OUTPUT_ROOT}/core/01_subfinder.txt" ]; then
        SUBDOMAIN_COUNT=$(grep -c '.' "${OUTPUT_ROOT}/core/01_subfinder.txt" 2>/dev/null || echo 0)
    fi
    if [ -f "${OUTPUT_ROOT}/advanced/01_amass.txt" ]; then
        AMASS_COUNT=$(grep -c '.' "${OUTPUT_ROOT}/advanced/01_amass.txt" 2>/dev/null || echo 0)
        SUBDOMAIN_COUNT=$((SUBDOMAIN_COUNT + AMASS_COUNT))
    fi
    if [ -f "${OUTPUT_ROOT}/core/06_waybackurls.txt" ]; then
        URL_COUNT=$(grep -c 'http' "${OUTPUT_ROOT}/core/06_waybackurls.txt" 2>/dev/null || echo 0)
    fi
    if [ -f "${OUTPUT_ROOT}/core/07_whatweb.txt" ]; then
        TECH_COUNT=$(grep -c '\[' "${OUTPUT_ROOT}/core/07_whatweb.txt" 2>/dev/null || echo 0)
    fi
    if [ -f "${OUTPUT_ROOT}/core/03_dig_A.txt" ]; then
        DNS_COUNT=$(grep -c '.' "${OUTPUT_ROOT}/core/03_dig_A.txt" 2>/dev/null || echo 0)
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
                [ -f "${OUTPUT_ROOT}/core/01_subfinder.txt" ] && cat "${OUTPUT_ROOT}/core/01_subfinder.txt" || warn "No subfinder output"
                [ -f "${OUTPUT_ROOT}/advanced/01_amass.txt" ] && cat "${OUTPUT_ROOT}/advanced/01_amass.txt" || true
                ;;
            2)
                echo ""
                echo -e "  ${CYAN}${BOLD}── DNS Records ─────────────────────────────────────────────${RESET}"
                for rec in A MX NS TXT; do
                    f="${OUTPUT_ROOT}/core/03_dig_${rec}.txt"
                    if [ -f "${f}" ]; then
                        echo -e "  ${YELLOW}${rec}:${RESET}"
                        cat "${f}"
                    fi
                done
                ;;
            3)
                echo ""
                echo -e "  ${CYAN}${BOLD}── WHOIS ───────────────────────────────────────────────────${RESET}"
                if [ -f "${OUTPUT_ROOT}/core/02_whois.txt" ]; then
                    grep -E "(Domain|Registrar|Name Server|Creation|Expiry|Email|handle|ldhName|status)" "${OUTPUT_ROOT}/core/02_whois.txt" | head -30 || head -30 "${OUTPUT_ROOT}/core/02_whois.txt"
                else
                    warn "No WHOIS output"
                fi
                ;;
            4)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Historical URLs (top 30) ────────────────────────────────${RESET}"
                [ -f "${OUTPUT_ROOT}/core/06_waybackurls.txt" ] && head -30 "${OUTPUT_ROOT}/core/06_waybackurls.txt" || warn "No waybackurls output"
                ;;
            5)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Technology Fingerprints ─────────────────────────────────${RESET}"
                [ -f "${OUTPUT_ROOT}/core/07_whatweb.txt" ] && cat "${OUTPUT_ROOT}/core/07_whatweb.txt" || warn "No WhatWeb output"
                ;;
            6)
                echo ""
                echo -e "  ${CYAN}${BOLD}── Certificate Transparency ────────────────────────────────${RESET}"
                [ -f "${OUTPUT_ROOT}/advanced/03_crtsh.txt" ] && cat "${OUTPUT_ROOT}/advanced/03_crtsh.txt" || warn "No crt.sh output (advanced profile only)"
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
    cp "${OUTPUT_ROOT}/core/"*.txt     "${EVIDENCE_DIR}/" 2>/dev/null || true
    cp "${OUTPUT_ROOT}/advanced/"*.txt "${EVIDENCE_DIR}/" 2>/dev/null || true

    echo -e "  ${WHITE}Evidence files:${RESET}"
    ls -lh "${EVIDENCE_DIR}/" | awk '{print "    "$0}'
    echo ""
    success "Evidence archived → ${EVIDENCE_DIR}/"
}

# ─── STEP 8: Generate Report ──────────────────────────────────────────────────
generate_report() {
    section "8" "GENERATE REPORT"

    REPORT_FILE="${OUTPUT_ROOT}/reports/WISPER_REPORT_${SESSION_ID}_${SAFE_NAME}.txt"
    REPORT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

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
        if [ -f "${OUTPUT_ROOT}/core/01_subfinder.txt" ]; then
            echo "  Subfinder:"
            sed 's/^/    /' "${OUTPUT_ROOT}/core/01_subfinder.txt"
        fi
        if [ -f "${OUTPUT_ROOT}/advanced/01_amass.txt" ]; then
            echo "  Amass:"
            sed 's/^/    /' "${OUTPUT_ROOT}/advanced/01_amass.txt" | head -30
        fi

        echo ""
        echo "  [DNS RECORDS]"
        for rec in A MX NS TXT; do
            f="${OUTPUT_ROOT}/core/03_dig_${rec}.txt"
            if [ -f "${f}" ] && [ -s "${f}" ]; then
                echo "  ${rec}:"
                sed 's/^/    /' "${f}"
            fi
        done

        echo ""
        echo "  [TECHNOLOGY STACK]"
        if [ -f "${OUTPUT_ROOT}/core/07_whatweb.txt" ]; then
            sed 's/^/    /' "${OUTPUT_ROOT}/core/07_whatweb.txt"
        fi

        echo ""
        echo "  [HISTORICAL URLS — TOP 20]"
        if [ -f "${OUTPUT_ROOT}/core/06_waybackurls.txt" ]; then
            head -20 "${OUTPUT_ROOT}/core/06_waybackurls.txt" | sed 's/^/    /'
        fi

        echo ""
        echo "  [WHOIS — KEY FIELDS]"
        if [ -f "${OUTPUT_ROOT}/core/02_whois.txt" ]; then
            grep -E "(Domain|Registrar|Name Server|Creation|Expiry|Email)" \
                "${OUTPUT_ROOT}/core/02_whois.txt" 2>/dev/null | head -15 | sed 's/^/    /'
        fi

        if [ -f "${OUTPUT_ROOT}/advanced/03_crtsh.txt" ]; then
            echo ""
            echo "  [CERTIFICATE TRANSPARENCY — crt.sh]"
            grep '"name_value"' "${OUTPUT_ROOT}/advanced/03_crtsh.txt" 2>/dev/null | \
                sed 's/.*"name_value": "//;s/".*//' | sort -u | head -20 | sed 's/^/    /' || \
                sed 's/^/    /' "${OUTPUT_ROOT}/advanced/03_crtsh.txt" | head -20
        fi

        if [ -f "${OUTPUT_ROOT}/advanced/02_theharvester.txt" ]; then
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
