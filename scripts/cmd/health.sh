#!/usr/bin/env bash
# scripts/cmd/health.sh - Project health check
set -euo pipefail

# Source shared libraries relative to this script's location
# shellcheck source=../lib/colors.sh
source "$(dirname "$0")"/../lib/colors.sh"
# shellcheck source=../lib/json.sh
source "$(dirname "$0")"/../lib/json.sh"
# shellcheck source=../lib/log.sh
source "$(dirname "$0")"/../lib/log.sh"
# shellcheck source=../lib/util.sh
source "$(dirname "$0")"/../lib/util.sh"
# shellcheck source=../lib/config.sh
source "$(dirname "$0")"/../lib/config.sh"

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

# Access PROJECT_ROOT and JSON_OUTPUT from environment (set by dispatcher)
PROJECT_ROOT="${PROJECT_ROOT:-.}" # Fallback if not set

health_check() {
  local manifests=(package.json pnpm-lock.yaml yarn.lock requirements.txt Pipfile composer.json pubspec.yaml Cargo.toml)
  local found_manifests=""
  for m in "${manifests[@]}"; do
    while IFS= read -r f; do
      found_manifests+="$f "
    done < <(find "$PROJECT_ROOT" -name "$m" -type f 2>/dev/null)
  done

  if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
    echo "$found_manifests" | jq -R -s 'split(" ") | .[:-1]'
  else
    log_header "PROJECT HEALTH CHECK"
    for f in $found_manifests; do
      log_info "\n📦 $f"; head -20 "$f";
    done
  fi
}

health_check
