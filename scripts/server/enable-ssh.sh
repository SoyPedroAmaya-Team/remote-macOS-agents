#!/bin/bash
# =============================================================================
# Enable SSH Remote Login on macOS Server
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

enable_ssh_server() {
	log_header "Enabling SSH Remote Login"

	# Check if already enabled
	if sudo systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
		log_success "SSH Remote Login is already enabled"
		return 0
	fi

	log_info "This will allow SSH connections to this Mac."

	if confirm "Enable SSH Remote Login?" "y"; then
		log_info "Enabling SSH Remote Login..."

		# Enable Remote Login (SSH)
		sudo systemsetup -f setremotelogin on

		# Verify
		if sudo systemsetup -getremotelogin | grep -q "On"; then
			log_success "SSH Remote Login enabled successfully"
		else
			log_error "Failed to enable SSH Remote Login"
			return 1
		fi
	else
		log_warning "SSH Remote Login not enabled"
		return 1
	fi
}

# Setup authorized_keys directory
setup_authorized_keys() {
	log_info "Setting up SSH authorized_keys..."

	mkdir -p "${HOME}/.ssh"
	chmod 700 "${HOME}/.ssh"

	# Create authorized_keys if it doesn't exist
	if [[ ! -f "${HOME}/.ssh/authorized_keys" ]]; then
		touch "${HOME}/.ssh/authorized_keys"
		chmod 600 "${HOME}/.ssh/authorized_keys"
		log_success "Created ${HOME}/.ssh/authorized_keys"
	else
		log_info "authorized_keys already exists"
	fi

	log_success "SSH directory configured"
}

# Add a public key to authorized_keys
add_authorized_key() {
	local pub_key_file="$1"

	if [[ ! -f "$pub_key_file" ]]; then
		log_error "Public key file not found: $pub_key_file"
		return 1
	fi

	local pub_key=$(cat "$pub_key_file")
	local key_comment=$(echo "$pub_key" | cut -d' ' -f3)

	# Check if key already exists
	if grep -qF "$pub_key" "${HOME}/.ssh/authorized_keys" 2>/dev/null; then
		log_info "Public key already in authorized_keys"
		return 0
	fi

	echo "$pub_key" >>"${HOME}/.ssh/authorized_keys"
	log_success "Added public key to authorized_keys"
	log_info "Key comment: ${key_comment:-(none)}"
}

# Main
enable_ssh_server
setup_authorized_keys
