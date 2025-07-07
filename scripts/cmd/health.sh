#!/usr/bin/env bash
# scripts/cmd/health.sh - Project health check
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

health_check() {
  local manifests=(package.json pnpm-lock.yaml yarn.lock requirements.txt Pipfile composer.json pubspec.yaml Cargo.toml)
  local found_manifests=()
  for m in "${manifests[@]}"; do
    while IFS= read -r f; do
      found_manifests+=("$f")
    done < <(find "$PROJECT_ROOT" -name "$m" -type f 2>/dev/null)
  done

  if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
    if [[ ${#found_manifests[@]} -gt 0 ]]; then
      printf '%s\n' "${found_manifests[@]}" | jq -R -s 'split("\n") | .[:-1]'
    else
      echo '[]'
    fi
  else
    log_header "PROJECT HEALTH CHECK"
    if [ ${#found_manifests[@]} -eq 0 ]; then
      log_warning "No dependency manifests found."
    else
      for f in "${found_manifests[@]}"; do
        log_info "\n📦 $f"; head -20 "$f";
      done
    fi
  fi
}

health_check