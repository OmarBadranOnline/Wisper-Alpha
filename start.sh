#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${REPO_ROOT}/app"
BACKEND_PATH="${APP_DIR}/backend"
FRONTEND_PATH="${APP_DIR}/frontend"
RECON_SCRIPT="${REPO_ROOT}/automation/wisper.sh"
BACKEND_PID=""
FRONTEND_PID=""

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

venv_python_path() {
    if [[ -x ".venv/bin/python" ]]; then
        echo ".venv/bin/python"
    elif ! is_linux && [[ -x ".venv/Scripts/python.exe" ]]; then
        echo ".venv/Scripts/python.exe"
    else
        echo ""
    fi
}

wait_for_url() {
    local url="$1"
    local timeout="${2:-120}"
    local start
    start="$(date +%s)"

    while true; do
        if curl -fsS -o /dev/null --max-time 5 "${url}" 2>/dev/null; then
            return 0
        fi
        if (( "$(date +%s)" - start >= timeout )); then
            return 1
        fi
        sleep 2
    done
}

cleanup() {
    [[ -n "${BACKEND_PID}" ]] && kill "${BACKEND_PID}" >/dev/null 2>&1 || true
    [[ -n "${FRONTEND_PID}" ]] && kill "${FRONTEND_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo ""
echo "Wisper-Alpha Launcher"
echo "1) Recon Terminal Mode"
echo "2) Web Monitor Mode"
echo ""
read -r -p "Select option (1 or 2): " choice

case "${choice}" in
    1)
        [[ -f "${RECON_SCRIPT}" ]] || { echo "Missing script: ${RECON_SCRIPT}" >&2; exit 1; }
        echo "Starting Terminal Mode..."
        bash "${RECON_SCRIPT}"
        ;;
    2)
        PY_CMD="$(choose_python)"
        [[ -n "${PY_CMD}" ]] || { echo "Python is required for Web Monitor Mode." >&2; exit 1; }

        echo "Starting backend on http://localhost:8000 ..."
        (
            cd "${BACKEND_PATH}"
            if is_linux && [[ -d ".venv/Scripts" && ! -x ".venv/bin/python" ]]; then
                rm -rf .venv
            fi
            [[ -n "$(venv_python_path)" ]] || "${PY_CMD}" -m venv .venv
            VENV_PY="$(venv_python_path)"
            [[ -n "${VENV_PY}" ]] || { echo "Backend virtual environment is unavailable." >&2; exit 1; }
            "${VENV_PY}" -m pip install -r requirements.txt >/dev/null
            exec "${VENV_PY}" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
        ) &
        BACKEND_PID="$!"

        echo "Starting frontend on http://localhost:5173 ..."
        (
            cd "${FRONTEND_PATH}"
            npm install >/dev/null
            exec npm run dev -- --host 0.0.0.0 --port 5173
        ) &
        FRONTEND_PID="$!"

        echo "Waiting for backend and GUI to become ready..."
        wait_for_url "http://localhost:8000/api/v1/health" 180 || { echo "Backend did not become ready on http://localhost:8000/api/v1/health" >&2; exit 1; }
        wait_for_url "http://localhost:5173" 180 || { echo "Frontend GUI did not become ready on http://localhost:5173" >&2; exit 1; }

        echo "Web monitor is ready at http://localhost:5173"
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "http://localhost:5173" >/dev/null 2>&1 || true
        fi

        wait "${BACKEND_PID}" "${FRONTEND_PID}"
        ;;
    *)
        echo "Invalid option. Run again and choose 1 or 2." >&2
        exit 1
        ;;
esac
