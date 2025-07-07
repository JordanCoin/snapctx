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
ARGS=()

# --- global arg parsing ---
while (($#)); do
  case "$1" in
    --json|-j)
      JSON_OUTPUT=true
      ;;
    --help|-h)
      COMMAND=help
      break
      ;;
    -*)
      ARGS+=("$1") # forward unknown flags
      ;;
    *)
      COMMAND="$1"
      shift
      ARGS+=("$@") # Capture all remaining args for the subcommand
      break
      ;;
  esac
  shift
done

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
      log_info "  cheatsheet    Quick project overview"
      log_info "  analyze       Detailed project structure analysis"
      log_info "  health        Check project health and manifest files"
      log_info "  cross-platform Cross-platform dependency mapping"
      log_info "  bench         Run benchmarks (if .bench.yml exists)"
      log_info "  verify        Run self-tests"
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
      # exec the real command
      exec "${DIR}/cmd/${COMMAND}.sh" "${ARGS[@]}"
      ;;
esac
