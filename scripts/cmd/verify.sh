#!/usr/bin/env bash
# scripts/cmd/verify.sh - Self-test for the toolkit
set -euo pipefail

# shellcheck source=../lib/log.sh
source "$(dirname "$0")/../lib/log.sh"

log_header "TOOLKIT SELF-VERIFICATION"

TEST_COMMANDS=(
  "cheatsheet"
  "-j cheatsheet"
  "--help"
)

ALL_PASS=true

for cmd in "${TEST_COMMANDS[@]}"; do
  log_info "Running: ./scripts/universal-toolkit.sh $cmd"
  if PROJECT_ROOT="$PWD" JSON_OUTPUT="false" "$(dirname "$0")/../universal-toolkit.sh" $cmd > /dev/null 2>&1; then
    log_success "  PASS: $cmd"
  else
    log_error "  FAIL: $cmd"
    ALL_PASS=false
  fi
done

if $ALL_PASS; then
  log_success "All toolkit self-tests passed!"
  exit 0
else
  log_error "Some toolkit self-tests failed."
  exit 1
fi
