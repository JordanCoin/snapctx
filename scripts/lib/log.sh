#!/usr/bin/env bash

# Source the centralized color definitions using a robust path
# shellcheck source=./colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
    echo -e "${PURPLE}$(printf '=%.0s' {1..60})${NC}"
}
