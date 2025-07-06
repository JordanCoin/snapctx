# snapctx-sh 🔎✨
_A universal, zero-config “project radar” you can drop into any folder._

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#license)
![ShellCheck](https://github.com/JordanCoin/snapctx-sh/actions/workflows/lint.yml/badge.svg)

## What it does
`snapctx` runs a four-stage scan (`cheatsheet → analyze → health → cross-platform`) and emits
a compact **ctx.json** that captures:

* 📊 **File & LOC counts** per language (via `tokei`)
* 🌲 **Tree-first architecture view** (uses `tree` or `eza`)
* 🩺 **Dependency-health report** (Node + Swift + Python… auto-detected)
* 🔗 **Cross-repo drift** (e.g. Firebase SDK version mismatches)
* ⚡ Optional **benchmarks** (`hyperfine`) and **disk usage** (`dust`)

> Drag `ctx.json` into Claude/Copilot/Cursor to give the model instant context.

## Quick start
```bash
bash curl -sSL https://raw.githubusercontent.com/JordanCoin/snapctx-sh/main/universal-toolkit.sh -o /usr/local/bin/snapctx && chmod +x /usr/local/bin/snapctx

# from any git repo ↓
./snapctx cheatsheet        # colourised human output
./snapctx cheatsheet --json > /tmp/ctx.json   # machine-readable

# Sub-commands

| Command          | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| `cheatsheet`     | 3-second overview (files, languages, key paths)          |
| `analyze`        | Full recursive tree & hot-spot language stats            |
| `health`         | Checks for missing lockfiles, outdated deps, lint errors |
| `cross-platform` | Finds version drift across multi-repo workspaces         |
| `bench`          | (opt-in) run `hyperfine` suites defined in `.bench.yml`  |

Run ./snapctx --help for flags like --json, --depth, --no-color.

# Requirements
The script auto-detects tools and falls back gracefully.


| Preferred                    | Fallback             |
| ---------------------------- | -------------------- |
| `ripgrep` (`rg`)             | `grep -R`            |
| `fd`                         | `find`               |
| `tree` or `eza`              | `ls -R`              |
| `tokei`, `hyperfine`, `dust` | skipped with warning |

# Development

# lint the shell
shellcheck snapctx.sh

# run unit tests (bats-core)
npm install -g bats && bats test/

