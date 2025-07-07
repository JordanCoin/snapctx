#!/usr/bin/env bash

command_exists() { command -v "$1" &>/dev/null; }

# Setup ripgrep command with fallback
# Use ripgrep if available, otherwise fallback to grep (portable)
RG_CMD=$(command -v rg || echo "grep -r")
