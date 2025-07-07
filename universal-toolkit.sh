#!/usr/bin/env bash
# universal-toolkit.sh — drop-in project reconnaissance script
# Dispatches to commands in scripts/cmd/*.sh
# -----------------------------------------------------------------------------
set -euo pipefail

# --- Configuration and Environment -------------------------------------------

# Security validations for environment variables
PROJECT_ROOT_OVERRIDE="${PROJECT_ROOT:-}"
if [[ -n "$PROJECT_ROOT_OVERRIDE" ]]; then
  # Security: Validate PROJECT_ROOT to prevent directory traversal
  if [[ "$PROJECT_ROOT_OVERRIDE" =~ \.\./|^/ ]]; then
    echo "❌ Security: PROJECT_ROOT cannot contain '..' or start with '/'" >&2
    echo "❌ Rejecting potentially malicious path: $PROJECT_ROOT_OVERRIDE" >&2
    exit 1
  fi
  # Additional check: ensure it's within current directory tree
  if [[ ! "$PROJECT_ROOT_OVERRIDE" =~ ^\.?$ ]] && [[ ! "$PROJECT_ROOT_OVERRIDE" =~ ^\./ ]]; then
    echo "❌ Security: PROJECT_ROOT must be current directory (.) or subdirectory (./path)" >&2
    echo "❌ Rejecting path: $PROJECT_ROOT_OVERRIDE" >&2
    exit 1
  fi
fi

# Security: Validate JSON_OUTPUT to prevent injection
if [[ -n "${JSON_OUTPUT:-}" ]] && [[ "$JSON_OUTPUT" != "true" ]] && [[ "$JSON_OUTPUT" != "false" ]]; then
  echo "❌ Security: JSON_OUTPUT must be 'true' or 'false'" >&2
  echo "❌ Rejecting potentially malicious value: $JSON_OUTPUT" >&2
  exit 1
fi

export PROJECT_ROOT="${PROJECT_ROOT:-.}"

# --- Library Sourcing --------------------------------------------------------

# Source shared libraries relative to this script's location
# shellcheck source=./scripts/lib/colors.sh
source "$(dirname "$0")/scripts/lib/colors.sh"
# shellcheck source=./scripts/lib/log.sh
source "$(dirname "$0")/scripts/lib/log.sh"
# shellcheck source=./scripts/lib/util.sh
source "$(dirname "$0")/scripts/lib/util.sh"

# --- Argument Parsing and Dispatch -------------------------------------------

show_help() {
  log_header "Universal Toolkit"
  log_info "Usage: $(basename "$0") <command> [options]"
  log_info ""
  log_info "Available commands:"
  for cmd_script in scripts/cmd/*.sh; do
    cmd_name=$(basename "$cmd_script" .sh)
    printf "  %-20s %s
" "$cmd_name" "$(grep -m 1 '^# scripts/cmd/' "$cmd_script" | sed 's/^# scripts.cmd....//')"
  done
  log_info ""
  log_info "Global options:"
  log_info "  -j, --json    Output in JSON format"
  log_info "  -h, --help    Show this help message"
}

# Handle global options and command
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  show_help
  exit 0
fi

if [[ "${1:-}" == "--version" || "${1:-}" == "version" ]]; then
  echo "snapctx-sh 0.2.0"
  exit 0
fi

COMMAND="${1:-cheatsheet}"
shift || true # Shift even if no arguments

JSON_OUTPUT="false"
# Filter arguments and check for --json
filtered_args=()
for arg in "$@"; do
  if [[ "$arg" == "-j" || "$arg" == "--json" ]]; then
    JSON_OUTPUT="true"
  else
    filtered_args+=("$arg")
  fi
done
export JSON_OUTPUT

# Use filtered arguments instead of original $@
if [[ ${#filtered_args[@]} -gt 0 ]]; then
  set -- "${filtered_args[@]}"
else
  set --
fi

CMD_SCRIPT="scripts/cmd/${COMMAND}.sh"

if [[ ! -f "$CMD_SCRIPT" ]]; then
  log_error "Unknown command: $COMMAND"
  show_help
  exit 1
fi

# --- Command Execution -------------------------------------------------------

# Pass all remaining arguments to the command script
# The command script will handle its own options
# shellcheck source=/dev/null
source "$CMD_SCRIPT" "$@"