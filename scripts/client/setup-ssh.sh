#!/bin/bash
# =============================================================================
# Setup SSH Access from Client to Server
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

load_config

setup_ssh_keys() {
	log_header "Setting Up SSH Keys"

	# Check for existing keys
	local key_types=("id_ed25519" "id_rsa")
	local found_key=""

	for key_type in "${key_types[@]}"; do
		if [[ -f "${HOME}/.ssh/${key_type}" ]]; then
			found_key="$key_type"
			break
		fi
	done

	if [[ -n "$found_key" ]]; then
		log_success "SSH key found: ${found_key}"

		if confirm "Use existing key?" "y"; then
			SSH_KEY_TYPE="$found_key"
		fi
	fi

	if [[ -z "$SSH_KEY_TYPE" ]]; then
		log_info "Which SSH key type do you want to generate?"
		echo "  1) ed25519 (recommended)"
		echo "  2) rsa (legacy)"
		echo ""
		read -p "Select [1]: " key_choice
		key_choice="${key_choice:-1}"

		case "$key_choice" in
		2)
			SSH_KEY_TYPE="rsa"
			;;
		*)
			SSH_KEY_TYPE="ed25519"
			;;
		esac
	fi

	local key_path="${HOME}/.ssh/id_${SSH_KEY_TYPE}"

	if [[ ! -f "$key_path" ]]; then
		log_info "Generating SSH key (${SSH_KEY_TYPE})..."

		ssh-keygen -t "$SSH_KEY_TYPE" \
			-C "$(whoami)@$(hostname)" \
			-f "$key_path" \
			-N ""

		log_success "SSH key generated"
	else
		log_info "SSH key already exists"
	fi

	log_info "Public key:"
	echo -e "  ${BOLD}$(cat "${key_path}.pub")${NC}"
}

setup_server_connection() {
	log_header "Server Connection Setup"

	# Ask for server hostname
	prompt_input "Server hostname (or IP)" SERVER_HOSTNAME "$SERVER_HOSTNAME"

	# Ask for username
	prompt_input "Username on server" SERVER_USER "$SERVER_USER"

	# Update config
	update_config "SERVER_HOSTNAME" "$SERVER_HOSTNAME"
	update_config "SERVER_USER" "$SERVER_USER"

	log_success "Server configured: ${SERVER_USER}@${SERVER_HOSTNAME}"
}

copy_public_key() {
	local server="$1"
	local user="$2"

	if [[ -z "$server" ]]; then
		load_config
		server="$SERVER_HOSTNAME"
		user="$SERVER_USER"
	fi

	log_header "Copying Public Key to Server"

	# Find public key
	local key_types=("id_ed25519.pub" "id_rsa.pub")
	local pub_key=""

	for key in "${key_types[@]}"; do
		if [[ -f "${HOME}/.ssh/${key}" ]]; then
			pub_key="${HOME}/.ssh/${key}"
			break
		fi
	done

	if [[ -z "$pub_key" ]]; then
		log_error "No public key found. Run setup-ssh.sh without args first."
		return 1
	fi

	log_info "Copying public key to ${user}@${server}..."
	log_info "You may be asked for the password."
	echo ""

	if command -v ssh-copy-id &>/dev/null; then
		ssh-copy-id -i "$pub_key" "${user}@${server}"
	else
		log_info "ssh-copy-id not found, using manual method..."

		# Manual method
		local pub_key_content=$(cat "$pub_key")
		local temp_key_file=$(mktemp)
		echo "$pub_key_content" >"$temp_key_file"

		scp -o StrictHostKeyChecking=accept-new "$temp_key_file" "${user}@${server}:~/tmp_pub_key" &&
			ssh "${user}@${server}" "mkdir -p ~/.ssh && cat ~/tmp_pub_key >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm ~/tmp_pub_key" &&
			rm "$temp_key_file"
	fi

	if [[ $? -eq 0 ]]; then
		log_success "Public key copied successfully"

		# Test connection
		echo ""
		log_info "Testing connection..."
		if ssh -o ConnectTimeout=5 "${user}@${server}" "echo 'SSH OK'" &>/dev/null; then
			log_success "SSH connection verified!"
		else
			log_warning "Could not verify SSH connection. Check server settings."
		fi
	else
		log_error "Failed to copy public key"
		return 1
	fi
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "${1:-all}" in
	keys)
		setup_ssh_keys
		;;
	server)
		setup_server_connection
		;;
	copy)
		copy_public_key "${2}" "${3}"
		;;
	all)
		setup_ssh_keys
		setup_server_connection
		copy_public_key
		;;
	*)
		echo "Usage: $0 {keys|server|copy|all}"
		exit 1
		;;
	esac
fi
