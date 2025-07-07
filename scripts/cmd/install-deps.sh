#!/bin/bash
# install-deps.sh - Universal Dependency Installer
# The Context Engineering Revolution requires the right tools

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/util.sh"

show_help() {
    cat << 'EOF'
Universal Toolkit - Install Dependencies

USAGE:
    install-deps [OPTIONS]

DESCRIPTION:
    Automatically detects your OS and package manager, then installs
    missing tools for the ultimate context engineering experience.

    This embodies our "zero-friction onboarding" philosophy:
    • Auto-detect platform (macOS, Linux, Windows/WSL)
    • Choose best package manager (brew, apt, yum, choco, etc.)
    • Install only what's missing
    • Graceful fallbacks when package managers aren't available

OPTIONS:
    --check-only      Only check what's missing, don't install
    --force          Install even if tools are already available
    --minimal        Install only core dependencies (jq, git)
    --enhanced       Install enhanced toolset (ripgrep, bat, tokei, hyperfine)
    --all            Install everything including optional tools
    --yes            Skip confirmation prompts
    -h, --help       Show this help

TOOLS MANAGED:
    Core (always needed):
        • jq           - JSON processing for context engineering
        • git          - Version control and repo analysis
    
    Enhanced (recommended):
        • ripgrep (rg) - Fast text search
        • bat          - Enhanced file viewing
        • tree         - Directory tree visualization
        • tokei        - Code statistics
    
    Optional (performance & analysis):
        • hyperfine    - Command-line benchmarking
        • shellcheck   - Shell script linting
        • fzf          - Fuzzy finder
        • fd           - Fast file search

EXAMPLES:
    install-deps --check-only          # See what's missing
    install-deps --minimal --yes       # Install core tools silently
    install-deps --enhanced           # Install recommended toolset
    install-deps --all               # Install everything

PHILOSOPHY:
    "The best tool is the one that works immediately"
    - Zero-config philosophy means handling missing dependencies gracefully
    - Context engineering requires quality tooling
    - Universal adoption through universal compatibility

EOF
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    local os="$1"
    
    case "$os" in
        "macos")
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        "linux"|"wsl")
            if command -v apt >/dev/null 2>&1; then
                echo "apt"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            elif command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            elif command -v pacman >/dev/null 2>&1; then
                echo "pacman"
            elif command -v zypper >/dev/null 2>&1; then
                echo "zypper"
            else
                echo "none"
            fi
            ;;
        "windows")
            if command -v choco >/dev/null 2>&1; then
                echo "choco"
            elif command -v winget >/dev/null 2>&1; then
                echo "winget"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Check if tool is installed
check_tool() {
    local tool="$1"
    command -v "$tool" >/dev/null 2>&1
}

# Get package name for tool on specific package manager
get_package_name() {
    local tool="$1"
    local pkg_mgr="$2"
    
    case "$tool-$pkg_mgr" in
        "jq-"*) echo "jq" ;;
        "git-"*) echo "git" ;;
        "rg-brew"|"rg-apt"|"rg-dnf"|"rg-yum") echo "ripgrep" ;;
        "rg-pacman") echo "ripgrep" ;;
        "rg-choco") echo "ripgrep" ;;
        "rg-winget") echo "BurntSushi.ripgrep.MSVC" ;;
        "bat-brew") echo "bat" ;;
        "bat-apt"|"bat-dnf"|"bat-yum") echo "bat" ;;
        "bat-pacman") echo "bat" ;;
        "bat-choco"|"bat-winget") echo "bat" ;;
        "tree-"*) echo "tree" ;;
        "tokei-brew") echo "tokei" ;;
        "tokei-apt") echo "tokei" ;;
        "tokei-choco"|"tokei-winget") echo "tokei" ;;
        "hyperfine-brew") echo "hyperfine" ;;
        "hyperfine-apt") echo "hyperfine" ;;
        "hyperfine-choco") echo "hyperfine" ;;
        "shellcheck-"*) echo "shellcheck" ;;
        "fzf-"*) echo "fzf" ;;
        "fd-brew") echo "fd" ;;
        "fd-apt"|"fd-dnf") echo "fd-find" ;;
        "fd-pacman") echo "fd" ;;
        "fd-choco"|"fd-winget") echo "fd" ;;
        *) echo "$tool" ;;
    esac
}

# Install package using detected package manager
install_package() {
    local package="$1"
    local pkg_mgr="$2"
    local force_yes="${3:-false}"
    
    local install_cmd=""
    local yes_flag=""
    
    if [[ "$force_yes" == "true" ]]; then
        case "$pkg_mgr" in
            "apt") yes_flag="-y" ;;
            "yum"|"dnf") yes_flag="-y" ;;
            "choco") yes_flag="-y" ;;
            # brew and others don't need explicit yes flags
        esac
    fi
    
    case "$pkg_mgr" in
        "brew")
            install_cmd="brew install $package"
            ;;
        "apt")
            install_cmd="sudo apt update && sudo apt install $yes_flag $package"
            ;;
        "yum")
            install_cmd="sudo yum install $yes_flag $package"
            ;;
        "dnf")
            install_cmd="sudo dnf install $yes_flag $package"
            ;;
        "pacman")
            install_cmd="sudo pacman -S --noconfirm $package"
            ;;
        "zypper")
            install_cmd="sudo zypper install -y $package"
            ;;
        "choco")
            install_cmd="choco install $yes_flag $package"
            ;;
        "winget")
            install_cmd="winget install $package"
            ;;
        *)
            log_error "Unknown package manager: $pkg_mgr"
            return 1
            ;;
    esac
    
    log_info "Installing $package with: $install_cmd"
    eval "$install_cmd"
}

main() {
    local check_only=false
    local force_install=false
    local install_level="enhanced"  # minimal, enhanced, all
    local skip_confirmation=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                check_only=true
                shift
                ;;
            --force)
                force_install=true
                shift
                ;;
            --minimal)
                install_level="minimal"
                shift
                ;;
            --enhanced)
                install_level="enhanced"
                shift
                ;;
            --all)
                install_level="all"
                shift
                ;;
            --yes)
                skip_confirmation=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    log_info "${GREEN}🚀 Context Engineering Revolution - Dependency Installer${NC}"
    echo
    
    # Detect system
    local os
    os=$(detect_os)
    log_info "Detected OS: $os"
    
    local pkg_mgr
    pkg_mgr=$(detect_package_manager "$os")
    log_info "Detected package manager: $pkg_mgr"
    
    if [[ "$pkg_mgr" == "none" ]]; then
        log_warning "No supported package manager found!"
        log_info "Manual installation required. See our documentation for alternative installation methods."
        exit 1
    fi
    
    # Define tool sets
    local -a core_tools=("jq" "git")
    local -a enhanced_tools=("rg" "bat" "tree" "tokei")
    local -a optional_tools=("hyperfine" "shellcheck" "fzf" "fd")
    
    local -a tools_to_check=()
    case "$install_level" in
        "minimal")
            tools_to_check=("${core_tools[@]}")
            ;;
        "enhanced")
            tools_to_check=("${core_tools[@]}" "${enhanced_tools[@]}")
            ;;
        "all")
            tools_to_check=("${core_tools[@]}" "${enhanced_tools[@]}" "${optional_tools[@]}")
            ;;
    esac
    
    echo
    log_info "${BLUE}📋 Checking installed tools...${NC}"
    
    local -a missing_tools=()
    local -a installed_tools=()
    
    for tool in "${tools_to_check[@]}"; do
        if check_tool "$tool" && [[ "$force_install" == "false" ]]; then
            log_success "✅ $tool - installed"
            installed_tools+=("$tool")
        else
            if [[ "$force_install" == "true" ]]; then
                log_info "🔄 $tool - will reinstall (--force)"
            else
                log_warning "❌ $tool - missing"
            fi
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 && "$force_install" == "false" ]]; then
        echo
        log_success "${GREEN}🎉 All tools are already installed!${NC}"
        log_info "Your system is ready for context engineering excellence."
        exit 0
    fi
    
    if [[ "$check_only" == "true" ]]; then
        echo
        if [[ ${#missing_tools[@]} -gt 0 ]]; then
            log_info "${YELLOW}Missing tools: ${missing_tools[*]}${NC}"
            log_info "Run without --check-only to install them."
        fi
        exit 0
    fi
    
    echo
    log_info "${BLUE}📦 Installing missing tools...${NC}"
    
    if [[ "$skip_confirmation" == "false" ]]; then
        echo "About to install: ${missing_tools[*]}"
        echo "Package manager: $pkg_mgr"
        echo
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi
    
    local failed_installs=()
    
    for tool in "${missing_tools[@]}"; do
        local package
        package=$(get_package_name "$tool" "$pkg_mgr")
        
        log_info "Installing $tool (package: $package)..."
        
        if install_package "$package" "$pkg_mgr" "$skip_confirmation"; then
            log_success "✅ $tool installed successfully"
        else
            log_error "❌ Failed to install $tool"
            failed_installs+=("$tool")
        fi
    done
    
    echo
    if [[ ${#failed_installs[@]} -eq 0 ]]; then
        log_success "${GREEN}🎉 All tools installed successfully!${NC}"
        echo
        log_info "Your system is now optimized for context engineering."
        log_info "Run './universal-toolkit.sh analyze --help' to get started!"
    else
        log_warning "${YELLOW}⚠️  Some installations failed: ${failed_installs[*]}${NC}"
        echo
        log_info "Don't worry - the toolkit uses graceful fallbacks."
        log_info "Missing tools will be replaced with alternative commands."
    fi
}

# Run main function
main "$@" 