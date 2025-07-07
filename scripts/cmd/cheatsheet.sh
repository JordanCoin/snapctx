#!/usr/bin/env bash
# scripts/cmd/cheatsheet.sh - Quick project overview
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

# Command-specific argument parsing (if any, for cheatsheet it's simple)
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

if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
  # JSON output logic
  files=$( (cd "$PROJECT_ROOT" && rg --files) | wc -l)

  if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
    local loc_json="{}"
    if command_exists tokei && command_exists jq; then
      loc_json=$(tokei "$PROJECT_ROOT" --output json 2>/dev/null || true)
    fi

    local json_output="{}"
    json_output=$(merge_json <(json_kv "files" "$files") <(echo "$json_output"))
    if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
      json_output=$(merge_json <(echo "$json_output") <(echo "$loc_json"))
    fi

  # Add other cheatsheet data to json_output
  json_output=$(merge_json <(json_kv "project_name" "Current Project") <(echo "$json_output"))
  json_output=$(merge_json <(json_kv "entrypoints" "(Dynamically detected)") <(echo "$json_output"))
  json_output=$(merge_json <(json_kv "build_commands" "(Project-specific)") <(echo "$json_output"))
  json_output=$(merge_json <(json_kv "test_commands" "(Project-specific)") <(echo "$json_output"))
  json_output=$(merge_json <(json_kv "prod_url" "(N/A)") <(echo "$json_output"))
  json_output=$(merge_json <(json_kv "docs" "(Project-specific)") <(echo "$json_output"))

  echo "$json_output" | jq '.' # Pretty print final JSON
else
  # Human-readable output logic
  log_header "SWTPA PROJECT CHEATSHEET"
  local files=$( (cd "$PROJECT_ROOT" && rg --files) | wc -l)
  log_info "📁 Directory : $PROJECT_ROOT"
  log_info "📄 Files     : $files"

  if command_exists tokei && command_exists jq; then
    local loc_json=$(tokei "$PROJECT_ROOT" --output json 2>/dev/null || true)
    if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
      local languages=$(echo "$loc_json" | jq -r '.languages | to_entries[] | "\(.key): \(.value.code) LOC"')
      log_info "🗣️ Languages :"
      echo "$languages" # Use echo directly for multi-line output
    else
      log_warning "(tokei analysis failed or no languages found)"
    fi
  else
    log_warning "(Install tokei & jq for LOC breakdown)"
  fi

  log_info "• Project: Current Project"
  log_info "• Entrypoints: (Dynamically detected)"
  log_info "• Build: (Project-specific)"
  log_info "• Test: (Project-specific)"
  log_info "• Deploy: (Project-specific)"
  log_info "• Prod URL: (N/A)"
  log_info "• Docs: (Project-specific)"
fi
