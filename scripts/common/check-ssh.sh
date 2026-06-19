#!/bin/bash
# =============================================================================
# Check SSH Configuration
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"

check_ssh_keys() {
	log_info "Checking SSH keys..."

	local key_types=("id_ed25519" "id_rsa")
	local found=""

	for key_type in "${key_types[@]}"; do
		if [[ -f "${HOME}/.ssh/${key_type}" ]]; then
			found="$key_type"
			break
		fi
	done

	if [[ -n "$found" ]]; then
		log_success "SSH key found: ${found}"
		log_info "Public key: ${HOME}/.ssh/${found}.pub"
		return 0
	else
		log_warning "No SSH key found"
		echo -e "  Generate: ${BOLD}ssh-keygen -t ed25519${NC}"
		return 1
	fi
}

check_ssh_server() {
	log_info "Checking SSH server..."

	# Check Remote Login status on macOS
	local status=$(sudo systemsetup -getremotelogin 2>/dev/null | grep -o "On\|Off")

	if [[ "$status" == "On" ]]; then
		log_success "SSH Remote Login is enabled"
		return 0
	else
		log_warning "SSH Remote Login is disabled"
		echo -e "  Enable: ${BOLD}sudo systemsetup -f setremotelogin on${NC}"
		return 1
	fi
}

generate_ssh_key() {
	local key_type="${1:-ed25519}"
	local key_path="${HOME}/.ssh/id_${key_type}"

	if [[ -f "$key_path" ]]; then
		log_info "SSH key already exists: $key_path"
		return 0
	fi

	log_info "Generating SSH key (${key_type})..."

	ssh-keygen -t "$key_type" \
		-C "$(whoami)@$(hostname)" \
		-f "$key_path" \
		-N ""

	log_success "SSH key generated: ${key_path}.pub"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "${1:-keys}" in
	keys)
		check_ssh_keys
		;;
	server)
		check_ssh_server
		;;
	generate)
		generate_ssh_key "${2:-ed25519}"
		;;
	*)
		echo "Usage: $0 {keys|server|generate [ed25519|rsa]}"
		exit 1
		;;
	esac
fi
