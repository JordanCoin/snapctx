#!/usr/bin/env bash

# ANSI colours (honour NO_COLOR spec)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  export B="\033[1m"
  export G="\033[32m"
  export Y="\033[33m"
  export C="\033[36m"
  export R="\033[0m"
  export RED="\033[0;31m"
  export GREEN="\033[0;32m"
  export YELLOW="\033[1;33m"
  export BLUE="\033[0;34m"
  export PURPLE="\033[0;35m"
  export CYAN="\033[0;36m"
  export NC="\033[0m"
else
  export B=""
  export G=""
  export Y=""
  export C=""
  export R=""
  export RED=""
  export GREEN=""
  export YELLOW=""
  export BLUE=""
  export PURPLE=""
  export CYAN=""
  export NC=""
fi