#!/bin/bash
# =============================================================================
# Check Git Installation
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"

check_git() {
    log_info "Checking Git..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git not found"
        echo -e "  Install: ${BOLD}brew install git${NC}"
        return 1
    fi
    
    local version=$(git --version)
    log_success "Git installed: ${version}"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_git
fi
