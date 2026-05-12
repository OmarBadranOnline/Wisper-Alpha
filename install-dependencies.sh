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

venv_python_path() {
    if [[ -x ".venv/bin/python" ]]; then
        echo ".venv/bin/python"
    elif [[ -x ".venv/Scripts/python.exe" ]]; then
        echo ".venv/Scripts/python.exe"
    else
        echo ""
    fi
}

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
    [[ -n "$(venv_python_path)" ]] || "${PY_CMD}" -m venv .venv
    VENV_PY="$(venv_python_path)"
    [[ -n "${VENV_PY}" ]] || { warn "Python virtual environment is unavailable."; add_missing "python-venv"; exit 1; }
    "${VENV_PY}" -m pip install --upgrade pip
    "${VENV_PY}" -m pip install -r requirements.txt
    "${VENV_PY}" -m pip install dnsrecon theHarvester spiderfoot
    if ! "${VENV_PY}" -m pip install recon-ng; then
        warn "recon-ng not available from current PyPI index; trying Git source."
        "${VENV_PY}" -m pip install git+https://github.com/lanmaster53/recon-ng.git || warn "Failed to install recon-ng from Git."
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
else
    warn "Go missing; subfinder/amass/waybackurls were not installed."
    add_missing "go"
    add_missing "subfinder"
    add_missing "amass"
    add_missing "waybackurls"
fi

step "Verifying key tools"
for cmd in \
    "python3 --version || python --version" \
    "node --version" \
    "npm --version" \
    "go version" \
    "subfinder -version" \
    "amass -version" \
    "waybackurls --help"; do
    if bash -lc "${cmd}" >/dev/null 2>&1; then
        ok "${cmd}"
    else
        warn "Failed: ${cmd}"
        [[ "${cmd}" == go* ]] && add_missing "go"
        [[ "${cmd}" == subfinder* ]] && add_missing "subfinder"
        [[ "${cmd}" == amass* ]] && add_missing "amass"
        [[ "${cmd}" == waybackurls* ]] && add_missing "waybackurls"
    fi
done

cd "${REPO_ROOT}"
ok "Dependency bootstrap finished"

if ((${#FAILED_REQUIRED[@]} > 0)); then
    MISSING="$(printf '%s\n' "${FAILED_REQUIRED[@]}" | sort -u | paste -sd ', ' -)"
    warn "Required dependencies still missing: ${MISSING}"
    exit 1
fi
