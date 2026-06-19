#!/bin/bash
# =============================================================================
# Check macOS Version
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"

MIN_MAJOR=14

check_macos() {
	log_info "Checking macOS version..."

	# Get macOS version
	local version=$(sw_vers -productVersion)
	local major=$(echo "$version" | cut -d. -f1)
	local minor=$(echo "$version" | cut -d. -f2)
	local build=$(sw_vers -buildVersion)
	local name=$(sw_vers -productName)

	echo -e "  ${BOLD}${name}${NC} ${version} (${build})"

	if [[ $major -ge $MIN_MAJOR ]]; then
		log_success "macOS version OK (>= ${MIN_MAJOR}.0)"
		return 0
	else
		log_error "macOS version too old (requires >= ${MIN_MAJOR}.0)"
		return 1
	fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	check_macos
fi
