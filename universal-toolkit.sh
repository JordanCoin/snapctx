#!/usr/bin/env bash
# universal-toolkit.sh — drop‑in project reconnaissance script
# Works in **any** folder; zero project‑specific paths.
# Dependencies (auto‑detected, script still runs with fallbacks):
#   jq, tokei, hyperfine, tree (or eza), ripgrep (or grep), fd (or find)
# -----------------------------------------------------------------------------
set -euo pipefail
shopt -s globstar nullglob 2>/dev/null || true

## ── helpers ────────────────────────────────────────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }

# ANSI colours (honour NO_COLOR spec)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; R=$'\033[0m'
else
  B=""; G=""; Y=""; C=""; R=""
fi
heading() { printf "\n${B}${G}🚀 %s${R}\n" "$1"; }

ROOT="${1:-$PWD}"   # allow `universal-toolkit.sh /path/to/project`
JSON_OUT=""          # set by --json flag
MODE="cheatsheet"    # default sub‑command
DEPTH=2               # default tree depth

## ── arg parsing ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    cheatsheet|analyze|health|cross-platform) MODE="$1";;
    -d|--depth) DEPTH="${2:-2}"; shift;;
    -j|--json) JSON_OUT="yes";;
    -h|--help) MODE="help";;
    *) ROOT="$1";;
  esac; shift;
done

out() { # echo or build JSON
  if [[ -n "$JSON_OUT" ]]; then printf "%s\n" "$1"; else echo -e "$1"; fi
}

json_kv() { jq -n --arg k "$1" --arg v "$2" '{($k):$v}'; }
merge_json() { jq -s 'reduce .[] as $item ({}; . += $item)'; }

## ── sub‑commands ──────────────────────────────────────────────────────────
cheatsheet() {
  heading "PROJECT CHEATSHEET"
  local files lines languages loc_json="{}"
  files=$(find "$ROOT" -type f | wc -l)
  out "📁 Directory : $ROOT"
  out "📄 Files     : $files"
  if command_exists tokei && command_exists jq; then
    languages=$(tokei "$ROOT" --output json | jq -r '.languages | to_entries[] | "\(.key): \(.value.code) LOC"')
    out "🗣️ Languages :"; out "$languages"
    loc_json=$(tokei "$ROOT" --output json)
  else
    out "(Install tokei & jq for LOC breakdown)"
  fi
  [[ -n "$JSON_OUT" ]] && merge_json <(json_kv "files" "$files") <(echo "$loc_json")
}

analyze() {
  heading "PROJECT STRUCTURE ANALYSIS (depth $DEPTH)"
  if command_exists tree; then tree -L "$DEPTH" -C -I ".git" "$ROOT"; 
  elif command_exists eza; then eza -T "$ROOT" --level "$DEPTH";
  else find "$ROOT" -maxdepth "$DEPTH" -print;
  fi
}

health() {
  heading "PROJECT HEALTH CHECK"
  local manifests=(package.json pnpm-lock.yaml yarn.lock requirements.txt Pipfile composer.json pubspec.yaml Cargo.toml)
  for m in "${manifests[@]}"; do
    for f in $(find "$ROOT" -name "$m" 2>/dev/null); do
      out "\n📦 $f"; head -20 "$f";
    done
  done
}

cross_platform() {
  heading "CROSS‑PLATFORM DEPENDENCY MAPPING"
  if command_exists rg; then SCAN="rg -n"; else SCAN="grep -Rni"; fi
  $SCAN --no-heading -e "firebase[\w\-]*[\s:'\"]+\d+\.\d+\.\d+" "$ROOT" || true
}

case "$MODE" in
  cheatsheet)  cheatsheet ;;
  analyze)     analyze ;; 
  health)      health ;;
  cross-platform) cross_platform ;;
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
