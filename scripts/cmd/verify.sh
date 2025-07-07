#!/usr/bin/env bash
# scripts/cmd/verify.sh - Self-test for the toolkit
set -euo pipefail

# shellcheck source=../lib/log.sh
source "$(dirname "$0")/../lib/log.sh"

# Ensure ripgrep is installed for tests
if ! command -v rg &>/dev/null; then
  log_warning "ripgrep not found. Attempting to install..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y ripgrep
  elif command -v brew &>/dev/null; then
    brew install ripgrep
  else
    log_error "Cannot install ripgrep. Please install it manually to run tests."
    exit 1
  fi
fi

log_header "TOOLKIT SELF-VERIFICATION"

TEST_COMMANDS=(
  "cheatsheet"
  "-j cheatsheet"
  "--help"
)

ALL_PASS=true

for cmd in "${TEST_COMMANDS[@]}"; do
  log_info "Running: ./scripts/universal-toolkit.sh $cmd"
  if PROJECT_ROOT="$PWD" JSON_OUTPUT="false" "$(dirname "$0")/../universal-toolkit.sh" $cmd > /dev/null 2> cmd_stderr.log; then
    log_success "  PASS: $cmd"
  else
    log_error "  FAIL: $cmd"
    log_error "    Stderr: $(cat cmd_stderr.log)"
    ALL_PASS=false
  fi
  rm -f cmd_stderr.log
done

if $ALL_PASS; then
  log_success "All toolkit self-tests passed!"
  exit 0
else
  log_error "Some toolkit self-tests failed."
  exit 1
fi
