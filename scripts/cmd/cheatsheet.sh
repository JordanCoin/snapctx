#!/usr/bin/env bash
# scripts/cmd/cheatsheet.sh - Quick project overview
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
  files=$( (cd "$PROJECT_ROOT" && find . -type f -not -path '*/.git/*' | wc -l) || echo 0)

  loc_json="{}"
  if command_exists tokei && command_exists jq; then
    loc_json=$(tokei "$PROJECT_ROOT" --output json 2>/dev/null || true)
    # Convert absolute paths to relative paths
    if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
      current_dir=$(pwd)
      loc_json=$(echo "$loc_json" | jq --arg pwd "$current_dir/" 'walk(if type == "object" and has("name") then .name |= gsub($pwd; "./") else . end)')
    fi
  fi

  json_output=$(json_kv "files" "$files")
  if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
    json_output=$(echo -e "$json_output\n$loc_json" | merge_json)
  fi

  echo "$json_output" | jq '.'
else
  log_header "PROJECT CHEATSHEET"
  files=$( (cd "$PROJECT_ROOT" && find . -type f -not -path '*/.git/*' | wc -l) || echo 0)
  project_name=$(basename "$(pwd)")
  log_info "📁 Project   : $project_name"
  log_info "📄 Files     : $files"

  if command_exists tokei && command_exists jq; then
    loc_json=$(tokei "$PROJECT_ROOT" --output json 2>/dev/null || true)
    if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
      languages=$(echo "$loc_json" | jq -r 'del(.Total) | to_entries[] | .key + " (" + (.value.code|tostring) + " lines)"')
      log_info "🗣️ Languages :"
      echo "$languages"
    else
      log_warning "(tokei analysis failed or no languages found)"
    fi
  else
    log_warning "(Install tokei & jq for LOC breakdown)"
  fi
fi
