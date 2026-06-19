#!/bin/bash
# =============================================================================
# Check Homebrew Installation
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"

check_homebrew() {
	log_info "Checking Homebrew..."

	if ! command -v brew &>/dev/null; then
		log_error "Homebrew not found"
		echo -e "  Install: ${BOLD}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
		return 1
	fi

	local version=$(brew --version | head -1)
	log_success "Homebrew installed: ${version}"
	return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	check_homebrew
fi
