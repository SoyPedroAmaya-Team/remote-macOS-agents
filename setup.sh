#!/bin/bash
# =============================================================================
# Remote macOS Agents - Setup Script
# =============================================================================
# Main interactive setup for configuring either server (Mac Mini) or client
# (Laptop) in a two-machine remote workflow via Tailscale VPN.
# =============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

# Source libraries
source "${REPO_DIR}/lib/colors.sh"
source "${REPO_DIR}/lib/utils.sh"
source "${REPO_DIR}/lib/config.sh"

# Load existing config if exists
load_config

# =============================================================================
# Help
# =============================================================================

show_help() {
	cat <<EOF
${BOLD}Remote macOS Agents Setup${NC}

${BOLD}Usage:${NC}
    $0 [OPTIONS]

${BOLD}Options:${NC}
    --role=ROLE       Force role: 'server' or 'client'
    --skip-checks     Skip requirement checks
    --skip-tests      Skip connectivity tests
    --verbose         Show detailed output
    -h, --help        Show this help

${BOLD}Examples:${NC}
    $0                  # Interactive mode
    $0 --role=server    # Setup as server
    $0 --role=client    # Setup as client

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

FORCE_ROLE=""
SKIP_CHECKS=false
SKIP_TESTS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--role=*)
		FORCE_ROLE="${1#*=}"
		;;
	--skip-checks)
		SKIP_CHECKS=true
		;;
	--skip-tests)
		SKIP_TESTS=true
		;;
	--verbose)
		VERBOSE=true
		;;
	-h | --help)
		show_help
		exit 0
		;;
	*)
		log_error "Unknown option: $1"
		show_help
		exit 1
		;;
	esac
	shift
done

# =============================================================================
# Role Detection
# =============================================================================

detect_role() {
	local hostname=$(get_hostname)

	case "$hostname" in
	*mini* | *Mac-Mini* | *macmini* | *mini* | *server*)
		echo "server"
		;;
	*MacBook* | *Laptop* | *macbook* | *book* | *air*)
		echo "client"
		;;
	*)
		echo "unknown"
		;;
	esac
}

prompt_role() {
	log_header "Select Device Role"

	echo "What type of device is this?"
	echo ""
	echo "  1) ${BOLD}server${NC} - Mac Mini, always-on machine (runs jobs, serves panel)"
	echo "  2) ${BOLD}client${NC} - Laptop, mobile workstation (connects to server)"
	echo ""
	read -p "Select [1 or 2]: " role_choice

	case "$role_choice" in
	2 | client | Client | CLIENT)
		echo "client"
		;;
	*)
		echo "server"
		;;
	esac
}

# =============================================================================
# Requirements Check
# =============================================================================

check_shared_requirements() {
	log_header "Checking Requirements"

	local failed=0
	local tools=(
		"macOS >= 14"
		"Homebrew"
		"Git"
		"Tailscale"
	)

	for tool in "${tools[@]}"; do
		echo -n "  Checking ${tool}... "
		case "$tool" in
		"macOS "*)
			local min_ver="${tool#macOS >=}"
			if [[ $(sw_vers -productVersion | cut -d. -f1) -ge ${min_ver%%.*} ]]; then
				echo -e "${GREEN}OK${NC}"
			else
				echo -e "${RED}FAIL${NC}"
				failed=1
			fi
			;;
		"Homebrew")
			if command -v brew &>/dev/null; then
				echo -e "${GREEN}OK${NC}"
			else
				echo -e "${RED}FAIL${NC}"
				failed=1
			fi
			;;
		"Git")
			if command -v git &>/dev/null; then
				echo -e "${GREEN}OK${NC}"
			else
				echo -e "${RED}FAIL${NC}"
				failed=1
			fi
			;;
		"Tailscale")
			if command -v tailscale &>/dev/null; then
				if tailscale status 2>&1 | grep -q "Logged out"; then
					echo -e "${YELLOW}NOT LOGGED IN${NC}"
					failed=1
				else
					echo -e "${GREEN}OK${NC}"
				fi
			else
				echo -e "${RED}NOT INSTALLED${NC}"
				failed=1
			fi
			;;
		esac
	done

	if [[ $failed -eq 1 ]]; then
		echo ""
		log_error "Some requirements are not met."
		echo ""
		echo "Please install missing tools and try again."
		return 1
	fi

	log_success "All requirements met"
	return 0
}

# =============================================================================
# Server Setup
# =============================================================================

setup_server() {
	log_header "Server Setup (Mac Mini)"

	# Update role
	ROLE="server"
	update_config "ROLE" "$ROLE"

	echo ""
	log_info "Server setup will:"
	echo "  1. Enable SSH Remote Login"
	echo "  2. Configure Tailscale with MagicDNS"
	echo "  3. Setup web panel port"
	echo ""

	if ! confirm "Continue with server setup?"; then
		log_warning "Setup cancelled"
		return 1
	fi

	# 1. Enable SSH
	echo ""
	"${REPO_DIR}/scripts/server/enable-ssh.sh"

	# 2. Setup Tailscale
	echo ""
	"${REPO_DIR}/scripts/server/install-tailscale.sh"

	# 3. Configure panel
	echo ""
	"${REPO_DIR}/scripts/server/configure-panel.sh"

	# Save final config
	save_config

	# Tests
	if [[ "$SKIP_TESTS" == "false" ]]; then
		echo ""
		"${REPO_DIR}/scripts/common/network-test.sh" server
	fi

	log_header "Server Setup Complete!"
	echo ""
	echo -e "  ${BOLD}Server hostname:${NC} $(get_magicdns_hostname)"
	echo -e "  ${BOLD}SSH ready at:${NC} ${SERVER_USER}@$(get_magicdns_hostname)"
	echo ""
	log_info "Add client public keys to ~/.ssh/authorized_keys to allow access."
}

# =============================================================================
# Client Setup
# =============================================================================

setup_client() {
	log_header "Client Setup (Laptop)"

	# Update role
	ROLE="client"
	update_config "ROLE" "$ROLE"

	echo ""
	log_info "Client setup will:"
	echo "  1. Ensure Tailscale is connected to the same network"
	echo "  2. Setup SSH keys"
	echo "  3. Configure server connection"
	echo "  4. Copy SSH key to server"
	echo "  5. Run connectivity tests"
	echo ""

	if ! confirm "Continue with client setup?"; then
		log_warning "Setup cancelled"
		return 1
	fi

	# 1. Check Tailscale
	echo ""
	"${REPO_DIR}/scripts/client/install-tailscale.sh"

	# 2. Setup SSH
	echo ""
	"${REPO_DIR}/scripts/client/setup-ssh.sh" keys
	
	# 3. Force update server connection (always ask for hostname)
	echo ""
	log_info "Updating server connection..."
	"${REPO_DIR}/scripts/client/setup-ssh.sh" server

	# 4. Copy key to server
	echo ""
	"${REPO_DIR}/scripts/client/setup-ssh.sh" copy

	# Save final config
	save_config

	# Tests
	if [[ "$SKIP_TESTS" == "false" ]]; then
		echo ""
		"${REPO_DIR}/scripts/common/network-test.sh" client
	fi

	log_header "Client Setup Complete!"
	echo ""
	echo -e "  ${BOLD}Server:${NC} ${SERVER_USER}@$(get_magicdns_hostname)"
	echo ""
	log_info "You can now SSH to the server with:"
	echo -e "  ${BOLD}ssh ${SERVER_USER}@$(get_magicdns_hostname)${NC}"
}

# =============================================================================
# Main
# =============================================================================

main() {
	clear

	echo -e "${CYAN}${BOLD}"
	echo "╔═══════════════════════════════════════════════════╗"
	echo "║       Remote macOS Agents - Setup                 ║"
	echo "╚═══════════════════════════════════════════════════╝"
	echo -e "${NC}"

	# Check for existing config
	if [[ -f "$CONFIG_FILE" ]]; then
		echo -e "Existing configuration found:"
		show_config
		echo ""

		if confirm "Use existing configuration?"; then
			if [[ "$ROLE" == "server" ]]; then
				setup_server
			elif [[ "$ROLE" == "client" ]]; then
				setup_client
			else
				ROLE=$(prompt_role)
				save_config
				if [[ "$ROLE" == "server" ]]; then
					setup_server
				else
					setup_client
				fi
			fi
			return
		fi
	fi

	# Determine role
	if [[ -n "$FORCE_ROLE" ]]; then
		ROLE="$FORCE_ROLE"
		log_info "Role forced to: $ROLE"
	else
		DETECTED=$(detect_role)

		if [[ "$DETECTED" == "unknown" ]]; then
			ROLE=$(prompt_role)
		else
			echo -e "Detected role: ${BOLD}${DETECTED}${NC}"
			if confirm "Is this correct?"; then
				ROLE="$DETECTED"
			else
				ROLE=$(prompt_role)
			fi
		fi
	fi

	# Check requirements
	if [[ "$SKIP_CHECKS" == "false" ]]; then
		echo ""
		if ! check_shared_requirements; then
			exit 1
		fi
	fi

	# Run setup based on role
	if [[ "$ROLE" == "server" ]]; then
		setup_server
	else
		setup_client
	fi

	echo ""
	log_success "Done!"
}

main "$@"
