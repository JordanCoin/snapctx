#!/usr/bin/env bash
# scripts/cmd/cross-platform.sh - Naive version drift scan
set -euo pipefail

# Source shared libraries using robust BASH_SOURCE path
# shellcheck source=../lib/colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/colors.sh"
# shellcheck source=../lib/json.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/json.sh"
# shellcheck source=../lib/log.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
# shellcheck source=../lib/util.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/util.sh"
# shellcheck source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Command-specific argument parsing
while getopts ":h" opt; do
  case $opt in
    h)
      log_info "Usage: $(basename "$0") [-h]"
      log_info "  -h, --help    Show this help message"
      exit 0
      ;;
    \?)
      log_error "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

PROJECT_ROOT="${PROJECT_ROOT:-.}"

if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
  SCAN_CMD=""
  if command_exists rg; then SCAN_CMD="rg -n"; else SCAN_CMD="grep -Rni"; fi
  result=$($SCAN_CMD --no-heading -e "firebase[\w\-]*[\s:'\"]+\d+\.\d+\.\d+" "$PROJECT_ROOT" 2>/dev/null || true)
  if [[ -n "$result" ]]; then
    echo "$result" | jq -R -s 'split("\n") | .[:-1] | map(split(":")) | map({"file": .[0], "line": .[1], "match": .[2:] | join(":")})'
  else
    echo '[]'
  fi
else
  log_header "CROSS-PLATFORM DEPENDENCY MAPPING"
  SCAN_CMD=""
  if command_exists rg; then SCAN_CMD="rg -n"; else SCAN_CMD="grep -Rni"; fi
  $SCAN_CMD --no-heading -e "firebase[\w\-]*[\s:'\"]+\d+\.\d+\.\d+" "$PROJECT_ROOT" || true
fi
