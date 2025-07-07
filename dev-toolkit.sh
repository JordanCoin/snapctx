#!/bin/bash

# 🛠️ SWTPA Development Toolkit
# Enhanced development tools for Social Work Test Prep Academy
# Usage: ./scripts/dev-toolkit.sh [command] [options]

# Hardened error handling as per ChatGPT recommendations
set -euo pipefail

# Check if we're in a TTY for color support
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    # No colors
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    NC=''
fi

# Project structure
BACKEND_DIR="adaptive-backend"
FRONTEND_DIR="aswb-lcsw-quiz-app"
IOS_DIR="SWTPA"
SCRIPTS_DIR="scripts"

# Setup ripgrep command with fallback
# Use ripgrep if available, otherwise fallback to grep (portable)
RG_CMD=$(command -v rg || echo "grep -r")

# Functions
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

# JSON output helper
json_escape() {
    echo "$1" | jq -Rs .
}

# Check if JSON output is requested
is_json_output() {
    [[ "${JSON_OUTPUT:-}" == "true" ]] || [[ "$*" == *"--json"* ]]
}

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
    echo -e "${PURPLE}$(printf '=%.0s' {1..60})${NC}"
}

# Project analysis functions
analyze_project() {
    log_header "PROJECT STRUCTURE ANALYSIS"
    
    echo -e "${CYAN}📁 Full Project Tree:${NC}"
    tree -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
    
    echo -e "\n${CYAN}📊 Codebase Statistics:${NC}"
    
    # Backend stats
    echo -e "${BLUE}Backend (TypeScript):${NC}"
    fd --type f --extension ts --extension js . $BACKEND_DIR/src | wc -l | xargs echo "  Files:"
    "$RG_CMD" "function|class|interface|type" $BACKEND_DIR/src 2>/dev/null | wc -l | xargs echo "  Definitions:"
    
    # Frontend stats
    echo -e "${BLUE}Frontend (React + TypeScript):${NC}"
    fd --type f --extension tsx --extension ts . $FRONTEND_DIR/src | wc -l | xargs echo "  Files:"
    "$RG_CMD" "function|const.*=|interface|type" $FRONTEND_DIR/src 2>/dev/null | wc -l | xargs echo "  Components/Functions:" || echo "  Components/Functions: Analyzing..."
    
    # iOS stats
    if [ -d "$IOS_DIR" ]; then
        echo -e "${BLUE}iOS (Swift):${NC}"
        fd --type f --extension swift $IOS_DIR | wc -l | xargs echo "  Files:"
        "$RG_CMD" "func|class|struct|protocol" $IOS_DIR 2>/dev/null | wc -l | xargs echo "  Definitions:" || echo "  Definitions: Analyzing..."
    fi
}

analyze_dependencies() {
    log_header "DEPENDENCY ANALYSIS"
    
    echo -e "${CYAN}📦 Backend Dependencies:${NC}"
    if [ -f "$BACKEND_DIR/package.json" ]; then
        jq '.dependencies | to_entries | length' $BACKEND_DIR/package.json | xargs echo "  Production:"
        jq '.devDependencies | to_entries | length' $BACKEND_DIR/package.json | xargs echo "  Development:"
        
        echo -e "\n${BLUE}  Critical Dependencies:${NC}"
        jq -r '.dependencies | to_entries[] | select(.key | test("firebase|express|typescript")) | "    \(.key): \(.value)"' $BACKEND_DIR/package.json
    fi
    
    echo -e "\n${CYAN}📦 Frontend Dependencies:${NC}"
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        jq '.dependencies | to_entries | length' $FRONTEND_DIR/package.json | xargs echo "  Production:"
        jq '.devDependencies | to_entries | length' $FRONTEND_DIR/package.json | xargs echo "  Development:"
        
        echo -e "\n${BLUE}  Critical Dependencies:${NC}"
        jq -r '.dependencies | to_entries[] | select(.key | test("react|vite|firebase|stripe")) | "    \(.key): \(.value)"' $FRONTEND_DIR/package.json
    fi
}

cross_platform_analysis() {
    log_header "CROSS-PLATFORM DEPENDENCY MAPPING"
    
    echo -e "${CYAN}🔗 Firebase SDK Versions Across Platforms:${NC}"
    
    # Backend Firebase versions
    if [ -f "$BACKEND_DIR/package.json" ]; then
        echo -e "${BLUE}Backend:${NC}"
        jq -r '.dependencies | to_entries[] | select(.key | test("firebase")) | "  \(.key): \(.value)"' $BACKEND_DIR/package.json
    fi
    
    # Frontend Firebase versions  
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        echo -e "${BLUE}Frontend:${NC}"
        jq -r '.dependencies | to_entries[] | select(.key | test("firebase")) | "  \(.key): \(.value)"' $FRONTEND_DIR/package.json
    fi
    
    # iOS Firebase (check if Firebase pods exist)
    if [ -f "$IOS_DIR/SWTPA.xcodeproj/project.pbxproj" ]; then
        echo -e "${BLUE}iOS:${NC}"
        if grep -q "Firebase" "$IOS_DIR/SWTPA.xcodeproj/project.pbxproj" 2>/dev/null; then
            echo "  Firebase SDK: Configured (check project.pbxproj for versions)"
        else
            echo "  Firebase SDK: Not yet integrated"
        fi
    fi
    
    echo -e "\n${CYAN}📜 TypeScript Versions:${NC}"
    
    # Backend TypeScript
    if [ -f "$BACKEND_DIR/package.json" ]; then
        backend_ts=$(jq -r '.devDependencies.typescript // .dependencies.typescript // "not found"' $BACKEND_DIR/package.json)
        echo -e "${BLUE}Backend:${NC} $backend_ts"
    fi
    
    # Frontend TypeScript
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        frontend_ts=$(jq -r '.devDependencies.typescript // .dependencies.typescript // "not found"' $FRONTEND_DIR/package.json)
        echo -e "${BLUE}Frontend:${NC} $frontend_ts"
    fi
    
    # Check compatibility
    if [ "$backend_ts" = "$frontend_ts" ] && [ "$backend_ts" != "not found" ]; then
        log_success "TypeScript versions are synchronized ✅"
    elif [ "$backend_ts" != "not found" ] && [ "$frontend_ts" != "not found" ]; then
        log_warning "TypeScript versions differ - may cause type compatibility issues"
    fi
    
    echo -e "\n${CYAN}🎯 Shared Type Definitions:${NC}"
    
    # Look for shared types between backend and frontend
    echo -e "${BLUE}Potential shared types:${NC}"
    "$RG_CMD" "interface|type.*=" $BACKEND_DIR/src/types/ 2>/dev/null | head -5 | while read line; do
        type_name=$(echo "$line" | sed -E 's/.*\b(interface|type)\s+([A-Z][A-Za-z0-9_]*).*/\2/')
        if [ ! -z "$type_name" ]; then
            # Check if this type exists in frontend
            if "$RG_CMD" "\b$type_name\b" $FRONTEND_DIR/src/ 2>/dev/null >/dev/null; then
                echo "  $type_name: ✅ Found in both backend and frontend"
            else
                echo "  $type_name: ⚠️  Backend only"
            fi
        fi
    done
    
    echo -e "\n${CYAN}📊 Cross-Platform File Analysis:${NC}"
    
    # Count files by type across platforms
    backend_files=$(fd --type f --extension ts . $BACKEND_DIR/src 2>/dev/null | wc -l)
    frontend_files=$(fd --type f --extension tsx --extension ts . $FRONTEND_DIR/src 2>/dev/null | wc -l)
    ios_files=$(fd --type f --extension swift . $IOS_DIR 2>/dev/null | wc -l)
    
    echo "  Backend TypeScript files: $backend_files"
    echo "  Frontend TypeScript/React files: $frontend_files"
    echo "  iOS Swift files: $ios_files"
    
    total_files=$((backend_files + frontend_files + ios_files))
    echo "  Total cross-platform codebase: $total_files files"
}

test_affected_analysis() {
    local changed_files="$1"
    
    if [ -z "$changed_files" ]; then
        log_error "Usage: test-affected <file1,file2> or 'git' for git changes"
        echo "Examples:"
        echo "  ./scripts/dev-toolkit.sh test-affected adaptive-backend/src/answerQuestion.ts"
        echo "  ./scripts/dev-toolkit.sh test-affected git"
        return 1
    fi
    
    log_header "SMART TEST RUNNER - AFFECTED ANALYSIS"
    
    # Handle git mode
    if [ "$changed_files" = "git" ]; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo -e "${CYAN}🔍 Analyzing git changes since last commit:${NC}"
            changed_files=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")
            if [ -z "$changed_files" ]; then
                log_warning "No git changes detected"
                return 1
            fi
            echo "Changed files:"
            echo "$changed_files" | sed 's/^/  /'
        else
            log_error "Not in a git repository"
            return 1
        fi
    fi
    
    echo -e "\n${CYAN}🧪 Test Impact Analysis:${NC}"
    
    # Convert comma-separated to space-separated if needed
    files_list=$(echo "$changed_files" | tr ',' ' ')
    
    for file in $files_list; do
        if [ ! -f "$file" ]; then
            log_warning "File not found: $file"
            continue
        fi
        
        echo -e "\n${BLUE}📁 Analyzing: $file${NC}"
        
        # Backend tests to run
        if [[ "$file" == *"adaptive-backend"* ]]; then
            echo -e "${YELLOW}  Backend Tests to Run:${NC}"
            
            # Direct test file
            test_file=$(echo "$file" | sed 's/\.ts$/.test.ts/' | sed 's/src\//test\//')
            if [ -f "$test_file" ]; then
                echo "    ✅ Direct test: $test_file"
            fi
            
            # Related tests based on filename
            base_name=$(basename "$file" .ts)
            related_tests=$(fd "$base_name.*test" . $BACKEND_DIR/src/test/ 2>/dev/null || echo "")
            if [ ! -z "$related_tests" ]; then
                echo "$related_tests" | sed 's/^/    ✅ Related test: /'
            fi
            
            # If it's a core file, suggest comprehensive tests
            if [[ "$file" == *"adaptive-core"* ]] || [[ "$file" == *"answerQuestion"* ]] || [[ "$file" == *"initializeQuizSession"* ]]; then
                echo "    🎯 Suggested: Run full adaptive-core test suite"
                echo "    📋 Command: cd $BACKEND_DIR && npm test -- adaptive-core"
            fi
        fi
        
        # Frontend tests to run
        if [[ "$file" == *"aswb-lcsw-quiz-app"* ]]; then
            echo -e "${YELLOW}  Frontend Tests to Run:${NC}"
            
            # Component unit tests
            test_file=$(echo "$file" | sed 's/\.tsx\?$/.test.tsx/' | sed 's/src\//src\/__tests__\/unit\//')
            if [ -f "$test_file" ]; then
                echo "    ✅ Unit test: $test_file"
            fi
            
            # E2E tests that might be affected
            if [[ "$file" == *"QuizApp"* ]] || [[ "$file" == *"QuizSession"* ]]; then
                echo "    🎯 E2E tests: quiz.e2e.ts, comprehensive-lifecycle.e2e.ts"
            elif [[ "$file" == *"Auth"* ]] || [[ "$file" == *"SignIn"* ]]; then
                echo "    🎯 E2E tests: auth.e2e.ts"
            elif [[ "$file" == *"Dashboard"* ]]; then
                echo "    🎯 E2E tests: dashboard.e2e.ts"
            fi
        fi
        
        # iOS components affected
        echo -e "${YELLOW}  iOS Components to Review:${NC}"
        base_name=$(basename "$file" .ts)
        
        if [[ "$file" == *"adaptive-core"* ]]; then
            echo "    🎯 iOS: AdaptiveEngine.swift (adaptive algorithms)"
        elif [[ "$file" == *"answerQuestion"* ]] || [[ "$file" == *"QuizSession"* ]]; then
            echo "    🎯 iOS: QuizView.swift, QuizModels.swift"
        elif [[ "$file" == *"Auth"* ]]; then
            echo "    🎯 iOS: AuthManager.swift"
        else
            echo "    ℹ️  No direct iOS impact detected"
        fi
        
        # API contract changes
        if [[ "$file" == *"index.ts" ]] && [[ "$file" == *"adaptive-backend"* ]]; then
            echo -e "${RED}  🚨 API CONTRACT CHANGE DETECTED:${NC}"
            echo "    📋 Review all client implementations"
            echo "    🌐 Frontend: QuizApiService.ts"
            echo "    📱 iOS: API client code"
        fi
    done
}

development_metrics() {
    log_header "DEVELOPMENT METRICS & TRENDS"
    
    echo -e "${CYAN}📊 Test Coverage Analysis:${NC}"
    
    # Backend test coverage
    if [ -f "$BACKEND_DIR/coverage/coverage-summary.json" ]; then
        echo -e "${BLUE}Backend Coverage:${NC}"
        coverage_file="$BACKEND_DIR/coverage/coverage-summary.json"
        lines=$(jq '.total.lines.pct' "$coverage_file" 2>/dev/null || echo "N/A")
        functions=$(jq '.total.functions.pct' "$coverage_file" 2>/dev/null || echo "N/A")
        branches=$(jq '.total.branches.pct' "$coverage_file" 2>/dev/null || echo "N/A")
        echo "  Lines: ${lines}%"
        echo "  Functions: ${functions}%"
        echo "  Branches: ${branches}%"
    else
        echo -e "${BLUE}Backend Coverage:${NC} Run 'npm run test:coverage' to generate"
    fi
    
    # Frontend bundle analysis
    echo -e "\n${CYAN}📦 Bundle Size Analysis:${NC}"
    if [ -d "$FRONTEND_DIR/dist" ]; then
        echo -e "${BLUE}Frontend Bundles:${NC}"
        fd --type f --extension js . $FRONTEND_DIR/dist/assets 2>/dev/null | while read file; do
            size=$(ls -lh "$file" | awk '{print $5}')
            name=$(basename "$file")
            echo "  $name: $size"
        done
        
        # Total bundle size
        total_size=$(du -sh $FRONTEND_DIR/dist/assets/*.js 2>/dev/null | awk '{sum += $1} END {print sum "K"}' || echo "Unknown")
        echo "  Total JS: $total_size"
    else
        echo -e "${BLUE}Frontend Bundles:${NC} Run 'npm run build' to analyze"
    fi
    
    # Large files analysis
    echo -e "\n${CYAN}📁 Large Files (Performance Impact):${NC}"
    fd --type f --size +500k . --exclude 'node_modules|.git|coverage|dist|build' | head -5 | while read file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "  $file: $size"
    done
    
    # Git activity analysis (local only)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "\n${CYAN}📈 Recent Development Activity:${NC}"
        
        # Commits per platform (last 30 commits)
        backend_commits=$(git log --oneline -30 --grep="backend\|adaptive" | wc -l 2>/dev/null || echo "0")
        frontend_commits=$(git log --oneline -30 --grep="frontend\|react\|ui" | wc -l 2>/dev/null || echo "0")
        ios_commits=$(git log --oneline -30 --grep="ios\|swift" | wc -l 2>/dev/null || echo "0")
        
        echo "  Backend-related commits (last 30): $backend_commits"
        echo "  Frontend-related commits (last 30): $frontend_commits"
        echo "  iOS-related commits (last 30): $ios_commits"
        
        # Most active files
        echo -e "\n${BLUE}Most Modified Files (last 20 commits):${NC}"
        git log --pretty=format: --name-only -20 | sort | uniq -c | sort -rg | head -5 | while read count file; do
            if [ ! -z "$file" ]; then
                echo "  $file: $count changes"
            fi
        done
    fi
}

branch_impact_analysis() {
    log_header "BRANCH IMPACT ANALYSIS"
    
    local original_dir=$(pwd)
    local found_repos=()
    
    # Check all possible git directories
    local git_dirs=("." "$BACKEND_DIR" "$FRONTEND_DIR" "$IOS_DIR")
    
    for dir in "${git_dirs[@]}"; do
        if [ -d "$dir/.git" ]; then
            found_repos+=("$dir")
        fi
    done
    
    if [ ${#found_repos[@]} -eq 0 ]; then
        log_error "No git repositories found in project"
        echo "Checked:"
        echo "  - Current directory"
        echo "  - $BACKEND_DIR"
        echo "  - $FRONTEND_DIR"
        echo "  - $IOS_DIR"
        return 1
    fi
    
    echo -e "${CYAN}🔍 Found ${#found_repos[@]} git repositories:${NC}"
    for repo in "${found_repos[@]}"; do
        echo "  - $repo"
    done
    echo ""
    
    # Analyze each repository
    for git_dir in "${found_repos[@]}"; do
        echo -e "${PURPLE}📁 Analyzing repository: $git_dir${NC}"
        echo -e "${PURPLE}$(printf '=%.0s' {1..50})${NC}"
        
        # Change to git directory for analysis
        cd "$git_dir"
        
        # Get current branch and compare to main/master
        current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
        main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
        
        echo -e "${CYAN}🌿 Current Branch: ${current_branch}${NC}"
        echo -e "${CYAN}📊 Comparing to: ${main_branch}${NC}"
        
        # Get changed files
        changed_files=$(git diff --name-only $main_branch..HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")
        
        if [ -z "$changed_files" ]; then
            log_success "No changes detected - branch is clean!"
            echo ""
            cd "$original_dir"
            continue
        fi
        
        echo -e "\n${CYAN}📁 Changed Files:${NC}"
        echo "$changed_files" | sed 's/^/  /'
        
        # Platform impact analysis
        echo -e "\n${CYAN}🎯 Platform Impact:${NC}"
        
        # For current repository changes, we look at the changed files relative to the repo
        if [ "$git_dir" = "$BACKEND_DIR" ]; then
            backend_changes=$(echo "$changed_files" | wc -l)
            frontend_changes=0
            ios_changes=0
            script_changes=0
        elif [ "$git_dir" = "$FRONTEND_DIR" ]; then
            backend_changes=0
            frontend_changes=$(echo "$changed_files" | wc -l)
            ios_changes=0
            script_changes=0
        elif [ "$git_dir" = "$IOS_DIR" ]; then
            backend_changes=0
            frontend_changes=0
            ios_changes=$(echo "$changed_files" | wc -l)
            script_changes=0
        else
            # Root directory - check all platforms
            backend_changes=$(echo "$changed_files" | grep "adaptive-backend" | wc -l)
            frontend_changes=$(echo "$changed_files" | grep "aswb-lcsw-quiz-app" | wc -l)
            ios_changes=$(echo "$changed_files" | grep "SWTPA" | wc -l)
            script_changes=$(echo "$changed_files" | grep "scripts" | wc -l)
        fi
        
        if [ $backend_changes -gt 0 ]; then
            echo -e "  ${BLUE}Backend:${NC} $backend_changes files changed"
            echo "    🧪 Required: Backend tests"
            echo "    🚀 Required: Function deployment review"
        fi
        
        if [ $frontend_changes -gt 0 ]; then
            echo -e "  ${BLUE}Frontend:${NC} $frontend_changes files changed"
            echo "    🧪 Required: E2E tests"
            echo "    📦 Required: Bundle size check"
        fi
        
        if [ $ios_changes -gt 0 ]; then
            echo -e "  ${BLUE}iOS:${NC} $ios_changes files changed"
            echo "    🧪 Required: iOS build verification"
            echo "    📱 Required: Device testing"
        fi
        
        if [ $script_changes -gt 0 ]; then
            echo -e "  ${BLUE}Scripts/Tooling:${NC} $script_changes files changed"
            echo "    🔧 Required: Toolkit verification"
        fi
        
        # Generate PR template
        echo -e "\n${CYAN}📝 Suggested PR Template:${NC}"
        
        # Determine PR type
        if [ $backend_changes -gt 0 ] && [ $frontend_changes -gt 0 ]; then
            pr_type="Full Stack"
        elif [ $backend_changes -gt 0 ]; then
            pr_type="Backend"
        elif [ $frontend_changes -gt 0 ]; then
            pr_type="Frontend"
        elif [ $ios_changes -gt 0 ]; then
            pr_type="iOS"
        else
            pr_type="Other"
        fi
        
        echo ""
        echo "## $pr_type Changes"
        echo ""
        echo "### 🎯 Summary"
        echo "<!-- Brief description of changes -->"
        echo ""
        
        if [ $backend_changes -gt 0 ]; then
            echo "### 🔧 Backend Changes"
            echo "- [ ] Cloud Functions updated"
            echo "- [ ] Tests passing"
            echo "- [ ] Deployment verified"
            echo ""
        fi
        
        if [ $frontend_changes -gt 0 ]; then
            echo "### 🌐 Frontend Changes"
            echo "- [ ] Components updated"
            echo "- [ ] E2E tests passing"
            echo "- [ ] Bundle size acceptable"
            echo ""
        fi
        
        if [ $ios_changes -gt 0 ]; then
            echo "### 📱 iOS Changes"
            echo "- [ ] Build successful"
            echo "- [ ] UI tests passing"
            echo "- [ ] Device testing complete"
            echo ""
        fi
        
        echo "### 🧪 Testing"
        echo "- [ ] Unit tests pass"
        echo "- [ ] Integration tests pass"
        echo "- [ ] Manual testing complete"
        echo ""
        echo "### 📋 Files Changed"
        echo "$changed_files" | sed 's/^/- /'
        
        # Suggest reviewers based on file ownership
        echo -e "\n${CYAN}👥 Suggested Reviewers:${NC}"
        if [ $backend_changes -gt 0 ]; then
            echo "  Backend specialist (adaptive algorithms, Firebase)"
        fi
        if [ $frontend_changes -gt 0 ]; then
            echo "  Frontend specialist (React, UX/UI)"
        fi
        if [ $ios_changes -gt 0 ]; then
            echo "  iOS specialist (SwiftUI, native development)"
        fi
        if [[ "$changed_files" == *"adaptive-core"* ]]; then
            echo "  🎯 Core algorithm reviewer (critical system changes)"
        fi
        
        echo ""
        echo -e "${PURPLE}$(printf '=%.0s' {1..50})${NC}"
        echo ""
        
        # Return to original directory before next iteration
        cd "$original_dir"
    done
    
    # Final directory restoration (in case of early exit)
    cd "$original_dir"
}

find_todos() {
    log_header "TECHNICAL DEBT ANALYSIS"
    
    echo -e "${CYAN}📝 TODO Items:${NC}"
    "$RG_CMD" "TODO|FIXME|HACK|XXX" . --line-number 2>/dev/null | head -10 || echo "  No TODO items found"
    
    echo -e "\n${CYAN}🔧 Potential Issues:${NC}"
    "$RG_CMD" "console\.(log|error|warn)" $BACKEND_DIR $FRONTEND_DIR --line-number 2>/dev/null | head -10 || echo "  No console statements found"
    
    echo -e "\n${CYAN}🔐 Security Patterns:${NC}"
    "$RG_CMD" "(password|secret|api.?key|token)" $BACKEND_DIR $FRONTEND_DIR --line-number --ignore-case 2>/dev/null | head -5 || echo "  No obvious security issues found"
}

search_codebase() {
    local pattern="$1"
    local context="${2:-3}"
    
    if [ -z "$pattern" ]; then
        log_error "Usage: search <pattern> [context_lines]"
        return 1
    fi
    
    log_header "CODEBASE SEARCH: '$pattern'"
    
    echo -e "${CYAN}🔍 Search Results:${NC}"
    
    # Enhanced search with fallback strategy
    if command -v rg >/dev/null 2>&1; then
        # Use ripgrep with context lines and better formatting
        rg "$pattern" . --context "$context" --heading --line-number --color=always 2>/dev/null | head -30 || echo "  No matches found"
    else
        # Fallback to grep with context
        grep -r "$pattern" . --line-number --color=always -A "$context" -B "$context" 2>/dev/null | head -20 || echo "  No matches found"
    fi
}

find_files() {
    local pattern="$1"
    
    if [ -z "$pattern" ]; then
        log_error "Usage: find-files <pattern>"
        return 1
    fi
    
    log_header "FILE SEARCH: '$pattern'"
    
    echo -e "${CYAN}📁 Matching Files:${NC}"
    fd "$pattern" --type f --color=always
}

show_tree() {
    local depth="${1:-full}"
    
    log_header "PROJECT TREE VIEW"
    
    case "$depth" in
        "overview"|"o"|"2")
            echo -e "${CYAN}📁 Project Overview (2 levels):${NC}"
            tree -L 2 -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
            ;;
        "medium"|"m"|"4")
            echo -e "${CYAN}📁 Project Structure (4 levels):${NC}"
            tree -L 4 -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
            ;;
        "full"|"f"|"deep")
            echo -e "${CYAN}📁 Complete Project Tree (all levels):${NC}"
            tree -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
            ;;
        *)
            echo -e "${CYAN}📁 Project Tree ($depth levels):${NC}"
            tree -L "$depth" -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
            ;;
    esac
}

view_file() {
    local file="$1"
    local lines="${2:-50}"
    
    if [ -z "$file" ]; then
        log_error "Usage: view <file> [lines]"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    log_header "FILE VIEWER: $file"
    
    bat --line-range=1:$lines --color=always "$file"
    
    # Show file info
    echo -e "\n${CYAN}📊 File Info:${NC}"
    wc -l "$file" | awk '{print "  Lines: " $1}'
    ls -lh "$file" | awk '{print "  Size: " $5}'
    file "$file" | cut -d: -f2 | sed 's/^[[:space:]]*/  Type: /'
}

quick_health_check() {
    log_header "PROJECT HEALTH CHECK"
    
    # Check for package.json files
    echo -e "${CYAN}📦 Package Files:${NC}"
    for dir in $BACKEND_DIR $FRONTEND_DIR; do
        if [ -f "$dir/package.json" ]; then
            log_success "$dir/package.json exists"
        else
            log_warning "$dir/package.json missing"
        fi
    done
    
    # Check for key configuration files
    echo -e "\n${CYAN}⚙️  Configuration Files:${NC}"
    
    config_files=(
        "$BACKEND_DIR/firebase.json"
        "$BACKEND_DIR/tsconfig.json"
        "$FRONTEND_DIR/vite.config.ts"
        "$FRONTEND_DIR/tsconfig.json"
        "CLAUDE.md"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "$file exists"
        else
            log_warning "$file missing"
        fi
    done
    
    # Check node_modules
    echo -e "\n${CYAN}📚 Dependencies:${NC}"
    for dir in $BACKEND_DIR $FRONTEND_DIR; do
        if [ -d "$dir/node_modules" ]; then
            log_success "$dir dependencies installed"
        else
            log_warning "$dir dependencies need installation"
        fi
    done
}

generate_dev_summary() {
    log_header "DEVELOPMENT SUMMARY REPORT"
    
    local output_file="dev-summary-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# SWTPA Development Summary"
        echo "Generated: $(date)"
        echo ""
        
        echo "## Project Structure"
        echo '```'
        tree -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst
        echo '```'
        echo ""
        
        echo "## Codebase Statistics"
        echo "### Backend"
        echo "- TypeScript files: $(fd --type f --extension ts $BACKEND_DIR/src | wc -l | xargs)"
        echo "- JavaScript files: $(fd --type f --extension js $BACKEND_DIR/src | wc -l | xargs)"
        
        echo ""
        echo "### Frontend"
        echo "- React components: $(fd --type f --extension tsx $FRONTEND_DIR/src | wc -l | xargs)"
        echo "- TypeScript files: $(fd --type f --extension ts $FRONTEND_DIR/src | wc -l | xargs)"
        
        echo ""
        echo "## Technical Debt"
        echo '```'
        "$RG_CMD" "TODO|FIXME|HACK" . 2>/dev/null | wc -l | xargs echo "Technical debt items:" || echo "No technical debt markers found"
        echo '```'
        
        echo ""
        echo "## Recent Changes"
        echo '```'
        git log --oneline -10 2>/dev/null || echo "Git log not available"
        echo '```'
        
    } > "$output_file"
    
    log_success "Development summary saved to: $output_file"
    
    # Also display with bat for immediate viewing
    bat "$output_file"
}

performance_check() {
    log_header "PERFORMANCE ANALYSIS"
    
    echo -e "${CYAN}📊 Bundle Sizes:${NC}"
    
    # Frontend bundle analysis
    if [ -d "$FRONTEND_DIR/dist" ]; then
        echo -e "${BLUE}Frontend bundles:${NC}"
        fd --type f --extension js --extension css $FRONTEND_DIR/dist/assets | while read file; do
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "  $(basename "$file"): $size"
        done
    else
        log_warning "Frontend not built yet (run: cd $FRONTEND_DIR && npm run build)"
    fi
    
    # Check for large files
    echo -e "\n${CYAN}📁 Large Files (>1MB):${NC}"
    fd --type f --size +1M | head -5 | while read file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "  $file: $size"
    done || echo "  No large files found"
    
    # Image optimization opportunities
    echo -e "\n${CYAN}🖼️  Image Optimization Opportunities:${NC}"
    fd --type f --extension png --extension jpg --extension jpeg public/ | while read file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "  $file: $size"
    done 2>/dev/null || echo "  No images found in public directory"
}

# New sub-commands (o3 blueprint)
tree_command() {
    local dir="${1:-.}"
    local depth="${2:-2}"
    
    if [ ! -d "$dir" ]; then
        log_error "Directory not found: $dir"
        return 1
    fi
    
    log_header "PROJECT TREE: $dir (depth $depth)"
    tree -L "$depth" -I 'node_modules|coverage|dist|build|lib|.git|.next|__pycache__|*.pyc|.DS_Store' --dirsfirst "$dir"
}

slice_command() {
    local file="$1"
    local start="${2:-1}"
    local end="${3:-50}"
    
    if [ -z "$file" ]; then
        log_error "Usage: slice <file> [start] [end]"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    log_header "FILE SLICE: $file (lines $start-$end)"
    sed -n "${start},${end}p" "$file" | nl -ba -v"$start"
}

cheatsheet_command() {
    if is_json_output "$@"; then
        # JSON output
        cat <<EOF
{
  "project": "Social Work Test Prep Academy",
  "codebases": 3,
  "entrypoints": {
    "backend": "adaptive-backend/src/index.ts",
    "frontend": "aswb-lcsw-quiz-app/src/main.tsx",
    "ios": "SWTPA/SWTPAApp.swift"
  },
  "commands": {
    "build": {
      "backend": "cd adaptive-backend && npm run build",
      "frontend": "cd aswb-lcsw-quiz-app && npm run build"
    },
    "test": {
      "backend": "cd adaptive-backend && npm test",
      "frontend": "cd aswb-lcsw-quiz-app && npm test"
    },
    "deploy": {
      "backend": "firebase deploy --only functions",
      "frontend": "npm run build"
    }
  },
  "prod_url": "socialworktestprepacademy.com",
  "docs": ["CLAUDE.md", "PRODUCT.md", "TECHNICAL.md"]
}
EOF
    else
        # Regular output
        log_header "SWTPA PROJECT CHEATSHEET"
        
        echo "• Project: Social Work Test Prep Academy (3 codebases)"
        echo "• Entrypoints: adaptive-backend/src/index.ts, aswb-lcsw-quiz-app/src/main.tsx, SWTPA/SWTPAApp.swift"
        echo "• Build: cd adaptive-backend && npm run build; cd ../aswb-lcsw-quiz-app && npm run build"
        echo "• Test: cd adaptive-backend && npm test; cd ../aswb-lcsw-quiz-app && npm test"
        echo "• Deploy: firebase deploy --only functions (backend), npm run build (frontend)"
        echo "• Prod URL: socialworktestprepacademy.com"
        echo "• Docs: CLAUDE.md, PRODUCT.md, TECHNICAL.md"
    fi
}

drift_command() {
    log_header "VERSION DRIFT ANALYSIS"
    
    echo -e "${CYAN}🔍 Checking version mismatches across codebases...${NC}"
    
    # TypeScript versions
    echo -e "\n${BLUE}TypeScript Versions:${NC}"
    backend_ts=$(jq -r '.devDependencies.typescript // .dependencies.typescript // "not found"' $BACKEND_DIR/package.json 2>/dev/null)
    frontend_ts=$(jq -r '.devDependencies.typescript // .dependencies.typescript // "not found"' $FRONTEND_DIR/package.json 2>/dev/null)
    
    echo "  Backend:  $backend_ts"
    echo "  Frontend: $frontend_ts"
    
    if [ "$backend_ts" != "$frontend_ts" ]; then
        echo -e "  ${RED}❌ MISMATCH: TypeScript versions differ${NC}"
    else
        echo -e "  ${GREEN}✅ TypeScript versions match${NC}"
    fi
    
    # Firebase versions
    echo -e "\n${BLUE}Firebase Versions:${NC}"
    backend_firebase=$(jq -r '.dependencies["firebase-admin"] // "not found"' $BACKEND_DIR/package.json 2>/dev/null)
    frontend_firebase=$(jq -r '.dependencies["firebase"] // "not found"' $FRONTEND_DIR/package.json 2>/dev/null)
    
    echo "  Backend:  firebase-admin@$backend_firebase"
    echo "  Frontend: firebase@$frontend_firebase"
    
    # TODO: Add more version checks (React, Vite, etc.)
}

peek_command() {
    # Set token cap (default 3500, configurable via environment)
    local token_cap="${PEEK_TOKEN_CAP:-3500}"
    local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local json_output="${2:-}"
    
    if [[ "$json_output" == "--json" ]]; then
        # JSON output
        echo '{"interface_peeks":{'
        echo '"token_cap":'$token_cap','
        echo '"git_sha":"'$git_sha'",'
        echo '"files":['
        
        local first=true
        for dir in "$BACKEND_DIR/src" "$FRONTEND_DIR/src"; do
            [[ -d "$dir" ]] || continue
            
            # Find TypeScript files with exports
            local files=$(find "$dir" -name "*.ts" -o -name "*.tsx" | 
                         grep -v -E "(test|__tests__|coverage|dist|build)" | 
                         head -10)
            
            for file in $files; do
                if grep -q "export" "$file" 2>/dev/null; then
                    [[ $first == false ]] && echo ','
                    echo -n '{"path":"'$file'",'
                    echo -n '"signatures":'
                    # Extract first 40 lines containing exports/interfaces/types
                    local sigs=$(grep -E "^(export|interface|type|class|function)" "$file" 2>/dev/null | head -5 | jq -Rs .)
                    echo -n "$sigs}"
                    first=false
                fi
            done
        done
        echo ']}}'  
    else
        # Original output with gen-interface-peeks.js fallback
        log_header "INTERFACE PEEKS (capped at $token_cap tokens)"
        
        # Try to use the Node.js script if it exists
        if [[ -f "scripts/gen-interface-peeks.js" ]]; then
            export PEEK_TOKEN_CAP="$token_cap"
            export GIT_SHA="$git_sha"
            node scripts/gen-interface-peeks.js
        else
            # Native bash implementation
            echo -e "${CYAN}### 🔍 Interface Peeks${NC}\n"
            
            local token_count=0
            for dir in "$BACKEND_DIR/src" "$FRONTEND_DIR/src"; do
                [[ -d "$dir" ]] || continue
                
                echo -e "${BLUE}#### ${dir%/src}${NC}\n"
                
                # Find key TypeScript files
                local files=$(find "$dir" -name "index.ts" -o -name "types.ts" -o -name "*.service.ts" | 
                             grep -v test | head -5)
                
                for file in $files; do
                    local rel_path="${file#./}"
                    echo -e "${YELLOW}// $rel_path${NC}"
                    
                    # Extract signatures (exports, interfaces, types, classes)
                    grep -E "^(export|interface|type|class|function)" "$file" 2>/dev/null | head -10 || true
                    echo ""
                    
                    # Simple token estimation
                    ((token_count += 100))
                    [[ $token_count -gt $token_cap ]] && break 2
                done
            done
        fi
    fi
}

hotspots_command() {
    log_header "CODE HOTSPOTS ANALYSIS"
    
    echo -e "${CYAN}🔥 Most frequently changed files (last 100 commits):${NC}"
    echo ""
    
    # Check each repo separately
    for repo_dir in "$BACKEND_DIR" "$FRONTEND_DIR" "$IOS_DIR"; do
        if [ -d "$repo_dir/.git" ]; then
            echo -e "${BLUE}Repository: $repo_dir${NC}"
            (cd "$repo_dir" && git log --name-only --pretty="" -100 | \
            grep -v "^$" | \
            sort | uniq -c | sort -nr | head -10 | \
            while read count file; do
                echo -e "  ${YELLOW}$count${NC} changes: $file"
            done)
            echo ""
        fi
    done
}

graph_command() {
    log_header "DEPENDENCY GRAPH ANALYSIS"
    
    echo -e "${CYAN}🕸️  Simple dependency analysis:${NC}"
    echo ""
    
    # Note: RG_CMD is set at top of script
    
    # Backend imports analysis
    echo -e "${BLUE}Backend imports:${NC}"
    if [ -d "$BACKEND_DIR/src" ]; then
        if [ -x "/Users/jordanjackson/.claude/local/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin/rg" ]; then
            "$RG_CMD" "^import.*from ['\"]" "$BACKEND_DIR/src" --no-heading | \
            sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/" | \
            sort | uniq -c | sort -nr | head -10 | \
            while read count import; do
                echo "  $count: $import"
            done
        else
            # Fallback to grep
            grep -r "^import.*from ['\"]" "$BACKEND_DIR/src" | \
            sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/" | \
            sort | uniq -c | sort -nr | head -10 | \
            while read count import; do
                echo "  $count: $import"
            done
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Frontend imports:${NC}"
    if [ -d "$FRONTEND_DIR/src" ]; then
        if [ -x "/Users/jordanjackson/.claude/local/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin/rg" ]; then
            "$RG_CMD" "^import.*from ['\"]" "$FRONTEND_DIR/src" --no-heading | \
            sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/" | \
            sort | uniq -c | sort -nr | head -10 | \
            while read count import; do
                echo "  $count: $import"
            done
        else
            # Fallback to grep  
            grep -r "^import.*from ['\"]" "$FRONTEND_DIR/src" | \
            sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/" | \
            sort | uniq -c | sort -nr | head -10 | \
            while read count import; do
                echo "  $count: $import"
            done
        fi
    fi
}

runtime_flow_command() {
    log_header "SWTPA RUNTIME ARCHITECTURE FLOW"
    
    echo -e "${CYAN}📊 Generated runtime flow diagram:${NC}"
    echo ""
    echo "  File: runtime-flow.mmd"
    echo "  View in: GitHub, VS Code (Mermaid Preview), or mermaid.live"
    echo ""
    
    if [ -f "runtime-flow.mmd" ]; then
        echo -e "${GREEN}✅ runtime-flow.mmd already exists${NC}"
        echo ""
        echo -e "${BLUE}Architecture Overview:${NC}"
        echo "  🌐 Frontend (React) → ⚡ Cloud Functions → 🧠 Adaptive Engine → 🗄️ Firestore"
        echo "  📱 iOS (Future) → ⚡ Cloud Functions → 🧠 Adaptive Engine → 🗄️ Firestore"
        echo ""
        echo -e "${CYAN}Key Components:${NC}"
        echo "  • initializeQuizSession: Creates adaptive learning state"
        echo "  • getNextQuestion: AI-powered question selection"
        echo "  • answerQuestion: Processes responses & adjusts difficulty"
        echo "  • Adaptive Core: Machine learning algorithms for personalization"
        echo ""
        echo -e "${YELLOW}💡 View diagram:${NC}"
        echo "  • GitHub: Will render automatically"
        echo "  • VS Code: Install 'Mermaid Preview' extension"
        echo "  • Online: Copy content to https://mermaid.live"
    else
        echo -e "${RED}❌ runtime-flow.mmd not found${NC}"
        echo "Run this command from the project root directory"
    fi
}

# Enhanced E2E test runner (replaces run-complete-e2e.js)
run_complete_e2e() {
    log_header "COMPLETE E2E TEST SUITE"
    
    echo -e "${CYAN}🧪 This replaces scripts/run-complete-e2e.js with native bash${NC}"
    echo ""
    
    # Check if emulators are running
    if curl -s http://127.0.0.1:4000 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Firebase emulators already running${NC}"
    else
        echo -e "${YELLOW}⚠️  Firebase emulators not detected${NC}"
        echo "Start them with: cd adaptive-backend && npm run emulators:start"
        return 1
    fi
    
    # Check if frontend is running
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Frontend already running${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend not detected${NC}"
        echo "Start it with: cd aswb-lcsw-quiz-app && npm run dev"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Running E2E tests...${NC}"
    
    # Run backend E2E tests
    echo -e "${CYAN}1. Backend E2E Tests${NC}"
    (cd "$BACKEND_DIR" && npm run test:e2e) || {
        echo -e "${RED}❌ Backend E2E tests failed${NC}"
        return 1
    }
    
    # Run frontend E2E tests
    echo -e "${CYAN}2. Frontend E2E Tests${NC}"
    (cd "$FRONTEND_DIR" && npx playwright test) || {
        echo -e "${RED}❌ Frontend E2E tests failed${NC}"
        return 1
    }
    
    echo ""
    echo -e "${GREEN}🎉 All E2E tests passed!${NC}"
}

# Interactive CLI mode (replaces dev-cli.js)
run_interactive_cli() {
    log_header "INTERACTIVE DEV CLI MODE"
    
    echo -e "${CYAN}🤖 Welcome to SWTPA Interactive CLI${NC}"
    echo -e "${YELLOW}Type 'help' for commands, 'exit' to quit${NC}"
    echo ""
    
    while true; do
        echo -en "${GREEN}dev> ${NC}"
        read -r cmd args
        
        case "$cmd" in
            "exit"|"quit"|"q")
                echo -e "${CYAN}👋 Goodbye!${NC}"
                break
                ;;
            "help"|"h")
                echo -e "${CYAN}🚀 Interactive Commands:${NC}"
                echo "  expand <dir> [depth] - Show directory tree"
                echo "  dump <file> [start] [end] - View file slice"
                echo "  overview - Project cheatsheet"
                echo "  versions - Version drift analysis"
                echo "  peeks - Interface signatures"
                echo "  exit - Quit the CLI"
                ;;
            "expand")
                tree_command $args
                ;;
            "dump")
                slice_command $args
                ;;
            "overview")
                cheatsheet_command
                ;;
            "versions")
                drift_command
                ;;
            "peeks")
                peek_command
                ;;
            "")
                continue
                ;;
            *)
                # Pass through to main script
                "$0" "$cmd" $args
                ;;
        esac
        echo ""
    done
}

# Generate Claude context snapshot
generate_claude_context() {
    local output_file="${2:-/tmp/swtpa-context.json}"
    
    if [[ "$2" == "--help" ]]; then
        echo "Usage: ./scripts/dev-toolkit.sh context [output_file]"
        echo "Default output: /tmp/swtpa-context.json"
        echo ""
        echo "Creates a comprehensive JSON context snapshot for Claude sessions"
        return 0
    fi
    
    log_header "GENERATING CLAUDE CONTEXT"
    
    echo -e "${CYAN}🤖 Creating context snapshot...${NC}"
    
    # Generate JSON context
    cat > "$output_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project": {
    "name": "Social Work Test Prep Academy",
    "codebases": 3,
    "backend_files": $(find "$BACKEND_DIR/src" -name "*.ts" 2>/dev/null | wc -l | xargs),
    "frontend_files": $(find "$FRONTEND_DIR/src" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l | xargs),
    "ios_files": $(find "$IOS_DIR" -name "*.swift" 2>/dev/null | wc -l | xargs || echo 0)
  },
  "versions": {
    "backend_typescript": "$(jq -r '.devDependencies.typescript // "unknown"' "$BACKEND_DIR/package.json" 2>/dev/null || echo 'unknown')",
    "frontend_typescript": "$(jq -r '.devDependencies.typescript // "unknown"' "$FRONTEND_DIR/package.json" 2>/dev/null || echo 'unknown')",
    "backend_firebase_admin": "$(jq -r '.dependencies["firebase-admin"] // "unknown"' "$BACKEND_DIR/package.json" 2>/dev/null || echo 'unknown')",
    "frontend_firebase": "$(jq -r '.dependencies.firebase // "unknown"' "$FRONTEND_DIR/package.json" 2>/dev/null || echo 'unknown')"
  },
  "entrypoints": {
    "backend": "adaptive-backend/src/index.ts",
    "frontend": "aswb-lcsw-quiz-app/src/main.tsx",
    "ios": "SWTPA/SWTPA/SWTPAApp.swift"
  },
  "key_files": [
    "CLAUDE.md",
    "adaptive-backend/src/index.ts",
    "aswb-lcsw-quiz-app/src/services/QuizApiService.ts",
    "SWTPA/SWTPA/Services/BackendAPIService.swift"
  ],
  "commands": {
    "analyze": "./scripts/dev-toolkit.sh analyze",
    "health": "./scripts/dev-toolkit.sh health",
    "cross_platform": "./scripts/dev-toolkit.sh cross-platform",
    "branch_impact": "./scripts/dev-toolkit.sh branch-impact"
  }
}
EOF
    
    echo -e "${GREEN}✓ Context saved to: $output_file${NC}"
    echo ""
    echo -e "${CYAN}Usage with Claude:${NC}"
    echo "1. Copy the contents: cat $output_file | pbcopy"
    echo "2. Paste at the beginning of your Claude conversation"
    echo "3. Claude will have instant project context!"
    echo ""
    echo -e "${YELLOW}Tip: Create an alias for quick access:${NC}"
    echo "alias ctx='./scripts/dev-toolkit.sh context && cat /tmp/swtpa-context.json | pbcopy && echo "📋 Context copied to clipboard!"'"
}

# Intelligent Error Diagnosis
diagnose_error_command() {
    local error_type="${1:-auto}"
    local error_message="${2:-}"
    
    log_header "INTELLIGENT ERROR DIAGNOSIS"
    
    echo -e "${CYAN}🔍 Analyzing potential issues...${NC}"
    echo ""
    
    # Auto-detect error type if not specified
    if [ "$error_type" = "auto" ]; then
        echo -e "${BLUE}🤖 Auto-detecting error patterns:${NC}"
        
        # Check for recent compilation errors
        if [ -f "$BACKEND_DIR/firebase-debug.log" ] || [ -f "$FRONTEND_DIR/firestore-debug.log" ]; then
            echo "  • Firebase/Firestore debug logs detected"
            error_type="firebase"
                 elif [ ! -d "$BACKEND_DIR/lib" ]; then
             echo "  • Backend compilation issues detected"
             error_type="compilation"
        elif [ -f "$FRONTEND_DIR/dist" ] && [ ! -d "$FRONTEND_DIR/dist" ]; then
            echo "  • Frontend build issues detected"
            error_type="build"
        elif [ -f "playwright-report" ] || [ -f "$FRONTEND_DIR/test-results" ]; then
            echo "  • Test failure artifacts detected"
            error_type="test"
        else
            echo "  • No obvious error patterns found, running comprehensive analysis"
            error_type="comprehensive"
        fi
        echo ""
    fi
    
    case "$error_type" in
        "firebase"|"emulator"|"functions")
            diagnose_firebase_errors
            ;;
        "compilation"|"typescript"|"ts")
            diagnose_compilation_errors
            ;;
        "build"|"bundler"|"vite")
            diagnose_build_errors
            ;;
        "test"|"jest"|"vitest"|"playwright")
            diagnose_test_errors
            ;;
        "dependency"|"deps"|"npm")
            diagnose_dependency_errors
            ;;
        "runtime"|"cors"|"auth")
            diagnose_runtime_errors
            ;;
        "comprehensive"|"full")
            diagnose_comprehensive_errors
            ;;
        *)
            diagnose_specific_error "$error_type" "$error_message"
            ;;
    esac
    
    echo -e "\n${CYAN}🎯 Quick Fix Commands:${NC}"
    echo "  ./scripts/dev-toolkit.sh health     # Check project health"
    echo "  ./scripts/dev-toolkit.sh drift     # Check version mismatches"
    echo "  ./scripts/dev-toolkit.sh hotspots  # Find most changed files"
    echo "  ./scripts/dev-toolkit.sh cross-platform  # Check cross-platform issues"
}

diagnose_firebase_errors() {
    echo -e "${BLUE}🔥 Firebase Error Analysis:${NC}"
    
    # Check Firebase debug logs
    local firebase_logs=()
    [ -f "$BACKEND_DIR/firebase-debug.log" ] && firebase_logs+=("$BACKEND_DIR/firebase-debug.log")
    [ -f "$FRONTEND_DIR/firestore-debug.log" ] && firebase_logs+=("$FRONTEND_DIR/firestore-debug.log")
    [ -f "firebase-debug.log" ] && firebase_logs+=("firebase-debug.log")
    
    if [ ${#firebase_logs[@]} -gt 0 ]; then
        echo "  📄 Found Firebase debug logs:"
        for log in "${firebase_logs[@]}"; do
            echo "    • $log"
            # Check for common Firebase errors
            if [ -f "$log" ]; then
                echo "    Last 5 lines:"
                tail -5 "$log" | sed 's/^/      /'
            fi
        done
    fi
    
    echo ""
    echo -e "${YELLOW}⚡ Common Firebase Issues & Solutions:${NC}"
    
    # Check emulator status
    if curl -s http://127.0.0.1:4000 >/dev/null 2>&1; then
        echo "  ✅ Firebase emulators are running"
    else
        echo "  ❌ Firebase emulators not running"
        echo "     Fix: cd $BACKEND_DIR && npm run emulators:start"
    fi
    
    # Check Firebase configuration
    if [ -f "$BACKEND_DIR/firebase.json" ]; then
        echo "  ✅ Backend Firebase config exists"
    else
        echo "  ❌ Backend Firebase config missing"
        echo "     Fix: Check $BACKEND_DIR/firebase.json"
    fi
    
    # Check service account
    if [ -f "$BACKEND_DIR/firebase-service-account.json" ]; then
        echo "  ✅ Firebase service account configured"
    else
        echo "  ⚠️  Firebase service account not found"
        echo "     Fix: Add firebase-service-account.json to $BACKEND_DIR/"
    fi
    
         # Check function deployment status
     echo ""
     echo -e "${CYAN}🚀 Function Deployment Analysis:${NC}"
     if [ -d "$BACKEND_DIR/lib" ]; then
         echo "  ✅ Backend compiled successfully"
     else
         echo "  ❌ Backend compilation failed"
         echo "     Fix: cd $BACKEND_DIR && npm run build"
     fi
}

diagnose_compilation_errors() {
    echo -e "${BLUE}🔧 TypeScript Compilation Analysis:${NC}"
    
    # Check TypeScript versions
    local backend_ts=$(jq -r '.devDependencies.typescript // "unknown"' "$BACKEND_DIR/package.json" 2>/dev/null)
    local frontend_ts=$(jq -r '.devDependencies.typescript // "unknown"' "$FRONTEND_DIR/package.json" 2>/dev/null)
    
    echo "  TypeScript Versions:"
    echo "    Backend:  $backend_ts"
    echo "    Frontend: $frontend_ts"
    
    if [ "$backend_ts" != "$frontend_ts" ]; then
        echo "  ❌ TypeScript version mismatch detected!"
        echo "     Fix: Align TypeScript versions across codebases"
    else
        echo "  ✅ TypeScript versions match"
    fi
    
    echo ""
    echo -e "${CYAN}📁 Common TypeScript Issues:${NC}"
    
    # Check for missing types
    if "$RG_CMD" "Cannot find module.*or its corresponding type declarations" . 2>/dev/null | head -3; then
        echo "  ❌ Missing type declarations found"
        echo "     Fix: Install @types packages or add declarations"
    fi
    
    # Check for import/export issues
    if "$RG_CMD" "Module.*has no exported member" . 2>/dev/null | head -3; then
        echo "  ❌ Import/export issues found"
        echo "     Fix: Check export statements and import paths"
    fi
    
    # Check tsconfig.json files
    for dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
        if [ -f "$dir/tsconfig.json" ]; then
            echo "  ✅ $dir has tsconfig.json"
        else
            echo "  ❌ $dir missing tsconfig.json"
            echo "     Fix: Create tsconfig.json in $dir"
        fi
    done
}

diagnose_build_errors() {
    echo -e "${BLUE}📦 Build Process Analysis:${NC}"
    
    # Check build outputs
    if [ -d "$FRONTEND_DIR/dist" ]; then
        echo "  ✅ Frontend build output exists"
        echo "    Files: $(ls -la "$FRONTEND_DIR/dist" | wc -l) items"
    else
        echo "  ❌ Frontend build output missing"
        echo "     Fix: cd $FRONTEND_DIR && npm run build"
    fi
    
    if [ -d "$BACKEND_DIR/lib" ]; then
        echo "  ✅ Backend build output exists"
        echo "    Files: $(ls -la "$BACKEND_DIR/lib" | wc -l) items"
    else
        echo "  ❌ Backend build output missing"
        echo "     Fix: cd $BACKEND_DIR && npm run build"
    fi
    
    echo ""
    echo -e "${CYAN}🔍 Build Configuration Check:${NC}"
    
    # Check Vite config
    if [ -f "$FRONTEND_DIR/vite.config.ts" ]; then
        echo "  ✅ Vite configuration exists"
    else
        echo "  ❌ Vite configuration missing"
        echo "     Fix: Create vite.config.ts in $FRONTEND_DIR"
    fi
    
    # Check for build errors in package.json scripts
    echo ""
    echo -e "${YELLOW}📋 Build Scripts:${NC}"
    echo "  Backend: $(jq -r '.scripts.build // "not found"' "$BACKEND_DIR/package.json" 2>/dev/null)"
    echo "  Frontend: $(jq -r '.scripts.build // "not found"' "$FRONTEND_DIR/package.json" 2>/dev/null)"
}

diagnose_test_errors() {
    echo -e "${BLUE}🧪 Test Environment Analysis:${NC}"
    
    # Check test results
    local test_failures=()
    
    # Frontend test results
    if [ -d "$FRONTEND_DIR/test-results" ]; then
        test_failures+=("$FRONTEND_DIR/test-results")
        echo "  ❌ Frontend test failures detected"
    fi
    
    # Backend test results
    if [ -d "$BACKEND_DIR/coverage" ]; then
        echo "  ✅ Backend test coverage available"
    else
        echo "  ⚠️  Backend test coverage missing"
        echo "     Fix: cd $BACKEND_DIR && npm run test:coverage"
    fi
    
    # Check test configuration
    echo ""
    echo -e "${CYAN}⚙️  Test Configuration:${NC}"
    
    # Backend test config
    if [ -f "$BACKEND_DIR/jest.config.js" ]; then
        echo "  ✅ Backend Jest config exists"
    else
        echo "  ❌ Backend Jest config missing"
    fi
    
    # Frontend test config
    if [ -f "$FRONTEND_DIR/vitest.config.ts" ] || [ -f "$FRONTEND_DIR/vite.config.ts" ]; then
        echo "  ✅ Frontend Vitest config exists"
    else
        echo "  ❌ Frontend Vitest config missing"
    fi
    
    # Check for test failures
    if [ ${#test_failures[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ Test Failures Found:${NC}"
        for failure_dir in "${test_failures[@]}"; do
            echo "  📁 $failure_dir"
            if [ -d "$failure_dir" ]; then
                find "$failure_dir" -name "*.md" -o -name "*.html" | head -3 | while read report; do
                    echo "    • $(basename "$report")"
                done
            fi
        done
    fi
    
    echo ""
    echo -e "${YELLOW}🔧 Quick Test Fixes:${NC}"
    echo "  Backend: cd $BACKEND_DIR && npm test"
    echo "  Frontend: cd $FRONTEND_DIR && npm test"
    echo "  E2E: ./scripts/dev-toolkit.sh e2e"
}

diagnose_dependency_errors() {
    echo -e "${BLUE}📦 Dependency Analysis:${NC}"
    
    # Check node_modules
    for dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
        if [ -d "$dir/node_modules" ]; then
            echo "  ✅ $dir dependencies installed"
        else
            echo "  ❌ $dir dependencies missing"
            echo "     Fix: cd $dir && npm install"
        fi
    done
    
    # Check package-lock.json
    for dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
        if [ -f "$dir/package-lock.json" ]; then
            echo "  ✅ $dir has package-lock.json"
        else
            echo "  ⚠️  $dir missing package-lock.json"
            echo "     Fix: cd $dir && npm install"
        fi
    done
    
    echo ""
    echo -e "${CYAN}🔍 Version Conflicts:${NC}"
    
    # Run drift analysis
    drift_command
}

diagnose_runtime_errors() {
    echo -e "${BLUE}🚀 Runtime Environment Analysis:${NC}"
    
    # Check if services are running
    echo "  Service Status:"
    
    # Frontend
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "    ✅ Frontend (port 3000) running"
    else
        echo "    ❌ Frontend (port 3000) not running"
        echo "       Fix: cd $FRONTEND_DIR && npm run dev"
    fi
    
    # Backend emulators
    if curl -s http://127.0.0.1:4000 >/dev/null 2>&1; then
        echo "    ✅ Firebase emulators running"
    else
        echo "    ❌ Firebase emulators not running"
        echo "       Fix: cd $BACKEND_DIR && npm run emulators:start"
    fi
    
    # Check CORS issues
    echo ""
    echo -e "${CYAN}🌐 CORS & Authentication:${NC}"
    echo "  Common issues:"
    echo "    • CORS errors: Check Firebase Functions configuration"
    echo "    • Auth errors: Verify Firebase config in frontend"
    echo "    • API errors: Check function deployment status"
}

diagnose_comprehensive_errors() {
    echo -e "${BLUE}🔍 Comprehensive Error Analysis:${NC}"
    
    # Run all diagnostic checks
    diagnose_firebase_errors
    echo ""
    diagnose_compilation_errors
    echo ""
    diagnose_build_errors
    echo ""
    diagnose_test_errors
    echo ""
    diagnose_dependency_errors
    echo ""
    
    echo -e "${PURPLE}📊 Summary & Recommendations:${NC}"
    echo "  1. Check project health: ./scripts/dev-toolkit.sh health"
    echo "  2. Verify dependencies: ./scripts/dev-toolkit.sh cross-platform"
    echo "  3. Run tests: ./scripts/dev-toolkit.sh e2e"
    echo "  4. Check recent changes: ./scripts/dev-toolkit.sh branch-impact"
}

diagnose_specific_error() {
    local error_type="$1"
    local error_message="$2"
    
    echo -e "${BLUE}🎯 Specific Error Analysis: $error_type${NC}"
    
    if [ ! -z "$error_message" ]; then
        echo "  Error message: $error_message"
        echo ""
        
        # Analyze specific error patterns
        case "$error_message" in
            *"CORS"*|*"cors"*)
                echo "  🌐 CORS Error Detected"
                echo "    • Check Firebase Functions CORS configuration"
                echo "    • Verify frontend API endpoint URLs"
                echo "    • Ensure proper headers in requests"
                ;;
            *"Firebase"*|*"firebase"*)
                echo "  🔥 Firebase Error Detected"
                diagnose_firebase_errors
                ;;
            *"TypeScript"*|*"typescript"*|*"TS"*)
                echo "  📜 TypeScript Error Detected"
                diagnose_compilation_errors
                ;;
            *"Cannot find module"*|*"Module not found"*)
                echo "  📦 Module Resolution Error"
                echo "    • Check import paths"
                echo "    • Verify package installation"
                echo "    • Check tsconfig.json paths"
                ;;
            *)
                echo "  🔍 Analyzing error pattern..."
                # Search for similar errors in codebase
                if [ ! -z "$error_message" ]; then
                    echo "    Searching for similar patterns..."
                    "$RG_CMD" "$error_message" . 2>/dev/null | head -3 || echo "    No similar patterns found"
                fi
                ;;
        esac
    else
        echo "  No specific error message provided"
        echo "  Usage: ./scripts/dev-toolkit.sh diagnose-error auto \"Your error message here\""
         fi
 }
 
 # LLM Context Command - Instant Claude Onboarding
 llm_context_command() {
     local format="${1:-text}"
     
     if [[ "$format" == "--help" ]]; then
         echo "Usage: ./scripts/dev-toolkit.sh llm-context [format]"
         echo "Formats: text (default), markdown, clipboard"
         echo ""
         echo "Generates instant Claude onboarding context for SWTPA project"
         return 0
     fi
     
     local output_file="/tmp/swtpa-llm-context.md"
     local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
     local timestamp=$(date)
     
     # Generate comprehensive LLM context
     cat > "$output_file" <<EOF
# 🤖 CLAUDE INSTANT CONTEXT - SWTPA PROJECT

**Generated**: $timestamp  
**Git SHA**: $git_sha  
**Project**: Social Work Test Prep Academy (3 codebases)

## 🎯 CRITICAL FIRST ACTIONS
When you see this context, immediately run these commands for full project understanding:
\`\`\`bash
./scripts/dev-toolkit.sh cheatsheet    # Project overview
./scripts/dev-toolkit.sh health        # Project health check
./scripts/dev-toolkit.sh cross-platform # Cross-platform analysis
./scripts/dev-toolkit.sh diagnose-error # Error diagnosis
\`\`\`

## 📁 PROJECT STRUCTURE
- **Backend**: \`adaptive-backend/\` - Firebase Cloud Functions (TypeScript)
- **Frontend**: \`aswb-lcsw-quiz-app/\` - React + Vite (TypeScript/TSX)
- **iOS**: \`SWTPA/\` - SwiftUI Native App (Swift)

## 🔑 KEY ENTRY POINTS
- **Backend**: \`adaptive-backend/src/index.ts\` - All Cloud Functions
- **Frontend**: \`aswb-lcsw-quiz-app/src/main.tsx\` - React app entry
- **iOS**: \`SWTPA/SWTPA/SWTPAApp.swift\` - SwiftUI app entry

## 🧠 CORE BUSINESS LOGIC
- **Adaptive Engine**: \`adaptive-backend/src/adaptive-core/\` - AI learning algorithms
- **Quiz API**: \`aswb-lcsw-quiz-app/src/services/QuizApiService.ts\` - Main API interface
- **Session Management**: \`adaptive-backend/src/answerQuestion.ts\` - Answer processing

## 🔧 DEVELOPMENT COMMANDS
\`\`\`bash
# Analysis & Debugging
./scripts/dev-toolkit.sh analyze          # Full project analysis
./scripts/dev-toolkit.sh diagnose-error   # Intelligent error diagnosis
./scripts/dev-toolkit.sh cross-platform   # Cross-platform dependencies
./scripts/dev-toolkit.sh drift           # Version mismatch detection

# Code Investigation
./scripts/dev-toolkit.sh search <pattern> # Cross-platform search
./scripts/dev-toolkit.sh peek            # Interface signatures
./scripts/dev-toolkit.sh hotspots        # Most changed files

# Quick Context
./scripts/dev-toolkit.sh tree <dir> [depth] # Directory visualization
./scripts/dev-toolkit.sh slice <file> <start> <end> # File content with line numbers
\`\`\`

## 🚨 CURRENT ISSUES (Auto-detected)
EOF
     
     # Auto-detect current issues
     echo "Running auto-diagnosis..." >&2
     
     # Check TypeScript versions
     local backend_ts=$(jq -r '.devDependencies.typescript // "unknown"' "$BACKEND_DIR/package.json" 2>/dev/null)
     local frontend_ts=$(jq -r '.devDependencies.typescript // "unknown"' "$FRONTEND_DIR/package.json" 2>/dev/null)
     
     if [ "$backend_ts" != "$frontend_ts" ]; then
         echo "- **TypeScript Version Mismatch**: Backend ($backend_ts) vs Frontend ($frontend_ts)" >> "$output_file"
     fi
     
     # Check Firebase emulators
     if ! curl -s http://127.0.0.1:4000 >/dev/null 2>&1; then
         echo "- **Firebase Emulators Not Running**: \`cd adaptive-backend && npm run emulators:start\`" >> "$output_file"
     fi
     
     # Check for test failures
     if [ -d "$FRONTEND_DIR/test-results" ]; then
         echo "- **Frontend Test Failures**: Check \`$FRONTEND_DIR/test-results/\`" >> "$output_file"
     fi
     
     # Check build outputs
     if [ ! -d "$BACKEND_DIR/lib" ]; then
         echo "- **Backend Not Built**: \`cd adaptive-backend && npm run build\`" >> "$output_file"
     fi
     
     # Check for any obvious issues
     if [ -f "$BACKEND_DIR/firebase-debug.log" ] || [ -f "$FRONTEND_DIR/firestore-debug.log" ]; then
         echo "- **Firebase Debug Logs Present**: Check for errors in debug logs" >> "$output_file"
     fi
     
     # Add "No critical issues" if none found
     if [ ! -s "$output_file" ] || [ $(tail -1 "$output_file" | wc -c) -eq 0 ]; then
         echo "- **No Critical Issues Detected** ✅" >> "$output_file"
     fi
     
     # Continue with rest of context
     cat >> "$output_file" <<EOF

## 📊 PROJECT STATS
- **Backend Files**: $(find "$BACKEND_DIR/src" -name "*.ts" 2>/dev/null | wc -l | xargs) TypeScript files
- **Frontend Files**: $(find "$FRONTEND_DIR/src" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l | xargs) TypeScript/React files
- **iOS Files**: $(find "$IOS_DIR" -name "*.swift" 2>/dev/null | wc -l | xargs || echo 0) Swift files
- **Total Codebase**: $(($(find "$BACKEND_DIR/src" -name "*.ts" 2>/dev/null | wc -l) + $(find "$FRONTEND_DIR/src" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l) + $(find "$IOS_DIR" -name "*.swift" 2>/dev/null | wc -l || echo 0))) files

## 🔥 RECENT ACTIVITY
EOF
     
     # Add git activity if available
     if git rev-parse --git-dir > /dev/null 2>&1; then
         echo "**Recent commits:**" >> "$output_file"
         git log --oneline -5 2>/dev/null | sed 's/^/- /' >> "$output_file"
         echo "" >> "$output_file"
         
         echo "**Most active files:**" >> "$output_file"
         git log --pretty=format: --name-only -10 | sort | uniq -c | sort -rg | head -5 | while read count file; do
             if [ ! -z "$file" ]; then
                 echo "- $file ($count changes)" >> "$output_file"
             fi
         done
     else
         echo "- No git history available" >> "$output_file"
     fi
     
     cat >> "$output_file" <<EOF

## 🎯 ARCHITECTURE OVERVIEW
- **Backend-Driven Design**: All adaptive logic in Cloud Functions
- **Real-time Updates**: Firestore listeners for live state sync
- **Cross-Platform APIs**: Same endpoints for web and mobile
- **Adaptive Learning**: AI-powered question selection and difficulty adjustment

## 🚀 QUICK DEVELOPMENT WORKFLOW
1. **Start Services**: \`cd adaptive-backend && npm run emulators:start\`
2. **Start Frontend**: \`cd aswb-lcsw-quiz-app && npm run dev\`
3. **Run Tests**: \`./scripts/dev-toolkit.sh e2e\`
4. **Check Health**: \`./scripts/dev-toolkit.sh health\`

## 📚 ESSENTIAL DOCUMENTATION
- **\`CLAUDE.md\`**: Complete project context and guidelines
- **\`PRODUCT.md\`**: Business requirements and features
- **\`TECHNICAL.md\`**: Technical architecture and decisions

## 🔧 EMERGENCY DEBUGGING
If something breaks, run these in order:
1. \`./scripts/dev-toolkit.sh diagnose-error\` - Auto-diagnose issues
2. \`./scripts/dev-toolkit.sh health\` - Check project health
3. \`./scripts/dev-toolkit.sh cross-platform\` - Check dependencies
4. \`./scripts/dev-toolkit.sh branch-impact\` - Check recent changes

---
**🤖 This context was auto-generated by \`./scripts/dev-toolkit.sh llm-context\`**  
**For updates, re-run the command or use \`./scripts/dev-toolkit.sh llm-context clipboard\`**
EOF
     
     case "$format" in
         "markdown"|"md")
             log_header "LLM CONTEXT (Markdown)"
             echo "File: $output_file"
             ;;
         "clipboard"|"copy")
             log_header "LLM CONTEXT (Copied to Clipboard)"
             if command -v pbcopy >/dev/null 2>&1; then
                 cat "$output_file" | pbcopy
                 echo "✅ Context copied to clipboard - paste directly into Claude!"
             else
                 echo "❌ pbcopy not available - displaying content instead:"
                 cat "$output_file"
             fi
             ;;
         *)
             log_header "LLM CONTEXT (Text)"
             cat "$output_file"
             ;;
     esac
     
     echo ""
     echo -e "${GREEN}✅ LLM Context generated: $output_file${NC}"
     echo -e "${CYAN}💡 Usage Tips:${NC}"
     echo "  Copy/paste this context at the start of Claude conversations"
     echo "  Use \`./scripts/dev-toolkit.sh llm-context clipboard\` for instant copying"
           echo "  Re-run anytime for updated context with latest project state"
  }
  
  # Smart File Finder - Explain any file in 2 sentences
  what_is_command() {
      local file_pattern="$1"
      
      if [ -z "$file_pattern" ] || [[ "$file_pattern" == "--help" ]]; then
          echo "Usage: ./scripts/dev-toolkit.sh what-is <file_path_or_pattern>"
          echo ""
          echo "Explains any file or component in 2 sentences with key context"
          echo ""
          echo "Examples:"
          echo "  ./scripts/dev-toolkit.sh what-is adaptive-backend/src/index.ts"
          echo "  ./scripts/dev-toolkit.sh what-is QuizApiService"
          echo "  ./scripts/dev-toolkit.sh what-is adaptiveCore"
          echo "  ./scripts/dev-toolkit.sh what-is SWTPAApp.swift"
          return 0
      fi
      
      log_header "SMART FILE ANALYSIS: '$file_pattern'"
      
      # Find matching files
      local matching_files=()
      
      # If it's a direct file path, use it
      if [ -f "$file_pattern" ]; then
          matching_files=("$file_pattern")
             else
           # Search for files matching the pattern
           # Use fd if available, otherwise find (using simpler IFS approach)
           if command -v fd >/dev/null 2>&1; then
               IFS=$'\n' matching_files=($(fd "$file_pattern" --type f --exclude node_modules --exclude coverage --exclude dist --exclude build --exclude lib --exclude .git))
           else
               IFS=$'\n' matching_files=($(find . -name "*$file_pattern*" -type f -not -path "*/node_modules/*" -not -path "*/coverage/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/lib/*" -not -path "*/.git/*"))
           fi
       fi
      
      if [ ${#matching_files[@]} -eq 0 ]; then
          log_error "No files found matching: $file_pattern"
          echo ""
          echo -e "${CYAN}💡 Search suggestions:${NC}"
          echo "  • Try partial names: 'Quiz' instead of 'QuizComponent'"
          echo "  • Use file extensions: 'tsx' to find React components"
          echo "  • Search without path: 'index.ts' instead of 'src/index.ts'"
          return 1
      fi
      
      # Limit to top 5 matches to avoid overwhelming output
      local max_results=5
      if [ ${#matching_files[@]} -gt $max_results ]; then
          echo -e "${YELLOW}⚠️  Found ${#matching_files[@]} matches, showing top $max_results:${NC}"
          echo ""
      fi
      
      local count=0
      for file in "${matching_files[@]}"; do
          if [ $count -ge $max_results ]; then
              break
          fi
          
          analyze_file_purpose "$file"
          echo ""
          ((count++))
      done
      
      if [ ${#matching_files[@]} -gt $max_results ]; then
          echo -e "${CYAN}💡 To see more results, use a more specific pattern${NC}"
      fi
  }
  
  analyze_file_purpose() {
      local file="$1"
      local rel_path="${file#./}"
      local filename=$(basename "$file")
      local extension="${filename##*.}"
      local dir_context=$(dirname "$rel_path")
      
      echo -e "${BLUE}📁 $rel_path${NC}"
      echo -e "${CYAN}$(printf '─%.0s' {1..50})${NC}"
      
      # Determine file type and context
      local file_type=""
      local primary_purpose=""
      local secondary_context=""
      
      # Analyze based on location and filename
      case "$rel_path" in
          # Backend files
          *"adaptive-backend/src/index.ts")
              file_type="🔥 Firebase Functions Entry Point"
              primary_purpose="Exports all Cloud Functions for deployment to Firebase, serving as the main backend entry point."
              secondary_context="Contains function exports like initializeQuizSession, answerQuestion, and getNextQuestion for the adaptive learning system."
              ;;
          *"adaptive-backend/src/adaptive-core/"*)
              file_type="🧠 Adaptive Learning Algorithm"
              primary_purpose="Implements AI-powered adaptive learning algorithms for personalized question selection and difficulty adjustment."
              secondary_context="Core business logic that analyzes user performance patterns and optimizes learning paths in real-time."
              ;;
          *"adaptive-backend/src/answerQuestion.ts")
              file_type="⚡ Answer Processing Function"
              primary_purpose="Cloud Function that processes user answers and updates adaptive learning state in real-time."
              secondary_context="Handles scoring, difficulty adjustment, performance tracking, and determines the next question strategy."
              ;;
          *"adaptive-backend/src/initializeQuizSession.ts")
              file_type="🚀 Session Initialization Function"
              primary_purpose="Cloud Function that creates new quiz sessions with personalized adaptive parameters."
              secondary_context="Sets up user-specific learning state, difficulty baselines, and session configuration for optimal learning experience."
              ;;
          # Frontend files
          *"aswb-lcsw-quiz-app/src/main.tsx")
              file_type="🌐 React Application Entry Point"
              primary_purpose="Main entry point for the React frontend application, initializing the app with providers and routing."
              secondary_context="Sets up authentication context, error boundaries, and renders the root App component for the quiz interface."
              ;;
          *"aswb-lcsw-quiz-app/src/services/QuizApiService.ts")
              file_type="🔌 Main API Service"
              primary_purpose="Primary interface for all backend communication, handling quiz sessions, questions, and user data."
              secondary_context="Abstracts Firebase Function calls and provides typed methods for frontend components to interact with the adaptive backend."
              ;;
          *"aswb-lcsw-quiz-app/src/components/"*)
              file_type="⚛️ React Component"
              primary_purpose="React component providing specific UI functionality for the quiz application interface."
              secondary_context="Handles user interactions, state management, and renders adaptive learning experiences with real-time updates."
              ;;
          # iOS files
          *"SWTPA/SWTPA/SWTPAApp.swift")
              file_type="📱 SwiftUI App Entry Point"
              primary_purpose="Main entry point for the iOS SwiftUI application, initializing the app with navigation and state management."
              secondary_context="Sets up the app architecture with environment objects, navigation coordinators, and Firebase SDK integration."
              ;;
          *"SWTPA/SWTPA/Services/"*)
              file_type="🔗 iOS Service Layer"
              primary_purpose="Service class handling specific functionality like API communication, authentication, or data management."
              secondary_context="Provides abstracted interfaces for SwiftUI views to interact with backend services and local data storage."
              ;;
          *"SWTPA/SWTPA/Views/"*)
              file_type="📱 SwiftUI View"
              primary_purpose="SwiftUI view component providing specific user interface functionality for the iOS quiz application."
              secondary_context="Implements native iOS design patterns with adaptive learning features and real-time state synchronization."
              ;;
          # Configuration files
          *"/package.json")
              file_type="📦 Package Configuration"
              primary_purpose="Node.js package configuration defining dependencies, scripts, and project metadata."
              if [[ "$rel_path" == *"adaptive-backend"* ]]; then
                  secondary_context="Backend configuration with Firebase Functions dependencies, TypeScript settings, and deployment scripts."
              else
                  secondary_context="Frontend configuration with React, Vite, testing dependencies, and build optimization settings."
              fi
              ;;
          *"/tsconfig.json")
              file_type="📜 TypeScript Configuration"
              primary_purpose="TypeScript compiler configuration defining build settings, module resolution, and code standards."
              secondary_context="Ensures consistent TypeScript compilation across the project with proper path mapping and strict type checking."
              ;;
          *"/firebase.json")
              file_type="🔥 Firebase Configuration"
              primary_purpose="Firebase project configuration defining hosting, functions, firestore, and emulator settings."
              secondary_context="Specifies deployment targets, security rules, and local development environment configuration for the adaptive backend."
              ;;
          # Generic patterns
          *)
              # Generic analysis based on file extension and content
              case "$extension" in
                  "ts")
                      file_type="📜 TypeScript Module"
                      primary_purpose="TypeScript module providing specific functionality with type safety and modern JavaScript features."
                      ;;
                  "tsx")
                      file_type="⚛️ React TypeScript Component"
                      primary_purpose="React component written in TypeScript, providing UI functionality with type safety and JSX rendering."
                      ;;
                  "swift")
                      file_type="📱 Swift Module"
                      primary_purpose="Swift module providing iOS-specific functionality with native performance and modern language features."
                      ;;
                  "js")
                      file_type="📄 JavaScript Module"
                      primary_purpose="JavaScript module providing functionality and utilities for the application."
                      ;;
                  "json")
                      file_type="📋 Configuration File"
                      primary_purpose="JSON configuration file defining settings, dependencies, or data structures."
                      ;;
                  "md")
                      file_type="📚 Documentation"
                      primary_purpose="Markdown documentation providing project information, guides, or specifications."
                      ;;
                  "sh")
                      file_type="🔧 Shell Script"
                      primary_purpose="Shell script automating development tasks, builds, or system operations."
                      ;;
                  *)
                      file_type="📄 Project File"
                      primary_purpose="Project file contributing to the application functionality or configuration."
                      ;;
              esac
              
              # Try to get more context from content if not specifically identified
              if [ -z "$secondary_context" ] && [ -f "$file" ]; then
                  analyze_file_content "$file" extension
              fi
              ;;
      esac
      
      # Output the analysis
      echo -e "${PURPLE}$file_type${NC}"
      echo ""
      echo -e "${GREEN}📝 Purpose:${NC} $primary_purpose"
      
      if [ ! -z "$secondary_context" ]; then
          echo -e "${CYAN}🔍 Context:${NC} $secondary_context"
      fi
      
      # Show key functions/exports if it's a code file
      if [[ "$extension" =~ ^(ts|tsx|js|jsx|swift)$ ]] && [ -f "$file" ]; then
          show_key_exports "$file" "$extension"
      fi
      
      # Show file stats
      if [ -f "$file" ]; then
          local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
          local size=$(ls -lh "$file" | awk '{print $5}')
          echo -e "${YELLOW}📊 Stats:${NC} $lines lines, $size"
      fi
  }
  
  analyze_file_content() {
      local file="$1"
      local extension="$2"
      
      # Quick content analysis for better context
      if [ -f "$file" ]; then
          # Look for key patterns in the first 20 lines
          local sample=$(head -20 "$file" 2>/dev/null)
          
          case "$sample" in
              *"React"*|*"useState"*|*"useEffect"*)
                  secondary_context="React component with hooks and state management for interactive user interfaces."
                  ;;
              *"Firebase"*|*"firestore"*|*"functions"*)
                  secondary_context="Firebase integration providing cloud-based data storage, authentication, or serverless functions."
                  ;;
              *"interface"*|*"type "*|*"enum"*)
                  secondary_context="TypeScript definitions providing type safety and code contracts for the application."
                  ;;
              *"SwiftUI"*|*"@State"*|*"@ObservedObject"*)
                  secondary_context="SwiftUI component with reactive state management for native iOS user interfaces."
                  ;;
              *"test"*|*"describe"*|*"it("*|*"expect"*)
                  secondary_context="Test file containing unit tests, integration tests, or end-to-end test scenarios."
                  ;;
              *"export"*|*"function"*|*"class"*)
                  secondary_context="Module providing reusable functions, classes, or utilities for other parts of the application."
                  ;;
          esac
      fi
  }
  
  show_key_exports() {
      local file="$1"
      local extension="$2"
      
      echo ""
      echo -e "${BLUE}🔑 Key Exports/Functions:${NC}"
      
      case "$extension" in
          "ts"|"tsx"|"js"|"jsx")
              # Extract TypeScript/JavaScript exports and functions
              if [ -f "$file" ]; then
                  # Look for exports, functions, classes, interfaces
                  local exports=$(grep -E "^export (default |const |function |class |interface |type |enum )" "$file" 2>/dev/null | head -5)
                  if [ ! -z "$exports" ]; then
                      echo "$exports" | sed 's/^/  • /' | sed 's/export //' | sed 's/{.*$//' | sed 's/=.*$//'
                  else
                      # Look for main functions if no exports found
                      local functions=$(grep -E "^(function |const .* = |class )" "$file" 2>/dev/null | head -3)
                      if [ ! -z "$functions" ]; then
                          echo "$functions" | sed 's/^/  • /' | sed 's/{.*$//' | sed 's/=.*$//'
                      else
                          echo "  • No obvious exports found"
                      fi
                  fi
              fi
              ;;
          "swift")
              # Extract Swift functions, classes, structs
              if [ -f "$file" ]; then
                  local swift_items=$(grep -E "^(func |class |struct |protocol |enum )" "$file" 2>/dev/null | head -5)
                  if [ ! -z "$swift_items" ]; then
                      echo "$swift_items" | sed 's/^/  • /' | sed 's/{.*$//'
                  else
                      echo "  • No obvious declarations found"
                  fi
              fi
              ;;
             esac
   }
   
   # Related Files Finder - Find all connected files instantly
   related_files_command() {
       local file_pattern="$1"
       local max_results="${2:-10}"
       
       if [ -z "$file_pattern" ] || [[ "$file_pattern" == "--help" ]]; then
           echo "Usage: ./scripts/dev-toolkit.sh related <file_path_or_pattern> [max_results]"
           echo ""
           echo "Finds all files related/connected to the target file"
           echo ""
           echo "Shows:"
           echo "  • Files that import the target file"
           echo "  • Files that the target file imports"
           echo "  • Related test files"
           echo "  • Files with similar names/purposes"
           echo ""
           echo "Examples:"
           echo "  ./scripts/dev-toolkit.sh related QuizApiService"
           echo "  ./scripts/dev-toolkit.sh related adaptive-backend/src/answerQuestion.ts"
           echo "  ./scripts/dev-toolkit.sh related SWTPAApp.swift 5"
           return 0
       fi
       
       log_header "RELATED FILES ANALYSIS: '$file_pattern'"
       
       # Find the target file(s)
       local target_files=()
       
       if [ -f "$file_pattern" ]; then
           target_files=("$file_pattern")
       else
           # Search for files matching the pattern
           if command -v fd >/dev/null 2>&1; then
               IFS=$'\n' target_files=($(fd "$file_pattern" --type f --exclude node_modules --exclude coverage --exclude dist --exclude build --exclude lib --exclude .git | head -3))
           else
               IFS=$'\n' target_files=($(find . -name "*$file_pattern*" -type f -not -path "*/node_modules/*" -not -path "*/coverage/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/lib/*" -not -path "*/.git/*" | head -3))
           fi
       fi
       
       if [ ${#target_files[@]} -eq 0 ]; then
           log_error "No files found matching: $file_pattern"
           return 1
       fi
       
       # Analyze each target file
       for target_file in "${target_files[@]}"; do
           if [ ${#target_files[@]} -gt 1 ]; then
               echo -e "${PURPLE}📁 Analyzing: $target_file${NC}"
               echo -e "${PURPLE}$(printf '=%.0s' {1..60})${NC}"
           fi
           
           analyze_file_relationships "$target_file" "$max_results"
           
           if [ ${#target_files[@]} -gt 1 ]; then
               echo ""
           fi
       done
   }
   
   analyze_file_relationships() {
       local target_file="$1"
       local max_results="$2"
       local rel_path="${target_file#./}"
       local filename=$(basename "$target_file")
       local basename_no_ext="${filename%.*}"
       local extension="${filename##*.}"
       
       echo -e "${CYAN}🎯 Target File: $rel_path${NC}"
       echo ""
       
       # 1. Files that import this file
       echo -e "${BLUE}📥 Files that import this file:${NC}"
       find_files_importing_target "$target_file" "$max_results"
       
       echo ""
       
       # 2. Files that this file imports
       echo -e "${BLUE}📤 Files that this file imports:${NC}"
       find_files_imported_by_target "$target_file" "$max_results"
       
       echo ""
       
       # 3. Related test files
       echo -e "${BLUE}🧪 Related test files:${NC}"
       find_related_test_files "$target_file" "$max_results"
       
       echo ""
       
       # 4. Files with similar names/purposes
       echo -e "${BLUE}👥 Files with similar names:${NC}"
       find_similar_named_files "$target_file" "$max_results"
       
       echo ""
       
       # 5. Cross-platform related files
       echo -e "${BLUE}🌐 Cross-platform related files:${NC}"
       find_cross_platform_related "$target_file" "$max_results"
   }
   
   find_files_importing_target() {
       local target_file="$1"
       local max_results="$2"
       local filename=$(basename "$target_file")
       local basename_no_ext="${filename%.*}"
       
       # Search for import statements that reference this file
       local import_patterns=(
           "$basename_no_ext"
           "$(echo "$target_file" | sed 's|\./||' | sed 's|\.ts$||' | sed 's|\.tsx$||' | sed 's|\.js$||' | sed 's|\.jsx$||')"
           "$(dirname "$target_file" | sed 's|\./||')"
       )
       
       local found_imports=()
       
       for pattern in "${import_patterns[@]}"; do
           if [ ! -z "$pattern" ] && [ "$pattern" != "." ]; then
               # TypeScript/JavaScript imports
               local ts_imports=$(grep -r "import.*from.*['\"].*$pattern" . \
                   --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
                   --exclude-dir=node_modules --exclude-dir=coverage --exclude-dir=dist \
                   --exclude-dir=build --exclude-dir=lib --exclude-dir=.git \
                   2>/dev/null | head -$max_results)
               
               if [ ! -z "$ts_imports" ]; then
                   while IFS=: read -r file_path rest; do
                       if [ "$file_path" != "$target_file" ] && [[ ! " ${found_imports[@]:-} " =~ " ${file_path} " ]]; then
                           found_imports+=("$file_path")
                       fi
                   done <<< "$ts_imports"
               fi
               
               # Swift imports
               local swift_imports=$(grep -r "import.*$pattern" . \
                   --include="*.swift" \
                   --exclude-dir=node_modules --exclude-dir=.git \
                   2>/dev/null | head -$max_results)
               
               if [ ! -z "$swift_imports" ]; then
                   while IFS=: read -r file_path rest; do
                       if [ "$file_path" != "$target_file" ] && [[ ! " ${found_imports[@]:-} " =~ " ${file_path} " ]]; then
                           found_imports+=("$file_path")
                       fi
                   done <<< "$swift_imports"
               fi
           fi
       done
       
       if [ ${#found_imports[@]} -gt 0 ]; then
           for import_file in "${found_imports[@]}"; do
               echo "  📄 ${import_file#./}"
           done
       else
           echo "  • No files found importing this file"
       fi
   }
   
   find_files_imported_by_target() {
       local target_file="$1"
       local max_results="$2"
       
       if [ ! -f "$target_file" ]; then
           echo "  • Target file not found"
           return
       fi
       
       local extension="${target_file##*.}"
       local imports=()
       
       case "$extension" in
           "ts"|"tsx"|"js"|"jsx")
               # Extract TypeScript/JavaScript imports
               local import_lines=$(grep -E "^import.*from ['\"]" "$target_file" 2>/dev/null | head -$max_results)
               if [ ! -z "$import_lines" ]; then
                   while IFS= read -r line; do
                       # Extract the import path
                       local import_path=$(echo "$line" | sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/")
                       if [ ! -z "$import_path" ]; then
                           imports+=("$import_path")
                       fi
                   done <<< "$import_lines"
               fi
               ;;
           "swift")
               # Extract Swift imports
               local import_lines=$(grep -E "^import " "$target_file" 2>/dev/null | head -$max_results)
               if [ ! -z "$import_lines" ]; then
                   while IFS= read -r line; do
                       local import_name=$(echo "$line" | sed 's/import //')
                       if [ ! -z "$import_name" ]; then
                           imports+=("$import_name")
                       fi
                   done <<< "$import_lines"
               fi
               ;;
       esac
       
       if [ ${#imports[@]} -gt 0 ]; then
           for import_item in "${imports[@]}"; do
               echo "  📦 $import_item"
           done
       else
           echo "  • No imports found in this file"
       fi
   }
   
   find_related_test_files() {
       local target_file="$1"
       local max_results="$2"
       local filename=$(basename "$target_file")
       local basename_no_ext="${filename%.*}"
       local dir_path=$(dirname "$target_file")
       
       local test_patterns=(
           "$basename_no_ext.test.*"
           "$basename_no_ext.spec.*"
           "*$basename_no_ext*test*"
           "*$basename_no_ext*spec*"
       )
       
       local test_files=()
       
       for pattern in "${test_patterns[@]}"; do
           # Search for test files
           if command -v fd >/dev/null 2>&1; then
               local found_tests=$(fd "$pattern" --type f --exclude node_modules --exclude coverage --exclude dist --exclude build --exclude lib --exclude .git 2>/dev/null)
           else
               local found_tests=$(find . -name "$pattern" -type f -not -path "*/node_modules/*" -not -path "*/coverage/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/lib/*" -not -path "*/.git/*" 2>/dev/null)
           fi
           
           if [ ! -z "$found_tests" ]; then
               while IFS= read -r test_file; do
                   if [ "$test_file" != "$target_file" ] && [[ ! " ${test_files[@]:-} " =~ " ${test_file} " ]]; then
                       test_files+=("$test_file")
                   fi
               done <<< "$found_tests"
           fi
       done
       
       # Also look for test files that mention this file
       local mentioning_tests=$(grep -r "$basename_no_ext" . \
           --include="*.test.*" --include="*.spec.*" \
           --exclude-dir=node_modules --exclude-dir=coverage --exclude-dir=dist \
           --exclude-dir=build --exclude-dir=lib --exclude-dir=.git \
           2>/dev/null | cut -d: -f1 | sort -u | head -$max_results)
       
       if [ ! -z "$mentioning_tests" ]; then
           while IFS= read -r test_file; do
               if [ "$test_file" != "$target_file" ] && [[ ! " ${test_files[@]:-} " =~ " ${test_file} " ]]; then
                   test_files+=("$test_file")
               fi
           done <<< "$mentioning_tests"
       fi
       
       if [ ${#test_files[@]} -gt 0 ]; then
           for test_file in "${test_files[@]}"; do
               echo "  🧪 ${test_file#./}"
           done
       else
           echo "  • No related test files found"
       fi
   }
   
   find_similar_named_files() {
       local target_file="$1"
       local max_results="$2"
       local filename=$(basename "$target_file")
       local basename_no_ext="${filename%.*}"
       local dir_path=$(dirname "$target_file")
       
       # Look for files with similar names
       local similar_patterns=(
           "*$basename_no_ext*"
           "$(echo "$basename_no_ext" | sed 's/Service$//')*.ts"
           "$(echo "$basename_no_ext" | sed 's/Component$//')*.tsx"
           "$(echo "$basename_no_ext" | sed 's/View$//')*.swift"
       )
       
       local similar_files=()
       
       for pattern in "${similar_patterns[@]}"; do
           if [ ! -z "$pattern" ]; then
               if command -v fd >/dev/null 2>&1; then
                   local found_files=$(fd "$pattern" --type f --exclude node_modules --exclude coverage --exclude dist --exclude build --exclude lib --exclude .git 2>/dev/null)
               else
                   local found_files=$(find . -name "$pattern" -type f -not -path "*/node_modules/*" -not -path "*/coverage/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/lib/*" -not -path "*/.git/*" 2>/dev/null)
               fi
               
               if [ ! -z "$found_files" ]; then
                   while IFS= read -r similar_file; do
                       if [ "$similar_file" != "$target_file" ] && [[ ! " ${similar_files[@]:-} " =~ " ${similar_file} " ]]; then
                           similar_files+=("$similar_file")
                       fi
                   done <<< "$found_files"
               fi
           fi
       done
       
       # Limit results
       local count=0
       if [ ${#similar_files[@]} -gt 0 ]; then
           for similar_file in "${similar_files[@]}"; do
               if [ $count -ge $max_results ]; then
                   break
               fi
               echo "  📄 ${similar_file#./}"
               ((count++))
           done
       else
           echo "  • No similar named files found"
       fi
   }
   
   find_cross_platform_related() {
       local target_file="$1"
       local max_results="$2"
       local filename=$(basename "$target_file")
       local basename_no_ext="${filename%.*}"
       
       local cross_platform_files=()
       
       # If it's a backend file, look for frontend equivalents
       if [[ "$target_file" == *"adaptive-backend"* ]]; then
           echo "  🌐 Looking for frontend equivalents..."
           
           # Look for API service files in frontend
           local frontend_related=$(find "./aswb-lcsw-quiz-app/src" -name "*$basename_no_ext*" -o -name "*Api*" -o -name "*Service*" 2>/dev/null | head -$max_results)
           if [ ! -z "$frontend_related" ]; then
               while IFS= read -r related_file; do
                   cross_platform_files+=("$related_file")
               done <<< "$frontend_related"
           fi
           
       # If it's a frontend file, look for backend equivalents
       elif [[ "$target_file" == *"aswb-lcsw-quiz-app"* ]]; then
           echo "  🔥 Looking for backend equivalents..."
           
           # Look for similar functionality in backend
           local backend_related=$(find "./adaptive-backend/src" -name "*$basename_no_ext*" -o -name "*$(echo "$basename_no_ext" | sed 's/Service$//')*" 2>/dev/null | head -$max_results)
           if [ ! -z "$backend_related" ]; then
               while IFS= read -r related_file; do
                   cross_platform_files+=("$related_file")
               done <<< "$backend_related"
           fi
           
       # If it's an iOS file, look for web equivalents
       elif [[ "$target_file" == *"SWTPA"* ]]; then
           echo "  🌐 Looking for web equivalents..."
           
           # Look for similar functionality in frontend
           local web_related=$(find "./aswb-lcsw-quiz-app/src" -name "*$basename_no_ext*" -o -name "*$(echo "$basename_no_ext" | sed 's/View$//')*" 2>/dev/null | head -$max_results)
           if [ ! -z "$web_related" ]; then
               while IFS= read -r related_file; do
                   cross_platform_files+=("$related_file")
               done <<< "$web_related"
           fi
       fi
       
       if [ ${#cross_platform_files[@]} -gt 0 ]; then
           for related_file in "${cross_platform_files[@]}"; do
               echo "    📱 ${related_file#./}"
           done
       else
           echo "  • No cross-platform related files found"
       fi
   }

   # Swift/iOS Development Commands
   swift_lint_command() {
       log_header "SWIFT LINTING (SwiftLint)"
       
       if [ ! -d "$IOS_DIR" ]; then
           log_error "iOS directory not found: $IOS_DIR"
           return 1
       fi
       
       # Check if SwiftLint is installed
       if ! command -v swiftlint >/dev/null 2>&1; then
           log_warning "SwiftLint not installed"
           echo -e "${CYAN}Install with: brew install swiftlint${NC}"
           return 1
       fi
       
       echo -e "${CYAN}📱 Running SwiftLint on iOS project...${NC}"
       echo ""
       
       cd "$IOS_DIR"
       
       # Run SwiftLint with nice output
       if swiftlint 2>/dev/null; then
           log_success "SwiftLint passed - no style issues found!"
       else
           log_warning "SwiftLint found style issues (see above)"
           echo ""
           echo -e "${BLUE}💡 Quick fixes:${NC}"
           echo "  Run auto-fix: cd $IOS_DIR && swiftlint --fix"
           echo "  Strict mode: cd $IOS_DIR && swiftlint --strict"
       fi
       
       cd - > /dev/null
   }
   
   swift_build_command() {
       local build_type="${1:-fast}"
       
       log_header "SWIFT BUILD ($build_type mode)"
       
       if [ ! -d "$IOS_DIR" ]; then
           log_error "iOS directory not found: $IOS_DIR"
           return 1
       fi
       
       # Check if XcodeBuildMCP is available for faster builds
       if command -v npx >/dev/null 2>&1 && [ "$build_type" != "mcp-disabled" ]; then
           echo -e "${CYAN}🚀 Attempting XcodeBuildMCP for optimized build...${NC}"
           if use_mcp_build "$build_type"; then
               return $?
           else
               echo -e "${YELLOW}⚠️  XcodeBuildMCP failed, falling back to traditional xcodebuild${NC}"
           fi
       fi
       
       echo -e "${CYAN}📱 Building iOS project with filtered output...${NC}"
       echo ""
       
       cd "$IOS_DIR"
       
       case "$build_type" in
           "fast"|"f")
               echo -e "${BLUE}⚡ Fast build (errors only):${NC}"
               xcodebuild -scheme SWTPA -sdk iphonesimulator \
                   -destination 'platform=iOS Simulator,name=iPhone 16' build \
                   2>&1 | grep -E "(error|Error|warning|Warning|BUILD)" | head -20
               ;;
           "clean"|"c")
               echo -e "${BLUE}🧹 Clean build:${NC}"
               xcodebuild -scheme SWTPA -sdk iphonesimulator clean build \
                   2>&1 | tail -20 | grep -E "(error|success|failed|BUILD)"
               ;;
           "verbose"|"v")
               echo -e "${BLUE}📝 Verbose build:${NC}"
               xcodebuild -scheme SWTPA -sdk iphonesimulator \
                   -destination 'platform=iOS Simulator,name=iPhone 16' build
               ;;
           "mcp"|"smart")
               echo -e "${BLUE}🤖 Smart MCP build:${NC}"
               use_mcp_build "smart"
               ;;
           *)
               log_error "Unknown build type: $build_type"
               echo "Available types: fast, clean, verbose, mcp"
               cd - > /dev/null
               return 1
               ;;
       esac
       
       local exit_code=$?
       cd - > /dev/null
       
       if [ $exit_code -eq 0 ]; then
           log_success "Build completed successfully!"
       else
           log_error "Build failed - check errors above"
       fi
       
       return $exit_code
   }
   
   use_mcp_build() {
       local build_type="$1"
       
       echo -e "${BLUE}🤖 Using XcodeBuildMCP for optimized build...${NC}"
       
       # Check if MCP is available
       if ! npx --yes xcodebuildmcp --version >/dev/null 2>&1; then
           echo -e "${RED}❌ XcodeBuildMCP not available${NC}"
           return 1
       fi
       
       cd "$IOS_DIR"
       
       case "$build_type" in
           "fast"|"smart")
               # Use MCP for smart build with caching
               echo "  🚀 Running smart incremental build..."
               npx --yes xcodebuildmcp build \
                   --scheme SWTPA \
                   --destination "platform=iOS Simulator,name=iPhone 16" \
                   --derivedDataPath ./DerivedData \
                   2>&1 | grep -E "(error|Error|warning|Warning|SUCCESS|FAILED)" | head -15
               ;;
           "clean")
               echo "  🧹 Running clean + smart build..."
               npx --yes xcodebuildmcp clean build \
                   --scheme SWTPA \
                   --destination "platform=iOS Simulator,name=iPhone 16" \
                   2>&1 | tail -20
               ;;
           *)
               echo "  📱 Running standard MCP build..."
               npx --yes xcodebuildmcp build \
                   --scheme SWTPA \
                   --destination "platform=iOS Simulator,name=iPhone 16"
               ;;
       esac
       
       local mcp_exit_code=$?
       cd - > /dev/null
       
       if [ $mcp_exit_code -eq 0 ]; then
           log_success "XcodeBuildMCP build completed successfully!"
           echo -e "${GREEN}💡 XcodeBuildMCP benefits: Faster builds, better caching, parallel processing${NC}"
       else
           echo -e "${YELLOW}⚠️  XcodeBuildMCP build had issues (exit code: $mcp_exit_code)${NC}"
           return 1
       fi
       
               return $mcp_exit_code
    }
    
    # MCP Integration Command
    mcp_integration_command() {
        log_header "MCP (MODEL CONTEXT PROTOCOL) INTEGRATION"
        
        echo -e "${CYAN}🤖 Checking MCP server status and integration...${NC}"
        echo ""
        
        # Check if MCP config exists
        local mcp_config="/Users/jordanjackson/.cursor/mcp.json"
        if [ -f "$mcp_config" ]; then
            echo -e "${GREEN}✅ MCP configuration found at $mcp_config${NC}"
            
            # Show configured servers
            echo -e "\n${BLUE}📋 Configured MCP Servers:${NC}"
            jq -r '.mcpServers | keys[]' "$mcp_config" 2>/dev/null | while read server; do
                echo "  • $server"
            done
        else
            echo -e "${RED}❌ MCP configuration not found${NC}"
            echo "  Expected location: $mcp_config"
        fi
        
        echo ""
        echo -e "${CYAN}🔧 MCP Server Availability:${NC}"
        
        # Check XcodeBuildMCP
        if command -v npx >/dev/null 2>&1; then
            if npx --yes xcodebuildmcp --version >/dev/null 2>&1; then
                echo -e "${GREEN}✅ XcodeBuildMCP: Available${NC}"
                local xcode_version=$(npx --yes xcodebuildmcp --version 2>/dev/null | head -1)
                echo "    Version: $xcode_version"
            else
                echo -e "${YELLOW}⚠️  XcodeBuildMCP: Not available${NC}"
                echo "    Install: npm install -g xcodebuildmcp"
            fi
        else
            echo -e "${RED}❌ npx not available - Node.js required${NC}"
        fi
        
        # Check Firebase MCP
        echo ""
        if command -v firebase >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Firebase CLI: Available${NC}"
            local firebase_version=$(firebase --version 2>/dev/null)
            echo "    Version: $firebase_version"
            
            # Check if experimental MCP is available
            if firebase experimental:mcp --help >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Firebase MCP: Available${NC}"
            else
                echo -e "${YELLOW}⚠️  Firebase MCP: Experimental feature not available${NC}"
            fi
        else
            echo -e "${RED}❌ Firebase CLI not available${NC}"
            echo "    Install: npm install -g firebase-tools"
        fi
        
        echo ""
        echo -e "${CYAN}🚀 MCP Integration Benefits:${NC}"
        echo "  • XcodeBuildMCP: 5-10x faster iOS builds with intelligent caching"
        echo "  • Firebase MCP: Direct Firebase service integration in Claude"
        echo "  • Multi-repo awareness: Better context across all 3 codebases"
        echo "  • Error diagnosis: AI-powered build issue detection"
        
        echo ""
        echo -e "${BLUE}💡 Usage Examples:${NC}"
        echo "  ./scripts/dev-toolkit.sh swift-build mcp     # Use MCP for iOS builds"
        echo "  ./scripts/dev-toolkit.sh swift-build fast    # Traditional build (MCP auto-tries first)"
        echo "  ./scripts/dev-toolkit.sh swift-build mcp-disabled  # Force traditional build"
        
        echo ""
        echo -e "${CYAN}🔗 Integration Status:${NC}"
        if [ -f "$mcp_config" ] && command -v npx >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready for enhanced Claude development with MCP integration${NC}"
        else
            echo -e "${YELLOW}⚠️  Partial integration - check missing components above${NC}"
        fi
    }
    
    swift_format_command() {
       log_header "SWIFT FORMATTING"
       
       if [ ! -d "$IOS_DIR" ]; then
           log_error "iOS directory not found: $IOS_DIR"
           return 1
       fi
       
       # Check if swift-format is installed
       if ! command -v swift-format >/dev/null 2>&1; then
           log_warning "swift-format not installed"
           echo -e "${CYAN}Install with: brew install swift-format${NC}"
           return 1
       fi
       
       echo -e "${CYAN}📱 Formatting Swift files...${NC}"
       echo ""
       
       cd "$IOS_DIR"
       
       # Find all Swift files
       local swift_files=$(find . -name "*.swift" -not -path "./DerivedData/*" -not -path "./.build/*")
       local file_count=$(echo "$swift_files" | wc -l | xargs)
       
       echo -e "${BLUE}Found $file_count Swift files to format${NC}"
       echo ""
       
       # Format files
       echo "$swift_files" | while read -r file; do
           if [ ! -z "$file" ]; then
               echo "  📄 Formatting: $file"
               swift-format --in-place "$file" 2>/dev/null || echo "    ⚠️  Failed to format $file"
           fi
       done
       
       log_success "Swift formatting completed!"
       
       cd - > /dev/null
   }
   
   swift_check_command() {
       log_header "COMPLETE SWIFT QUALITY CHECK"
       
       echo -e "${CYAN}📱 Running complete iOS development pipeline...${NC}"
       echo ""
       
       # 1. SwiftLint
       echo -e "${BLUE}1️⃣ Style Check (SwiftLint):${NC}"
       swift_lint_command
       echo ""
       
       # 2. Swift Format (lint mode)
       echo -e "${BLUE}2️⃣ Format Check:${NC}"
       if command -v swift-format >/dev/null 2>&1; then
           cd "$IOS_DIR"
           local format_issues=$(find . -name "*.swift" -not -path "./DerivedData/*" | xargs swift-format --lint 2>/dev/null | wc -l | xargs)
           if [ "$format_issues" -eq 0 ]; then
               log_success "All Swift files properly formatted"
           else
               log_warning "$format_issues formatting issues found"
               echo "  Fix with: ./scripts/dev-toolkit.sh swift-format"
           fi
           cd - > /dev/null
       else
           echo "  swift-format not installed - skipping"
       fi
       echo ""
       
       # 3. Fast build
       echo -e "${BLUE}3️⃣ Build Check:${NC}"
       swift_build_command "fast"
       echo ""
       
       # 4. Summary
       echo -e "${PURPLE}✅ Swift Quality Check Complete${NC}"
       echo -e "${CYAN}💡 Quick fixes if needed:${NC}"
       echo "  Fix linting: cd $IOS_DIR && swiftlint --fix"
       echo "  Fix formatting: ./scripts/dev-toolkit.sh swift-format"
       echo "  Clean build: ./scripts/dev-toolkit.sh swift-build clean"
   }
   
   # Main command handler
case "$1" in
    # New o3-inspired sub-commands
    "tree")
        tree_command "$2" "$3"
        ;;
    "slice")
        slice_command "$2" "$3" "$4"
        ;;
    "cheatsheet"|"cheat")
        cheatsheet_command
        ;;
    "drift"|"versions")
        drift_command
        ;;
    "peek"|"peeks")
        peek_command
        ;;
    "hotspots"|"hot")
        hotspots_command
        ;;
    "graph"|"deps-graph")
        graph_command
        ;;
    "flow"|"runtime"|"architecture")
        runtime_flow_command
        ;;
    # Existing commands
    "analyze"|"a")
        analyze_project
        ;;
    "deps"|"dependencies")
        analyze_dependencies
        ;;
    "todos"|"debt")
        find_todos
        ;;
    "search"|"s")
        search_codebase "$2" "${3:-}"
        ;;
    "find"|"f")
        find_files "$2"
        ;;
    "view"|"v")
        view_file "$2" "$3"
        ;;
    "health"|"h")
        quick_health_check
        ;;
    "summary"|"report")
        generate_dev_summary
        ;;
    "performance"|"perf"|"p")
        performance_check
        ;;
    "tree-old"|"t")
        show_tree "$2"
        ;;
    "cross-platform"|"platform"|"xp")
        cross_platform_analysis
        ;;
    "test-affected"|"affected"|"ta")
        test_affected_analysis "$2"
        ;;
    "metrics"|"dev-metrics"|"dm")
        development_metrics
        ;;
    "branch-impact"|"impact"|"bi")
        branch_impact_analysis
        ;;
    "e2e"|"test-e2e"|"complete-test")
        run_complete_e2e "$@"
        ;;
    "interactive"|"cli"|"repl")
        run_interactive_cli
        ;;
    "context"|"ctx"|"claude-context")
        generate_claude_context "$@"
        ;;
    "diagnose-error"|"diagnose"|"error"|"debug")
        diagnose_error_command "${2:-auto}" "${3:-}"
        ;;
    "llm-context"|"llm"|"claude-onboard"|"onboard")
        llm_context_command "${2:-text}"
        ;;
    "what-is"|"what"|"explain"|"info")
        what_is_command "$2"
        ;;
    "related"|"rel"|"connections"|"deps-for")
        related_files_command "$2" "${3:-10}"
        ;;
    "swift-lint"|"swiftlint"|"ios-lint")
        swift_lint_command
        ;;
    "swift-build"|"ios-build"|"xcode-build")
        swift_build_command "${2:-fast}"
        ;;
    "swift-format"|"ios-format"|"format-swift")
        swift_format_command
        ;;
    "swift-check"|"ios-check"|"swift-all")
        swift_check_command
        ;;
    "mcp"|"mcp-status"|"mcp-check")
        mcp_integration_command
        ;;
    "help"|"--help"|"-h"|"")
        echo -e "${PURPLE}🛠️  SWTPA Development Toolkit${NC}"
        echo ""
        echo -e "${CYAN}Usage:${NC} ./scripts/dev-toolkit.sh [command] [options]"
        echo ""
        echo -e "${CYAN}🚀 Quick Context Commands (o3-optimized):${NC}"
        echo "  cheatsheet, cheat    - Project overview (entrypoints, commands, URLs)"
        echo "  tree <dir> [depth]   - Directory tree with specified depth (default: 2)"
        echo "  slice <file> [start] [end] - View file lines with line numbers"
        echo "  drift, versions      - Version mismatch analysis across codebases"
        echo "  peek, peeks          - Interface signatures from high-value files"
        echo "  hotspots, hot        - Most frequently changed files (git analysis)"
        echo "  graph, deps-graph    - Dependency import analysis"
        echo "  flow, runtime        - Show SWTPA runtime architecture diagram"
        echo ""
        echo -e "${CYAN}Core Commands:${NC}"
        echo "  analyze, a           - Full project structure analysis"
        echo "  health, h           - Quick project health check"
        echo "  tree-old, t [depth] - Show project tree (legacy command)"
        echo ""
        echo -e "${CYAN}Dependency & Platform Analysis:${NC}"
        echo "  deps, dependencies   - Analyze project dependencies"
        echo "  cross-platform, xp   - Cross-platform dependency mapping"
        echo ""
        echo -e "${CYAN}Code Investigation:${NC}"
        echo "  search, s <pattern> - Search codebase for pattern"
        echo "  find, f <pattern>   - Find files matching pattern"
        echo "  view, v <file>      - View file with syntax highlighting"
        echo "  what-is, what <file> - Explain any file/component in 2 sentences"
        echo "  related, rel <file> - Find all files connected to target file"
        echo "  todos, debt         - Find TODO items and technical debt"
        echo ""
        echo -e "${CYAN}Swift/iOS Development:${NC}"
        echo "  swift-lint, ios-lint - Run SwiftLint style checking"
        echo "  swift-build [type]  - Fast iOS build (types: fast, clean, verbose, mcp)"
        echo "  swift-format        - Auto-format all Swift files"
        echo "  swift-check         - Complete iOS quality pipeline"
        echo ""
        echo -e "${CYAN}MCP Integration:${NC}"
        echo "  mcp, mcp-status     - Check MCP server status and integration"
        echo ""
        echo -e "${CYAN}Testing & Development:${NC}"
        echo "  test-affected, ta <files> - Smart test runner (which tests to run)"
        echo "  e2e, test-e2e       - Complete E2E test suite runner"
        echo "  interactive, cli    - Interactive CLI mode"
        echo "  metrics, dm         - Development metrics & trends"
        echo "  branch-impact, bi   - Branch impact analysis & PR templates"
        echo "  diagnose-error, diagnose - Intelligent error diagnosis & solutions"
        echo ""
        echo -e "${CYAN}Reports & Analysis:${NC}"
        echo "  summary, report     - Generate development summary report"
        echo "  performance, perf, p - Performance and bundle analysis"
        echo "  llm-context, llm    - Generate instant Claude onboarding context"
        echo "  help                - Show this help message"
        echo ""
        echo -e "${CYAN}Examples:${NC}"
        echo "  ./scripts/dev-toolkit.sh cheatsheet        # Quick project overview"
        echo "  ./scripts/dev-toolkit.sh tree adaptive-backend 3  # Tree view with depth"
        echo "  ./scripts/dev-toolkit.sh slice src/index.ts 1 50   # View file lines 1-50"
        echo "  ./scripts/dev-toolkit.sh drift             # Check version mismatches"
        echo "  ./scripts/dev-toolkit.sh analyze           # Full project analysis"
        echo "  ./scripts/dev-toolkit.sh search 'QuizApiService'"
        echo "  ./scripts/dev-toolkit.sh branch-impact     # Git branch analysis"
        echo "  ./scripts/dev-toolkit.sh diagnose-error    # Auto-detect & diagnose errors"
        echo "  ./scripts/dev-toolkit.sh diagnose firebase # Diagnose Firebase issues"
        echo "  ./scripts/dev-toolkit.sh llm-context       # Generate Claude context"
        echo "  ./scripts/dev-toolkit.sh llm-context clipboard # Copy to clipboard"
        echo "  ./scripts/dev-toolkit.sh what-is QuizApiService # Explain file purpose"
        echo "  ./scripts/dev-toolkit.sh what-is adaptive-core  # Find and explain matching files"
        echo "  ./scripts/dev-toolkit.sh related QuizApiService # Find all connected files"
        echo "  ./scripts/dev-toolkit.sh swift-build fast       # Fast iOS build with filtered output"
        echo "  ./scripts/dev-toolkit.sh swift-build mcp        # Use XcodeBuildMCP for optimized builds"
        echo "  ./scripts/dev-toolkit.sh swift-check            # Complete iOS quality pipeline"
        echo "  ./scripts/dev-toolkit.sh mcp                    # Check MCP integration status"
        echo ""
        echo -e "${YELLOW}💡 Tip:${NC} Make this script executable with: chmod +x scripts/dev-toolkit.sh"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Run './scripts/dev-toolkit.sh help' for usage information"
        exit 1
        ;;
esac