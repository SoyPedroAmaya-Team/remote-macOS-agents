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

	# Check if already enabled using netstat or lsof
	if sudo lsof -i :22 &>/dev/null; then
		log_success "SSH Remote Login is already enabled (port 22 in use)"
		return 0
	fi

	log_info "This will allow SSH connections to this Mac."

	if confirm "Enable SSH Remote Login?" "y"; then
		# Try launchctl first
		log_info "Trying to enable SSH via launchctl..."
		sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null

		sleep 2

		# Check if it worked
		if sudo lsof -i :22 &>/dev/null; then
			log_success "SSH Remote Login enabled successfully"
			return 0
		fi

		# If launchctl failed, ask user to enable manually
		log_error "Could not enable SSH automatically."
		echo ""
		echo "Please enable SSH manually:"
		echo "  1. Click Apple menu → System Settings"
		echo "  2. Go to General → Sharing"
		echo "  3. Enable 'Remote Login'"
		echo ""

		if confirm "Has SSH been enabled manually?" "y"; then
			if sudo lsof -i :22 &>/dev/null; then
				log_success "SSH is now enabled"
				return 0
			else
				log_error "SSH still not enabled"
				return 1
			fi
		else
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
