#!/bin/bash
# =============================================================================
# Network Connectivity Tests
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"

load_config

# Test SSH connection
test_ssh() {
	local host="$1"
	local user="${2:-$SERVER_USER}"
	local timeout="${3:-5}"

	log_info "Testing SSH connection to ${user}@${host}..."

	if ssh -o ConnectTimeout="$timeout" \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		"${user}@${host}" "echo 'SSH OK'" &>/dev/null; then
		log_success "SSH connection successful"
		return 0
	else
		log_error "SSH connection failed"
		return 1
	fi
}

# Test Tailscale ping
test_tailscale_ping() {
	local target="$1"

	log_info "Testing Tailscale ping to ${target}..."

	if command -v tailscale &>/dev/null; then
		local result=$(tailscale ping "$target" 2>&1)
		if echo "$result" | grep -q "pong"; then
			log_success "Tailscale ping successful"
			echo "  $result"
			return 0
		else
			log_error "Tailscale ping failed"
			echo "  $result"
			return 1
		fi
	else
		log_warning "Tailscale not available"
		return 1
	fi
}

# Test web panel
test_web_panel() {
	local host="$1"
	local port="${2:-$PANEL_PORT}"

	log_info "Testing web panel at ${host}:${port}..."

	if curl -s --connect-timeout 5 "http://${host}:${port}" &>/dev/null; then
		log_success "Web panel is reachable"
		return 0
	else
		log_warning "Web panel not reachable (may not be running)"
		return 1
	fi
}

# Run all tests (client perspective)
test_all_client() {
	local server_host
	server_host="$(get_magicdns_hostname)"

	log_header "Running Connectivity Tests"

	echo -e "  Server: ${BOLD}${server_host}${NC}"
	echo -e "  User:   ${BOLD}${SERVER_USER}${NC}"
	echo ""

	local failed=0

	test_ssh "$server_host" || failed=1
	echo ""

	test_web_panel "$server_host" || failed=1
	echo ""

	if [[ $failed -eq 0 ]]; then
		log_header "All Tests Passed"
		return 0
	else
		log_header "Some Tests Failed"
		return 1
	fi
}

# Run all tests (server perspective)
test_all_server() {
	log_header "Server Self-Tests"

	local failed=0

	# Test SSH server
	if launchctl list | grep -q "com.openssh.sshd"; then
		log_success "SSH server enabled"
	else
		log_error "SSH server disabled"
		failed=1
	fi

	# Test Tailscale
	if command -v tailscale &>/dev/null; then
		if tailscale status 2>&1 | grep -q "Logged out"; then
			log_error "Tailscale not logged in"
			failed=1
		else
			log_success "Tailscale logged in"
		fi
	else
		log_error "Tailscale not installed"
		failed=1
	fi

	if [[ $failed -eq 0 ]]; then
		log_success "Server self-tests passed"
		return 0
	else
		log_error "Server self-tests failed"
		return 1
	fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "${1:-all}" in
	ssh)
		test_ssh "${2}" "${3:-}"
		;;
	ping)
		test_tailscale_ping "${2}"
		;;
	panel)
		test_web_panel "${2}" "${3:-}"
		;;
	client)
		test_all_client
		;;
	server)
		test_all_server
		;;
	all)
		load_config
		if [[ "$ROLE" == "server" ]]; then
			test_all_server
		else
			test_all_client
		fi
		;;
	*)
		echo "Usage: $0 {ssh|ping|panel|client|server|all}"
		exit 1
		;;
	esac
fi
