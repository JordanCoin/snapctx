#!/usr/bin/env bash
# scripts/cmd/analyze.sh - Project structure analysis
set -euo pipefail

# Source shared libraries relative to this script's location
# shellcheck source=../lib/colors.sh
source "$(dirname "$0")/../lib/colors.sh"
# shellcheck source=../lib/json.sh
source "$(dirname "$0")/../lib/json.sh"
# shellcheck source=../lib/log.sh
source "$(dirname "$0")/../lib/log.sh"
# shellcheck source=../lib/util.sh
source "$(dirname "$0")/../lib/util.sh"
# shellcheck source=../lib/config.sh
source "$(dirname "$0")/../lib/config.sh"

# Default depth
DEPTH=2

# Command-specific argument parsing
while getopts ":d:h" opt; do
  case $opt in
    d)
      DEPTH="$OPTARG"
      ;;
    h)
      log_info "Usage: $(basename "$0") [-d <depth>] [-h]"
      log_info "  -d, --depth N  Tree depth (default: 2)"
      log_info "  -h, --help     Show this help message"
      exit 0
      ;;
    \?)
      log_error "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      log_error "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Access PROJECT_ROOT and JSON_OUTPUT from environment (set by dispatcher)
PROJECT_ROOT="${PROJECT_ROOT:-.}" # Fallback if not set

# Calculate files for adaptive depth
local files=$( (cd "$PROJECT_ROOT" && rg --files) | wc -l || echo 0)
if [[ $files -gt 400 ]]; then
  DEPTH=2
fi

if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
  # JSON output logic
  local tree_output=""
  if command_exists tree; then
    tree_output=$(tree -L "$DEPTH" -I ".git" --noreport --dirsfirst -J "$PROJECT_ROOT" || true)
  elif command_exists eza; then
    tree_output=$(eza -T "$PROJECT_ROOT" --level "$DEPTH" --no-quotes --no-permissions --no-user --no-time --no-filesize -J || true)
  else
    tree_output=$(find "$PROJECT_ROOT" -maxdepth "$DEPTH" -print | jq -R -s 'split("\n") | .[1:]' || true)
  fi
  echo "$tree_output" | jq '.' # Pretty print final JSON
else
  # Human-readable output logic
  log_header "PROJECT STRUCTURE ANALYSIS (depth $DEPTH)"
  log_info "📁 Analyzing directory: $PROJECT_ROOT"
  if command_exists tree; then
    tree -L "$DEPTH" -C -I ".git" "$PROJECT_ROOT"
  elif command_exists eza; then
    eza -T "$PROJECT_ROOT" --level "$DEPTH"
  else
    find "$PROJECT_ROOT" -maxdepth "$DEPTH" -print
  fi
fi
