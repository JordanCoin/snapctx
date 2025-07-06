#!/usr/bin/env bash

# ANSI colours (honour NO_COLOR spec)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  B=
\033[1m'; G=
\033[32m'; Y=
\033[33m'; C=
\033[36m'; R=
\033[0m'
else
  B=""; G=""; Y=""; C=""; R=""
fi
export B G Y C R
