#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BACKEND="${REPO_ROOT}/app/backend"
APP_FRONTEND="${REPO_ROOT}/app/frontend"
RECON_SCRIPT="${REPO_ROOT}/automation/wisper.sh"
REPORTING_ROOT="${REPO_ROOT}/reporting"
FAILED=0

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

run_step() {
    local name="$1"
    shift
    echo ""
    echo "==> ${name}"
    if "$@"; then
        echo "[PASS] ${name}"
    else
        echo "[FAIL] ${name}"
        FAILED=1
    fi
}

test_backend() {
    local py
    local venv_py
    py="$(choose_python)"
    [[ -n "${py}" ]] || return 1
    cd "${APP_BACKEND}"
    [[ -n "$(venv_python_path)" ]] || "${py}" -m venv .venv
    venv_py="$(venv_python_path)"
    [[ -n "${venv_py}" ]] || return 1
    "${venv_py}" -m pip install -r requirements.txt >/dev/null
    "${venv_py}" -m pytest -q
}

test_frontend() {
    cd "${APP_FRONTEND}"
    npm install --silent
    npm run build --silent
}

test_part2_syntax() {
    bash -n "${RECON_SCRIPT}"
}

test_part3_structure() {
    local required=(
        "01-scope-and-deliverables.md"
        "02-technical-structure.md"
        "03-execution-plan.md"
        "04-data-contract-plan.md"
        "README.md"
        "pentest.zip"
    )
    for item in "${required[@]}"; do
        [[ -e "${REPORTING_ROOT}/${item}" ]] || return 1
    done
}

run_step "Backend unit tests" test_backend
run_step "Frontend build check" test_frontend
run_step "Recon script syntax validation" test_part2_syntax
run_step "Reporting deliverables validation" test_part3_structure

echo ""
if [[ "${FAILED}" -ne 0 ]]; then
    echo "Some checks failed."
    exit 1
fi
echo "All checks passed."
