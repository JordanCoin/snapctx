#!/usr/bin/env bats

@test "cheatsheet --json returns valid json" {
  run "$GITHUB_WORKSPACE/universal-toolkit.sh" -j cheatsheet
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}