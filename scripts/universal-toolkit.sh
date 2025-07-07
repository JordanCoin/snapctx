#!/usr/bin/env bash
# 🛠️ SWTPA Development Toolkit - Main Dispatcher
set -euo pipefail

# shellcheck source=./lib/colors.sh
# shellcheck source=./lib/json.sh
# shellcheck source=./lib/log.sh
# shellcheck source=./lib/util.sh
# shellcheck source=./lib/config.sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for lib in colors json log util config; do
  # shellcheck disable=SC1090
  source "${DIR}/lib/${lib}.sh"
done

JSON_OUTPUT=false
COMMAND=""

# --- global arg parsing with getopts ---
while getopts ":jh" opt; do
  case "$opt" in
    j) JSON_OUTPUT=true ;;
    h) COMMAND="help";; # Set command to help if -h is present
    \?) log_error "Invalid option: -$OPTARG"; exit 1 ;;
    :) log_error "Option -$OPTARG requires an argument."; exit 1 ;;
  esac
done
shift $((OPTIND -1)) # Shift past the global options

# The first non-option argument is the command
if [[ -n "$1" ]]; then
  COMMAND="$1"
  shift # Shift past the command
fi

export PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
export JSON_OUTPUT

case "${COMMAND:-help}" in
  help|"")
      log_info "Usage: $(basename "$0") [global_options] <command> [command_options]"
      log_info "Global Options:"
      log_info "  -j, --json    Output in JSON format (where supported)"
      log_info "  -h, --help    Show global help"
      log_info ""
      log_info "Commands:"
      log_info "  🚀 CONTEXT ENGINEERING REVOLUTION:"
      log_info "  cheatsheet    Quick project overview"
      log_info "  analyze       Detailed project structure analysis"
      log_info "  health        Check project health and manifest files"
      log_info "  cross-platform Cross-platform dependency mapping"
      log_info "  install-deps  Universal dependency installer (auto-detect OS/pkg-mgr)"
      log_info "  context-manifesto The revolution manifesto & industry evidence"
      log_info "  verify        Run comprehensive self-tests with schema validation"
      log_info "  llm-context   Generate Claude context snapshot"
      log_info "  what-is       Explain a file or component"
      log_info "  diagnose-error Intelligent error diagnosis"
      log_info "  find-files    Find files by pattern"
      log_info "  find-todos    Find TODOs, FIXMEs, etc."
      log_info "  generate-dev-summary Generate a development summary report"
      log_info "  graph         Analyze dependency graph"
      log_info "  hotspots      Analyze code hotspots"
      log_info "  peek          Interface signatures"
      log_info "  performance   Performance analysis"
      log_info "  run-complete-e2e Run complete E2E test suite"
      log_info "  run-interactive-cli Start interactive CLI mode"
      log_info "  search        Search codebase for pattern"
      log_info "  show-tree     Show project tree view"
      log_info "  slice         View file slice"
      log_info "  drift         Version drift analysis"
      log_info "  branch-impact Branch impact analysis"
      ;;
  *)
      # exec the real command, passing all remaining arguments
      exec "${DIR}/cmd/${COMMAND}.sh" "$@"
      ;;
esac
