#!/bin/bash
# =============================================================================
# Install and Configure Tailscale on Client (Laptop)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_tailscale_client() {
	log_header "Installing Tailscale on Client"

	# Check if already installed
	if command -v tailscale &>/dev/null; then
		log_success "Tailscale already installed"

		# Check if logged in
		if tailscale status 2>&1 | grep -q "Logged out"; then
			log_warning "Tailscale not logged in"
		else
			log_success "Tailscale is already logged in"

			# Show connected devices
			echo ""
			log_info "Connected devices:"
			tailscale status | head -10
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

	# On macOS, Tailscale app handles everything
	if [[ "$(uname)" == "Darwin" ]]; then
		log_info "On macOS, Tailscale runs as an app."
		log_info "Open Tailscale app and log in if not already done."
		
		if confirm "Is Tailscale logged in?" "y"; then
			return 0
		else
			log_error "Please log in to Tailscale first"
			return 1
		fi
	else
		# Linux/other
		log_info "Starting Tailscale service..."
		sudo tailscaled install

		log_info "Please authenticate with Tailscale:"
		echo ""

		# Prompt for auth key or interactive login
		if confirm "Do you have an auth key to use?" "n"; then
			prompt_input "Enter your Tailscale auth key" AUTH_KEY "" "^tskey-auth-[a-zA-Z0-9-]+$"
			tailscale up --authkey="$AUTH_KEY" --accept-routes
		else
			tailscale up
		fi
	fi

	log_success "Tailscale started"
}

# List connected devices
list_devices() {
	log_header "Connected Tailscale Devices"

	if ! command -v tailscale &>/dev/null; then
		log_error "Tailscale not installed"
		return 1
	fi

	tailscale status
}

# Ping a device
ping_device() {
	local target="$1"

	if [[ -z "$target" ]]; then
		log_error "Usage: $0 ping <device-name-or-ip>"
		return 1
	fi

	log_info "Pinging ${target}..."
	tailscale ping "$target"
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "${1:-install}" in
	install)
		install_tailscale_client
		;;
	list)
		list_devices
		;;
	ping)
		ping_device "${2}"
		;;
	*)
		echo "Usage: $0 {install|list|ping}"
		exit 1
		;;
	esac
fi
