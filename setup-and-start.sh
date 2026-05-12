#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_ROOT}"

echo "Running dependency bootstrap..."
"${REPO_ROOT}/install-dependencies.sh"

echo ""
echo "Starting application launcher..."
"${REPO_ROOT}/start.sh"

