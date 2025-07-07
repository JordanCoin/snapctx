#!/usr/bin/env bash
# scripts/cmd/verify.sh - Self-test for the toolkit
set -euo pipefail

# Source libraries using a robust path
# shellcheck source=../lib/log.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

# The main script to test, located at the project root
SNAPCTX_CMD="$(dirname "${BASH_SOURCE[0]}")/../../universal-toolkit.sh"

log_header "TOOLKIT SELF-VERIFICATION"

# Test cases: command and arguments
TEST_CASES=(
  "cheatsheet"
  "cheatsheet --json"
  "analyze"
  "analyze --json"
  "health"
  "health --json"
  "cross-platform"
  "cross-platform --json"
  "help"
  "version"
)

ALL_PASS=true

# Temporary log file for stderr
STDERR_LOG=$(mktemp)
# Cleanup trap to remove the temp file on exit
trap 'rm -f "$STDERR_LOG"' EXIT

# Change to project root to run tests
pushd "$(dirname "${BASH_SOURCE[0]}")/../../" > /dev/null

for args in "${TEST_CASES[@]}"; do
  log_info "Running: $SNAPCTX_CMD $args"
  # Pass the arguments exactly as they are in the TEST_CASES array
  # Note: we use "bash" to run the script to ensure it works in various environments
  if bash "$SNAPCTX_CMD" $args > /dev/null 2> "$STDERR_LOG"; then
    log_success "  PASS: $args"
  else
    log_error "  FAIL: $args"
    if [[ -s "$STDERR_LOG" ]]; then
      log_error "    Stderr: $(cat "$STDERR_LOG")"
    else
      log_error "    Stderr: (empty)"
    fi
    ALL_PASS=false
  fi
done

# Return to the original directory
popd > /dev/null

if $ALL_PASS; then
  log_success "All toolkit self-tests passed!"
  exit 0
else
  log_error "Some toolkit self-tests failed."
  exit 1
fi