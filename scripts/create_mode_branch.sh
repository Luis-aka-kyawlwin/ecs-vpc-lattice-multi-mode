#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <mode-a-http|mode-b-https|mode-c-tls>"
  exit 1
fi

MODE="$1"
BRANCH="feat/${MODE}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Current directory is not a git repository. Initialize git or run inside your repo first."
  exit 1
fi

git checkout main
git pull --ff-only
git checkout -b "${BRANCH}"

echo "Created and switched to ${BRANCH}"
