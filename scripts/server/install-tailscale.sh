#!/bin/bash
# =============================================================================
# Install and Configure Tailscale on Server (Mac Mini)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

load_config

install_tailscale_server() {
	log_header "Installing Tailscale on Server"

	# Check if already installed
	if command -v tailscale &>/dev/null; then
		log_success "Tailscale already installed"

		# Check if logged in
		local status=$(tailscale status --json 2>/dev/null | grep -o '"LoggedIn":[^,]*' | cut -d: -f2 || echo "false")

		if [[ "$status" == "true" ]]; then
			log_success "Tailscale is already logged in"
			return 0
		fi
	else
		# Install Tailscale
		log_info "Installing Tailscale..."

		if ! command -v brew &>/dev/null; then
			log_error "Homebrew not found. Please install Homebrew first."
			return 1
		fi

		brew install --cask tailscale

		if command -v tailscale &>/dev/null; then
			log_success "Tailscale installed successfully"
		else
			log_error "Failed to install Tailscale"
			return 1
		fi
	fi

	# Start Tailscale
	log_info "Starting Tailscale service..."
	sudo tailscaled install

	log_info "Please authenticate with Tailscale:"
	log_info "  tailscale up --accept-routes"
	echo ""

	# Prompt for auth key or interactive login
	if confirm "Do you have an auth key to use?" "n"; then
		prompt_input "Enter your Tailscale auth key" AUTH_KEY "" "^tskey-auth-[a-zA-Z0-9-]+$"
		tailscale up --authkey="$AUTH_KEY" --accept-routes
	else
		tailscale up --accept-routes
	fi

	log_success "Tailscale started"
}

setup_magicdns() {
	local hostname="${1:-$TAILSCALE_HOSTNAME}"

	log_header "Configuring MagicDNS"

	if ! command -v tailscale &>/dev/null; then
		log_error "Tailscale not installed"
		return 1
	fi

	# Check if logged in
	local status=$(tailscale status --json 2>/dev/null)
	if ! echo "$status" | grep -q '"LoggedIn":true'; then
		log_error "Tailscale not logged in. Please run 'tailscale up' first."
		return 1
	fi

	log_info "Setting MagicDNS hostname to: ${hostname}"
	tailscale set --hostname "$hostname"

	local magicdns_hostname="${hostname}.tailnet.ts.net"
	log_success "MagicDNS configured"
	echo ""
	echo -e "  ${BOLD}Access this server at:${NC}"
	echo -e "  ${GREEN}https://${magicdns_hostname}${NC}"
	echo ""

	# Update config
	update_config "TAILSCALE_HOSTNAME" "$hostname"
}

# Main
install_tailscale_server
setup_magicdns
