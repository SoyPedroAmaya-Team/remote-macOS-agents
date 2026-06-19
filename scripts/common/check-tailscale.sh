#!/bin/bash
# =============================================================================
# Check Tailscale Installation and Status
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"

check_tailscale() {
	log_info "Checking Tailscale..."

	# Check if installed
	if ! command -v tailscale &>/dev/null; then
		log_error "Tailscale not installed"
		echo -e "  Install: ${BOLD}brew install --cask tailscale${NC}"
		return 1
	fi

	local version=$(tailscale version 2>/dev/null | head -1 || echo "unknown")
	log_info "Tailscale version: ${version}"

	# Check if logged in (use text status, more reliable on macOS)
	local status_text=$(tailscale status 2>&1 || echo "")
	
	if echo "$status_text" | grep -q "Logged out"; then
		log_warning "Tailscale is installed but not logged in"
		echo -e "  Run: ${BOLD}tailscale up${NC}"
		return 1
	elif echo "$status_text" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
		log_success "Tailscale is installed and logged in"

		# Show current connection info
		local hostname=$(tailscale status --self 2>/dev/null | grep -v "^$" | head -1 || echo "unknown")
		local ip=$(tailscale ip -4 2>/dev/null || echo "unknown")

		log_success "Tailscale is installed and logged in"
		echo -e "  Hostname: ${BOLD}${hostname}${NC}"
		echo -e "  Tailscale IP: ${BOLD}${ip}${NC}"
		return 0
	fi
}

install_tailscale() {
	log_info "Installing Tailscale..."

	if command -v brew &>/dev/null; then
		brew install --cask tailscale
		log_success "Tailscale installed"
	else
		log_error "Homebrew not found. Please install Homebrew first."
		return 1
	fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	check_tailscale
fi
