#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║              WISPER ALPHA — Launcher                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECON_SCRIPT="${REPO_ROOT}/automation/wisper.sh"
WEB_APP="${REPO_ROOT}/app/web/app.py"
VENV_DIR="${REPO_ROOT}/app/web/.venv"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'; RESET='\033[0m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; DIM='\033[2m'; WHITE='\033[1;37m'

# ── Helpers ───────────────────────────────────────────────────────────────────
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

detect_python() {
    if command -v python3 &>/dev/null; then echo "python3"
    elif command -v python &>/dev/null; then echo "python"
    else echo ""
    fi
}

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║       ██╗    ██╗██╗███████╗██████╗ ███████╗██████╗           ║"
    echo "  ║       ██║    ██║██║██╔════╝██╔══██╗██╔════╝██╔══██╗          ║"
    echo "  ║       ██║ █╗ ██║██║███████╗██████╔╝█████╗  ██████╔╝          ║"
    echo "  ║       ██║███╗██║██║╚════██║██╔═══╝ ██╔══╝  ██╔══██╗          ║"
    echo "  ║       ╚███╔███╔╝██║███████║██║     ███████╗██║  ██║          ║"
    echo "  ║        ╚══╝╚══╝ ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝          ║"
    echo "  ║                   A L P H A  v1.0                            ║"
    echo "  ║           Automated Web Attack Surface Mapper                ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

launch_web_gui() {
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ Starting Wisper Web GUI${RESET}"
    echo ""

    # Resolve Python
    local py
    py="$(detect_python)"
    if [[ -z "${py}" ]]; then
        echo -e "  ${YELLOW}✗ Python not found. Please install Python 3.8+.${RESET}"
        exit 1
    fi

    # Prefer venv Python if present
    if [[ -f "${VENV_DIR}/bin/python" ]]; then
        py="${VENV_DIR}/bin/python"
    elif [[ -f "${VENV_DIR}/Scripts/python.exe" ]]; then
        py="${VENV_DIR}/Scripts/python.exe"
    fi

    # Check Flask is available
    if ! "${py}" -c "import flask" &>/dev/null; then
        echo -e "  ${YELLOW}⚠ Flask not found — installing requirements...${RESET}"
        local req="${REPO_ROOT}/wisper-v2/requirements.txt"
        if [[ -f "${req}" ]]; then
            "${py}" -m pip install -q -r "${req}"
        else
            "${py}" -m pip install -q flask
        fi
    fi

    # Sanity check
    [[ -f "${WEB_APP}" ]] || {
        echo -e "  ${YELLOW}✗ Web app not found: ${WEB_APP}${RESET}" >&2
        exit 1
    }

    echo -e "  ${DIM}App  : ${WEB_APP}${RESET}"
    echo -e "  ${DIM}Python: ${py}${RESET}"
    echo ""
    echo -e "  ${GREEN}✓ Dashboard will be available at → ${WHITE}http://localhost:5000${RESET}"
    echo -e "  ${DIM}(Press Ctrl+C to stop)${RESET}"
    echo ""
    # Run python in the background and wait so we can trap Ctrl+C
    "${py}" "${WEB_APP}" &
    APP_PID=$!
    
    cleanup() {
        echo -e "\n  ${YELLOW}Stopping Wisper and freeing port...${RESET}"
        kill "${APP_PID}" 2>/dev/null || true
        
        # Kill any lingering bash scans and python instances
        if command -v pkill &>/dev/null; then
            pkill -f "app.py" || true
            pkill -f "automation/wisper.sh" || true
        fi
        
        # Forcefully free port 5000 using lsof/fuser on Linux/Mac, or taskkill on Windows
        if command -v fuser &>/dev/null; then
            fuser -k 5000/tcp 2>/dev/null || true
        elif command -v lsof &>/dev/null; then
            lsof -ti:5000 | xargs kill -9 2>/dev/null || true
        elif command -v netstat &>/dev/null; then
            # Windows native fallback if running in Git Bash
            cmd.exe /c "FOR /F \"tokens=5\" %a IN ('netstat -aon ^| find \":5000\" ^| find \"LISTENING\"') DO taskkill /f /pid %a" 2>/dev/null || true
        fi
        exit 0
    }
    
    trap cleanup SIGINT SIGTERM EXIT
    wait "${APP_PID}"
}

launch_cli() {
    [[ -f "${RECON_SCRIPT}" ]] || {
        echo "Missing script: ${RECON_SCRIPT}" >&2
        exit 1
    }
    exec bash "${RECON_SCRIPT}" "$@"
}

# ── Main ──────────────────────────────────────────────────────────────────────
bootstrap_tool_paths

# If arguments were passed, forward directly to CLI (non-interactive use)
if [[ $# -gt 0 ]]; then
    launch_cli "$@"
fi

banner

echo -e "  ${WHITE}How would you like to run Wisper?${RESET}"
echo ""
echo -e "  ${CYAN}[1]${RESET}  ${WHITE}Web GUI${RESET}  ${DIM}— Browser dashboard at http://localhost:5000${RESET}"
echo -e "  ${CYAN}[2]${RESET}  ${WHITE}CLI Wizard${RESET}  ${DIM}— Interactive terminal recon orchestrator${RESET}"
echo ""
printf "  %b›%b " "${CYAN}" "${RESET}"
read -r choice

case "${choice}" in
    1) launch_web_gui ;;
    2) launch_cli ;;
    *) echo -e "\n  ${YELLOW}Invalid choice — defaulting to CLI.${RESET}\n"
       launch_cli ;;
esac
