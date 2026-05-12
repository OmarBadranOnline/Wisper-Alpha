#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECON_SCRIPT="${REPO_ROOT}/automation/wisper.sh"

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

bootstrap_tool_paths

[[ -f "${RECON_SCRIPT}" ]] || { echo "Missing script: ${RECON_SCRIPT}" >&2; exit 1; }
exec bash "${RECON_SCRIPT}" "$@"
