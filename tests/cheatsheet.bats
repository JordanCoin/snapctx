#!/usr/bin/env bats

@test "cheatsheet --json returns valid json" {
  run ../universal-toolkit.sh cheatsheet --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}