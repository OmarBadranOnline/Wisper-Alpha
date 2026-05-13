#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${REPO_ROOT}/app"
BACKEND_DIR="${APP_DIR}/backend"
FRONTEND_DIR="${APP_DIR}/frontend"
FAILED_REQUIRED=()

step() { printf "\n==> %s\n" "$1"; }
ok() { printf "[OK] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }

add_missing() {
    FAILED_REQUIRED+=("$1")
}

choose_python() {
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    else
        echo ""
    fi
}

is_linux() {
    [[ "$(uname -s 2>/dev/null)" == "Linux" ]]
}

venv_dir() {
    case "$(uname -s 2>/dev/null || echo unknown)" in
        Linux*) echo ".venv-linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo ".venv-win" ;;
        *) echo ".venv" ;;
    esac
}

venv_python_path() {
    local venv
    venv="$(venv_dir)"
    if [[ -x "${venv}/bin/python" ]]; then
        echo "${venv}/bin/python"
    elif ! is_linux && [[ -x "${venv}/Scripts/python.exe" ]]; then
        echo "${venv}/Scripts/python.exe"
    else
        echo ""
    fi
}

run_quick_check() {
    local cmd="$1"
    if command -v timeout >/dev/null 2>&1; then
        timeout 20 bash -lc "${cmd}" >/dev/null 2>&1
    else
        bash -lc "${cmd}" >/dev/null 2>&1
    fi
}

# Prepend GOPATH/bin so Go tools (httpx, dnsx, nuclei, gau) take priority
# over any system package with the same name (e.g. Kali python3-httpx)
_ensure_go_path() {
    local gopath
    gopath="$(go env GOPATH 2>/dev/null || echo "${HOME}/go")"
    case ":${PATH}:" in
        *":${gopath}/bin:"*) ;;
        *) export PATH="${gopath}/bin:${PATH}" ;;
    esac
}
command -v go >/dev/null 2>&1 && _ensure_go_path

ensure_cmd() {
    local name="$1"
    if command -v "${name}" >/dev/null 2>&1; then
        ok "${name} installed"
        return 0
    fi
    warn "${name} not found"
    add_missing "${name}"
    return 1
}

install_with_system_manager() {
    local pkg="$1"
    local prefix=()
    command -v sudo >/dev/null 2>&1 && prefix=(sudo)

    if command -v apt-get >/dev/null 2>&1; then
        "${prefix[@]}" apt-get install -y -qq "${pkg}" >/dev/null 2>&1 && return 0
    elif command -v dnf >/dev/null 2>&1; then
        "${prefix[@]}" dnf install -y "${pkg}" >/dev/null 2>&1 && return 0
    elif command -v yum >/dev/null 2>&1; then
        "${prefix[@]}" yum install -y "${pkg}" >/dev/null 2>&1 && return 0
    elif command -v pacman >/dev/null 2>&1; then
        "${prefix[@]}" pacman -S --noconfirm "${pkg}" >/dev/null 2>&1 && return 0
    elif command -v zypper >/dev/null 2>&1; then
        "${prefix[@]}" zypper --non-interactive install "${pkg}" >/dev/null 2>&1 && return 0
    fi
    return 1
}

try_install_base_runtimes() {
    step "Checking base runtimes"

    ensure_cmd python3 || true
    ensure_cmd node || true
    ensure_cmd npm || true
    ensure_cmd go || true

    if ((${#FAILED_REQUIRED[@]} > 0)); then
        step "Attempting package-manager install for missing runtimes"
        install_with_system_manager python3 || true
        install_with_system_manager nodejs || true
        install_with_system_manager npm || true
        install_with_system_manager golang-go || install_with_system_manager go || true
        FAILED_REQUIRED=()
        ensure_cmd python3 || true
        ensure_cmd node || true
        ensure_cmd npm || true
        ensure_cmd go || true
    fi
}

try_install_base_runtimes

PY_CMD="$(choose_python)"
if [[ -z "${PY_CMD}" ]]; then
    warn "No Python runtime available"
    add_missing "python3"
else
    step "Installing backend dependencies"
    cd "${BACKEND_DIR}"
    if is_linux && [[ -d ".venv/Scripts" ]]; then
        warn "Detected legacy Windows .venv. Using isolated Linux env at .venv-linux."
    fi
    [[ -n "$(venv_python_path)" ]] || "${PY_CMD}" -m venv "$(venv_dir)"
    VENV_PY="$(venv_python_path)"
    [[ -n "${VENV_PY}" ]] || { warn "Python virtual environment is unavailable."; add_missing "python-venv"; exit 1; }
    "${VENV_PY}" -m pip install --upgrade pip
    "${VENV_PY}" -m pip install -r requirements.txt
    "${VENV_PY}" -m pip install dnsrecon theHarvester
    if command -v spiderfoot >/dev/null 2>&1 || "${VENV_PY}" -m spiderfoot --help >/dev/null 2>&1; then
        ok "spiderfoot available"
    else
        step "Installing SpiderFoot (optional advanced tool)"
        install_with_system_manager "spiderfoot" || true
        if ! command -v spiderfoot >/dev/null 2>&1 && ! "${VENV_PY}" -m spiderfoot --help >/dev/null 2>&1; then
            warn "SpiderFoot is not available via direct pip install in many environments."
            warn "Install SpiderFoot via distro package, Docker, or source if you need advanced aggregation."
        fi
    fi
    if ! command -v recon-ng >/dev/null 2>&1; then
        install_with_system_manager "recon-ng" || true
    fi
    if ! command -v recon-ng >/dev/null 2>&1; then
        warn "recon-ng is not available from standard pip for this setup."
        warn "Install recon-ng from your distro package manager or official source if needed."
    fi
fi

step "Installing frontend dependencies"
cd "${FRONTEND_DIR}"
npm install

if command -v go >/dev/null 2>&1; then
    step "Installing Go-based recon tools"
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="${PATH}:${GOPATH}/bin"
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/owasp-amass/amass/v4/...@master
    go install github.com/tomnomnom/waybackurls@latest
    go install github.com/lc/gau/v2/cmd/gau@latest
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
else
    warn "Go missing; subfinder/amass/waybackurls/gau/httpx/dnsx/nuclei were not installed."
    add_missing "go"
    add_missing "subfinder"
    add_missing "amass"
    add_missing "waybackurls"
    add_missing "gau"
    add_missing "httpx"
    add_missing "dnsx"
    add_missing "nuclei"
fi

step "Verifying key tools"
GOBIN="$(go env GOPATH 2>/dev/null || echo "${HOME}/go")/bin"
for cmd in \
    "python3 --version || python --version" \
    "node --version" \
    "npm --version" \
    "go version" \
    "subfinder -version" \
    "amass -version" \
    "waybackurls --help" \
    "gau --version" \
    "dnsx -version" \
    "nuclei -version"; do
    if run_quick_check "${cmd}"; then
        ok "${cmd}"
    else
        warn "Failed: ${cmd}"
        [[ "${cmd}" == go* ]]          && add_missing "go"
        [[ "${cmd}" == subfinder* ]]   && add_missing "subfinder"
        [[ "${cmd}" == amass* ]]       && add_missing "amass"
        [[ "${cmd}" == waybackurls* ]] && add_missing "waybackurls"
        [[ "${cmd}" == gau* ]]         && add_missing "gau"
        [[ "${cmd}" == dnsx* ]]        && add_missing "dnsx"
        [[ "${cmd}" == nuclei* ]]      && add_missing "nuclei"
    fi
done

# httpx: verify via full GOPATH path to avoid conflict with Kali python3-httpx
if [[ -x "${GOBIN}/httpx" ]]; then
    ok "httpx (projectdiscovery) installed at ${GOBIN}/httpx"
else
    warn "httpx (projectdiscovery) not found at ${GOBIN}/httpx"
    warn "Install manually: go install github.com/projectdiscovery/httpx/cmd/httpx@latest"
    warn "Note: apt 'httpx' is a Python tool, not the ProjectDiscovery scanner."
fi

cd "${REPO_ROOT}"
ok "Dependency bootstrap finished"

if ((${#FAILED_REQUIRED[@]} > 0)); then
    MISSING="$(printf '%s\n' "${FAILED_REQUIRED[@]}" | sort -u | paste -sd ', ' -)"
    warn "Required dependencies still missing: ${MISSING}"
    exit 1
fi
