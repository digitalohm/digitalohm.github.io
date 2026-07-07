#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/github-auth.sh
  scripts/github-auth.sh --status
  scripts/github-auth.sh --help

Behavior:
  - Reuses an existing GitHub CLI login when available.
  - Otherwise logs in with GH_TOKEN or GITHUB_TOKEN if one is set.
  - Otherwise starts the standard GitHub CLI browser login flow.
  - Configures git to use GitHub CLI credentials for HTTPS operations.

Notes:
  - This may update git credential settings outside this repository.
  - The browser/device login step still requires user interaction.
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

print_status() {
  gh auth status -h github.com
}

ensure_login() {
  if gh auth status -h github.com >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
    return 0
  fi

  local token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -n "$token" ]]; then
    echo "Logging into GitHub CLI with token from environment."
    printf '%s' "$token" | gh auth login --hostname github.com --git-protocol https --with-token
    return 0
  fi

  echo "Starting GitHub browser login flow."
  gh auth login --hostname github.com --git-protocol https --web
}

setup_git_credentials() {
  echo "Configuring git to use GitHub CLI credentials for HTTPS."
  gh auth setup-git
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      exit 0
      ;;
    --status)
      require_cmd gh
      print_status
      exit 0
      ;;
    "")
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac

  require_cmd gh
  require_cmd git

  ensure_login
  setup_git_credentials

  echo
  echo "GitHub authentication is ready for git HTTPS operations."
  print_status
}

main "$@"
