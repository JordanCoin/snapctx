#!/usr/bin/env bash
# universal-toolkit.sh — drop‑in project reconnaissance script
# Works in **any** folder; zero project‑specific paths.
# Dependencies (auto‑detected, script still runs with fallbacks):
#   jq, tokei, hyperfine, tree (or eza), ripgrep (or grep), fd (or find)
# -----------------------------------------------------------------------------
set -euo pipefail
shopt -s globstar nullglob 2>/dev/null || true

source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/json.sh"

## ── sub‑commands ──────────────────────────────────────────────────────────
cheatsheet() {
  heading "PROJECT CHEATSHEET"
  local files lines languages loc_json="{}"
  files=$( (cd "$ROOT" && rg --files) | wc -l)
  out "📁 Directory : $ROOT"
  out "📄 Files     : $files"
  if command_exists tokei && command_exists jq; then
    # Run tokei, but ignore exit code in case it fails on some projects
    loc_json=$(tokei "$ROOT" --output json 2>/dev/null || true)
    if [[ -n "$loc_json" && "$loc_json" != "{}" ]]; then
      languages=$(echo "$loc_json" | jq -r '.languages | to_entries[] | "\(.key): \(.value.code) LOC"')
      out "🗣️ Languages :"
      out "$languages"
    else
      out "(tokei analysis failed or no languages found)"
      loc_json="{}" # ensure loc_json is valid json for merge later
    fi
  else
    out "(Install tokei & jq for LOC breakdown)"
  fi
  [[ -n "$JSON_OUT" ]] && merge_json <(json_kv "files" "$files") <(echo "$loc_json")
}

analyze() {
  if [[ $files -gt 400 ]]; then DEPTH=2; fi
  heading "PROJECT STRUCTURE ANALYSIS (depth $DEPTH)"
  if [[ -n "$JSON_OUT" ]]; then
    if command_exists tree; then
      tree -L "$DEPTH" -I ".git" --noreport --dirsfirst -J "$ROOT" | jq '.'
    elif command_exists eza; then
      eza -T "$ROOT" --level "$DEPTH" --no-quotes --no-permissions --no-user --no-time --no-filesize -J | jq '.'
    else
      find "$ROOT" -maxdepth "$DEPTH" -print | jq -R -s 'split("\n") | .[1:]'
    fi
  else
    if command_exists tree; then tree -L "$DEPTH" -C -I ".git" "$ROOT";
    elif command_exists eza; then eza -T "$ROOT" --level "$DEPTH";
    else find "$ROOT" -maxdepth "$DEPTH" -print;
    fi
  fi
}

health() {
  heading "PROJECT HEALTH CHECK"
  local manifests=(package.json pnpm-lock.yaml yarn.lock requirements.txt Pipfile composer.json pubspec.yaml Cargo.toml)
  local found_manifests=""
  for m in "${manifests[@]}"; do
    while IFS= read -r f; do
      found_manifests+="$f "
    done < <(find "$ROOT" -name "$m" -type f 2>/dev/null)
  done

  if [[ -n "$JSON_OUT" ]]; then
    echo "$found_manifests" | jq -R -s 'split(" ") | .[:-1]'
  else
    for f in $found_manifests; do
      out "\n📦 $f"; head -20 "$f";
    done
  fi
}

cross_platform() {
  heading "CROSS‑PLATFORM DEPENDENCY MAPPING"
  if command_exists rg; then SCAN="rg -n"; else SCAN="grep -Rni"; fi

  if [[ -n "$JSON_OUT" ]]; then
    $SCAN --no-heading -e "firebase[\w\-]*[\s:'\"]+\d+\.\d+\.\d+" "$ROOT" | jq -R -s 'split("\n") | .[:-1] | map(split(":")) | map({"file": .[0], "line": .[1], "match": .[2:] | join(":")})'
  else
    $SCAN --no-heading -e "firebase[\w\-]*[\s:'\"]+\d+\.\d+\.\d+" "$ROOT" || true
  fi
}

bench() {
  heading "BENCHMARKING"
  local bench_file="$ROOT/.bench.yml"
  if [[ -f "$bench_file" ]]; then
    if command_exists hyperfine; then
      if [[ -n "$JSON_OUT" ]]; then
        hyperfine --export-json - "$bench_file" | jq '.'
      else
        hyperfine --yaml "$bench_file"
      fi
    else
      out "(Install hyperfine to run benchmarks)"
    fi
  else
    out "(No .bench.yml file found)"
  fi
}

case "$MODE" in
  cheatsheet)  cheatsheet ;;
  analyze)     analyze ;;
  health)      health ;;
  cross-platform) cross_platform ;;
  bench)       bench ;;
  version)
    echo "snapctx-sh 0.2.0"
    ;;
  help|*)
    cat <<EOF
Usage: $(basename "$0") [mode] [options] [root]
Modes:
  cheatsheet           quick stats (default)
  analyze              tree view
  health               manifest previews
  cross-platform       naive version drift scan
Options:
  -d, --depth N        tree depth (analyze mode)
  -j, --json           machine‑readable JSON output (cheatsheet only)
  -h, --help           show this help
EOF
  ;;
esac
